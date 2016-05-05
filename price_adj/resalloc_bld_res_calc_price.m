function [stMachinePriceInfo, stMachineUsageInfoSystem, stMachineUsageInfoByQc, s_r, alpha] = resalloc_bld_res_calc_price(stBerthJobInfo, stQC_Solution, stMachinePriceInfo)

if stBerthJobInfo.iAlgoChoice == 1 || ...
        stBerthJobInfo.iAlgoChoice == 2 || ...
        stBerthJobInfo.iAlgoChoice == 4 
            %% single period model
    %        [stMachineUsageInfoSystem] = psa_resalloc_build_mach_usage(stBerthJobInfo, stQC_Solution);
            [stMachineUsageInfoSystem, stMachineUsageInfoByQc] = psa_bidgen_bld_mach_usage02(stBerthJobInfo, stQC_Solution);
elseif stBerthJobInfo.iAlgoChoice == 5 || ...
        stBerthJobInfo.iAlgoChoice == 7 || ...
        stBerthJobInfo.iAlgoChoice == 18 || ...
        stBerthJobInfo.iAlgoChoice == 19 || ...
        stBerthJobInfo.iAlgoChoice == 20 || ...
        stBerthJobInfo.iAlgoChoice == 21
    %% multiple period model
    [stMachineUsageInfoSystem, stMachineUsageInfoByQc] = psa_bidgen_build_bid_by_cfg(stBerthJobInfo, stQC_Solution);

else
            error('wrong input');
end

%%% Calculation price
if stBerthJobInfo.stPriceAjustment.iFlagStrategy == 1
    [stMachinePriceInfo] = psa_resalloc_update_price(stBerthJobInfo, stMachineUsageInfoSystem, stMachinePriceInfo);
elseif stBerthJobInfo.stPriceAjustment.iFlagStrategy == 2
    [stMachinePriceInfo] = price_adj_psa_02(stBerthJobInfo, stMachineUsageInfoSystem, stMachinePriceInfo);
elseif stBerthJobInfo.stPriceAjustment.iFlagStrategy == 3
    [stMachinePriceInfo] = price_adj_psa_03(stBerthJobInfo, stMachineUsageInfoSystem, stMachinePriceInfo);
elseif stBerthJobInfo.stPriceAjustment.iFlagStrategy == 4
    [stMachinePriceInfo] = price_adj_psa_04(stBerthJobInfo, stMachineUsageInfoSystem, stMachinePriceInfo);
elseif stBerthJobInfo.stPriceAjustment.iFlagStrategy == 5
    [stMachinePriceInfo] = price_adj_psa_05(stBerthJobInfo, stMachineUsageInfoSystem, stMachinePriceInfo);
elseif stBerthJobInfo.stPriceAjustment.iFlagStrategy == 6
    [stMachinePriceInfo] = price_adj_psa_06(stBerthJobInfo, stMachineUsageInfoSystem, stMachinePriceInfo);
elseif stBerthJobInfo.stPriceAjustment.iFlagStrategy == 7
    [stMachinePriceInfo] = price_adj_psa_07(stBerthJobInfo, stMachineUsageInfoSystem, stMachinePriceInfo);
elseif stBerthJobInfo.stPriceAjustment.iFlagStrategy == 8
    [stMachinePriceInfo] = price_adj_psa_08(stBerthJobInfo, stMachineUsageInfoSystem, stMachinePriceInfo);
else    
    error('Wrong input, check: PA_STRATEGY');
end

