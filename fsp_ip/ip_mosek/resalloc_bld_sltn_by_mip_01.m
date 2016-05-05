function [stAgent_Solution] = resalloc_bld_sltn_by_mip_01(stSolutionInfo, stSystemMasterConfig)
% resource allocation build solution by Mixed Integer Problem ver 01
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%  
%
%The MIT License (MIT)
%
%Copyright (c) 2016 ZHAOZhengyi-tgx
%
%Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the "Software"), to deal in the Software without restriction, including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions:
%
%The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.
%
%THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%
% Module: Solution for Resource Allocation among Scheduling Agents 
% Template for Problem Input
% OUTPUT from the solver: schedule for each job's process, dispatching for each machine
% During this whole document, % is for line commenting, which means any line starting with a % will not be taken into parsing.
%
% all right reserved (c)2016
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% all right reserved, @2016, Sg.LongRenE@gmail.com

iXip = stSolutionInfo.stMipSolution.xip;
fsp_resalloc_formulation = stSolutionInfo.fsp_resalloc_formulation;
astAgentFormulateInfo = stSolutionInfo.astAgentFormulateInfo;
stResAllocSystemJspCfg         = stSolutionInfo.stResAllocSystemJspCfg;

tSlotInPeriod = round(60/stResAllocSystemJspCfg.tMinmumTimeUnit_Min);

for ii = 1:1:stSystemMasterConfig.iTotalAgent
    stResAllocSystemJspCfg.stJspConfigList(ii).iTotalTimeSlot = stSolutionInfo.stResAllocSystemJspCfg.iTotalTimeSlot;
    x_ip_ii = iXip(astAgentFormulateInfo(ii).iStartIndexJobVariable(1):(astAgentFormulateInfo(ii).stMachineUsageVariable(1).iVarableStartIndex - 1));
    [stAgentPartialSchedule_ii] = jsp_bld_solution_by_x_02(x_ip_ii, stResAllocSystemJspCfg.stJspConfigList(ii));
% Debugging
%jsp_plot_jobsolution_2(stAgentPartialSchedule_ii, ii);
%end
    [astMachineUsageTimeInfo] = jsp_build_machine_usage_con_tm(stAgentPartialSchedule_ii);
%    stAgentPartialSchedule_ii.iTotalMachineNum = [1, astMachineUsageTimeInfo(2).iMaxUsage, astMachineUsageTimeInfo(3).iMaxUsage];
    
    %%% Temperaily for dispatching
    stResourceConfig_ii = stResAllocSystemJspCfg.stJspConfigList(ii).stResourceConfig;
    for kk = 1:1:stSystemMasterConfig.iTotalMachType
        astMachineBiddingPerAgent(ii).astMachineUsage(kk).aUsageAtFrame = iXip(astAgentFormulateInfo(ii).stMachineUsageVariable(kk).iVarableStartIndex: ...
            astAgentFormulateInfo(ii).stMachineUsageVariable(kk).iVarableEndIndex);
        if kk == stSystemMasterConfig.iCriticalMachType
            stResourceConfig_ii.stMachineConfig(kk).iNumPointTimeCap = 1;
        else
            stResourceConfig_ii.stMachineConfig(kk).iNumPointTimeCap = stResAllocSystemJspCfg.iTotalTimeFrame;
        end
    end
    
    for kk = 1:1:stSystemMasterConfig.iTotalMachType
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

    stAgentPartialSchedule_ii.stResourceConfig = stResourceConfig_ii;
    
    [Agent_jsp_schedule, stSpecificMachineTimeInfo] = psa_jsp_dispatch_machine_02(stAgentPartialSchedule_ii);
    
%    figure_id = ii;
%    psa_jsp_plot_jobsolution(Agent_jsp_schedule, figure_id);
%    title('Job Sequence Generation, Y-Group is Machine');
    stCostAtAgent(ii).stSolutionMinCost.stSchedule = Agent_jsp_schedule;
    
end


for kk = 1:1:stSystemMasterConfig.iTotalMachType
    astMachineGlobalUsage(kk).aUsageAtFrame = zeros(1, stResAllocSystemJspCfg.iTotalTimeFrame);
    for qq = 1:1:stSystemMasterConfig.iTotalAgent
        astMachineGlobalUsage(kk).aUsageAtFrame = astMachineGlobalUsage(kk).aUsageAtFrame + astMachineBiddingPerAgent(qq).astMachineUsage(kk).aUsageAtFrame';
    end
end

figure(10);
for kk = 1:1:stSystemMasterConfig.iTotalMachType
    subplot(stSystemMasterConfig.iTotalMachType,1,kk);
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
