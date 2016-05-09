function [stJspSchedule, astRelTimeMachType] = jsp_solve_mm_sp_heu_rand(stJspCfg, astRelTimeMachType)
% [stJspSchedule] = jsp_solve_mm_sp_heu(stJspCfg)
% Multi-Machine
% Single-Period
% Allow Wait in Process
% jsp(open shop, flow shop) mm(Multi-machine) sp(Single-period)
% a floating process time version of jsp_solution_heuristic01
% INPUT:
% stJspCfg: a struct containing following variables:
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
% OUTPUT:
% stJspSchedule: a struct with following variables
%    iTotalJob: 
%    stProcessPerJob: 
%    stJobSet: 
% stJspSchedule.stJobSet: an array (length of stJspSchedule.iTotalJob )of struct with following variables
%    iProcessStartTime: an array with length as stJspSchedule.stProcessPerJob
%    iProcessEndTime:   an array with length as stJspSchedule.stProcessPerJob
%    iProcessMachine:   an array with length as stJspSchedule.stProcessPerJob

%% Local Variables
%% astQuingTaskByJob: Que for Executable Task(in the sense of operation precedence) 
%% astQuingTaskMachType(mm): Machine List for each type
%% astMachTypeSche(1:stJspCfg.iTotalMachine).tRelTimeAtOneMach
%%    tRelTimeAtOneMach(1:stJspCfg.iTotalMachineNum(mm)
%% Initialize the SchedulableOperationSet
% History
% YYYYMMDD Notes
% 20080429 Add different objective function values

jsp_glb_define();
global OBJ_MINIMIZE_MAKESPAN;
global OBJ_MINIMIZE_SUM_TARDINESS;

global tEpsilonTime;

iCheckSumSchedulableOperation = 0;
for ii = 1:1:stJspCfg.iTotalJob
    astQuingTaskByJob(ii).iJobId = ii;
    if stJspCfg.stProcessPerJob(ii) >= 1
        astQuingTaskByJob(ii).iProcessToStart = 1;
    end
    astQuingTaskByJob(ii).ProcessTime = stJspCfg.jsp_process_time(ii).fProcessTime(1);
    astQuingTaskByJob(ii).iProcMachType = stJspCfg.jsp_process_machine(ii).iProcessMachine(1);
    iCheckSumSchedulableOperation = iCheckSumSchedulableOperation + astQuingTaskByJob(ii).iJobId;
end
%% Initialize the Current Time Slot for Job on each machine, all machines
%% are available at planning start
if ~exist('astRelTimeMachType')
    for mm = 1:1:stJspCfg.iTotalMachine
        for mi = 1:1:stJspCfg.iTotalMachineNum(mm)
            astRelTimeMachType(mm).tRelTimeAtOneMach(mi) = 0;
        end
        %% to be extended for multiperiod, 
        astRelTimeMachType(mm).nTotalAvailMach = stJspCfg.iTotalMachineNum(mm);
    end
end

iFlagObjFuncDefine = stJspCfg.stJssProbStructConfig.iFlagObjFuncDefine;

%% Initialize stJspSchedule
[stJspSchedule] = jsp_constr_sche_struct_by_cfg(stJspCfg);
ga_init_seed(stJspCfg);

%%% each time astQuingTaskMachType be initialized for all machines
astQuingTaskMachTypeInit = jsp_init_qtask_per_mype(stJspCfg, astQuingTaskByJob);

%% bakup the initial variables.
stJspScheduleInit = stJspSchedule;
astRelTimeMachTypeInit = astRelTimeMachType;
astQuingTaskByJobInit = astQuingTaskByJob;
iCheckSumInit = iCheckSumSchedulableOperation;

%% Initialize a population of sequence, stJspCfg.stGASetting.iPopSize
nMaxProcess = max(stJspCfg.stProcessPerJob);
nTotalMachineType = stJspCfg.iTotalMachine;
nTotalCaseBySeq = 20; % temperarily hardcoded, stJspCfg.stGASetting.iPopSize;
stJspCfg.iPlotFlag = 1;
for ii = 1:1:nTotalCaseBySeq
    aiSeqMachType = [];
    for bb = 1:1:nMaxProcess
        aiSeqMachType = [aiSeqMachType, randperm(nTotalMachineType)];
    end
    astCaseBySeq(ii).aiSeqMachType = aiSeqMachType;
    astCaseBySeq(ii).stScheduleJobSet = [];
    astCaseBySeq(ii).fMakespan = [];
end

for cc = 1:1:nTotalCaseBySeq
%    Load initial variables
    stJobSet = stJspScheduleInit.stJobSet;
    astRelTimeMachType = astRelTimeMachTypeInit;
    astQuingTaskByJob = astQuingTaskByJobInit;
    astQuingTaskMachType= astQuingTaskMachTypeInit;
    iCheckSumSchedulableOperation = iCheckSumInit;
    % load sequence
    aiSeqMachType = astCaseBySeq(cc).aiSeqMachType;
    iCurrPointer = 1;
    %% Planning by machine one after one
    while  iCheckSumSchedulableOperation > 0

        mm = aiSeqMachType(iCurrPointer);
        iCurrPointer = iCurrPointer + 1;
        if iCurrPointer > length(aiSeqMachType)
            iCurrPointer = 1;
        end
        if stJspCfg.iPlotFlag >= 4
            iCurrPointer
        end

        if astQuingTaskMachType(mm).iTotalTask >= 1 %%  astRelTimeMachType(mm).nTotalAvailMach

            [astQuingTaskByJob, astRelTimeMachType, astQuingTaskMachType, stJobSet] = ...
                jsp_solve_mm_sp_1_iter...
                (stJspCfg, mm, astQuingTaskByJob, astRelTimeMachType, astQuingTaskMachType, stJobSet);        

        end
        %% astRelTimeMachType(mm).nTotalAvailMach for this period
        %%% for all the machines, to be extended for multiperiod, \
            
        iCheckSumSchedulableOperation = 0;
        for mm = 1:1:stJspCfg.iTotalJob
            iCheckSumSchedulableOperation = iCheckSumSchedulableOperation + astQuingTaskByJob(mm).iJobId;
        end
    end

    %% calculate makespan
    fMaxEndTime = stJobSet(1).fProcessEndTime(stJspSchedule(1).stProcessPerJob(1));
    fSumCompletionTime = fMaxEndTime; % 20080429
    for ii = 2:1:stJspSchedule.iTotalJob
        fCompletionTimeCurrJob = stJobSet(ii).fProcessEndTime(stJspSchedule.stProcessPerJob(ii));
        if fMaxEndTime < fCompletionTimeCurrJob
            fMaxEndTime = fCompletionTimeCurrJob;
        end
        fSumCompletionTime = fSumCompletionTime + fCompletionTimeCurrJob; % 20080429
    end

    astCaseBySeq(cc).stScheduleJobSet = stJobSet;
    astCaseBySeq(cc).fMakespan = fMaxEndTime;
    if cc == 1 % 20080429
        idxCaseOptimal = 1;
        if iFlagObjFuncDefine == OBJ_MINIMIZE_MAKESPAN
            fMinMakespan = fMaxEndTime;
        elseif iFlagObjFuncDefine == OBJ_MINIMIZE_SUM_TARDINESS
            fMinMakespan = fMaxEndTime;
            fMinSumCompleteTime = fSumCompletionTime;
        else
        end
    else
        if iFlagObjFuncDefine == OBJ_MINIMIZE_MAKESPAN
            if fMaxEndTime < fMinMakespan
                fMinMakespan = fMaxEndTime;
                idxCaseOptimal = cc;
            end
        elseif iFlagObjFuncDefine == OBJ_MINIMIZE_SUM_TARDINESS
            if fSumCompletionTime < fMinSumCompleteTime
                fMinMakespan = fMaxEndTime;
                fMinSumCompleteTime = fSumCompletionTime;
                idxCaseOptimal = cc;
            end
        end
    end % 20080429
    if stJspCfg.iPlotFlag >= 2
        cc
        if stJspCfg.iPlotFlag >= 4
            input('any key')
        end
    end
end

stJspSchedule.stJobSet = astCaseBySeq(idxCaseOptimal).stScheduleJobSet;
stJspSchedule.MaxEndTime = fMinMakespan;
stJspSchedule.iMaxEndTime = ceil(fMinMakespan);

if stJspCfg.iPlotFlag >= 1
    MaxEndTime = stJspSchedule.MaxEndTime
end