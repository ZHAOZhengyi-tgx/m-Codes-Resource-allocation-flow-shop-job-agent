function [stOutput] = jsp_bld_machfig_by_sch(stSystemMasterConfig, stAgenJspSchedule)
% jsp_bld_machfig_by_sch
% History
% YYYYMMDD Notes
% 20080107 port from psa_fsp_bld_machfig_by_sch
% 20080301 debug, replace stResourceConfigInit
% 20080415 debug for the last frame 

global epsilon_slot; % 20071109

stResourceConfig = stAgenJspSchedule.stResourceConfig;
% % % stResourceConfig.iaMachCapOnePer = stAgenJspSchedule.iTotalMachineNum;
% % % stResourceConfig.iCriticalMachType = stResourceConfigInit.iCriticalMachType;
% % % stResourceConfig.iTotalMachine = stResourceConfigInit.iTotalMachine;
fTimeFrameUnitInHour = stSystemMasterConfig.fTimeFrameUnitInHour;
iTotalMachType = stSystemMasterConfig.iTotalMachType;

[astMachineUsageTimeInfo] = jsp_build_machine_usage_con_tm(stAgenJspSchedule);

for mm = 1:1:stAgenJspSchedule.iTotalMachine
    iaMaxMachUsageBySchOut(mm) = astMachineUsageTimeInfo(mm).iMaxUsage;
%    stResourceConfig.iaMachCapOnePer(mm) = iaMaxMachUsageBySchOut(mm); % 20080301
end

astMachineUsageInfoPerAgent.astMachineUsageTimeInfo = astMachineUsageTimeInfo;
iTotalTimePoint_inFrame_SchOut = ceil(stAgenJspSchedule.iMaxEndTime * stAgenJspSchedule.fTimeUnit_Min/60 /fTimeFrameUnitInHour);
fFactorSlotPerFrame = fTimeFrameUnitInHour * 60 /stAgenJspSchedule.fTimeUnit_Min;

%%% Initalize output structure
for mm = 1:1:iTotalMachType
    
%    stResourceConfig.stMachineConfig(mm).strName = stResourceConfigInit.stMachineConfig(mm).strName;
    %% whether this machine is a critical machine
    if mm == stSystemMasterConfig.iCriticalMachType
        stResourceConfig.stMachineConfig(mm).iNumPointTimeCap = 1;
        stResourceConfig.stMachineConfig(mm).afMaCapAtTimePoint = 1;
        stResourceConfig.stMachineConfig(mm).afTimePointAtCap = 0;
    else

        %%%% Machine Config for PM
        stResourceConfig.stMachineConfig(mm).iNumPointTimeCap = iTotalTimePoint_inFrame_SchOut;
        stResourceConfig.stMachineConfig(mm).afMaCapAtTimePoint = zeros(1, iTotalTimePoint_inFrame_SchOut);
        for tt = 1:1:iTotalTimePoint_inFrame_SchOut
            stResourceConfig.stMachineConfig(mm).afTimePointAtCap(tt) = (tt - 1) * fFactorSlotPerFrame;
        end
    end
end

for mm = 1:1:iTotalMachType
    if mm ~= stSystemMasterConfig.iCriticalMachType
        iTimeSlotPointCurr = 1;
        iMaxPointTimeSlot = length(astMachineUsageTimeInfo(mm).aSortedTime);
        for tt = 1:1:iTotalTimePoint_inFrame_SchOut
            stResourceConfig.stMachineConfig(mm).afMaCapAtTimePoint(tt) = 0;
            tFrameStartPoint = stResourceConfig.stMachineConfig(mm).afTimePointAtCap(tt);
            if tt == iTotalTimePoint_inFrame_SchOut
                tFrameEndPoint = stAgenJspSchedule.iMaxEndTime;
            else
                tFrameEndPoint =  stResourceConfig.stMachineConfig(mm).afTimePointAtCap(tt+1) - epsilon_slot;
            end
            if iTimeSlotPointCurr >= iMaxPointTimeSlot
                break;
            end
            while astMachineUsageTimeInfo(mm).aSortedTime(iTimeSlotPointCurr) <= tFrameEndPoint
                   % ... & %%% numerical error may happen such that
                   % astMachineUsageTimeInfo(mm).aSortedTime(iTimeSlotPointCu
                   % rr) < 0
                   % astMachineUsageTimeInfo(mm).aSortedTime(iTimeSlotPointCurr) >= tFrameStartPoint 
                if astMachineUsageTimeInfo(mm).aMachineUsageAfterTime(iTimeSlotPointCurr) > stResourceConfig.stMachineConfig(mm).afMaCapAtTimePoint(tt)
                    stResourceConfig.stMachineConfig(mm).afMaCapAtTimePoint(tt) = ...
                        astMachineUsageTimeInfo(mm).aMachineUsageAfterTime(iTimeSlotPointCurr);
                end
    %             if astMachineUsageTimeInfo(mm).aMachineUsageBeforeTime(iTimeSlotPointCurr) > stResourceConfig.stMachineConfig(mm).afMaCapAtTimePoint(tt)
    %                 stResourceConfig.stMachineConfig(mm).afMaCapAtTimePoint(tt) = ...
    %                     astMachineUsageTimeInfo(mm).aMachineUsageBeforeTime(iTimeSlotPointCurr);
    %             end
                iTimeSlotPointCurr = iTimeSlotPointCurr + 1;
                if iTimeSlotPointCurr >= iMaxPointTimeSlot
                    break;
                end
            end
        end
    end
end

% Protection in case there is 0 in afMaCapAtTimePoint
% Donot consider the first machine % 20080415 debug for the last frame 
for mm = 1:1:iTotalMachType
    if mm ~= stSystemMasterConfig.iCriticalMachType && ...
            stResourceConfig.stMachineConfig(mm).afMaCapAtTimePoint(iTotalTimePoint_inFrame_SchOut) == 0
%         if iTotalTimePoint_inFrame_SchOut >= 2
%             stResourceConfig.stMachineConfig(mm).afMaCapAtTimePoint(iTotalTimePoint_inFrame_SchOut) ...
%                 = stResourceConfig.stMachineConfig(mm).afMaCapAtTimePoint(iTotalTimePoint_inFrame_SchOut-1);
%         else
            stResourceConfig.stMachineConfig(mm).afMaCapAtTimePoint(iTotalTimePoint_inFrame_SchOut) = 1;
%         end
    end
end

stOutput.iaMaxMachUsageBySchOut = iaMaxMachUsageBySchOut;
stOutput.astMachineUsageInfoPerAgent    = astMachineUsageInfoPerAgent;
stOutput.stResourceConfig      = stResourceConfig;