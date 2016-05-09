function   [TotalConflictTimePerMachine, astMachineTimeUsage] = jsp_calc_cnflt_disce_tm02(stJspSchedule, stResourceConfig, iTimeStart, iTimeEnd)

fDeltaTime = 0.1;

iTotalJob = stJspSchedule.iTotalJob;
tTotalTimeSlot = stJspSchedule.iMaxEndTime + 1;
% stJspSchedule.stJobSet(iTotalJob).iProcessEndTime(stJspSchedule.stProcessPerJob(iTotalJob))+1
for mm = 1:1:stJspSchedule.iTotalMachine
    for tt = 1:1:tTotalTimeSlot
        astMachineTimeUsage(mm, tt).iTotalJobProcess = 0;
    end
end

TotalConflictTimePerMachine = zeros(stJspSchedule.iTotalMachine, 1);

%%%%% build machine usage information
for ii = 1:1:stJspSchedule.iTotalJob
    for jj = 1:1:stJspSchedule.stProcessPerJob(ii)
        mm = stJspSchedule.stJobSet(ii).iProcessMachine(jj);
%         ii, jj, 
%         size_JobSet = size(stJspSchedule.stJobSet)
%         size_StartTime = size(stJspSchedule.stJobSet(ii).iProcessStartTime)
%         size_EndTime = size(stJspSchedule.stJobSet(ii).iProcessEndTime)
        for tt = stJspSchedule.stJobSet(ii).iProcessStartTime(jj):1:stJspSchedule.stJobSet(ii).iProcessEndTime(jj)-1
            if tt >= iTimeStart &  tt <= iTimeEnd
%                 tt
                astMachineTimeUsage(mm, tt+1).iTotalJobProcess = astMachineTimeUsage(mm, tt+1).iTotalJobProcess + 1;
%                astMachineTimeUsage(mm, tt+1).aJobSet(astMachineTimeUsage(mm, tt+1).iTotalJobProcess) = ii;
%                astMachineTimeUsage(mm, tt+1).iProcessSet(astMachineTimeUsage(mm, tt+1).iTotalJobProcess) = jj;
            end
        end
    end
end


for mm = 1:1:stJspSchedule.iTotalMachine
%    stResourceConfig.stMachineConfig(mm).afMaCapAtTimePoint
%     stResourceConfig.stMachineConfig(mm).afTimePointAtCap
    for tt = iTimeStart+1 :1: iTimeEnd
%        tt = floor(tt)
        [fMaxCapacity, iIndex] = calc_lut_max_between(stResourceConfig.stMachineConfig(mm).afMaCapAtTimePoint, ...
            stResourceConfig.stMachineConfig(mm).afTimePointAtCap, tt - 1 -fDeltaTime, tt - fDeltaTime);
        if fMaxCapacity < astMachineTimeUsage(mm, tt).iTotalJobProcess
            TotalConflictTimePerMachine(mm) = TotalConflictTimePerMachine(mm) + 1;
        end
    end
end

