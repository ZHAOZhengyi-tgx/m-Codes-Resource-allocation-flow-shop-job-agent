function [stAgent_Solution] = psa_bld_solution_by_berth_mip(stSolutionInfo, stBerthJobInfo)

iXip = stSolutionInfo.stMipSolution.xip;
fsp_resalloc_formulation = stSolutionInfo.fsp_resalloc_formulation;
stQuayCraneFormulateInfo = stSolutionInfo.stQuayCraneFormulateInfo;
stBerthJspConfig         = stSolutionInfo.stBerthJspConfig;

tSlotInPeriod = round(60/stBerthJspConfig.tMinmumTimeUnit_Min);

for ii = 1:1:stBerthJobInfo.iTotalAgent
    stBerthJspConfig.stJspConfigList(ii).iTotalTimeSlot = stSolutionInfo.stBerthJspConfig.iTotalTimeSlot;
    x_ip_ii = iXip(stQuayCraneFormulateInfo(ii).iStartIndexJobVariable(1):(stQuayCraneFormulateInfo(ii).stMachineUsageVariable(1).iVarableStartIndex - 1));
    [stContainerPartialSchedule_ii] = jsp_bld_solution_by_x_02(x_ip_ii, stBerthJspConfig.stJspConfigList(ii));
% Debugging
%jsp_plot_jobsolution_2(stContainerPartialSchedule_ii, ii);
%end
    [astMachineUsageTimeInfo] = jsp_build_machine_usage_con_tm(stContainerPartialSchedule_ii);
    stContainerPartialSchedule_ii.iTotalMachineNum = [1, astMachineUsageTimeInfo(2).iMaxUsage, astMachineUsageTimeInfo(3).iMaxUsage];
    
    %%% Temperaily for dispatching
    stResourceConfig_ii = stBerthJspConfig.stJspConfigList(ii).stResourceConfig;
    for kk = 1:1:stBerthJspConfig.iTotalMachineTypeAtBerth
        astMachineBiddingPerAgent(ii).astMachineUsage(kk).aUsageAtFrame = iXip(stQuayCraneFormulateInfo(ii).stMachineUsageVariable(kk).iVarableStartIndex: ...
            stQuayCraneFormulateInfo(ii).stMachineUsageVariable(kk).iVarableEndIndex);
    end
    stResourceConfig_ii.stMachineConfig(2).iNumPointTimeCap = stBerthJspConfig.iTotalTimeFrame;
    stResourceConfig_ii.stMachineConfig(3).iNumPointTimeCap = stBerthJspConfig.iTotalTimeFrame;
    for pp = 1:1:stBerthJspConfig.iTotalTimeFrame
        stResourceConfig_ii.stMachineConfig(2).afMaCapAtTimePoint(pp) = astMachineBiddingPerAgent(ii).astMachineUsage(2).aUsageAtFrame(pp);
        stResourceConfig_ii.stMachineConfig(3).afMaCapAtTimePoint(pp) = astMachineBiddingPerAgent(ii).astMachineUsage(3).aUsageAtFrame(pp);
        stResourceConfig_ii.stMachineConfig(2).afTimePointAtCap(pp) = tSlotInPeriod * (pp -1);
        stResourceConfig_ii.stMachineConfig(3).afTimePointAtCap(pp) = tSlotInPeriod * (pp -1);
    end

    stContainerPartialSchedule_ii.stResourceConfig = stResourceConfig_ii;
    
    [container_jsp_schedule, stSpecificMachineTimeInfo] = psa_jsp_dispatch_machine_02(stContainerPartialSchedule_ii);
    
%    figure_id = ii;
%    psa_jsp_plot_jobsolution(container_jsp_schedule, figure_id);
%    title('Job Sequence Generation, Y-Group is Machine');
    stCostAtAgent(ii).stSolutionMinCost.stSchedule = container_jsp_schedule;
    
end


for kk = 1:1:stBerthJspConfig.iTotalMachineTypeAtBerth
    astMachineGlobalUsage(kk).aUsageAtFrame = zeros(1, stBerthJspConfig.iTotalTimeFrame);
    for qq = 1:1:stBerthJobInfo.iTotalAgent
        astMachineGlobalUsage(kk).aUsageAtFrame = astMachineGlobalUsage(kk).aUsageAtFrame + astMachineBiddingPerAgent(qq).astMachineUsage(kk).aUsageAtFrame';
    end
end

figure(10);
for kk = 1:1:stBerthJspConfig.iTotalMachineTypeAtBerth
    subplot(stBerthJspConfig.iTotalMachineTypeAtBerth,1,kk);
    axis([-1, stBerthJspConfig.iTotalTimeFrame+1, 0, max(astMachineGlobalUsage(kk).aUsageAtFrame)+1])
    hold on;
    grid on;
    for pp = 1:1:stBerthJspConfig.iTotalTimeFrame
        if pp == 1
            plot([pp-1, pp], [astMachineGlobalUsage(kk).aUsageAtFrame(pp), astMachineGlobalUsage(kk).aUsageAtFrame(pp)]);
        else
            plot([pp-1, pp-1], [astMachineGlobalUsage(kk).aUsageAtFrame(pp-1), astMachineGlobalUsage(kk).aUsageAtFrame(pp)]);
            plot([pp-1, pp], [astMachineGlobalUsage(kk).aUsageAtFrame(pp), astMachineGlobalUsage(kk).aUsageAtFrame(pp)]);
        end
    end
end

for ii = 1:1:stBerthJobInfo.iTotalAgent
    stCostAtAgent(ii).tSolutionTime_sec = stSolutionInfo.tSolutionTime_sec/stBerthJobInfo.iTotalAgent;
    stAgent_Solution(ii).stCostAtAgent = stCostAtAgent(ii);
    stAgent_Solution(ii).stSchedule_MinCost = stCostAtAgent(ii).stSolutionMinCost.stSchedule;
end
