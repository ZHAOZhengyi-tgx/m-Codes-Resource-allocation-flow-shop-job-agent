function [fsp_resalloc_formulation, astAgentFormulateInfo] = fsp_resalloc_formulate_mosek(stResAllocSystemJspCfg, stSystemMasterConfig, stJssProbStructConfig)
% flow-shop-problem resource allocation, formulate to MOSEK format
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%  
%
%The MIT License (MIT)
%
%Copyright (c) 2016 ZHAOZhengyi-tgx
%
%Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the "Software"), to deal in the Software without restriction, including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions:
%
%The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.
%
%THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%
% Module: Solution for Resource Allocation among Scheduling Agents 
% Template for Problem Input
% OUTPUT from the solver: schedule for each job's process, dispatching for each machine
% During this whole document, % is for line commenting, which means any line starting with a % will not be taken into parsing.
%
% all right reserved (c)2016
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% all right reserved, @2016, Sg.LongRenE@gmail.com
% Prototype:
%    [fsp_resalloc_formulation, stMachineProcessMapping, lagrangian_info] =fsp_resalloc_formulate_mosek(stResAllocSystemJspCfg, stSystemMasterConfig, stJssProbStructConfig)
% Problem Formulation with machine capacity and job dependency
% INPUT:
% 
% stResAllocSystemJspCfg.tEarlistStartTime_datenum
% stResAllocSystemJspCfg.tLatestEndTime_datenum
% stResAllocSystemJspCfg.iTotalTimeT
% stResAllocSystemJspCfg.stJspConfigList(1:stSystemMasterConfig.iTotalAgent)-- 
%     jobshop_config: a struct containing following variables:
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
% History
% YYYYMMDD Notes
% 20070724 Add Job Shop Scheduling Problem Struct Config
% 20071026 Add idxBaseVarDummyStartOperation, for constraints on release time
%if jobshop_config.iOptRule == 26 | jobshop_config.iOptRule == 28
%    stResourceConfig = jobshop_config.stResourceConfig;
%end

%% 20070724
global OBJ_MINIMIZE_MAKESPAN;
global OBJ_MINIMIZE_SUM_TARDINESS;
global OBJ_MINIMIZE_SUM_TARD_MAKESPAN;
%% 20070724
iPlotFlag = stSystemMasterConfig.iPlotFlag;

for qq = 1:1:stSystemMasterConfig.iTotalAgent
    jobshop_config = stResAllocSystemJspCfg.stJspConfigList(qq);
    for kk = 1:1:jobshop_config.iTotalMachine
        astAgentFormulateInfo(qq).stMachineProcessMapping(kk).iTotalProcess = 0;
    end
    for ii = 1:1:jobshop_config.iTotalJob
        for jj = 1:1:jobshop_config.stProcessPerJob(ii)
            kk = jobshop_config.jsp_process_machine(ii).iProcessMachine(jj);
            iCurrentTotalProcessOnMachineK = astAgentFormulateInfo(qq).stMachineProcessMapping(kk).iTotalProcess + 1;
            astAgentFormulateInfo(qq).stMachineProcessMapping(kk).iTotalProcess = iCurrentTotalProcessOnMachineK;
            astAgentFormulateInfo(qq).stMachineProcessMapping(kk).stJobProcess(iCurrentTotalProcessOnMachineK).iJobId = ii;
            astAgentFormulateInfo(qq).stMachineProcessMapping(kk).stJobProcess(iCurrentTotalProcessOnMachineK).iProcessId = jj;
            astAgentFormulateInfo(qq).stMachineProcessMapping(kk).stJobProcess(iCurrentTotalProcessOnMachineK).iAgentId = qq;
        end
    end
end

