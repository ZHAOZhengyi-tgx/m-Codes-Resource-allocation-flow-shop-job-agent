function [jobshop_formulation, stMachineProcessMapping, lagrangian_info] = psa_jsp_formulate_mosek(jobshop_config)
% Prototype:
%    [jobshop_formulation, stMachineProcessMapping, lagrangian_info] = psa_jsp_formulate_mosek(jobshop_config)
% Problem Formulation with machine capacity and job dependency
% INPUT:
%
% jobshop_config: a struct containing following variables:
%              iTotalJob: Total Number of Jobs
%          iTotalMachine: Total Number of Machines
%         iTotalTimeSlot: Total Time Slot
%            iAlgoOption: Algorithm Option
%              fTimeUnit: Time Unit for each time 1
%        stProcessPerJob: An array with length of iTotalJob, total process for each job
%       jsp_process_time: array of iTotalJob structs, each struct contains two arrays with same length
%                 iProcessTime:  Integer Array 
%                 fProcessTime:  Floating Array
%    jsp_process_machine: array of iTotalJob structs, each struct contains one array
%                 iProcessMachine: integer array
%
%% History
% YYYYMMDD  Notes
% 20070629  comments remove the iOptRule = 16, 17, 18
% 20070701  modification to relax the critical operational sequencing
% complete (default) MIP Model: non-preemptive, no-wait in operation,
% machine capacity, critical operational sequencing( strict COS)
% constraints, X = 0 or 1
%          XXXX,XXXX,XXXX,XXXX
%                 ||       110 --> MIP, and solution by MOSEK, 
%                 ||      1001 --> Lagrangian Relaxation
%                 ||    1,0001 --> MIP formulation only
%                  --------------> 00: strict COS, 01: semi-strict COS,
%                  10:Userdefine, 11: complete no COS
% 20070724 Add jobshop_config.stJssProbStructConfig.isCriticalOperateSeq,
% to replace above defination

global OBJ_MINIMIZE_MAKESPAN;
global OBJ_MINIMIZE_SUM_TARDINESS;

jobshop_config.iOptRule;
% iCnstBitsConfigCOS = 768; % 20070701
% iCnstBitsLow8BitsOptRule = 255;
% iConfigCOS = bitand(jobshop_config.iOptRule, iCnstBitsConfigCOS);
% iOptRuleLower8Bits = bitand(jobshop_config.iOptRule, iCnstBitsLow8BitsOptRule); 


%% always support multiple period resource configuration
stResourceConfig = jobshop_config.stResourceConfig;

for kk = 1:1:jobshop_config.iTotalMachine
    stMachineProcessMapping(kk).iTotalProcess = 0;
end
for ii = 1:1:jobshop_config.iTotalJob
    for jj = 1:1:jobshop_config.stProcessPerJob(ii)
        kk = jobshop_config.jsp_process_machine(ii).iProcessMachine(jj);
        stMachineProcessMapping(kk).iTotalProcess = stMachineProcessMapping(kk).iTotalProcess + 1;
        stMachineProcessMapping(kk).stJobProcess(stMachineProcessMapping(kk).iTotalProcess).iJobId = ii;
        stMachineProcessMapping(kk).stJobProcess(stMachineProcessMapping(kk).iTotalProcess).iProcessId = jj;
    end
end
%% A mapping from JobId to the start variables for this job
for ii = 1:1:jobshop_config.iTotalJob
    if ii >= 2
        iStartIndexJobVariable(ii) = sum(jobshop_config.stProcessPerJob(1:(ii-1))) * jobshop_config.iTotalTimeSlot + 1;
    else
        iStartIndexJobVariable(ii) = 1;
    end
end

%%
curr_var_index = 1;
for ii = 1:1:jobshop_config.iTotalJob
    total_var_curr_job = jobshop_config.stProcessPerJob(ii) * jobshop_config.iTotalTimeSlot;
    lagrangian_info.job_var_info(ii).iJobId = ii;
    lagrangian_info.job_var_info(ii).iVarIndexList = curr_var_index : (curr_var_index + total_var_curr_job - 1);
    lagrangian_info.job_var_info(ii).iTotalVar = total_var_curr_job;
    curr_var_index = curr_var_index + total_var_curr_job;
end

