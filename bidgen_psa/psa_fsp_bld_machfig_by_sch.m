function [stOutput] = psa_fsp_bld_machfig_by_sch(fTimeFrameUnitInHour, stResourceConfigInit, stAgenJspSchedule)
% psa_fsp_bld_machfig_by_sch
% History
% YYYYMMDD Notes
% 20071109 Add global parameter definition
% 20080211 Add iaMachCapOnePer for version compatibility
% 20080415 debug for the last frame 
global epsilon_slot; % 20071109

[astMachineUsageTimeInfo] = jsp_build_machine_usage_con_tm(stAgenJspSchedule);
iMaxPrimeMoverUsageBySchOut = astMachineUsageTimeInfo(2).iMaxUsage;
iMaxYardCraneUsageBySchOut  = astMachineUsageTimeInfo(3).iMaxUsage;
astMachineUsageInfoPerAgent.astMachineUsageTimeInfo = astMachineUsageTimeInfo;

%%%% The machine
%%%% stAgenJspSchedule, stPortJobInfo,
%%%% astMachineUsageTimeInfo
iTotalTimePoint_inFrame_SchOut = ...
    ceil(stAgenJspSchedule.iMaxEndTime * stAgenJspSchedule.fTimeUnit_Min/60 /fTimeFrameUnitInHour);

%%% Initalize output structure
stResourceConfigSchOut.stResourceConfig.iTotalMachine = stResourceConfigInit.iTotalMachine;
stResourceConfigSchOut.stResourceConfig.iaMachCapOnePer = stResourceConfigInit.iaMachCapOnePer; % 20080211
stResourceConfigSchOut.stResourceConfig.iCriticalMachType = stResourceConfigInit.iCriticalMachType; % 20080211
stResourceConfigSchOut.stResourceConfig.stMachineConfig(1) = stResourceConfigInit.stMachineConfig(1);
stResourceConfigSchOut.stResourceConfig.stMachineConfig(2).strName = stResourceConfigInit.stMachineConfig(2).strName;
stResourceConfigSchOut.stResourceConfig.stMachineConfig(3).strName = stResourceConfigInit.stMachineConfig(3).strName;

%%%% Machine Config for PM
stResourceConfigSchOut.stResourceConfig.stMachineConfig(2).iNumPointTimeCap = iTotalTimePoint_inFrame_SchOut;
stResourceConfigSchOut.stResourceConfig.stMachineConfig(2).afMaCapAtTimePoint = zeros(1, iTotalTimePoint_inFrame_SchOut);
stResourceConfigSchOut.stResourceConfig.stMachineConfig(3).iNumPointTimeCap = iTotalTimePoint_inFrame_SchOut;
stResourceConfigSchOut.stResourceConfig.stMachineConfig(3).afMaCapAtTimePoint = zeros(1, iTotalTimePoint_inFrame_SchOut);
for tt = 1:1:iTotalTimePoint_inFrame_SchOut
    stResourceConfigSchOut.stResourceConfig.stMachineConfig(2).afTimePointAtCap(tt) = (tt - 1) * fTimeFrameUnitInHour * 60 /stAgenJspSchedule.fTimeUnit_Min;
%    end
%    for tt = 1:1:iTotalTimePoint_inFrame_SchOut
    stResourceConfigSchOut.stResourceConfig.stMachineConfig(3).afTimePointAtCap(tt) = (tt - 1) * fTimeFrameUnitInHour * 60 /stAgenJspSchedule.fTimeUnit_Min;
end


iTimeSlotPointCurr = 1;
iMaxPointTimeSlot = length(astMachineUsageTimeInfo(2).aSortedTime);
for tt = 1:1:iTotalTimePoint_inFrame_SchOut
    stResourceConfigSchOut.stResourceConfig.stMachineConfig(2).afMaCapAtTimePoint(tt) = 0;
    tFrameStartPoint = stResourceConfigSchOut.stResourceConfig.stMachineConfig(2).afTimePointAtCap(tt);
    if tt == iTotalTimePoint_inFrame_SchOut
        tFrameEndPoint = stAgenJspSchedule.iMaxEndTime;
    else
        tFrameEndPoint = ...
            stResourceConfigSchOut.stResourceConfig.stMachineConfig(2).afTimePointAtCap(tt+1) - epsilon_slot;
    end
    if iTimeSlotPointCurr >= iMaxPointTimeSlot
        break;
    end
    while astMachineUsageTimeInfo(2).aSortedTime(iTimeSlotPointCurr) <= tFrameEndPoint
           % ... & %%% numerical error may happen such that
           % astMachineUsageTimeInfo(2).aSortedTime(iTimeSlotPointCu
           % rr) < 0
           % astMachineUsageTimeInfo(2).aSortedTime(iTimeSlotPointCurr) >= tFrameStartPoint 
        if astMachineUsageTimeInfo(2).aMachineUsageAfterTime(iTimeSlotPointCurr) ...
                > stResourceConfigSchOut.stResourceConfig.stMachineConfig(2).afMaCapAtTimePoint(tt)
            stResourceConfigSchOut.stResourceConfig.stMachineConfig(2).afMaCapAtTimePoint(tt) = ...
                astMachineUsageTimeInfo(2).aMachineUsageAfterTime(iTimeSlotPointCurr);
        end