iTotalTimeSlotGlbAgent = stResAllocSystemJspCfg.iTotalTimeSlot;
iTotalTimeFrameGlbRes = stResAllocSystemJspCfg.iTotalTimeFrame;
%% A mapping from JobId to the start variables for this job
for qq = 1:1:stSystemMasterConfig.iTotalAgent
    stCurrJspConfig = stResAllocSystemJspCfg.stJspConfigList(qq);
    if qq == 1
        for ii = 1:1:stCurrJspConfig.iTotalJob
            if ii >= 2
                astAgentFormulateInfo(qq).iStartIndexJobVariable(ii) = stCurrJspConfig.stProcessPerJob(ii-1) * iTotalTimeSlotGlbAgent +  ...
                    astAgentFormulateInfo(qq).iStartIndexJobVariable(ii-1);
            else
                astAgentFormulateInfo(qq).iStartIndexJobVariable(ii) = 1;
            end
        end
    else
        stPrevJspConfig = stResAllocSystemJspCfg.stJspConfigList(qq-1);
        for ii = 1:1:stCurrJspConfig.iTotalJob
            if ii >= 2
                astAgentFormulateInfo(qq).iStartIndexJobVariable(ii) = stCurrJspConfig.stProcessPerJob(ii-1) * iTotalTimeSlotGlbAgent +  ...
                    astAgentFormulateInfo(qq).iStartIndexJobVariable(ii-1);
            else
                astAgentFormulateInfo(qq).iStartIndexJobVariable(ii) = astAgentFormulateInfo(qq-1).iStartIndexJobVariable(stPrevJspConfig.iTotalJob) + ...
                    stPrevJspConfig.stProcessPerJob(stPrevJspConfig.iTotalJob) * iTotalTimeSlotGlbAgent +  ...
                    iTotalTimeFrameGlbRes * stPrevJspConfig.iTotalMachine;
            end
        end
    end
end

for qq = 1:1:stSystemMasterConfig.iTotalAgent
    stCurrJspConfig = stResAllocSystemJspCfg.stJspConfigList(qq);
    for kk = 1:1:stSystemMasterConfig.iTotalMachType
        if kk == 1
            astAgentFormulateInfo(qq).stMachineUsageVariable(kk).iVarableStartIndex = astAgentFormulateInfo(qq).iStartIndexJobVariable(stCurrJspConfig.iTotalJob) + ...
                stCurrJspConfig.stProcessPerJob(stCurrJspConfig.iTotalJob) * iTotalTimeSlotGlbAgent;
            astAgentFormulateInfo(qq).stMachineUsageVariable(kk).iVarableEndIndex = astAgentFormulateInfo(qq).stMachineUsageVariable(kk).iVarableStartIndex + ...
                iTotalTimeFrameGlbRes - 1;
        else
            astAgentFormulateInfo(qq).stMachineUsageVariable(kk).iVarableStartIndex = astAgentFormulateInfo(qq).stMachineUsageVariable(kk-1).iVarableEndIndex + 1;
            astAgentFormulateInfo(qq).stMachineUsageVariable(kk).iVarableEndIndex = astAgentFormulateInfo(qq).stMachineUsageVariable(kk).iVarableStartIndex + ...
                iTotalTimeFrameGlbRes - 1;
            
        end
    end
end

%%%
curr_var_index = 1;
for qq = 1:1:stSystemMasterConfig.iTotalAgent
    stCurrJspConfig = stResAllocSystemJspCfg.stJspConfigList(qq);
    for ii = 1:1:stCurrJspConfig.iTotalJob
        total_var_curr_job = stCurrJspConfig.stProcessPerJob(ii) * iTotalTimeSlotGlbAgent;
        astAgentFormulateInfo(qq).lagrangian_info.job_var_info(ii).iJobId = ii;
        astAgentFormulateInfo(qq).lagrangian_info.job_var_info(ii).iVarIndexList = curr_var_index : (curr_var_index + total_var_curr_job - 1);
        astAgentFormulateInfo(qq).lagrangian_info.job_var_info(ii).iTotalVar = total_var_curr_job;
        curr_var_index = curr_var_index + total_var_curr_job;
    end
    curr_var_index = curr_var_index + iTotalTimeFrameGlbRes * stCurrJspConfig.iTotalMachine;
end
%%%

% if stSystemMasterConfig.fTimeFrameUnitInHour ~= 1
%     error('stSystemMasterConfig.fTimeFrameUnitInHour must be 1');
% end
fFactorFramePerSlot = stResAllocSystemJspCfg.tMinmumTimeUnit_Min /60/stSystemMasterConfig.fTimeFrameUnitInHour;
fEpsilonStartTime = 0.1 * fFactorFramePerSlot/24;
%% Allocation of memory
total_col = 0;
total_row = 0;
for qq = 1:1:stSystemMasterConfig.iTotalAgent
    stCurrJspConfig = stResAllocSystemJspCfg.stJspConfigList(qq);
    total_col = total_col + sum(stCurrJspConfig.stProcessPerJob ) * iTotalTimeSlotGlbAgent + stCurrJspConfig.iTotalMachine * iTotalTimeFrameGlbRes;
    total_row = total_row + sum(stCurrJspConfig.stProcessPerJob ) * (iTotalTimeSlotGlbAgent - 1);
    %% total_row is less than actual total number of constraints, 
    %% matlab will extend later