%% Allocation of memory, 20070724, last jobshop_config.iTotalTimeSlot
%% variables are dummy operation, to get the makespan of all job's
%% operations
iTotalNumOperation =  sum(jobshop_config.stProcessPerJob );
if jobshop_config.stJssProbStructConfig.isCriticalOperateSeq == 0
    total_col = iTotalNumOperation * jobshop_config.iTotalTimeSlot + jobshop_config.iTotalTimeSlot;  %% total num. of variables
    idxBaseVarDummyOperation = iTotalNumOperation * jobshop_config.iTotalTimeSlot;                   %% 20070724
else
    total_col = iTotalNumOperation * jobshop_config.iTotalTimeSlot;  %% total num. of variables
end
total_row = iTotalNumOperation * (jobshop_config.iTotalTimeSlot - 1);                            %% total num. of constraints, should be greater than it
MatrixA = sparse([], [], [], total_col, total_row, 0);

%% First kind of constraints make sure that once an operation(process) is
%% started, it remains so in all subsequent time periods.
curr_row = 1;
curr_col = 1;
for ii = 1:1:jobshop_config.iTotalJob
    lagrangian_info.job_constr_info(ii).iJobId = ii;
    lagrangian_info.job_constr_info(ii).iTotalConstr = 0;
    for jj = 1:1:jobshop_config.stProcessPerJob(ii)
        for tt = 1:1:jobshop_config.iTotalTimeSlot - 1
            lagrangian_info.job_constr_info(ii).iTotalConstr = lagrangian_info.job_constr_info(ii).iTotalConstr + 1;
            lagrangian_info.job_constr_info(ii).iConstrIndexList(lagrangian_info.job_constr_info(ii).iTotalConstr) = curr_row;
            MatrixA(curr_row, curr_col) = 1;
            MatrixA(curr_row, curr_col + 1) = -1;
            B_LowConstr(curr_row) = -inf;
            B_UppConstr(curr_row) = 0;
            curr_row = curr_row + 1;
            curr_col = curr_col + 1;
        end
        curr_col = curr_col + 1;
    end
end
%% Second kind of constraits: an operation cannot start until all its
%% predecessors are completed. An operation will start immediately after
%% its predecessor has compeleted.
row_second_constr = curr_row
for ii = 1:1:jobshop_config.iTotalJob
    for jj = 2:1:jobshop_config.stProcessPerJob(ii)
        iTimeSlotPrevProcess = jobshop_config.jsp_process_time(ii).iProcessTime(jj - 1);
        curr_col = iStartIndexJobVariable(ii) + (jj-1)* jobshop_config.iTotalTimeSlot;
        
        for tt = 1:1:jobshop_config.iTotalTimeSlot
            lagrangian_info.job_constr_info(ii).iTotalConstr = lagrangian_info.job_constr_info(ii).iTotalConstr + 1;
            lagrangian_info.job_constr_info(ii).iConstrIndexList(lagrangian_info.job_constr_info(ii).iTotalConstr) = curr_row;
            MatrixA(curr_row, curr_col) = 1;
            if (curr_col - jobshop_config.iTotalTimeSlot - iTimeSlotPrevProcess) >= iStartIndexJobVariable(ii) + (jj-2)* jobshop_config.iTotalTimeSlot
                MatrixA(curr_row, curr_col - jobshop_config.iTotalTimeSlot - iTimeSlotPrevProcess) = -1;
            %% else    
            end %% else, the variable should start as 0

            if jobshop_config.iOptRule == 6 | jobshop_config.iOptRule == 9 | jobshop_config.iOptRule == 17 % % 20070701, 20070724
                if jobshop_config.stJssProbStructConfig.isWaitInProcess == 0
                % no wait in process
                    B_LowConstr(curr_row) = 0;
                    B_UppConstr(curr_row) = 0;
                else % wait is allowed
                     B_LowConstr(curr_row) = -inf;
                     B_UppConstr(curr_row) = 0;
                end
                %% following commented code is for consideration of adding wait between processes between any taskes % 20070629
            % elseif jobshop_config.iOptRule == 16  %% Add in-process wait for all job and processes 
            % elseif jobshop_config.iOptRule ==  %% relax PM and YC in-process wait, process 2 and 3 for discharge and process 1 and 2 for load
            %     if jobshop_config.iJobType(ii) == 1 %% a discharge job
            %         if jj == 2
            %             B_LowConstr(curr_row) = 0;
            %             B_UppConstr(curr_row) = 0;
            %         elseif jj ==3
            %             B_LowConstr(curr_row) = -inf;
            %             B_UppConstr(curr_row) = 0;
            %         else
            %         end
            %     elseif jobshop_config.iJobType(ii) == 2 %% a load job
            %         if jj == 3
            %             B_LowConstr(curr_row) = 0;
            %             B_UppConstr(curr_row) = 0;
            %         elseif jj == 2
            %             B_LowConstr(curr_row) = -inf;
            %             B_UppConstr(curr_row) = 0;
            %         else
            %         end
            %     end
            % elseif jobshop_config.iOptRule == 18  %% relax Machine-1 and Machine-2 in-process wait, process 1 and 2 for discharge and process 2 and 3 for load
            %     if jobshop_config.iJobType(ii) == 1 %% a discharge job
            %         if jj == 3
            %             B_LowConstr(curr_row) = 0;
            %             B_UppConstr(curr_row) = 0;
            %         elseif jj ==2
            %             B_LowConstr(curr_row) = -inf;
            %             B_UppConstr(curr_row) = 0;
            %         else
            %         end
            %     elseif jobshop_config.iJobType(ii) == 2 %% a load job
            %         if jj == 2
            %             B_LowConstr(curr_row) = 0;
            %             B_UppConstr(curr_row) = 0;
            %         elseif jj == 3
            %             B_LowConstr(curr_row) = -inf;
            %             B_UppConstr(curr_row) = 0;
            %         else
            %         end
            %     end
            else
            end
