function [stSchedulePerformance] = jsp_eval_schedule_perform(stJspSchedule, astRelTimeMachType)
% Input: 
%  stJspSchedule:Task schedule and task-machine assignment
%
% Output:
%  stPerformIndex
%

%% average of task-completion time by total number of jobs
global epsilon;

[astMachineUsageTimeInfo] = jsp_build_machine_usage_con_tm(stJspSchedule);
[stMachUtilizationInfo] = jsp_get_machine_utilization(stJspSchedule, astMachineUsageTimeInfo);
[astPriorityAtJobSet] = jsp_calc_priority_by_mach_sche(astMachineUsageTimeInfo, stJspSchedule);

%% performance of wait
fJobOverallStartTime = stJspSchedule.stJobSet(1).fProcessStartTime(1);
fSumCompletionTime = 0;
nTotalWaitCount = 0;
astTaskWaitInfo = [];
fMaxWaitTime = 0;
fSumWaitTime = 0;
% struct {'iJobId', 0, 'iTaskId', 0, ]
for ii = 1:1:stJspSchedule.iTotalJob
    nTotalProcReg = stJspSchedule.stProcessPerJob(ii);
    fSumCompletionTime = fSumCompletionTime + stJspSchedule.stJobSet(ii).fProcessEndTime(nTotalProcReg);
    if fJobOverallStartTime > stJspSchedule.stJobSet(ii).fProcessStartTime(1)
        fJobOverallStartTime > stJspSchedule.stJobSet(ii).fProcessStartTime(1);
    end
    for jj = 1:1:nTotalProcReg - 1
        fWaitTimeReg = stJspSchedule.stJobSet(ii).fProcessStartTime(jj+1) - stJspSchedule.stJobSet(ii).fProcessEndTime(jj);
        if abs(fWaitTimeReg) > epsilon
            nTotalWaitCount = nTotalWaitCount + 1;
            astTaskWaitInfo(nTotalWaitCount).iJobId = ii;
            astTaskWaitInfo(nTotalWaitCount).iTaskId = jj+1;
            astTaskWaitInfo(nTotalWaitCount).fWaitTime = fWaitTimeReg;
            fSumWaitTime = fSumWaitTime + fWaitTimeReg;
            if fMaxWaitTime < fWaitTimeReg
                fMaxWaitTime = fWaitTimeReg;
            end
        end
    end
end

fAveCompleteTime = fSumCompletionTime/stJspSchedule.iTotalJob;

%% performance of machine release time
fSumReleaseTimeAllMach = 0;
nSumAllMach = 0;
for mm =1:1:stJspSchedule.iTotalMachine
    afSumReleaseTimePerMachType(mm) = sum(astRelTimeMachType(mm).tRelTimeAtOneMach);
    fSumReleaseTimeAllMach = fSumReleaseTimeAllMach + afSumReleaseTimePerMachType(mm);
    nSumAllMach = nSumAllMach + astRelTimeMachType(mm).nTotalAvailMach;
%    astRelTimeMachType(mm).nTotalAvailMach
    afMeanRelaseTimePerMach(mm) = afSumReleaseTimePerMachType(mm)/astRelTimeMachType(mm).nTotalAvailMach;
end

%% output
stSchedulePerformance.nTotalWaitCount = nTotalWaitCount;
stSchedulePerformance.fMeanWaitTime = fSumWaitTime/nTotalWaitCount;
stSchedulePerformance.fMaxWaitTime = fMaxWaitTime;
stSchedulePerformance.fSumCompletionTime = fSumCompletionTime;
stSchedulePerformance.fAveCompleteTime   = fAveCompleteTime;
stSchedulePerformance.astMachineUsageTimeInfo = astMachineUsageTimeInfo;
stSchedulePerformance.stMachUtilizationInfo   = stMachUtilizationInfo;
stSchedulePerformance.astTaskWaitInfo = astTaskWaitInfo;
stSchedulePerformance.astRelTimeMachType = astRelTimeMachType;
stSchedulePerformance.fSumReleaseTimeAllMach = fSumReleaseTimeAllMach;
stSchedulePerformance.fMeanReleaseTimeAllMach = fSumReleaseTimeAllMach/nSumAllMach;
stSchedulePerformance.afSumReleaseTimePerMachType = afSumReleaseTimePerMachType;
stSchedulePerformance.afMeanRelaseTimePerMach = afMeanRelaseTimePerMach;
stSchedulePerformance.astPriorityAtJobSet = astPriorityAtJobSet;
% Machine release time,