end

%% 20070724
if stJssProbStructConfig.isCriticalOperateSeq == 0
    for qq = 1:1:stSystemMasterConfig.iTotalAgent
        idxBaseVarDummyOperation(qq) = total_col;
        total_col = total_col + iTotalTimeSlotGlbAgent;  %% for problem with No COS, formulate the makespan
    end
    for qq = 1:1:stSystemMasterConfig.iTotalAgent       % 20071026 
        idxBaseVarDummyStartOperation(qq) = total_col;
        total_col = total_col + iTotalTimeSlotGlbAgent;  %% for problem with No COS, formulate the makespan
    end          % 20071026 
end
%% 20070724
MatrixA = sparse([], [], [], total_col, total_row, 0);

for qq = 1:1:stSystemMasterConfig.iTotalAgent
    stCurrJspConfig = stResAllocSystemJspCfg.stJspConfigList(qq);
    if qq == 1
        astAgentFormulateInfo(qq).col_base_machine_time = sum(stCurrJspConfig.stProcessPerJob ) * iTotalTimeSlotGlbAgent;
    else
        astAgentFormulateInfo(qq).col_base_machine_time = astAgentFormulateInfo(qq).iStartIndexJobVariable(1) - 1 + ...
            sum(stCurrJspConfig.stProcessPerJob) * iTotalTimeSlotGlbAgent;
    end
end

%%% Start Formulating
%%% fill in the matrix
curr_row = 1;
for qq = 1:1:stSystemMasterConfig.iTotalAgent
    jobshop_config = stResAllocSystemJspCfg.stJspConfigList(qq);
    curr_col = astAgentFormulateInfo(qq).iStartIndexJobVariable(1);