%            MatrixA(curr_row, :)
%            if ii == 1
%                input('Any key')
%            end
            curr_row = curr_row + 1;
            curr_col = curr_col + 1;
        end
    end
end    
aiJobSeqInJspCfg = jobshop_config.aiJobSeqInJspCfg;

row_third_constr = curr_row
%% Third kind of constraits: a critical operation cannot start until all
%% previous job's critial operation has finished, 
if jobshop_config.stJssProbStructConfig.isCriticalOperateSeq == 0
    %% complete no COS constraints, % 20070701, 20070724

else
    %% strict COS constraints
    for ii = 2:1:jobshop_config.iTotalJob
        iPrevJobId = aiJobSeqInJspCfg(ii - 1);
        iCurrJobId = aiJobSeqInJspCfg(ii);
        if jobshop_config.iJobType(iPrevJobId) == 1   % previous job is a discharge type
            jj_prev_job_critical_proc = 1;
        elseif jobshop_config.iJobType(iPrevJobId) == 2   % previous job is a load type
            jj_prev_job_critical_proc = jobshop_config.iTotalMachine;
        else
            error('Only discharge job and loading job are enabled')
        end
        iTimeSlotPrevProcess = jobshop_config.jsp_process_time(iPrevJobId).iProcessTime(jj_prev_job_critical_proc);
    %    if ii == 2 %% For Debugging
    %        iTimeSlotPrevProcess
    %    end
        if jobshop_config.iJobType(iCurrJobId) == 1   % current job is a discharge type
            jj_current_job_critical_proc = 1;
        elseif jobshop_config.iJobType(iCurrJobId) == 2   % current job is a load type
            jj_current_job_critical_proc = jobshop_config.iTotalMachine;
        else
            error('Only discharge job and loading job are enabled')
        end

        curr_col = iStartIndexJobVariable(iCurrJobId) + (jj_current_job_critical_proc-1)* jobshop_config.iTotalTimeSlot;

        for tt = 1:1:jobshop_config.iTotalTimeSlot
            MatrixA(curr_row, curr_col) = 1;
            index_prev_job_critical_proc = iStartIndexJobVariable(iPrevJobId) + (jj_prev_job_critical_proc - 1)*jobshop_config.iTotalTimeSlot ...
                + tt - iTimeSlotPrevProcess - 1;
            if tt > iTimeSlotPrevProcess
                MatrixA(curr_row, index_prev_job_critical_proc) = -1;
                %% else    
            end %% else, the variable should start as 0
            B_LowConstr(curr_row) = -inf;
            B_UppConstr(curr_row) = 0;
            %            MatrixA(curr_row, :)
            %            if ii == 1
            %                input('Any key')       
            %            end
            curr_row = curr_row + 1;
            curr_col = curr_col + 1;
        end
    end

    %% The start time of the first job's first process, is from the heuristic
    %% solution, % 20070701
    if jobshop_config.iOptRule == 6 | jobshop_config.iOptRule == 17 % | jobshop_config.iOptRule == 26
        MatrixA(curr_row, jobshop_config.iTimeStartFirstJobFirstProcess) = 1;
        B_LowConstr(curr_row) = 1;
        B_UppConstr(curr_row) = 1;
        curr_row = curr_row + 1;
    end
    
