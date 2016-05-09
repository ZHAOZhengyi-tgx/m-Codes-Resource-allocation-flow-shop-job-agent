function [stJspSchedule, astRelTimeMachType] = jsp_solve_mm_sp_heu(stJspCfg, astRelTimeMachType)
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

%% Initialize stJspSchedule
[stJspSchedule] = jsp_constr_sche_struct_by_cfg(stJspCfg);
stJobSet = stJspSchedule.stJobSet;
ga_init_seed(stJspCfg);

%fPlanningTimeWindow = tEpsilonTime;

%%% each time astQuingTaskMachType be initialized for all machines
astQuingTaskMachType = jsp_init_qtask_per_mype(stJspCfg, astQuingTaskByJob);

%% Planning by machine one after one
while  iCheckSumSchedulableOperation > 0
    
    
    %% astRelTimeMachType(mm).nTotalAvailMach for this period
    %%% for all the machines, to be extended for multiperiod, \
%    mmDisp_tSumProcessingTimeArrivalTime = [mm, tSumProcessingTimeArrivalTime, tSumMachineReleaseTime]

   mTypeNext = jsp_get_next_mach_type(stJspCfg, astQuingTaskByJob, astRelTimeMachType, astQuingTaskMachType, stJobSet);
   mm = mTypeNext;

             
    [astQuingTaskByJob, astRelTimeMachType, astQuingTaskMachType, stJobSet] = ...
        jsp_solve_mm_sp_1_iter(stJspCfg, mm, astQuingTaskByJob, astRelTimeMachType, astQuingTaskMachType, stJobSet);        
    
    iCheckSumSchedulableOperation = 0;
    for mm = 1:1:stJspCfg.iTotalJob
        iCheckSumSchedulableOperation = iCheckSumSchedulableOperation + astQuingTaskByJob(mm).iJobId;
    end
end

stJspSchedule.stJobSet = stJobSet;

fMaxEndTime = stJspSchedule.stJobSet(1).fProcessEndTime(stJspSchedule(1).stProcessPerJob(1));
for ii = 2:1:stJspSchedule.iTotalJob
    if fMaxEndTime < stJspSchedule.stJobSet(ii).fProcessEndTime(stJspSchedule.stProcessPerJob(ii))
        fMaxEndTime = stJspSchedule.stJobSet(ii).fProcessEndTime(stJspSchedule.stProcessPerJob(ii));
    end
end
stJspSchedule.MaxEndTime = fMaxEndTime;
stJspSchedule.iMaxEndTime = ceil(fMaxEndTime);

if stJspCfg.iPlotFlag >= 1
    MaxEndTime = stJspSchedule.MaxEndTime
end