%% First kind of constraints make sure that once an operation(process) is
%% started, it remains so in all subsequent time periods.
    row_first_constr = curr_row;
    for ii = 1:1:jobshop_config.iTotalJob
        astAgentFormulateInfo(qq).lagrangian_info.job_constr_info(ii).iJobId = ii;
        astAgentFormulateInfo(qq).lagrangian_info.job_constr_info(ii).iTotalConstr = 0;
        for jj = 1:1:jobshop_config.stProcessPerJob(ii)
            for tt = 1:1:iTotalTimeSlotGlbAgent - 1
                iTotalConstr = astAgentFormulateInfo(qq).lagrangian_info.job_constr_info(ii).iTotalConstr + 1;
                astAgentFormulateInfo(qq).lagrangian_info.job_constr_info(ii).iTotalConstr = iTotalConstr;
                astAgentFormulateInfo(qq).lagrangian_info.job_constr_info(ii).iConstrIndexList(iTotalConstr) = curr_row;
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
    %% its predecessor has compeleted. No wait in process
    row_second_constr = curr_row;
    for ii = 1:1:jobshop_config.iTotalJob
        for jj = 2:1:jobshop_config.stProcessPerJob(ii)
            iTimeSlotPrevProcess = jobshop_config.jsp_process_time(ii).iProcessTime(jj - 1);
            curr_col = astAgentFormulateInfo(qq).iStartIndexJobVariable(ii) + (jj-1)* iTotalTimeSlotGlbAgent;

            for tt = 1:1:iTotalTimeSlotGlbAgent
                iTotalConstr = astAgentFormulateInfo(qq).lagrangian_info.job_constr_info(ii).iTotalConstr + 1;
                astAgentFormulateInfo(qq).lagrangian_info.job_constr_info(ii).iTotalConstr = iTotalConstr;
                astAgentFormulateInfo(qq).lagrangian_info.job_constr_info(ii).iConstrIndexList(iTotalConstr) = curr_row;
                MatrixA(curr_row, curr_col) = 1;
                if (curr_col - iTotalTimeSlotGlbAgent - iTimeSlotPrevProcess) >= astAgentFormulateInfo(qq).iStartIndexJobVariable(ii) + (jj-2)* iTotalTimeSlotGlbAgent
                    MatrixA(curr_row, curr_col - iTotalTimeSlotGlbAgent - iTimeSlotPrevProcess) = -1;
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

    aiJobSeqInJspCfg = jobshop_config.aiJobSeqInJspCfg;
    %% Third kind of constraits: a critical operation cannot start until all
    %% previous job's critial operation has finished %% 20070724
    row_third_constr = curr_row;
    if stJssProbStructConfig.isCriticalOperateSeq ~= 0
        for ii = 2:1:jobshop_config.iTotalJob
            iPrevJobId = aiJobSeqInJspCfg(ii - 1);
            iCurrJobId = aiJobSeqInJspCfg(ii);
            if jobshop_config.iJobType(iPrevJobId) == 1   % previous job is a discharge type
                jj_prev_job_critical_proc = 1;
            elseif jobshop_config.iJobType(iPrevJobId) == 2   % previous job is a load type
                jj_prev_job_critical_proc = stSystemMasterConfig.iTotalMachType;
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
                jj_current_job_critical_proc = stSystemMasterConfig.iTotalMachType;
            else
                error('Only discharge job and loading job are enabled')
            end

            curr_col = astAgentFormulateInfo(qq).iStartIndexJobVariable(iCurrJobId) + (jj_current_job_critical_proc-1)* iTotalTimeSlotGlbAgent;

            for tt = 1:1:iTotalTimeSlotGlbAgent
                MatrixA(curr_row, curr_col) = 1;
                index_prev_job_critical_proc = astAgentFormulateInfo(qq).iStartIndexJobVariable(iPrevJobId) + (jj_prev_job_critical_proc - 1)*iTotalTimeSlotGlbAgent ...
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
    end %% 20070724


    %% Fourth Kind of Constraints: the machine capacity constraints. At any
    %% time, at most one job can be processed on a paricular machine.
    %% col_base_machine_time
    row_fourth_constr = curr_row;
    for kk = 1:1:jobshop_config.iTotalMachine
        iTotalProcessOnMachine = astAgentFormulateInfo(qq).stMachineProcessMapping(kk).iTotalProcess;
        for tt = 1:1:iTotalTimeSlotGlbAgent
            for jj = 1:1:iTotalProcessOnMachine
                iJobOnMachine = astAgentFormulateInfo(qq).stMachineProcessMapping(kk).stJobProcess(jj).iJobId;
                iProcessOnMachine = astAgentFormulateInfo(qq).stMachineProcessMapping(kk).stJobProcess(jj).iProcessId;
                iAgentIdOnMachine = astAgentFormulateInfo(qq).stMachineProcessMapping(kk).stJobProcess(jj).iAgentId;
                time_process = jobshop_config.jsp_process_time(iJobOnMachine).iProcessTime(iProcessOnMachine);
                curr_col = astAgentFormulateInfo(qq).iStartIndexJobVariable(iJobOnMachine) + (iProcessOnMachine-1)* iTotalTimeSlotGlbAgent + tt - 1;
                MatrixA(curr_row, curr_col) = 1;
                if tt > time_process
                    MatrixA(curr_row, curr_col - time_process) = -1;
                end
            end
            idx_col_var_machine_time_cap = astAgentFormulateInfo(qq).col_base_machine_time + (kk -1)* iTotalTimeFrameGlbRes + floor((tt-1)*fFactorFramePerSlot) + 1;
            MatrixA(curr_row, idx_col_var_machine_time_cap) = -1;
            B_LowConstr(curr_row) = -inf;
            B_UppConstr(curr_row) = 0;
            curr_row = curr_row + 1;
        end
    end

    row_fifth_constr = curr_row;
    %% fifth kind of constraints:
    %% The start time of the first job's first process.
    %% It cannot start before earliest start time --- job release time.
    fAbsDiffStartTime = datenum(jobshop_config.atClockJobStart.aClockYearMonthDateHourMinSec) - stResAllocSystemJspCfg.tEarlistStartTime_datenum;
    if stJssProbStructConfig.isCriticalOperateSeq == 1
        idxVarFirstJobFirstProcessStartTimeSlot = astAgentFormulateInfo(qq).iStartIndexJobVariable(1) - 1 + ...
            floor((datenum(jobshop_config.atClockJobStart.aClockYearMonthDateHourMinSec) - stResAllocSystemJspCfg.tEarlistStartTime_datenum)*24*60 ...
                    /stResAllocSystemJspCfg.tMinmumTimeUnit_Min + jobshop_config.iTimeStartFirstJobFirstProcess);
    else %% idxBaseVarDummyStartOperation, 20071026 
        idxVarFirstJobFirstProcessStartTimeSlot = idxBaseVarDummyStartOperation(qq) + ...
            floor((datenum(jobshop_config.atClockJobStart.aClockYearMonthDateHourMinSec) - stResAllocSystemJspCfg.tEarlistStartTime_datenum)*24*60 ...
                    /stResAllocSystemJspCfg.tMinmumTimeUnit_Min + jobshop_config.iTimeStartFirstJobFirstProcess);
    end  %% 20071026 for NoCOS
    if fAbsDiffStartTime < fEpsilonStartTime
        MatrixA(curr_row, idxVarFirstJobFirstProcessStartTimeSlot) = 1;
        B_LowConstr(curr_row) = 1;
        B_UppConstr(curr_row) = 1;
    else
        MatrixA(curr_row, idxVarFirstJobFirstProcessStartTimeSlot) = 1;
        B_LowConstr(curr_row) = 0;
        B_UppConstr(curr_row) = 0;

        curr_row = curr_row + 1;
        MatrixA(curr_row, idxVarFirstJobFirstProcessStartTimeSlot+1) = 1;
        B_LowConstr(curr_row) = 1;
        B_UppConstr(curr_row) = 1;
    end
    curr_row = curr_row + 1;
    
    if stJssProbStructConfig.isCriticalOperateSeq == 0 %% idxBaseVarDummyStartOperation, 20071026
        for ii = 1:1:jobshop_config.iTotalJob
            for tt = 1:1:iTotalTimeSlotGlbAgent
                curr_col_job_var = astAgentFormulateInfo(qq).iStartIndexJobVariable(ii) + tt - 1; % every job's first operation
                curr_col_dummy_start_operation = idxBaseVarDummyStartOperation(qq) + tt;
                MatrixA(curr_row, curr_col_job_var) = 1;
                MatrixA(curr_row, curr_col_dummy_start_operation) = -1;
                B_LowConstr(curr_row) = -inf;
                B_UppConstr(curr_row) = 0;
                curr_row = curr_row + 1;
            end
        end
    end %% 20071026 for NoCOS
    %% sixth kind of constraints: machine usage at every time frame must be
    %% >= 1
    row_sixth_constr = curr_row;
    for kk = 1:1:jobshop_config.iTotalMachine
        for tt = 1:1:iTotalTimeFrameGlbRes
            idx_col_var_machine_time_cap = astAgentFormulateInfo(qq).col_base_machine_time + (kk -1)* iTotalTimeFrameGlbRes + tt;
            MatrixA(curr_row, idx_col_var_machine_time_cap) = 1;
            B_LowConstr(curr_row) = 1;
            B_UppConstr(curr_row) = inf;
            curr_row = curr_row + 1;
        end
    end

    %% seventh kind of constraints: all job's all operations must finish in last
    %% operation
    row_seventh_constr = curr_row;
    for ii = 1:1:jobshop_config.iTotalJob
        for jj = 1:1:jobshop_config.stProcessPerJob(ii)
            iTimeSlotCurrProcess = jobshop_config.jsp_process_time(ii).iProcessTime(jj);
            curr_col = astAgentFormulateInfo(qq).iStartIndexJobVariable(ii) + jj* iTotalTimeSlotGlbAgent - iTimeSlotCurrProcess;
            MatrixA(curr_row, curr_col) = 1;
            B_LowConstr(curr_row) = 1;
            B_UppConstr(curr_row) = 1;
            curr_row = curr_row + 1;
        end
    end

    %%  kind of constraints %% 20070724
    row_eightth_constr = curr_row;
    if stJssProbStructConfig.isCriticalOperateSeq == 0
        for ii = 1:1:jobshop_config.iTotalJob
            idxLastOperation = jobshop_config.stProcessPerJob(ii);
            for tt = 1:1:iTotalTimeSlotGlbAgent
                curr_col_job_var = astAgentFormulateInfo(qq).iStartIndexJobVariable(ii) + (idxLastOperation-1)* iTotalTimeSlotGlbAgent + tt - 1;
                curr_col_dummy_operation = idxBaseVarDummyOperation(qq) + tt;
                MatrixA(curr_row, curr_col_job_var) = 1;
                MatrixA(curr_row, curr_col_dummy_operation) = -1;
                B_LowConstr(curr_row) = 0;
                B_UppConstr(curr_row) = inf;
                curr_row = curr_row + 1;
            end
        end
    end
    row_constr_1_2_3_4_5_6_7_8 = [row_first_constr, row_second_constr, row_third_constr, row_fourth_constr, row_fifth_constr, row_sixth_constr, row_seventh_constr, row_eightth_constr];

    if iPlotFlag >= 1
        row_constr_1_2_3_4_5_6_7_8
    end
