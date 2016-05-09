function   [TotalConflictTimePerMachine, astMachineTimeUsage] = jsp_calc_cnflt_disce_tm01(container_sequence_jsp, stResourceConfig, iTotalTimeSlot)

fDeltaTime = 0.1;

iTotalJob = container_sequence_jsp.iTotalJob;

for mm = 1:1:container_sequence_jsp.iTotalMachine
    for tt = 1:1: iTotalTimeSlot+1
        astMachineTimeUsage(mm, tt).iTotalJobProcess = 0;
%        astMachineTimeUsage(mm, tt).aJobSet = [];
%        astMachineTimeUsage(mm, tt).iProcessSet = [];
    end
end

TotalConflictTimePerMachine = zeros(container_sequence_jsp.iTotalMachine, 1);

%%%%% build machine usage information
for ii = 1:1:container_sequence_jsp.iTotalJob
    for jj = 1:1:container_sequence_jsp.stProcessPerJob(ii)
        mm = container_sequence_jsp.stJobSet(ii).iProcessMachine(jj);
        for tt = container_sequence_jsp.stJobSet(ii).iProcessStartTime(jj):1:container_sequence_jsp.stJobSet(ii).iProcessEndTime(jj)-1
            astMachineTimeUsage(mm, tt+1).iTotalJobProcess = astMachineTimeUsage(mm, tt+1).iTotalJobProcess + 1;
            %                astMachineTimeUsage(mm, tt+1).aJobSet(astMachineTimeUsage(mm, tt+1).iTotalJobProcess) = ii;
            %                astMachineTimeUsage(mm, tt+1).iProcessSet(astMachineTimeUsage(mm, tt+1).iTotalJobProcess) = jj;
        end
    end
end


for mm = 2:1:container_sequence_jsp.iTotalMachine
%    stResourceConfig.stMachineConfig(mm).afMaCapAtTimePoint
%     stResourceConfig.stMachineConfig(mm).afTimePointAtCap
    for tt = 1 :1: iTotalTimeSlot
%        tt = floor(tt)
        [fMaxCapacity, iIndex] = calc_lut_max_between(stResourceConfig.stMachineConfig(mm).afMaCapAtTimePoint, ...
            stResourceConfig.stMachineConfig(mm).afTimePointAtCap, tt - 1 -fDeltaTime, tt - fDeltaTime);
        if fMaxCapacity < astMachineTimeUsage(mm, tt).iTotalJobProcess
            TotalConflictTimePerMachine(mm) = TotalConflictTimePerMachine(mm) + 1;
        end
    end
end

