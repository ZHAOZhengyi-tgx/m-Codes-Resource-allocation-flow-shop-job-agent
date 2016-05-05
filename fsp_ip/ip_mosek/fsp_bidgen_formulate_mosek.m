function [fsp_resalloc_formulation, stMachineProcessMapping, lagrangian_info] = fsp_bidgen_formulate_mosek(jobshop_config, stBerthJobInfo)
% Prototype:
%    [fsp_resalloc_formulation, stMachineProcessMapping, lagrangian_info] =psa_resalloc_formulate_mosek(jobshop_config, stBerthJobInfo)
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

%if jobshop_config.iOptRule == 26 | jobshop_config.iOptRule == 28
    stResourceConfig = jobshop_config.stResourceConfig;
%end

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
%%%
fFactorFramePerSlot = jobshop_config.fTimeUnit_Min/60/stBerthJobInfo.fTimeFrameUnitInHour;
iTotalTimeFrame = floor(jobshop_config.iTotalTimeSlot * fFactorFramePerSlot) + 1;
%% Allocation of memory
total_col = sum(jobshop_config.stProcessPerJob ) * jobshop_config.iTotalTimeSlot + jobshop_config.iTotalMachine * iTotalTimeFrame;
total_row = sum(jobshop_config.stProcessPerJob ) * (jobshop_config.iTotalTimeSlot - 1);
MatrixA = sparse([], [], [], total_col, total_row, 0);
col_base_machine_time = sum(jobshop_config.stProcessPerJob ) * jobshop_config.iTotalTimeSlot;

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
row_second_constr = curr_row;
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
            B_LowConstr(curr_row) = 0;
            B_UppConstr(curr_row) = 0;
%            MatrixA(curr_row, :)
%            if ii == 1
%                input('Any key')
%            end
            curr_row = curr_row + 1;
            curr_col = curr_col + 1;
        end
    end
end    

row_third_constr = curr_row;
%% Third kind of constraits: a critical operation cannot start until all
%% previous job's critial operation has finished
for ii = 2:1:jobshop_config.iTotalJob
    if jobshop_config.iJobType(ii-1) == 1   % previous job is a discharge type
        jj_prev_job_critical_proc = 1;
    elseif jobshop_config.iJobType(ii-1) == 2   % previous job is a load type
        jj_prev_job_critical_proc = 3;
    else
        error('Only discharge job and loading job are enabled')
    end
    iTimeSlotPrevProcess = jobshop_config.jsp_process_time(ii-1).iProcessTime(jj_prev_job_critical_proc);
%    if ii == 2 %% For Debugging
%        iTimeSlotPrevProcess
%    end
    if jobshop_config.iJobType(ii) == 1   % current job is a discharge type
        jj_current_job_critical_proc = 1;
    elseif jobshop_config.iJobType(ii) == 2   % current job is a load type
        jj_current_job_critical_proc = 3;
    else
        error('Only discharge job and loading job are enabled')
    end

    curr_col = iStartIndexJobVariable(ii) + (jj_current_job_critical_proc-1)* jobshop_config.iTotalTimeSlot;
    
    for tt = 1:1:jobshop_config.iTotalTimeSlot
        MatrixA(curr_row, curr_col) = 1;
        index_prev_job_critical_proc = iStartIndexJobVariable(ii-1) + (jj_prev_job_critical_proc - 1)*jobshop_config.iTotalTimeSlot ...
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
%% solution
MatrixA(curr_row, jobshop_config.iTimeStartFirstJobFirstProcess) = 1;
B_LowConstr(curr_row) = 1;
B_UppConstr(curr_row) = 1;
curr_row = curr_row + 1;

row_fourth_constr = curr_row;
%% Fourth Kind of Constraints: the machine capacity constraints. At any
%% time, at most one job can be processed on a paricular machine.
%% col_base_machine_time
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
        idx_col_var_machine_time_cap = col_base_machine_time + (kk -1)* iTotalTimeFrame + floor(tt*fFactorFramePerSlot) + 1;
        MatrixA(curr_row, idx_col_var_machine_time_cap) = -1;
        B_LowConstr(curr_row) = -inf;
        B_UppConstr(curr_row) = 0;
        curr_row = curr_row + 1;
    end
