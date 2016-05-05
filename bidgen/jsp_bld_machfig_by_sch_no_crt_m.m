function [stOutput] = jsp_bld_machfig_by_sch_no_crt_m(fTimeFrameUnitInHour, stAgenJspSchedule)
% psa_fsp_bld_machfig_by_sch
% History
% YYYYMMDD Notes

global epsilon_slot; % 20071109
stResourceConfigInit = stAgenJspSchedule.stResourceConfig;

[astMachineUsageTimeInfo] = jsp_build_machine_usage_con_tm(stAgenJspSchedule);
for mm = 1:1:stAgenJspSchedule.iTotalMachine
    iaMaxMachUsageBySchOut(mm) = astMachineUsageTimeInfo(mm).iMaxUsage;
end
astMachineUsageInfoPerAgent.astMachineUsageTimeInfo = astMachineUsageTimeInfo;

%%%% The machine
iTotalTimePoint_inFrame_SchOut = ceil(stAgenJspSchedule.iMaxEndTime * stAgenJspSchedule.fTimeUnit_Min/60 /fTimeFrameUnitInHour);

%%% Initalize output structure
nTotalMachineType = stResourceConfigInit.iTotalMachine;
stResourceConfigSchOut.stResourceConfig.iTotalMachine = nTotalMachineType;
for mm = 1:1:nTotalMachineType
    stResourceConfigSchOut.stResourceConfig.stMachineConfig(mm).strName = stResourceConfigInit.stMachineConfig(mm).strName;
    stResourceConfigSchOut.stResourceConfig.stMachineConfig(mm).iNumPointTimeCap = iTotalTimePoint_inFrame_SchOut;
    stResourceConfigSchOut.stResourceConfig.stMachineConfig(mm).afMaCapAtTimePoint = zeros(1, iTotalTimePoint_inFrame_SchOut);
end

fFactorSlotPerFrame = fTimeFrameUnitInHour * 60 /stAgenJspSchedule.fTimeUnit_Min;
for tt = 1:1:iTotalTimePoint_inFrame_SchOut
    for mm = 1:1:nTotalMachineType
        stResourceConfigSchOut.stResourceConfig.stMachineConfig(mm).afTimePointAtCap(tt) = (tt - 1) * fFactorSlotPerFrame;
    end
end
    
for mm = 1:1:nTotalMachineType
    iTimeSlotPointCurr = 1;
    iMaxPointTimeSlot = length(astMachineUsageTimeInfo(mm).aSortedTime);
    for tt = 1:1:iTotalTimePoint_inFrame_SchOut
        stResourceConfigSchOut.stResourceConfig.stMachineConfig(mm).afMaCapAtTimePoint(tt) = 0;
        tFrameStartPoint = stResourceConfigSchOut.stResourceConfig.stMachineConfig(mm).afTimePointAtCap(tt);
        if tt == iTotalTimePoint_inFrame_SchOut
            tFrameEndPoint = stAgenJspSchedule.iMaxEndTime;
        else
            tFrameEndPoint =  stResourceConfigSchOut.stResourceConfig.stMachineConfig(mm).afTimePointAtCap(tt+1) - epsilon_slot;
        end
        if iTimeSlotPointCurr >= iMaxPointTimeSlot
            break;
        end
        while astMachineUsageTimeInfo(mm).aSortedTime(iTimeSlotPointCurr) <= tFrameEndPoint
               % ... & %%% numerical error may happen such that
               % astMachineUsageTimeInfo(mm).aSortedTime(iTimeSlotPointCu
               % rr) < 0
               % astMachineUsageTimeInfo(mm).aSortedTime(iTimeSlotPointCurr) >= tFrameStartPoint 
            if astMachineUsageTimeInfo(mm).aMachineUsageAfterTime(iTimeSlotPointCurr) > stResourceConfigSchOut.stResourceConfig.stMachineConfig(mm).afMaCapAtTimePoint(tt)
                stResourceConfigSchOut.stResourceConfig.stMachineConfig(mm).afMaCapAtTimePoint(tt) = ...
                    astMachineUsageTimeInfo(mm).aMachineUsageAfterTime(iTimeSlotPointCurr);
            end
%             if astMachineUsageTimeInfo(mm).aMachineUsageBeforeTime(iTimeSlotPointCurr) > stResourceConfigSchOut.stResourceConfig.stMachineConfig(mm).afMaCapAtTimePoint(tt)
%                 stResourceConfigSchOut.stResourceConfig.stMachineConfig(mm).afMaCapAtTimePoint(tt) = ...
%                     astMachineUsageTimeInfo(mm).aMachineUsageBeforeTime(iTimeSlotPointCurr);
%             end
            iTimeSlotPointCurr = iTimeSlotPointCurr + 1;
            if iTimeSlotPointCurr >= iMaxPointTimeSlot
                break;
            end
        end
    end
end

for mm = 1:1:nTotalMachineType
    if stResourceConfigSchOut.stResourceConfig.stMachineConfig(mm).afMaCapAtTimePoint(iTotalTimePoint_inFrame_SchOut) == 0
        if iTotalTimePoint_inFrame_SchOut >= 2
            stResourceConfigSchOut.stResourceConfig.stMachineConfig(mm).afMaCapAtTimePoint(iTotalTimePoint_inFrame_SchOut) ...
                = stResourceConfigSchOut.stResourceConfig.stMachineConfig(mm).afMaCapAtTimePoint(iTotalTimePoint_inFrame_SchOut-1);
        else
            stResourceConfigSchOut.stResourceConfig.stMachineConfig(mm).afMaCapAtTimePoint(iTotalTimePoint_inFrame_SchOut) = 1
        end
    end
end

stOutput.iaMaxMachUsageBySchOut = iaMaxMachUsageBySchOut;
stOutput.astMachineUsageInfoPerAgent    = astMachineUsageInfoPerAgent;
stOutput.stResourceConfigSchOut      = stResourceConfigSchOut;