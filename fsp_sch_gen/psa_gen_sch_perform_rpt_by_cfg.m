function [stAgent_Solution] = psa_gen_sch_perform_rpt_by_cfg(stBerthJobInfo, stAgentJobInfo, stJobListInfoAgent)

% if stBerthJobInfo.stJssProbStructConfig.isCriticalOperateSeq == 1
%     [stPartialScheduleCH, jobshop_config] = psa_jsp_gen_job_schedule_28(stJobListInfoAgent);
% else

%     stJobListInfoAgent.aiJobSeqInJspCfg = stJobListInfoAgent.stJobListBiFsp.aiJobSeqInJspCfg;
%     [stPartialScheduleCH, jobshop_config] = fsp_bidir_multi_m_t_ch_seq(stJobListInfoAgent);
   [stPartialScheduleCH] = fsp_gen_job_sche_ch_seq_(stJobListInfoAgent.stJobListBiFsp, ...
       stJobListInfoAgent.stJobListBiFsp.aiJobSeqInJspCfg);
% end
%%%% debug display
%stPartialScheduleCH.iTotalMachineNum(2)
%max(stJobListInfoAgent.stResourceConfig.stMachineConfig(2).afMaCapAtTimePoint)

%%%% dispatching is done in the centralized auctioneer, to save timing,
%%%% donot do it each round of auction
stAgent_Solution.stCostAtAgent.stSolutionMinCost.stSchedule = stPartialScheduleCH;

%% use one of the following three
% 1.
[stBuildMachConfigOutput] = psa_fsp_bld_machfig_by_sch ...
    (stBerthJobInfo.fTimeFrameUnitInHour, stJobListInfoAgent.stResourceConfig, stPartialScheduleCH);
stJobListInfoAgent.stResourceConfig = stBuildMachConfigOutput.stResourceConfigSchOut.stResourceConfig;

% 2.
% [stBuildMachConfigOutput] = jsp_bld_machfig_by_sch ...
%     (stBerthJobInfo.stSystemMasterConfig, stPartialScheduleCH);
% stJobListInfoAgent.stResourceConfig = stBuildMachConfigOutput.stResourceConfig;

% 3.
stAgent_Solution.stCostAtAgent.stSolutionMinCost.stSchedule.stResourceConfig = stJobListInfoAgent.stResourceConfig;
stAgent_Solution.stMinCostResourceConfig = stJobListInfoAgent.stResourceConfig;

%%%% MakeSpan and Tardiness
fFactorHourPerSlot    = stJobListInfoAgent.fTimeUnit_Min/60 /stBerthJobInfo.fTimeFrameUnitInHour;
tMinCostMakeSpan_hour = stPartialScheduleCH.iMaxEndTime * fFactorHourPerSlot;
[fTardinessFineMinCost_Sgd, tAgentTardiness_hour] = resalloc_calc_tardi_fine(stBerthJobInfo, stAgentJobInfo, tMinCostMakeSpan_hour);

%%%% Resource Cost
iTotalPeriod_act = ceil(tMinCostMakeSpan_hour);
iTotalPeriod = stJobListInfoAgent.stResourceConfig.stMachineConfig(2).iNumPointTimeCap;
atClockAgentJobStart     = stAgentJobInfo.atClockAgentJobStart;
tStartHour            = mod(atClockAgentJobStart.aClockYearMonthDateHourMinSec(4), 24);
iPriceHourStartIndex  = tStartHour + 1;
iPriceHourIndex = iPriceHourStartIndex;
fCostPMYC = 0;
for tt = 1:1:iTotalPeriod_act
    if tt > iTotalPeriod
        kUsagePM = stJobListInfoAgent.stResourceConfig.stMachineConfig(2).afMaCapAtTimePoint(iTotalPeriod);
        kUsageYC = stJobListInfoAgent.stResourceConfig.stMachineConfig(3).afMaCapAtTimePoint(iTotalPeriod);
    else
        kUsagePM = stJobListInfoAgent.stResourceConfig.stMachineConfig(2).afMaCapAtTimePoint(tt);
        kUsageYC = stJobListInfoAgent.stResourceConfig.stMachineConfig(3).afMaCapAtTimePoint(tt);
    end
    if stBerthJobInfo.iObjFunction == 5 % donot consider basement resource-level, only bid for extra
        fCostPMYC = fCostPMYC + ...
            stBerthJobInfo.astResourceInitPrice(2).afMachinePriceListPerFrame(iPriceHourIndex) ...
                  * max([0, kUsagePM - stJobListInfoAgent.stResourceConfig.iaMachCapOnePer(2)]) ...
            + ...
            stBerthJobInfo.astResourceInitPrice(3).afMachinePriceListPerFrame(iPriceHourIndex) ...
                * max([0, kUsageYC - stJobListInfoAgent.stResourceConfig.iaMachCapOnePer(3)]);
    else
        fCostPMYC = fCostPMYC ...
            + stBerthJobInfo.astResourceInitPrice(2).afMachinePriceListPerFrame(iPriceHourIndex) * kUsagePM ...
            + stBerthJobInfo.astResourceInitPrice(3).afMachinePriceListPerFrame(iPriceHourIndex) * kUsageYC;
    end

    if iPriceHourIndex == 24
        iPriceHourIndex = 0;
    end
    iPriceHourIndex = iPriceHourIndex + 1;
end


stAgentBiFSPJobMachConfig = stJobListInfoAgent.stJobListBiFsp.stAgentBiFSPJobMachConfig;
nTotalJobs = stAgentBiFSPJobMachConfig.iTotalForwardJobs + stAgentBiFSPJobMachConfig.iTotalReverseJobs;

stAgent_Solution.stPerformReport.tMinCostMakeSpan_hour = tMinCostMakeSpan_hour;
stAgent_Solution.stPerformReport.tMinCostGrossCraneRate = ...
    nTotalJobs / stAgent_Solution.stPerformReport.tMinCostMakeSpan_hour;
stAgent_Solution.stPerformReport.fCostMakespanTardiness = ...
    tMinCostMakeSpan_hour * stAgentJobInfo.fPriceAgentDollarPerFrame + fTardinessFineMinCost_Sgd;

stAgent_Solution.stPerformReport.fMinCost              = fCostPMYC  + ...
                                                      stAgent_Solution.stPerformReport.fCostMakespanTardiness;
stAgent_Solution.stSchedule_MinCost                   = stAgent_Solution.stCostAtAgent.stSolutionMinCost.stSchedule;