end

%seventh kind of constraints: machine capacity constraint, sum of biddings
%are less than total number of machine on berth
machine_cap_constr = curr_row;
for kk = 1:1:stSystemMasterConfig.iTotalMachType
    for pp = 1:1:iTotalTimeFrameGlbRes
        for qq = 1:1:stSystemMasterConfig.iTotalAgent
            curr_col = astAgentFormulateInfo(qq).col_base_machine_time +  (kk -1)* iTotalTimeFrameGlbRes + pp; 
            MatrixA(curr_row, curr_col) = 1;
        end
        B_LowConstr(curr_row) = 0;
        B_UppConstr(curr_row) = stResAllocSystemJspCfg.astMachineCapAtPeriod(pp).aiMaxMachineCapacity(kk);
        curr_row = curr_row + 1;
    end
end
total_constr = curr_row - 1;

%%% Relaxed Constraints Information
%lagrangian_info.iRelaxedConstrIndexList = row_fourth_constr:length(B_UppConstr);
%lagrangian_info.iTotalRelexedConstr = length(lagrangian_info.iRelaxedConstrIndexList);
%lagrangian_info.lamda = zeros(lagrangian_info.iTotalRelexedConstr, 1);
%lagrangian_info.alpha_r = jobshop_config.stLagrangianRelax.alpha_r;
%lagrangian_info.iHeuristicAchieveFeasibility = jobshop_config.stLagrangianRelax.iHeuristicAchieveFeasibility;
%lagrangian_info.iMaxIter = jobshop_config.stLagrangianRelax.iMaxIter;
%lagrangian_info.fDesiredDualityGap = jobshop_config.stLagrangianRelax.fDesiredDualityGap;

