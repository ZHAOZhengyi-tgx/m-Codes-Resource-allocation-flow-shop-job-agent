function [fCostPerPM, fCostPerYC]  = fsp_resalloc_calc_cost(stBerthJobInfo, stAgentJobInfo, tAgentJobDuration_hour)

tStartHour = stAgentJobInfo.atClockAgentJobStart.aClockYearMonthDateHourMinSec(4) ...
             + (stAgentJobInfo.atClockAgentJobStart.aClockYearMonthDateHourMinSec(5) ...
                 +  stAgentJobInfo.atClockAgentJobStart.aClockYearMonthDateHourMinSec(6)/60 ...
               )/60;
tStartTimeFrame = tStartHour/stBerthJobInfo.fTimeFrameUnitInHour;
tAgentJobDurationTimeFrame = tAgentJobDuration_hour /stBerthJobInfo.fTimeFrameUnitInHour;
tEndTimeFrame = tAgentJobDurationTimeFrame + tStartTimeFrame;
tIntStartTimeFrame = ceil(tStartTimeFrame);
tIntEndTimeFrame = ceil(tEndTimeFrame);
iTotalFramePerDay = floor(24/stBerthJobInfo.fTimeFrameUnitInHour);

fCostPerPM = 0;
fCostPerYC = 0;
for idxFrameFromZero = tIntStartTimeFrame:1:tIntEndTimeFrame
    idxFrameFromOne = mod(idxFrameFromZero, iTotalFramePerDay)+1;
    fCostCurrentFramePM = stBerthJobInfo.fPricePrimeMoverDollarPerFrame(idxFrameFromOne);
    fCostCurrentFrameYC = stBerthJobInfo.fPriceYardCraneDollarPerFrame(idxFrameFromOne);
    if idxFrameFromZero == tIntStartTimeFrame
         fCostPerPM = (tIntStartTimeFrame - tStartTimeFrame) * fCostCurrentFramePM;
         fCostPerYC = (tIntStartTimeFrame - tStartTimeFrame) * fCostCurrentFrameYC;
    elseif idxFrameFromZero == tIntEndTimeFrame
         fCostPerPM = fCostPerPM + (tEndTimeFrame + 1 - tIntEndTimeFrame) * fCostCurrentFramePM;
         fCostPerYC = fCostPerYC + (tEndTimeFrame + 1 - tIntEndTimeFrame) * fCostCurrentFrameYC;
    else
         fCostPerPM = fCostPerPM + fCostCurrentFramePM;
         fCostPerYC = fCostPerYC + fCostCurrentFrameYC;
    end
   
end

