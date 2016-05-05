function [stAgent_Solution] = psa_bidgen_gen_perform_mip(stBerthJobInfo, stAgent_Solution, stPortJobInfo)


for ii = 1: 1:stBerthJobInfo.iTotalAgent

    fFactorHourPerSlot    = stPortJobInfo(ii).fTimeUnit_Min/60 /stBerthJobInfo.fTimeFrameUnitInHour;
    tMinCostMakeSpan_hour =  stAgent_Solution(ii).stCostAtAgent.stSolutionMinCost.stSchedule.iMaxEndTime * fFactorHourPerSlot;
    [fTardinessFine_Sgd, tAgentTardiness_hour] = resalloc_calc_tardi_fine(stBerthJobInfo, stBerthJobInfo.stAgentJobInfo(ii), tMinCostMakeSpan_hour);
    stAgent_Solution(ii).stPerformReport.tMinCostMakeSpan_hour = tMinCostMakeSpan_hour;
%    stAgent_Solution(ii).    stCostAtAgent(ii).stCostList(iCasePMYC).fTardiness = tMinCostMakeSpan_hour;
        
        if stBerthJobInfo.iObjFunction == 3
            [fCostPerPM, fCostPerYC]  = ...
                fsp_resalloc_calc_cost(stBerthJobInfo, stBerthJobInfo.stAgentJobInfo(ii), tMinCostMakeSpan_hour);
            stAgent_Solution(ii).stPerformReport.fDelayPanelty =  fTardinessFine_Sgd;
            stAgent_Solution(ii).stPerformReport.fCostMakespan =  0;
        elseif stBerthJobInfo.iObjFunction == 4
            [fCostPerPM, fCostPerYC]  = ...
                fsp_resalloc_calc_cost(stBerthJobInfo, stBerthJobInfo.stAgentJobInfo(ii), tMinCostMakeSpan_hour);
            stAgent_Solution(ii).stPerformReport.fDelayPanelty =  fTardinessFine_Sgd;
            stAgent_Solution(ii).stPerformReport.fCostMakespan =  stBerthJobInfo.stAgentJobInfo(ii).fPriceQuayCraneDollarPerFrame ...
                * stAgent_Solution(ii).stPerformReport.tMinCostMakeSpan_hour / stBerthJobInfo.fTimeFrameUnitInHour;
        elseif stBerthJobInfo.iObjFunction == 2
            idxTimeFrameStart = floor(stBerthJobInfo.stAgentJobInfo(ii).atClockAgentJobStart.aClockYearMonthDateHourMinSec(4)/stBerthJobInfo.fTimeFrameUnitInHour) + 1;
            fCostPerPM = stBerthJobInfo.fPricePrimeMoverDollarPerFrame(idxTimeFrameStart);
            fCostPerYC = stBerthJobInfo.fPriceYardCraneDollarPerFrame(idxTimeFrameStart);
            stAgent_Solution(ii).stPerformReport.fDelayPanelty =  fTardinessFine_Sgd;
            stAgent_Solution(ii).stPerformReport.fCostMakespan =  0;
        elseif stBerthJobInfo.iObjFunction == 1
            idxTimeFrameStart = floor(stBerthJobInfo.stAgentJobInfo(ii).atClockAgentJobStart.aClockYearMonthDateHourMinSec(4)/stBerthJobInfo.fTimeFrameUnitInHour) + 1;
            fCostPerPM = stBerthJobInfo.fPricePrimeMoverDollarPerFrame(idxTimeFrameStart);
            fCostPerYC = stBerthJobInfo.fPriceYardCraneDollarPerFrame(idxTimeFrameStart);
            stAgent_Solution(ii).stPerformReport.fCostMakespan = stBerthJobInfo.stAgentJobInfo(ii).fPriceQuayCraneDollarPerFrame ...
                * stAgent_Solution(ii).stPerformReport.tMinCostMakeSpan_hour / stBerthJobInfo.fTimeFrameUnitInHour; 
            stAgent_Solution(ii).stPerformReport.fDelayPanelty = 0;
        end
        stAgent_Solution(ii).stPerformReport.fCostMakespanTardiness = ...
            + stAgent_Solution(ii).stPerformReport.fDelayPanelty ...
            + stAgent_Solution(ii).stPerformReport.fCostMakespan;

        stAgent_Solution(ii).stPerformReport.tMinCostGrossCraneRate = (stPortJobInfo(ii).TotalContainer_Load + stPortJobInfo(ii).TotalContainer_Discharge)/ stAgent_Solution(ii).stPerformReport.tMinCostMakeSpan_hour;
        stAgent_Solution(ii).stPerformReport.tSolutionTime_sec      = stAgent_Solution(ii).stCostAtAgent.tSolutionTime_sec;

        [stBuildMachConfigOutput] = psa_fsp_bld_machfig_by_sch ...
                (stBerthJobInfo.fTimeFrameUnitInHour, stPortJobInfo(ii).stResourceConfig, stAgent_Solution(ii).stCostAtAgent.stSolutionMinCost.stSchedule);
        stResourceConfigMIP_Solution(ii)      = stBuildMachConfigOutput.stResourceConfigSchOut;
        
        atClockAgentJobStart     = stBerthJobInfo.stAgentJobInfo(ii).atClockAgentJobStart;
        tStartHour            = mod(atClockAgentJobStart.aClockYearMonthDateHourMinSec(4), 24);
        iPriceHourStartIndex  = tStartHour + 1;
        iTotalPeriod_act = ceil(tMinCostMakeSpan_hour);
        iPriceHourIndex = iPriceHourStartIndex;
        fCostPMYC = 0;
        for tt = 1:1:iTotalPeriod_act
            kUsagePM = stResourceConfigMIP_Solution(ii).stResourceConfig.stMachineConfig(2).afMaCapAtTimePoint(tt);
            kUsageYC = stResourceConfigMIP_Solution(ii).stResourceConfig.stMachineConfig(3).afMaCapAtTimePoint(tt);
            
            fCostPMYC = fCostPMYC + stBerthJobInfo.fPricePrimeMoverDollarPerFrame(iPriceHourIndex) * kUsagePM + ...
                stBerthJobInfo.fPriceYardCraneDollarPerFrame(iPriceHourIndex) * kUsageYC;
            if iPriceHourIndex == 24
                iPriceHourIndex = 0;
            end
            iPriceHourIndex = iPriceHourIndex + 1;
        end
        
        stAgent_Solution(ii).stPerformReport.fMinCost               = fCostPMYC + stAgent_Solution(ii).stPerformReport.fCostMakespanTardiness;

end

if stBerthJobInfo.iPlotFlag >= 3
    stAgent_Solution.stPerformReport
end