end

row_fifth_constr = curr_row;
%% Fifth kind of constraints: machine usage at every time frame must be
%% >= 1
for kk = 1:1:jobshop_config.iTotalMachine
    for tt = 1:1:iTotalTimeFrame
        idx_col_var_machine_time_cap = col_base_machine_time + (kk -1)* iTotalTimeFrame + tt;
        MatrixA(curr_row, idx_col_var_machine_time_cap) = 1;
        B_LowConstr(curr_row) = 1;
        B_UppConstr(curr_row) = inf;
        curr_row = curr_row + 1;
    end
end

%% sixth kind of constraints: all job's all operations must finish in last
%% operation
row_sixth_constr = curr_row;
for ii = 1:1:jobshop_config.iTotalJob
    for jj = 1:1:jobshop_config.stProcessPerJob(ii)
        iTimeSlotCurrProcess = jobshop_config.jsp_process_time(ii).iProcessTime(jj);
        curr_col = iStartIndexJobVariable(ii) + jj* jobshop_config.iTotalTimeSlot - iTimeSlotCurrProcess;
        MatrixA(curr_row, curr_col) = 1;
        B_LowConstr(curr_row) = 1;
        B_UppConstr(curr_row) = 1;
        curr_row = curr_row + 1;
    end
end
row_constr_1_2_3_4_5_6 = [1, row_second_constr, row_third_constr, row_fourth_constr, row_fifth_constr, row_sixth_constr]

%%% Relaxed Constraints Information
lagrangian_info.iRelaxedConstrIndexList = row_fourth_constr:length(B_UppConstr);
lagrangian_info.iTotalRelexedConstr = length(lagrangian_info.iRelaxedConstrIndexList);
%lagrangian_info.lamda = zeros(lagrangian_info.iTotalRelexedConstr, 1);
lagrangian_info.alpha_r = jobshop_config.stLagrangianRelax.alpha_r;
lagrangian_info.iHeuristicAchieveFeasibility = jobshop_config.stLagrangianRelax.iHeuristicAchieveFeasibility;
lagrangian_info.iMaxIter = jobshop_config.stLagrangianRelax.iMaxIter;
lagrangian_info.fDesiredDualityGap = jobshop_config.stLagrangianRelax.fDesiredDualityGap;

%%% Constraints on variables
%blx = sparse(zeros(col_base_machine_time, 1));
%blx((col_base_machine_time + 1): total_col, 1) = ones(total_col - col_base_machine_time, 1);
blx = sparse(zeros(total_col, 1));
bux = ones(col_base_machine_time, 1);
for kk = 1:1:jobshop_config.iTotalMachine
    for tt = 1:1:iTotalTimeFrame
        idx_col_var_machine_time_cap = col_base_machine_time + (kk -1)* iTotalTimeFrame + tt;
        bux(idx_col_var_machine_time_cap) = jobshop_config.iMaxMachineUsageInSch0(kk);
    end
end
        %%% according to the time variant machine capacity
%        if stResourceConfig.stMachineConfig(kk).iNumPointTimeCap == 0
%            B_UppConstr(curr_row) = jobshop_config.iTotalMachineNum(kk);  % machine capacity for each type of machine
%        else
%            [iCapAtTime, iIndex] = calc_table_look_up(stResourceConfig.stMachineConfig(kk).afMaCapAtTimePoint, ...
%                          stResourceConfig.stMachineConfig(kk).afTimePointAtCap, ...
%                          tt-1);
%            B_UppConstr(curr_row) = iCapAtTime;
%        end
        %%%

