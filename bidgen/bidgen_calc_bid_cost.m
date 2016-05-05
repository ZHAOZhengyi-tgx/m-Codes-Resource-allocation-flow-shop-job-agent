function [fTardinessFine_dollar, tAgentTardiness_frame, afCostPerUnitRes, fCostMakespan] = bidgen_calc_bid_cost(stSystemMasterConfig, stAgentJobInfo, tMakeSpan_hour, astResourceInitPrice)
%% INPUT:  
%%    stSystemMasterConfig, 
%%    stAgentJobInfo,
%%    tMakeSpan_hour, 
%%    astResourceInitPrice
%% OUTPUT: 
%%    fTardinessFine_dollar, 
%%    tAgentTardiness_frame,
%%    afCostPerUnitRes, 
%%    fCostMakespan

[fTardinessFine_dollar, tAgentTardiness_frame] = resalloc_calc_tardi_fine(stSystemMasterConfig, stAgentJobInfo, tMakeSpan_hour);
%% OUTPUT: tAgentTardiness_frame;

if stSystemMasterConfig.iObjFunction == 4  %% tardiness penalty + resource cost ( round to time slot unitr) + makespan cost (round to time frame)
    [afCostPerUnitRes]  = resalloc_calc_res_cost(stSystemMasterConfig, stAgentJobInfo, tMakeSpan_hour, astResourceInitPrice);
    fCostMakespan =  stAgentJobInfo.fPriceAgentDollarPerFrame ...
        * tMakeSpan_hour / stSystemMasterConfig.fTimeFrameUnitInHour; %% OUTPUT:

elseif stSystemMasterConfig.iObjFunction == 3      %% tardiness penalty + resource cost to time slot unitr, no makespan cost, 
    [afCostPerUnitRes]  = resalloc_calc_res_cost(stSystemMasterConfig, stAgentJobInfo, tMakeSpan_hour, astResourceInitPrice);
    fCostMakespan =  0;

elseif stSystemMasterConfig.iObjFunction == 2  %% tardiness penalty + resource cost ( round to time frame), no makespan cost
    idxTimeFrameStart = floor(stAgentJobInfo.atClockAgentJobStart.aClockYearMonthDateHourMinSec(4)/stSystemMasterConfig.fTimeFrameUnitInHour) + 1;
    for mm = 1:1:nTotalMachType
        afCostPerUnitRes(mm) = astResourceInitPrice(mm).afMachinePriceListPerFrame(idxTimeFrameStart); %% OUTPUT
    end
    fCostMakespan =  0; %% OUTPUT

elseif stSystemMasterConfig.iObjFunction == 1  %% makespan cost (round to time frame) + resource cost(round to time frame), no tardiness penalty
    idxTimeFrameStart = floor(stAgentJobInfo.atClockAgentJobStart.aClockYearMonthDateHourMinSec(4)/stSystemMasterConfig.fTimeFrameUnitInHour) + 1;
    for mm = 1:1:nTotalMachType
        afCostPerUnitRes(mm) = astResourceInitPrice(mm).afMachinePriceListPerFrame(idxTimeFrameStart); %% OUTPUT
    end
    fCostMakespan = stAgentJobInfo.fPriceAgentDollarPerFrame ...
        * tMakeSpan_hour / stSystemMasterConfig.fTimeFrameUnitInHour;  %% OUTPUT
    fTardinessFine_dollar = 0;  %% OUTPUT
end