%             if astMachineUsageTimeInfo(2).aMachineUsageBeforeTime(iTimeSlotPointCurr) > stResourceConfigSchOut.stResourceConfig.stMachineConfig(2).afMaCapAtTimePoint(tt)
%                 stResourceConfigSchOut.stResourceConfig.stMachineConfig(2).afMaCapAtTimePoint(tt) = ...
%                     astMachineUsageTimeInfo(2).aMachineUsageBeforeTime(iTimeSlotPointCurr);
%             end
        iTimeSlotPointCurr = iTimeSlotPointCurr + 1;
        if iTimeSlotPointCurr >= iMaxPointTimeSlot
            break;
        end
    end
end

%%%% Machine Config for YC
iTimeSlotPointCurr = 1;    
iMaxPointTimeSlot = length(astMachineUsageTimeInfo(3).aSortedTime);
%    iTotalTimePoint_inFrame_SchOut
for tt = 1:1:iTotalTimePoint_inFrame_SchOut
    stResourceConfigSchOut.stResourceConfig.stMachineConfig(3).afMaCapAtTimePoint(tt) = 0;
    tFrameStartPoint = stResourceConfigSchOut.stResourceConfig.stMachineConfig(3).afTimePointAtCap(tt);
    if tt == iTotalTimePoint_inFrame_SchOut
        tFrameEndPoint = stAgenJspSchedule.iMaxEndTime;
    else
        tFrameEndPoint = ...
            stResourceConfigSchOut.stResourceConfig.stMachineConfig(3).afTimePointAtCap(tt+1) - epsilon_slot;
    end
%        tFrameStartPoint
%        tFrameEndPoint
%        astMachineUsageTimeInfo(3).aSortedTime
%        iTimeSlotPointCurr
%        iMaxPointTimeSlot
    if iTimeSlotPointCurr >= iMaxPointTimeSlot
        break;
    end
    while astMachineUsageTimeInfo(3).aSortedTime(iTimeSlotPointCurr) <= tFrameEndPoint  % & astMachineUsageTimeInfo(3).aSortedTime(iTimeSlotPointCurr) >= tFrameStartPoint
        %astMachineUsageTimeInfo(3).aMachineUsageAfterTime(iTimeSlotPointCurr)
        if astMachineUsageTimeInfo(3).aMachineUsageAfterTime(iTimeSlotPointCurr) ...
                > stResourceConfigSchOut.stResourceConfig.stMachineConfig(3).afMaCapAtTimePoint(tt)
            stResourceConfigSchOut.stResourceConfig.stMachineConfig(3).afMaCapAtTimePoint(tt) = ...
                astMachineUsageTimeInfo(3).aMachineUsageAfterTime(iTimeSlotPointCurr);
        end
        if astMachineUsageTimeInfo(3).aMachineUsageBeforeTime(iTimeSlotPointCurr) ...
                > stResourceConfigSchOut.stResourceConfig.stMachineConfig(3).afMaCapAtTimePoint(tt)
            stResourceConfigSchOut.stResourceConfig.stMachineConfig(3).afMaCapAtTimePoint(tt) = ...
                astMachineUsageTimeInfo(3).aMachineUsageBeforeTime(iTimeSlotPointCurr);
        end
        iTimeSlotPointCurr = iTimeSlotPointCurr + 1;
        if iTimeSlotPointCurr >= iMaxPointTimeSlot
            break;
        end
    end
end

    % Donot consider the first machine, debug for the last frame 20080415 
for mm = 2:1:stResourceConfigSchOut.stResourceConfig.iTotalMachine    
    if stResourceConfigSchOut.stResourceConfig.stMachineConfig(mm).afMaCapAtTimePoint(iTotalTimePoint_inFrame_SchOut) ...
            == 0
%         if iTotalTimePoint_inFrame_SchOut >= 2
%             stResourceConfigSchOut.stResourceConfig.stMachineConfig(mm).afMaCapAtTimePoint(iTotalTimePoint_inFrame_SchOut) ...
%                 = stResourceConfigSchOut.stResourceConfig.stMachineConfig(mm).afMaCapAtTimePoint(iTotalTimePoint_inFrame_SchOut-1);
%         else
            stResourceConfigSchOut.stResourceConfig.stMachineConfig(mm).afMaCapAtTimePoint(iTotalTimePoint_inFrame_SchOut) = 1;
%         end
    end
end

stOutput.iMaxPrimeMoverUsageBySchOut = iMaxPrimeMoverUsageBySchOut;
stOutput.iMaxYardCraneUsageBySchOut  = iMaxYardCraneUsageBySchOut;
stOutput.astMachineUsageInfoPerAgent    = astMachineUsageInfoPerAgent;
stOutput.stResourceConfigSchOut      = stResourceConfigSchOut;