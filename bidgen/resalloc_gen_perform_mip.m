function [stAgent_Solution] = resalloc_gen_perform_mip(stInputResAlloc, stAgent_Solution)

% 20080321
stResAllocGenJspAgent    = stInputResAlloc.stResAllocGenJspAgent;
astAgentJobListJspCfg    = stInputResAlloc.astAgentJobListJspCfg;

stSystemMasterConfig     = stResAllocGenJspAgent.stSystemMasterConfig;
stAgentJobInfo       = stResAllocGenJspAgent.stAgentJobInfo;
iPlotFlag = stSystemMasterConfig.iPlotFlag;

%% donot consider resource cost
for ii = 1: 1:stSystemMasterConfig.iTotalAgent

    fFactorHourPerSlot    = astAgentJobListJspCfg(ii).fTimeUnit_Min/60 /stSystemMasterConfig.fTimeFrameUnitInHour;
    tMinCostMakeSpan_hour =  stAgent_Solution(ii).stCostAtAgent.stSolutionMinCost.stSchedule.iMaxEndTime * fFactorHourPerSlot;
    [fTardinessFine_Sgd, tAgentTardiness_hour] = resalloc_calc_tardi_fine(stSystemMasterConfig, stAgentJobInfo(ii), tMinCostMakeSpan_hour);
    stAgent_Solution(ii).stPerformReport.tMinCostMakeSpan_hour = tMinCostMakeSpan_hour;
        
        if stSystemMasterConfig.iObjFunction == 3
            stAgent_Solution(ii).stPerformReport.fDelayPanelty =  fTardinessFine_Sgd;
            stAgent_Solution(ii).stPerformReport.fCostMakespan =  0;
        elseif stSystemMasterConfig.iObjFunction == 4
            stAgent_Solution(ii).stPerformReport.fDelayPanelty =  fTardinessFine_Sgd;
            stAgent_Solution(ii).stPerformReport.fCostMakespan =  stAgentJobInfo(ii).fPriceAgentDollarPerFrame ...
                * stAgent_Solution(ii).stPerformReport.tMinCostMakeSpan_hour / stSystemMasterConfig.fTimeFrameUnitInHour;
        elseif stSystemMasterConfig.iObjFunction == 2
            idxTimeFrameStart = floor(stAgentJobInfo(ii).atClockAgentJobStart.aClockYearMonthDateHourMinSec(4)/stSystemMasterConfig.fTimeFrameUnitInHour) + 1;
            stAgent_Solution(ii).stPerformReport.fDelayPanelty =  fTardinessFine_Sgd;
            stAgent_Solution(ii).stPerformReport.fCostMakespan =  0;
        elseif stSystemMasterConfig.iObjFunction == 1
            idxTimeFrameStart = floor(stAgentJobInfo(ii).atClockAgentJobStart.aClockYearMonthDateHourMinSec(4)/stSystemMasterConfig.fTimeFrameUnitInHour) + 1;
            stAgent_Solution(ii).stPerformReport.fCostMakespan = stAgentJobInfo(ii).fPriceAgentDollarPerFrame ...
                * stAgent_Solution(ii).stPerformReport.tMinCostMakeSpan_hour / stSystemMasterConfig.fTimeFrameUnitInHour; 
            stAgent_Solution(ii).stPerformReport.fDelayPanelty = 0;
        end
        stAgent_Solution(ii).stPerformReport.fCostMakespanTardiness = ...
            + stAgent_Solution(ii).stPerformReport.fDelayPanelty ...
            + stAgent_Solution(ii).stPerformReport.fCostMakespan;

        stAgent_Solution(ii).stPerformReport.tMinCostGrossCraneRate = (astAgentJobListJspCfg(ii).iTotalJob)/ stAgent_Solution(ii).stPerformReport.tMinCostMakeSpan_hour;
        stAgent_Solution(ii).stPerformReport.tSolutionTime_sec      = stAgent_Solution(ii).stCostAtAgent.tSolutionTime_sec;

        if stSystemMasterConfig.iAlgoChoice == 22 %% MIP debug later
            [stBuildMachConfigOutput] = jsp_bld_machfig_by_sch(stSystemMasterConfig.fTimeFrameUnitInHour, stAgent_Solution(ii).stCostAtAgent.stSolutionMinCost.stSchedule);
            stResourceConfigMIP_Solution(ii)      = stBuildMachConfigOutput.stResourceConfigSchOut;
        elseif stSystemMasterConfig.iAlgoChoice == 25 %% LPR already done in psa_bld_solution_by_berth_lpr or *_lpr.m % 20080321
            stResourceConfigMIP_Solution(ii)      = stAgent_Solution(ii).stSchedule_MinCost.stResourceConfig;
        end
        
        atClockAgentJobStart     = stAgentJobInfo(ii).atClockAgentJobStart;
        tStartHour            = mod(atClockAgentJobStart.aClockYearMonthDateHourMinSec(4), 24);
        iPriceHourStartIndex  = tStartHour + 1;
        iTotalPeriod_act = ceil(tMinCostMakeSpan_hour);
        iPriceHourIndex = iPriceHourStartIndex;
        fCostPMYC = 0;
        
        stAgent_Solution(ii).stPerformReport.fMinCost               = fCostPMYC + stAgent_Solution(ii).stPerformReport.fCostMakespanTardiness;

end

if iPlotFlag >= 5
    stAgent_Solution.stPerformReport
end

