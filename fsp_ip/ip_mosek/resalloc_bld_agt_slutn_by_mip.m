function [stAgent_Solution] = resalloc_bld_agt_slutn_by_mip(stSolutionInfo, stSystemMasterConfig)

iXip = stSolutionInfo.stMipSolution.xip;
fsp_resalloc_formulation = stSolutionInfo.fsp_resalloc_formulation;
astAgentFormulateInfo = stSolutionInfo.astAgentFormulateInfo;
stResAllocSystemJspCfg         = stSolutionInfo.stResAllocSystemJspCfg;

tSlotInPeriod = round(60/stResAllocSystemJspCfg.tMinmumTimeUnit_Min);

for ii = 1:1:stSystemMasterConfig.iTotalAgent
    stResAllocSystemJspCfg.stJspConfigList(ii).iTotalTimeSlot = stResAllocSystemJspCfg.iTotalTimeSlot;
    x_ip_ii = iXip(astAgentFormulateInfo(ii).iStartIndexJobVariable(1):(astAgentFormulateInfo(ii).stMachineUsageVariable(1).iVarableStartIndex - 1));
    [stContainerPartialSchedule_ii] = jsp_bld_solution_by_x_02(x_ip_ii, stResAllocSystemJspCfg.stJspConfigList(ii));
% Debugging
%jsp_plot_jobsolution_2(stContainerPartialSchedule_ii, ii);
%end
    [astMachineUsageTimeInfo] = jsp_build_machine_usage_con_tm(stContainerPartialSchedule_ii);
    for kk = 1:1:stResAllocSystemJspCfg.iTotalMachineTypeAtSystem
        stContainerPartialSchedule_ii.iTotalMachineNum(kk) = astMachineUsageTimeInfo(kk).iMaxUsage;
    end

    %%% Temperaily for dispatching
    stResourceConfig_ii = stResAllocSystemJspCfg.stJspConfigList(ii).stResourceConfig;
    for kk = 1:1:stResAllocSystemJspCfg.iTotalMachineTypeAtSystem
        astMachineBiddingPerAgent(ii).astMachineUsage(kk).aUsageAtFrame = iXip(astAgentFormulateInfo(ii).stMachineUsageVariable(kk).iVarableStartIndex: ...
            astAgentFormulateInfo(ii).stMachineUsageVariable(kk).iVarableEndIndex);
        if kk == stSystemMasterConfig.iCriticalMachType
            stResourceConfig_ii.stMachineConfig(kk).iNumPointTimeCap = 1;
        else
            stResourceConfig_ii.stMachineConfig(kk).iNumPointTimeCap = stResAllocSystemJspCfg.iTotalTimeFrame;
        end
    end
    
    for kk = 1:1:stResAllocSystemJspCfg.iTotalMachineTypeAtSystem
        if kk == stSystemMasterConfig.iCriticalMachType
            stResourceConfig_ii.stMachineConfig(kk).afMaCapAtTimePoint = 1;
            stResourceConfig_ii.stMachineConfig(kk).afTimePointAtCap = 0;
        else
            for pp = 1:1:stResAllocSystemJspCfg.iTotalTimeFrame
                stResourceConfig_ii.stMachineConfig(kk).afMaCapAtTimePoint(pp) = astMachineBiddingPerAgent(ii).astMachineUsage(kk).aUsageAtFrame(pp);
                stResourceConfig_ii.stMachineConfig(kk).afTimePointAtCap(pp) = tSlotInPeriod * (pp -1);
            end
        end
    end

    stContainerPartialSchedule_ii.stResourceConfig = stResourceConfig_ii;
    
    [container_jsp_schedule, stSpecificMachineTimeInfo] = psa_jsp_dispatch_machine_02(stContainerPartialSchedule_ii);
    container_jsp_schedule.iTotalMachineNum
%    figure_id = ii;
%    psa_jsp_plot_jobsolution(container_jsp_schedule, figure_id);
%    title('Job Sequence Generation, Y-Group is Machine');
    stCostAtAgent(ii).stSolutionMinCost.stSchedule = container_jsp_schedule;
    
end


for kk = 1:1:stResAllocSystemJspCfg.iTotalMachineTypeAtSystem
    astMachineGlobalUsage(kk).aUsageAtFrame = zeros(1, stResAllocSystemJspCfg.iTotalTimeFrame);
    for qq = 1:1:stSystemMasterConfig.iTotalAgent
        astMachineGlobalUsage(kk).aUsageAtFrame = astMachineGlobalUsage(kk).aUsageAtFrame + astMachineBiddingPerAgent(qq).astMachineUsage(kk).aUsageAtFrame';
    end
end

figure(10);
for kk = 1:1:stResAllocSystemJspCfg.iTotalMachineTypeAtSystem
    subplot(stResAllocSystemJspCfg.iTotalMachineTypeAtSystem,1,kk);
    axis([-1, stResAllocSystemJspCfg.iTotalTimeFrame+1, 0, max(astMachineGlobalUsage(kk).aUsageAtFrame)+1])
    hold on;
    grid on;
    for pp = 1:1:stResAllocSystemJspCfg.iTotalTimeFrame
        if pp == 1
            plot([pp-1, pp], [astMachineGlobalUsage(kk).aUsageAtFrame(pp), astMachineGlobalUsage(kk).aUsageAtFrame(pp)]);
        else
            plot([pp-1, pp-1], [astMachineGlobalUsage(kk).aUsageAtFrame(pp-1), astMachineGlobalUsage(kk).aUsageAtFrame(pp)]);
            plot([pp-1, pp], [astMachineGlobalUsage(kk).aUsageAtFrame(pp), astMachineGlobalUsage(kk).aUsageAtFrame(pp)]);
        end
    end
end

for ii = 1:1:stSystemMasterConfig.iTotalAgent
    stCostAtAgent(ii).tSolutionTime_sec = stSolutionInfo.tSolutionTime_sec/stSystemMasterConfig.iTotalAgent;
    stAgent_Solution(ii).stCostAtAgent = stCostAtAgent(ii);
    stAgent_Solution(ii).stSchedule_MinCost = stCostAtAgent(ii).stSolutionMinCost.stSchedule;
end
