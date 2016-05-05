function [stOutput] = fsp_get_sched_cost_by_agent(stInput)
% fsp_get_sched_cost_by_agent
% History
% YYYYMMDD  Notes
% 20070524  rename from psa_fsp_get_sched_cost_per_qc




stJobListInfoAgent = stInput.stJobListInfoAgent;
stBerthJobInfo = stInput.stBerthJobInfo;

%stJobListInfoAgent.stResourceConfig.stMachineConfig(2).afMaCapAtTimePoint
%stJobListInfoAgent.stResourceConfig.stMachineConfig(3).afMaCapAtTimePoint

if stBerthJobInfo.iAlgoChoice == 7
    if stBerthJobInfo.stJssProbStructConfig.isCriticalOperateSeq == 1
        [container_sequence_jsp, jobshop_config] = psa_jsp_gen_job_schedule_28(stJobListInfoAgent);
    else
        [container_sequence_jsp, jobshop_config] = fsp_bidir_multi_m_t_ch_seq(stJobListInfoAgent);
    end
else
%     if stBerthJobInfo.stJssProbStructConfig.isCriticalOperateSeq == 1
%         [stContainerDischargeJobSequence, container_jsp_discha_schedule, stContainerLoadJobSequence, container_jsp_load_schedule, container_sequence_jsp] = ...
%             psa_jsp_gen_sch3_multiperiod(stJobListInfoAgent);
%     else
        [container_sequence_jsp] = ...
            fsp_bd_multi_m_t_greedy_seq(stJobListInfoAgent);
%     end
end
    tMakeSpan_hour = container_sequence_jsp.iMaxEndTime * stInput.fFactorHourPerSlot;

%%% adjusting price vector length, 
%%% and calculate ResourceCost = fCostPMYC
iTotalPeriod_act = ceil(tMakeSpan_hour);
iPriceHourIndex = stInput.iPriceHourStartIndex;
fCostPMYC = 0;
for tt = 1:1:iTotalPeriod_act
    if tt > stInput.iTotalPeriod
        kUsagePM = stJobListInfoAgent.stResourceConfig.stMachineConfig(2).afMaCapAtTimePoint(stInput.iTotalPeriod);
        kUsageYC = stJobListInfoAgent.stResourceConfig.stMachineConfig(3).afMaCapAtTimePoint(stInput.iTotalPeriod);
    else
        kUsagePM = stJobListInfoAgent.stResourceConfig.stMachineConfig(2).afMaCapAtTimePoint(tt);
        kUsageYC = stJobListInfoAgent.stResourceConfig.stMachineConfig(3).afMaCapAtTimePoint(tt);
    end
    fCostPMYC = fCostPMYC + stInput.stBerthJobInfo.astResourceInitPrice(2).afMachinePriceListPerFrame(iPriceHourIndex) * kUsagePM + ...
        stInput.stBerthJobInfo.astResourceInitPrice(3).afMachinePriceListPerFrame(iPriceHourIndex) * kUsageYC;
    if iPriceHourIndex == 24
        iPriceHourIndex = 0;
    end
    iPriceHourIndex = iPriceHourIndex + 1;
end

    stOutput.stContainerSchedule = container_sequence_jsp;
    stOutput.fCostPMYC = fCostPMYC;
    stOutput.tMakeSpan_hour = tMakeSpan_hour;