%%% Constraints on variables
%blx = sparse(zeros(col_base_machine_time, 1));
%blx((col_base_machine_time + 1): total_col, 1) = ones(total_col - col_base_machine_time, 1);
blx = sparse(zeros(total_col, 1));
bux = ones(total_col, 1);
for qq = 1:1:stSystemMasterConfig.iTotalAgent
    jobshop_config = stResAllocSystemJspCfg.stJspConfigList(qq);
    for kk = 1:1:jobshop_config.iTotalMachine
        for pp = 1:1:iTotalTimeFrameGlbRes
            idx_col_var_machine_time_cap = astAgentFormulateInfo(qq).col_base_machine_time + (kk -1)* iTotalTimeFrameGlbRes + pp;
            bux(idx_col_var_machine_time_cap) = jobshop_config.iMaxMachineUsageInSch0(kk);
        end
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
if stJssProbStructConfig.isCriticalOperateSeq ~= 0
    for qq = 1:1:stSystemMasterConfig.iTotalAgent
        jobshop_config = stResAllocSystemJspCfg.stJspConfigList(qq);
        ii = jobshop_config.iTotalJob;
        fJobDueByDay = datenum(jobshop_config.atClockJobDue.aClockYearMonthDateHourMinSec) - datenum(jobshop_config.atClockJobStart.aClockYearMonthDateHourMinSec);
        iJobDueTimeSlot = floor(fJobDueByDay * 24 * 60/stResAllocSystemJspCfg.tMinmumTimeUnit_Min) + 1;
        iLastProcess = jobshop_config.stProcessPerJob(ii);
        iLastProcessTime = jobshop_config.jsp_process_time(ii).iProcessTime(iLastProcess);
        base_col_last_process = astAgentFormulateInfo(qq).iStartIndexJobVariable(ii) - 1 + (iLastProcess-1)* iTotalTimeSlotGlbAgent;
        for tt = (iJobDueTimeSlot - iLastProcessTime)+1:1:iTotalTimeSlotGlbAgent
            c(tt + base_col_last_process, 1) = - jobshop_config.fOverallTardinessPenalty * fFactorFramePerSlot;
            obj_offset = obj_offset + jobshop_config.fOverallTardinessPenalty * fFactorFramePerSlot;
        end
    end