end

row_fourth_constr = curr_row
%% Fourth Kind of Constraints: the machine capacity constraints. At any
%% time, at most one job can be processed on a paricular machine.
for kk = 1:1:jobshop_config.iTotalMachine
    iTotalProcessOnMachine = stMachineProcessMapping(kk).iTotalProcess;
    for tt = 1:1:jobshop_config.iTotalTimeSlot
        for jj = 1:1:iTotalProcessOnMachine
            iJobOnMachine = stMachineProcessMapping(kk).stJobProcess(jj).iJobId;
            iProcessOnMachine = stMachineProcessMapping(kk).stJobProcess(jj).iProcessId;
            time_process = jobshop_config.jsp_process_time(iJobOnMachine).iProcessTime(iProcessOnMachine);
            curr_col = iStartIndexJobVariable(iJobOnMachine) + (iProcessOnMachine-1)* jobshop_config.iTotalTimeSlot + tt - 1;
            MatrixA(curr_row, curr_col) = 1;
            if tt > time_process
                MatrixA(curr_row, curr_col - time_process) = -1;
            end
        end
        B_LowConstr(curr_row) = 0;
%        B_LowConstr(curr_row) = -inf;
        %%% according to the time variant machine capacity
        if stResourceConfig.stMachineConfig(kk).iNumPointTimeCap == 0
            B_UppConstr(curr_row) = jobshop_config.iTotalMachineNum(kk);  % machine capacity for each type of machine
        else
            [iCapAtTime, iIndex] = calc_table_look_up(stResourceConfig.stMachineConfig(kk).afMaCapAtTimePoint, ...
                          stResourceConfig.stMachineConfig(kk).afTimePointAtCap, ...
                          tt-1);
            B_UppConstr(curr_row) = iCapAtTime;
        end
        %%%
        curr_row = curr_row + 1;
    end
end

row_fifth_constr = curr_row
%%% Fifth constraints, all jobs' all operations must complete at the end
for ii = 1:1:jobshop_config.iTotalJob
%    for jj = 1:1:jobshop_config.stProcessPerJob(ii)
     jj = jobshop_config.stProcessPerJob(ii);
        iTimeSlotCurrProcess = jobshop_config.jsp_process_time(ii).iProcessTime(jj);
        curr_col = lagrangian_info.job_var_info(ii).iVarIndexList(1) - 1 + jj*  jobshop_config.iTotalTimeSlot - iTimeSlotCurrProcess;
        MatrixA(curr_row, curr_col) = 1;
        B_LowConstr(curr_row) = 1;
        B_UppConstr(curr_row) = 1;
        curr_row = curr_row + 1;
%    end
end

%%% Sixth constraints, formulate the makespan
if jobshop_config.stJssProbStructConfig.isCriticalOperateSeq == 0
    row_sixth_constr = curr_row
    for ii = 1:1:jobshop_config.iTotalJob
        idxLastOperation = jobshop_config.stProcessPerJob(ii);
        for tt = 1:1:jobshop_config.iTotalTimeSlot
            curr_col_job_var = iStartIndexJobVariable(ii) + (idxLastOperation-1)* jobshop_config.iTotalTimeSlot + tt - 1;
            curr_col_dummy_operation = idxBaseVarDummyOperation + tt;
            MatrixA(curr_row, curr_col_job_var) = 1;
            MatrixA(curr_row, curr_col_dummy_operation) = -1;
            B_LowConstr(curr_row) = 0;
            B_UppConstr(curr_row) = inf;
            curr_row = curr_row + 1;
        end
    end
