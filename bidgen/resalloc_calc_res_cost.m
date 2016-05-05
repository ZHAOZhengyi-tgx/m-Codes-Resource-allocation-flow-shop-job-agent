function [afCostPerUnitRes]  = resalloc_calc_res_cost(stSystemMasterConfig, stAgentJobInfo, tAgentJobDuration_hour, astResourcePrice)

tStartHour = stAgentJobInfo.atClockAgentJobStart.aClockYearMonthDateHourMinSec(4) ...
             + (stAgentJobInfo.atClockAgentJobStart.aClockYearMonthDateHourMinSec(5) ...
                 +  stAgentJobInfo.atClockAgentJobStart.aClockYearMonthDateHourMinSec(6)/60 ...
               )/60;
tStartTimeFrame = tStartHour/stSystemMasterConfig.fTimeFrameUnitInHour;
tAgentJobDurationTimeFrame = tAgentJobDuration_hour /stSystemMasterConfig.fTimeFrameUnitInHour;
tEndTimeFrame = tAgentJobDurationTimeFrame + tStartTimeFrame;
tIntStartTimeFrame = ceil(tStartTimeFrame);
tIntEndTimeFrame = ceil(tEndTimeFrame);
iTotalFramePerDay = floor(24/stSystemMasterConfig.fTimeFrameUnitInHour);

iTotalMachType = stSystemMasterConfig.iTotalMachType;
afCostPerUnitRes = zeros(1, iTotalMachType);
fCostPerYC = 0;
for mm = 1:1:iTotalMachType
    for idxFrameFromZero = tIntStartTimeFrame:1:tIntEndTimeFrame
        idxFrameFromOne = mod(idxFrameFromZero, iTotalFramePerDay)+1;
        fCostCurrentFrameRes = astResourcePrice(mm).afMachinePriceListPerFrame(idxFrameFromOne);
        if idxFrameFromZero == tIntStartTimeFrame
             afCostPerUnitRes(mm) = (tIntStartTimeFrame - tStartTimeFrame) * fCostCurrentFrameRes;
        elseif idxFrameFromZero == tIntEndTimeFrame
             afCostPerUnitRes(mm) = afCostPerUnitRes(mm) + (tEndTimeFrame + 1 - tIntEndTimeFrame) * fCostCurrentFrameRes;
        else
             afCostPerUnitRes(mm) = afCostPerUnitRes(mm) + fCostCurrentFrameRes;
        end

    end
end
