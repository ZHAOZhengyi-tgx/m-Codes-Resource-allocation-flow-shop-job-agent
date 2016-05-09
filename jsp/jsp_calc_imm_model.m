function  [stJobSet, astQuingTask, stRelTimeMachType] = jsp_calc_imm_model(stJspCfg, mType, tPlanningTimeWindow, stJobSet,  stQuingTaskMachType, stRelTimeMachType, astQuingTask)
% calculate a matching among tasks and machines
%  imm: Iterative Minimization Micro-model
%  to minimize the overall sum of makespan
% Input:
%  stQuingTaskMachType: Quing Task for the same machine type
%  stRelTimeMachType: Release Time for each machine type
%            tRelTimeAtOneMach: an array
%            nTotalAvailMach: 
%  stJobSet: Job Schedule
%  stJspCfg: Job Config
%
% output:
% History
% 20080110 review
% 20080113 One Machine Prob, Optimize IMM model
% 20080418 IMM3 choose the p(i,j) + a(
% 20091216 Batch Job Arrival Time
iPlotFlag = stJspCfg.iPlotFlag;

aMachineSet.iTotalMach = 0;
aMachineSet.aiMachId = [];
aMachineSet.atMachRelTime = [];

% stJobSet = 
% find the earliest machine who finish its current job (such mach as with smallest release time)
[tMinReleaseTime, idxMachEarliestCome] = min(stRelTimeMachType.tRelTimeAtOneMach);
for mi = 1:1:stJspCfg.iTotalMachineNum(mType)
    aMachineSet.iTotalMach = aMachineSet.iTotalMach + 1;
    aMachineSet.aiMachId(aMachineSet.iTotalMach) = mi;
    aMachineSet.atMachRelTime(aMachineSet.iTotalMach) = stRelTimeMachType.tRelTimeAtOneMach(mi);
end

%% atTaskArriveTime and atProcTimeAtTask is the seq in stQuingTaskMachType
nTotalTaskInQue = stQuingTaskMachType.iTotalTask;
for ii = 1:1: nTotalTaskInQue
    jJobIdReg = stQuingTaskMachType.iJobSet(ii);
    if jJobIdReg == 0
        error('Job should have finished')
    end
    iTask = astQuingTask(jJobIdReg).iProcessToStart;
    if iTask >= 2
        atTaskArriveTime(ii) = stJobSet(jJobIdReg).iProcessEndTime(iTask-1);
    else
        atTaskArriveTime(ii) = stJspCfg.atArrivalTimePerJob(jJobIdReg);  % 0;  %% TBM 20080110, % 20091216
    end
    atProcTimeAtTask(ii) = astQuingTask(jJobIdReg).ProcessTime;
    atSumProcTimeAndTaskArrival(ii) = atProcTimeAtTask(ii) + atTaskArriveTime(ii); % 20080418
end

if iPlotFlag >= 3
    nTotalTaskInQue
    aMachineSet    
end

if aMachineSet.iTotalMach == 1
    tRelTimeOneMach = aMachineSet.atMachRelTime(1);
    % single machine available, 
    % planning window is too small 
    % or 1-mach problem
    %% Version >  20080113
    % IN: 
    % atTaskArriveTime, atProcTimeAtTask, stQuingTaskMachType,
    % astQuingTask, tRelTimeOneMach
    % OUT:
    % jJobIdReg, iProcIdReg, tProcStartTime, idxTaskInQueMinEndTime 
    %% 
    [jJobIdReg, iProcIdReg, tProcStartTime, idxTaskInQueMinEndTime] = ...
        jsp_calc_imm_1(atTaskArriveTime, atProcTimeAtTask, stQuingTaskMachType, astQuingTask, tRelTimeOneMach);
    %%% 
    stJobSet(jJobIdReg).fProcessStartTime(iProcIdReg) = tProcStartTime;
    stJobSet(jJobIdReg).fProcessEndTime(iProcIdReg) = tProcStartTime + atProcTimeAtTask(idxTaskInQueMinEndTime);
    stJobSet(jJobIdReg).iProcessStartTime = round(stJobSet(jJobIdReg).fProcessStartTime);
    stJobSet(jJobIdReg).iProcessEndTime = round(stJobSet(jJobIdReg).fProcessEndTime);
    stJobSet(jJobIdReg).iProcessMachineId(iProcIdReg) = idxMachEarliestCome;
    stRelTimeMachType.tRelTimeAtOneMach(idxMachEarliestCome) = tProcStartTime + atProcTimeAtTask(idxTaskInQueMinEndTime);
    
    if iPlotFlag >= 3
        timeTaskArive_timeProcTask_idJobHit_idTaskHit = [atTaskArriveTime, atProcTimeAtTask, jJobIdReg, iProcIdReg]
        timeTaskEndJobSetHit = stJobSet(jJobIdReg).iProcessEndTime'
    end
    % update astQuingTask
    astQuingTask = jsp_update_quing_task(jJobIdReg, iProcIdReg, stJspCfg, astQuingTask);
    
elseif aMachineSet.iTotalMach < nTotalTaskInQue
    % multiple machines available at the same time
    nTotalTaskMatchMach = aMachineSet.iTotalMach;

    % only selete the first nTotalTaskMatchMach of tasks with smallest
    % SumProcArrivTime
    [atSortedSumProcArrivTime, aiSortedTaskBySumProcArrivTime] = sort(atSumProcTimeAndTaskArrival);
    aiTaskIdSeleted = aiSortedTaskBySumProcArrivTime(1:nTotalTaskMatchMach);
    
    %% sort the task by arrival time
    atTaskArriveTimeSelected = atTaskArriveTime(aiTaskIdSeleted);
    [atSortedTimeTaskArrive, aiSortTaskInPlan] = sort(atTaskArriveTimeSelected);
    
    %% sort the machine by release time
    [atSortedMachRelTime, aiSortMachIdInSet] = sort(aMachineSet.atMachRelTime);
    
    %% schedule by Min Release Mach First
    for ii = 1:1:nTotalTaskMatchMach
        iMachIdReg = aMachineSet.aiMachId(aiSortMachIdInSet(ii));
        jJobIdReg = stQuingTaskMachType.iJobSet(aiTaskIdSeleted(aiSortTaskInPlan( ii))); % TBM nTotalTaskMatchMach + 1 -
        iProcIdReg = astQuingTask(jJobIdReg).iProcessToStart;
        
        tProcStartTimeReg = max(atSortedTimeTaskArrive( ii), atSortedMachRelTime(ii)); %TBM nTotalTaskMatchMach + 1 -
        tProcEndTimeReg = tProcStartTimeReg + atProcTimeAtTask(aiTaskIdSeleted(aiSortTaskInPlan( ii))); %TBM nTotalTaskMatchMach + 1 -
        stJobSet(jJobIdReg).fProcessStartTime(iProcIdReg) = tProcStartTimeReg; % astMatchCase(1).atProcessStartTime(ii);
        stJobSet(jJobIdReg).fProcessEndTime(iProcIdReg) = tProcEndTimeReg;     % astMatchCase(1).atProcessEndTime(ii);
        stJobSet(jJobIdReg).iProcessStartTime = round(stJobSet(jJobIdReg).fProcessStartTime);
        stJobSet(jJobIdReg).iProcessEndTime = round(stJobSet(jJobIdReg).fProcessEndTime);
        stJobSet(jJobIdReg).iProcessMachineId(iProcIdReg) = iMachIdReg;

        stRelTimeMachType.tRelTimeAtOneMach(iMachIdReg) = tProcEndTimeReg; % astMatchCase(1).atProcessEndTime(ii);
        % update astQuingTask
        astQuingTask = jsp_update_quing_task(jJobIdReg, iProcIdReg, stJspCfg, astQuingTask);
        
        astMatchCase(1).aiMachId(ii) = iMachIdReg; 
        astMatchCase(1).aiJobId(ii) = jJobIdReg;
        astMatchCase(1).aiTaskIdInJob(ii) = iProcIdReg;
        astMatchCase(1).atProcessStartTime(ii) = tProcStartTimeReg;  %%% NOTE 1 max(atSortedTimeTaskArrive(ii), atSortedMachRelTime(ii));
        astMatchCase(1).atProcessEndTime(ii) = tProcEndTimeReg;  %%% astMatchCase(1).atProcessStartTime(ii) + atProcTimeAtTask(aiSortTaskMinArriveFirst(ii));  %%% NOTE 2
        
    end
    astMatchCase(1).fSumMakespan = sum(astMatchCase(1).atProcessEndTime);
    
%     %% only schedule for nTotalTaskMatchMach of tasks, fist coming
%     [atSortedTimeTaskArrive, aiSortTaskInPlan] = sort(atTaskArriveTime); 
%     aiSortTask = aiSortTaskInPlan(1:nTotalTaskMatchMach);
%     
%     %% 1st Case by Min Arrive Task First
%     for ii = 1:1:nTotalTaskMatchMach
%         %% aiSortTask(ii) ==== aiSortTaskInPlan(ii);
%         jJobIdReg = stQuingTaskMachType.iJobSet(aiSortTask(ii));
%         astMatchCase(1).aiJobId(ii) = jJobIdReg;
%         astMatchCase(1).aiTaskIdInJob(ii) = astQuingTask(jJobIdReg).iProcessToStart;
%         astMatchCase(1).atProcessStartTime(ii) = max(atSortedTimeTaskArrive(ii), aMachineSet.atMachRelTime(ii));  %%% NOTE 1
%         astMatchCase(1).atProcessEndTime(ii) = astMatchCase(1).atProcessStartTime(ii) + atProcTimeAtTask(aiSortTask(ii)); %%% NOTE 2
%         astMatchCase(1).aiMachId(ii) = aMachineSet.aiMachId(ii);
%     end
%     astMatchCase(1).fSumMakespan = sum(astMatchCase(1).atProcessEndTime);
% 
%     %% 2nd case from Case by Min Release Mach First
%     [atSortedMachRelTime, aiSortMachIdInSet] = sort(aMachineSet.atMachRelTime);
%     for ii = 1:1:nTotalTaskMatchMach
%         astMatchCase(2).aiMachId(ii) = aMachineSet.aiMachId(aiSortMachIdInSet(ii));
%         jJobIdReg = stQuingTaskMachType.iJobSet(aiSortTask(ii));
%         astMatchCase(2).aiJobId(ii) = jJobIdReg;
%         astMatchCase(2).aiTaskIdInJob(ii) = astQuingTask(jJobIdReg).iProcessToStart;
%         astMatchCase(2).atProcessStartTime(ii) = max(atTaskArriveTime(aiSortTask(ii)), atSortedMachRelTime(ii));  %%% NOTE 1
%         astMatchCase(2).atProcessEndTime(ii) = astMatchCase(2).atProcessStartTime(ii) + atProcTimeAtTask(aiSortTask(ii));  %%% NOTE 2
%     end
%     astMatchCase(2).fSumMakespan = sum(astMatchCase(2).atProcessEndTime);
%     
%     %% get the minimum Makespan and it case-id
%     if astMatchCase(2).fSumMakespan < astMatchCase(1).fSumMakespan
%         idxCaseMinSumMakespan = 2;
%     else
%         idxCaseMinSumMakespan = 1;
%     end
%     fMinSumMakespan = astMatchCase(idxCaseMinSumMakespan).fSumMakespan;
% 
%     
%     %% 3rd case from a random matching
%     nTotalRandCase = min([stJspCfg.stGASetting.iPopSize, factorial(aMachineSet.iTotalMach)]);
%     for cc = 3:1:nTotalRandCase+2
%         aiRandSeqMachId = randperm(nTotalTaskMatchMach); %% random permutation
%         atMachRelTimeByRandSeq = aMachineSet.atMachRelTime(aiRandSeqMachId); %% array assignment
%         
%         for ii = 1:1:nTotalTaskMatchMach
%             astMatchCase(cc).aiMachId(ii) = aMachineSet.aiMachId(aiRandSeqMachId(ii));
%             jJobIdReg = stQuingTaskMachType.iJobSet(aiSortTask(ii));
%             astMatchCase(cc).aiJobId(ii) = jJobIdReg;
%             astMatchCase(cc).aiTaskIdInJob(ii) = astQuingTask(jJobIdReg).iProcessToStart;
%             astMatchCase(cc).atProcessStartTime(ii) = max(atTaskArriveTime(aiSortTask(ii)), atMachRelTimeByRandSeq(ii));  %%% NOTE 1
%             astMatchCase(cc).atProcessEndTime(ii) = astMatchCase(cc).atProcessStartTime(ii) + atProcTimeAtTask(aiSortTask(ii));  %%% NOTE 2
%         end
%         astMatchCase(cc).fSumMakespan = sum(astMatchCase(cc).atProcessEndTime);
%         
%         if fMinSumMakespan > astMatchCase(cc).fSumMakespan
%             idxCaseMinSumMakespan = cc;
%             fMinSumMakespan = astMatchCase(cc).fSumMakespan;
%         end
%     end
%     
%     %% assign solution to stJobSet
%     for ii = 1:1:nTotalTaskMatchMach
%         jJobIdReg = astMatchCase(idxCaseMinSumMakespan).aiJobId(ii);
%         iProcIdReg = astQuingTask(jJobIdReg).iProcessToStart;
%         iMachIdReg = astMatchCase(idxCaseMinSumMakespan).aiMachId(ii);
%         
%         stJobSet(jJobIdReg).fProcessStartTime(iProcIdReg) = astMatchCase(idxCaseMinSumMakespan).atProcessStartTime(ii);
%         stJobSet(jJobIdReg).fProcessEndTime(iProcIdReg) = astMatchCase(idxCaseMinSumMakespan).atProcessEndTime(ii);
%         stJobSet(jJobIdReg).iProcessStartTime = round(stJobSet(jJobIdReg).fProcessStartTime);
%         stJobSet(jJobIdReg).iProcessEndTime = round(stJobSet(jJobIdReg).fProcessEndTime);
%         stJobSet(jJobIdReg).iProcessMachineId(iProcIdReg) = iMachIdReg;
% 
%         stRelTimeMachType.tRelTimeAtOneMach(iMachIdReg) = astMatchCase(idxCaseMinSumMakespan).atProcessEndTime(ii);
%         % update astQuingTask
%         astQuingTask = jsp_update_quing_task(jJobIdReg, iProcIdReg, stJspCfg, astQuingTask);
%     end

else %%% Multiple machine, num of machin in planing >= num of task quing
     %% Num of Quing Task <= Num of Available Machine
    % multiple machines available at the same time
    %% only schedule for nTotalTaskInQue of machins, first come first serve
    nTotalTaskMatchMach = aMachineSet.iTotalMach;
    
    [atSortedMachRelTime, aiSortMachIdInSet] = sort(aMachineSet.atMachRelTime);
    aiMachIdInPlanning = aiSortMachIdInSet(1:nTotalTaskInQue);
    
    [atSortedTimeTaskArrive, aiSortTaskMinArriveFirst] = sort(atTaskArriveTime); 
    
    %% from Case by Min Release Mach First
    for ii = 1:1:nTotalTaskInQue
        iMachIdReg = aMachineSet.aiMachId(aiSortMachIdInSet(ii)); %% nTotalTaskMatchMach - nTotalTaskInQue + 
        jJobIdReg = stQuingTaskMachType.iJobSet(aiSortTaskMinArriveFirst( ii)); %% TBM nTotalTaskInQue + 1 -
        iProcIdReg = astQuingTask(jJobIdReg).iProcessToStart;
        
        tProcStartTimeReg = max(atSortedTimeTaskArrive( ii), atSortedMachRelTime( ii)); %% nTotalTaskMatchMach - nTotalTaskInQue + %%TBM nTotalTaskInQue + 1 -
        tProcEndTimeReg = tProcStartTimeReg + atProcTimeAtTask(aiSortTaskMinArriveFirst( ii)); %% TBM nTotalTaskInQue + 1 -
        stJobSet(jJobIdReg).fProcessStartTime(iProcIdReg) = tProcStartTimeReg; % astMatchCase(1).atProcessStartTime(ii);
        stJobSet(jJobIdReg).fProcessEndTime(iProcIdReg) = tProcEndTimeReg;     % astMatchCase(1).atProcessEndTime(ii);
        stJobSet(jJobIdReg).iProcessStartTime = round(stJobSet(jJobIdReg).fProcessStartTime);
        stJobSet(jJobIdReg).iProcessEndTime = round(stJobSet(jJobIdReg).fProcessEndTime);
        stJobSet(jJobIdReg).iProcessMachineId(iProcIdReg) = iMachIdReg;

        stRelTimeMachType.tRelTimeAtOneMach(iMachIdReg) = tProcEndTimeReg; % astMatchCase(1).atProcessEndTime(ii);
        % update astQuingTask
        astQuingTask = jsp_update_quing_task(jJobIdReg, iProcIdReg, stJspCfg, astQuingTask);
        
        astMatchCase(1).aiMachId(ii) = iMachIdReg; 
        astMatchCase(1).aiJobId(ii) = jJobIdReg;
        astMatchCase(1).aiTaskIdInJob(ii) = iProcIdReg;
        astMatchCase(1).atProcessStartTime(ii) = tProcStartTimeReg;  %%% NOTE 1 max(atSortedTimeTaskArrive(ii), atSortedMachRelTime(ii));
        astMatchCase(1).atProcessEndTime(ii) = tProcEndTimeReg;  %%% astMatchCase(1).atProcessStartTime(ii) + atProcTimeAtTask(aiSortTaskMinArriveFirst(ii));  %%% NOTE 2
        
    end
    astMatchCase(1).fSumMakespan = sum(astMatchCase(1).atProcessEndTime);

end

if iPlotFlag >= 5
    stRelTimeMachType
%     aMachineSet.iTotalMach
%     nTotalTaskInQue
    if aMachineSet.iTotalMach > 1
        if aMachineSet.iTotalMach < nTotalTaskInQue
            atFirstBatchArrivingTask = atTaskArriveTime(aiTaskIdSeleted(aiSortTaskInPlan))
            atProcTimeFirstArrivTask = atProcTimeAtTask(aiTaskIdSeleted(aiSortTaskInPlan))
            atSumProcTimeAndTaskArrival
            disp('IMM-2')
%            aiSortTaskInPlan
        else
%            atSortedMachRelTime
            atTaskArriveTime
            atProcTimeAtTask
            disp('IMM-3')
        end
%         for ii = 1:1:nTotalRandCase 
%             aSumMakespanInCase(ii) = astMatchCase(ii).fSumMakespan;
%         end
%         min_max_choose_MakespanInCase_totalcase = [min(aSumMakespanInCase), max(aSumMakespanInCase), astMatchCase(idxCaseMinSumMakespan).fSumMakespan, nTotalRandCase]
        input('any key')
    end
end
%% can be done by sequence
%tMinTimeTaskArrival = min();