end

%%% Relaxed Constraints Information
lagrangian_info.iRelaxedConstrIndexList = row_fourth_constr:length(B_UppConstr);
lagrangian_info.iTotalRelexedConstr = length(lagrangian_info.iRelaxedConstrIndexList);
%lagrangian_info.lamda = zeros(lagrangian_info.iTotalRelexedConstr, 1);
lagrangian_info.alpha_r = jobshop_config.stLagrangianRelax.alpha_r;
lagrangian_info.iHeuristicAchieveFeasibility = jobshop_config.stLagrangianRelax.iHeuristicAchieveFeasibility;
lagrangian_info.iMaxIter = jobshop_config.stLagrangianRelax.iMaxIter;
lagrangian_info.fDesiredDualityGap = jobshop_config.stLagrangianRelax.fDesiredDualityGap;

%%% Constraints on variables
bux = ones(total_col, 1);
blx = sparse(zeros(total_col, 1));

%%% Cost Vector
obj_offset = 0;
c = sparse([], [], [], total_col, 1, 0);
% 20070701, it has strict Critial Operational Sequencing constraints,
% 20070724
if jobshop_config.stJssProbStructConfig.isCriticalOperateSeq == 1

    iLastJob = jobshop_config.iTotalJob
    iJobDueTime = 0; %jobshop_config.aJobDueTime(iLastJob);
    iLastProcess = jobshop_config.stProcessPerJob(iLastJob);
    iLastProcessTime = jobshop_config.jsp_process_time(iLastJob).iProcessTime(iLastProcess);
    base_col_last_process = iStartIndexJobVariable(iLastJob) - 1 + (iLastProcess-1)* jobshop_config.iTotalTimeSlot;
    for tt = (iJobDueTime - iLastProcessTime)+1:1:jobshop_config.iTotalTimeSlot
        c(tt + base_col_last_process, 1) = - jobshop_config.aJobWeight(iLastJob);
        obj_offset = obj_offset + jobshop_config.aJobWeight(iLastJob);
    end

elseif jobshop_config.stJssProbStructConfig.isCriticalOperateSeq == 0
% 20070629, % 20070701, 20070724
    if jobshop_config.stJssProbStructConfig.iFlagObjFuncDefine == OBJ_MINIMIZE_MAKESPAN
        base_col_dummy_process = idxBaseVarDummyOperation;
        for tt = 1:1:jobshop_config.iTotalTimeSlot
            c(tt + base_col_dummy_process, 1) = -1;
            obj_offset = obj_offset + 1;
        end
    else % sum tardiness
        for ii = 1:1:jobshop_config.iTotalJob
            iJobDueTime = 0;
            iLastProcess = jobshop_config.stProcessPerJob(ii);
            iLastProcessTime = jobshop_config.jsp_process_time(ii).iProcessTime(iLastProcess);
            base_col_last_process = iStartIndexJobVariable(ii) - 1 + (iLastProcess-1)* jobshop_config.iTotalTimeSlot;
            for tt = (iJobDueTime - iLastProcessTime)+1:1:jobshop_config.iTotalTimeSlot
                c(tt + base_col_last_process, 1) = - jobshop_config.aJobWeight(ii);
                obj_offset = obj_offset + jobshop_config.aJobWeight(ii);
            end
        end
    end
end
    
jobshop_formulation.mosek_form.a = MatrixA;
jobshop_formulation.mosek_form.blc = B_LowConstr;
jobshop_formulation.mosek_form.buc = B_UppConstr;
jobshop_formulation.mosek_form.c = c;
jobshop_formulation.mosek_form.blx = blx;
jobshop_formulation.mosek_form.bux = bux;
jobshop_formulation.obj_offset = 0; %obj_offset;
jobshop_formulation.mosek_form.ints.sub = 1:total_col;
jobshop_formulation.mosek_form.index_start_machine_constr = row_fourth_constr;


for ii = 1:1:jobshop_config.iTotalJob
    lagrangian_info.job_var_info(ii).iMaxIndex = max(lagrangian_info.job_var_info(ii).iVarIndexList);
    lagrangian_info.job_var_info(ii).iMinIndex = min(lagrangian_info.job_var_info(ii).iVarIndexList);
end