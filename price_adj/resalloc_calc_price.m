function [stMachinePriceInfo, stMachineUsageInfoSystem, stMachineUsageInfoByAgent, s_r, alpha] = resalloc_calc_price(stResAllocGenJspAgent, stAgent_Solution, stMachinePriceInfo)

if stResAllocGenJspAgent.iAlgoChoice == 7 | stResAllocGenJspAgent.iAlgoChoice == 18 ...
      | stResAllocGenJspAgent.iAlgoChoice == 19 | stResAllocGenJspAgent.iAlgoChoice == 20 | stResAllocGenJspAgent.iAlgoChoice == 21
    %% multiple period model
    [stMachineUsageInfoSystem, stMachineUsageInfoByAgent] = psa_bidgen_build_bid_by_cfg(stResAllocGenJspAgent, stAgent_Solution);
%    [stMachineUsageInfoBerth, stMachineUsageInfoByQc] = psa_bidgen_build_bid_by_cfg(stBerthJobInfo, stAgent_Solution);
else
            error('wrong input');
end

%%% Calculation price
if stResAllocGenJspAgent.stPriceAjustment.iFlagStrategy == 1
    [stMachinePriceInfo] = psa_resalloc_update_price(stResAllocGenJspAgent, stMachineUsageInfoSystem, stMachinePriceInfo);
elseif stResAllocGenJspAgent.stPriceAjustment.iFlagStrategy == 2
    [stMachinePriceInfo] = price_adj_psa_02(stResAllocGenJspAgent, stMachineUsageInfoSystem, stMachinePriceInfo);
elseif stResAllocGenJspAgent.stPriceAjustment.iFlagStrategy == 3
    [stMachinePriceInfo] = price_adj_psa_03(stResAllocGenJspAgent, stMachineUsageInfoSystem, stMachinePriceInfo);
elseif stResAllocGenJspAgent.stPriceAjustment.iFlagStrategy == 4
    [stMachinePriceInfo] = price_adj_psa_04(stResAllocGenJspAgent, stMachineUsageInfoSystem, stMachinePriceInfo);
elseif stResAllocGenJspAgent.stPriceAjustment.iFlagStrategy == 5
    [stMachinePriceInfo] = price_adj_psa_05(stResAllocGenJspAgent, stMachineUsageInfoSystem, stMachinePriceInfo);
elseif stResAllocGenJspAgent.stPriceAjustment.iFlagStrategy == 6
    [stMachinePriceInfo] = price_adj_psa_06(stResAllocGenJspAgent, stMachineUsageInfoSystem, stMachinePriceInfo);
elseif stResAllocGenJspAgent.stPriceAjustment.iFlagStrategy == 7
    [stMachinePriceInfo] = price_adj_psa_07(stResAllocGenJspAgent, stMachineUsageInfoSystem, stMachinePriceInfo);
elseif stResAllocGenJspAgent.stPriceAjustment.iFlagStrategy == 8
    [stMachinePriceInfo] = price_adj_psa_08(stResAllocGenJspAgent, stMachineUsageInfoSystem, stMachinePriceInfo);
else    
    error('Wrong input, check: PA_STRATEGY');
end

