function [stMachineUsageInfo] = psa_resalloc_build_mach_usage(stBerthJobInfo, stQC_Solution)
% For single period resoure allocation problem,
% The usage for each kind of machine is a constant for each job, the usage
% is maximum number of machines used by the job.
%
astMachineUsage(1).strName = stBerthJobInfo.stResourceConfig.stMachineConfig(2).strName;
astMachineUsage(1).iTotalTimePoint = 0;
astMachineUsage(1).nInitialUsage = 0;
astMachineUsage(1).iMaxCapacity = stBerthJobInfo.iTotalPrimeMover;
astMachineUsage(2).strName = stBerthJobInfo.stResourceConfig.stMachineConfig(3).strName;
astMachineUsage(2).iTotalTimePoint = 0;
astMachineUsage(2).nInitialUsage = 0;
astMachineUsage(2).iMaxCapacity = stBerthJobInfo.iTotalYardCrane;

for ii=1:1:stBerthJobInfo.iTotalAgent
    tStartTime_datenum = datenum(stBerthJobInfo.atClockQCJobStart(ii).aClockYearMonthDateHourMinSec);
    tCompleteTime_datenum = tStartTime_datenum + stQC_Solution(ii).stCostAtQC.stSolutionMinCost.stSchedule.iMaxEndTime * stQC_Solution(ii).stCostAtQC.stSolutionMinCost.stSchedule.fTimeUnit_Min/60/24;
    
    if ii == 1
        tEarliestStartTime = tStartTime_datenum;
        tLatestCompleteTime = tCompleteTime_datenum;
    else
        if tEarliestStartTime > tStartTime_datenum
            tEarliestStartTime = tStartTime_datenum;
        end
        if tLatestCompleteTime < tCompleteTime_datenum
            tLatestCompleteTime = tCompleteTime_datenum;
        end
    end
    astMachineUsage(1).iTotalTimePoint = astMachineUsage(1).iTotalTimePoint + 2;
    astMachineUsage(1).aTimeArray(astMachineUsage(1).iTotalTimePoint - 1) = tStartTime_datenum;
    astMachineUsage(1).aDeltaStartEnd(astMachineUsage(1).iTotalTimePoint - 1) = stQC_Solution(ii).stCostAtQC.stSolutionMinCost.iMaxPM;
    astMachineUsage(1).aTimeArray(astMachineUsage(1).iTotalTimePoint) = tCompleteTime_datenum;
    astMachineUsage(1).aDeltaStartEnd(astMachineUsage(1).iTotalTimePoint) = -stQC_Solution(ii).stCostAtQC.stSolutionMinCost.iMaxPM;
    astMachineUsage(1).aJobArray(astMachineUsage(1).iTotalTimePoint - 1) = ii;
    astMachineUsage(1).aJobArray(astMachineUsage(1).iTotalTimePoint) = ii;
    
    astMachineUsage(2).iTotalTimePoint = astMachineUsage(2).iTotalTimePoint + 2;
    astMachineUsage(2).aTimeArray(astMachineUsage(1).iTotalTimePoint - 1) = tStartTime_datenum;
    astMachineUsage(2).aDeltaStartEnd(astMachineUsage(1).iTotalTimePoint - 1) = stQC_Solution(ii).stCostAtQC.stSolutionMinCost.iMaxYC;
    astMachineUsage(2).aTimeArray(astMachineUsage(1).iTotalTimePoint) = tCompleteTime_datenum;
    astMachineUsage(2).aDeltaStartEnd(astMachineUsage(1).iTotalTimePoint) = -stQC_Solution(ii).stCostAtQC.stSolutionMinCost.iMaxYC;
    astMachineUsage(2).aJobArray(astMachineUsage(1).iTotalTimePoint - 1) = ii;
    astMachineUsage(2).aJobArray(astMachineUsage(1).iTotalTimePoint) = ii;

end

for mm = 1:1:2
    [aSortedTime, iSortIdx] = sort(astMachineUsage(mm).aTimeArray);
    astMachineUsage(mm).aSortedTime = aSortedTime;
    astMachineUsage(mm).aSortedDelta = astMachineUsage(mm).aDeltaStartEnd(iSortIdx);
    astMachineUsage(mm).aSortedJob = astMachineUsage(mm).aJobArray(iSortIdx);
    
    astMachineUsage(mm).aMachineUsageAfterTime(1) = astMachineUsage(mm).nInitialUsage + astMachineUsage(mm).aSortedDelta(1);
    for tt = 2:1:astMachineUsage(mm).iTotalTimePoint
        astMachineUsage(mm).aMachineUsageAfterTime(tt) = astMachineUsage(mm).aMachineUsageAfterTime(tt-1) + astMachineUsage(mm).aSortedDelta(tt);
    end
    astMachineUsage(mm).iMaxUsage = max(astMachineUsage(mm).aMachineUsageAfterTime);
    
    astMachineUsage(mm).aSortedTime_inHour = (astMachineUsage(mm).aSortedTime - floor(tEarliestStartTime))*24;
end

stMachineUsageInfo.tEarliestStartTime = tEarliestStartTime;
stMachineUsageInfo.tLatestCompleteTime = tLatestCompleteTime;
stMachineUsageInfo.astMachineUsage = astMachineUsage;