%%% Cost Vector
obj_offset = 0;
c = sparse([], [], [], total_col, 1, 0);
%%% Tardiness cost
%for ii = 1:1:jobshop_config.iTotalJob
    ii = jobshop_config.iTotalJob;
    fJobDueByDay = datenum(jobshop_config.atClockJobDue.aClockYearMonthDateHourMinSec) - datenum(jobshop_config.atClockJobStart.aClockYearMonthDateHourMinSec);
    iJobDueTimeSlot = floor(fJobDueByDay * 24 * 60/jobshop_config.fTimeUnit_Min) + 1
    iLastProcess = jobshop_config.stProcessPerJob(ii);
    iLastProcessTime = jobshop_config.jsp_process_time(ii).iProcessTime(iLastProcess);
    base_col_last_process = iStartIndexJobVariable(ii) - 1 + (iLastProcess-1)* jobshop_config.iTotalTimeSlot;
    for tt = (iJobDueTimeSlot - iLastProcessTime)+1:1:jobshop_config.iTotalTimeSlot
        c(tt + base_col_last_process, 1) = - jobshop_config.fOverallTardinessPenalty * fFactorFramePerSlot;
        obj_offset = obj_offset - c(tt + base_col_last_process, 1);
    end
%end
%%% Makespan Cost
iLastJob = jobshop_config.iTotalJob;
iJobDueTime = 0;
iLastProcess = jobshop_config.stProcessPerJob(iLastJob);
iLastProcessTime = jobshop_config.jsp_process_time(iLastJob).iProcessTime(iLastProcess);
base_col_last_process = iStartIndexJobVariable(iLastJob) - 1 + (iLastProcess-1)* jobshop_config.iTotalTimeSlot;
for tt = 1:1:jobshop_config.iTotalTimeSlot
    c(tt + base_col_last_process, 1) = c(tt + base_col_last_process, 1) - jobshop_config.fMakespanCost * fFactorFramePerSlot;
    obj_offset = obj_offset + jobshop_config.fMakespanCost * fFactorFramePerSlot;
end
%%% Resource Cost
for kk = 2:1:jobshop_config.iTotalMachine
    for tt = 1:1:iTotalTimeFrame
        idx_col_var_machine_time_cap = col_base_machine_time + (kk -1)* iTotalTimeFrame + tt;
        tDate = tt * stBerthJobInfo.fTimeFrameUnitInHour/24 + datenum(jobshop_config.atClockJobStart.aClockYearMonthDateHourMinSec);
        tHour = (tDate - floor(tDate))*24;
        iFrame = floor(tHour/stBerthJobInfo.fTimeFrameUnitInHour) + 1;
        %% to be add
        if kk == 2
            c(idx_col_var_machine_time_cap, 1) = stBerthJobInfo.fPricePrimeMoverDollarPerFrame(iFrame) ; % astResourceInitPrice(kk).afMachinePriceListPerFrame(tt)
        elseif kk == 3
            c(idx_col_var_machine_time_cap, 1) = stBerthJobInfo.fPriceYardCraneDollarPerFrame(iFrame) ;
        end
    end
end
%c(col_base_machine_time:end)

%%%%%%%%%%%%%%%%%%%%%%%%%% compose output    
fsp_resalloc_formulation.mosek_form.a = MatrixA;
fsp_resalloc_formulation.mosek_form.blc = B_LowConstr;
fsp_resalloc_formulation.mosek_form.buc = B_UppConstr;
fsp_resalloc_formulation.mosek_form.c = c;
fsp_resalloc_formulation.mosek_form.blx = blx;
fsp_resalloc_formulation.mosek_form.bux = bux;
fsp_resalloc_formulation.obj_offset = 0; %obj_offset;
fsp_resalloc_formulation.mosek_form.ints.sub = 1:total_col;
fsp_resalloc_formulation.mosek_form.index_start_machine_constr = row_fourth_constr;


for ii = 1:1:jobshop_config.iTotalJob
    lagrangian_info.job_var_info(ii).iMaxIndex = max(lagrangian_info.job_var_info(ii).iVarIndexList);
    lagrangian_info.job_var_info(ii).iMinIndex = min(lagrangian_info.job_var_info(ii).iVarIndexList);
end