else %% 20070724
    for qq = 1:1:stSystemMasterConfig.iTotalAgent        
        jobshop_config = stResAllocSystemJspCfg.stJspConfigList(qq);
        fJobDueByDay = datenum(jobshop_config.atClockJobDue.aClockYearMonthDateHourMinSec) - datenum(jobshop_config.atClockJobStart.aClockYearMonthDateHourMinSec);
        iJobDueTimeSlot = floor(fJobDueByDay * 24 * 60/stResAllocSystemJspCfg.tMinmumTimeUnit_Min) + 1;
            
        base_col_dummy_process = idxBaseVarDummyOperation(qq);
        for tt = iJobDueTimeSlot+1:1:iTotalTimeSlotGlbAgent
            c(tt + base_col_dummy_process, 1) = - jobshop_config.fOverallTardinessPenalty * fFactorFramePerSlot;
            obj_offset = obj_offset - c(tt + base_col_dummy_process, 1);
        end
    end    
end
%end
%%% Makespan Cost
if stJssProbStructConfig.isCriticalOperateSeq ~= 0
    for qq = 1:1:stSystemMasterConfig.iTotalAgent
        jobshop_config = stResAllocSystemJspCfg.stJspConfigList(qq);
        iLastJob = jobshop_config.iTotalJob;
        iLastProcess = jobshop_config.stProcessPerJob(iLastJob);
        iLastProcessTime = jobshop_config.jsp_process_time(iLastJob).iProcessTime(iLastProcess);
        base_col_last_process = astAgentFormulateInfo(qq).iStartIndexJobVariable(iLastJob) - 1 + (iLastProcess-1)* iTotalTimeSlotGlbAgent;
        for tt = 1:1:iTotalTimeSlotGlbAgent
            c(tt + base_col_last_process, 1) = c(tt + base_col_last_process, 1) - jobshop_config.fMakespanCost * fFactorFramePerSlot;
            obj_offset = obj_offset + jobshop_config.fMakespanCost * fFactorFramePerSlot;
        end
    end
else %% 20070724
    for qq = 1:1:stSystemMasterConfig.iTotalAgent        
        base_col_dummy_process = idxBaseVarDummyOperation(qq);
        for tt = 1:1:iTotalTimeSlotGlbAgent
            c(tt + base_col_dummy_process, 1) = - stResAllocSystemJspCfg.stJspConfigList(qq).fOverallTardinessPenalty * fFactorFramePerSlot;
            obj_offset = obj_offset - c(tt + base_col_dummy_process, 1);
        end
    end   
end
%%% Resouce usage should be zero, if no task on it
for qq = 1:1:stSystemMasterConfig.iTotalAgent
    for kk = 1:1:stSystemMasterConfig.iTotalMachType
        c(astAgentFormulateInfo(qq).stMachineUsageVariable(kk).iVarableStartIndex: astAgentFormulateInfo(qq).stMachineUsageVariable(kk).iVarableEndIndex, 1) ...
            = ones(iTotalTimeFrameGlbRes, 1);
    end
end
    

%%%%%%%%%%%%%%%%%%%%%%%%%% compose output    
[total_constr, total_var] = size(MatrixA);

fsp_resalloc_formulation.mosek_form.a = MatrixA;
fsp_resalloc_formulation.mosek_form.blc = B_LowConstr;
fsp_resalloc_formulation.mosek_form.buc = B_UppConstr;
fsp_resalloc_formulation.mosek_form.c = c;
fsp_resalloc_formulation.mosek_form.blx = blx;
fsp_resalloc_formulation.mosek_form.bux = bux;
fsp_resalloc_formulation.obj_offset = obj_offset;
fsp_resalloc_formulation.mosek_form.ints.sub = 1:total_col;
fsp_resalloc_formulation.mosek_form.index_start_machine_constr = row_fourth_constr;


for qq = 1:1:stSystemMasterConfig.iTotalAgent
    jobshop_config = stResAllocSystemJspCfg.stJspConfigList(qq);
    for ii = 1:1:jobshop_config.iTotalJob
        astAgentFormulateInfo(qq).lagrangian_info.job_var_info(ii).iMaxIndex = max(astAgentFormulateInfo(qq).lagrangian_info.job_var_info(ii).iVarIndexList);
        astAgentFormulateInfo(qq).lagrangian_info.job_var_info(ii).iMinIndex = min(astAgentFormulateInfo(qq).lagrangian_info.job_var_info(ii).iVarIndexList);
    end
end

