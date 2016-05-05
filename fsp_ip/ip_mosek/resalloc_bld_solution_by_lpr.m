function [stAgent_Solution] = resalloc_bld_solution_by_lpr(stSolverSolutionInfo, stInputResAlloc)
%
% Build solution by linear programming relaxation solution
%
iXip = stSolverSolutionInfo.stMipSolution.xip;
fsp_resalloc_formulation = stSolverSolutionInfo.fsp_resalloc_formulation;
astAgentFormulateInfo = stSolverSolutionInfo.astAgentFormulateInfo;
stResAllocSystemJspCfg   = stSolverSolutionInfo.stResAllocSystemJspCfg;
stJobListInfoAgentJspCfg       = stInputResAlloc.astAgentJobListJspCfg;
stResAllocGenJspAgent    = stInputResAlloc.stResAllocGenJspAgent;
astAgentMachineHourInfo  = stInputResAlloc.astAgentMachineHourInfo;
astAgentJobListBiFspCfg  = stInputResAlloc.astAgentJobListBiFspCfg;
% astAgentJobListJspCfg    = stInputResAlloc.astAgentJobListJspCfg;

stSystemMasterConfig     = stResAllocGenJspAgent.stSystemMasterConfig;
iPlotFlag = stSystemMasterConfig.iPlotFlag;

nTotalMachType = stSystemMasterConfig.iTotalMachType;
nTotalAgent = stSystemMasterConfig.iTotalAgent;
tSlotInPeriod = round(60/stResAllocSystemJspCfg.tMinmumTimeUnit_Min);

for kk = 1:1:nTotalMachType
    astMachineGlobalUsage(kk).aUsageAtFrame = zeros(1, stResAllocSystemJspCfg.iTotalTimeFrame);
end

%%% calculate the normalized agent work load weight
afMaxWorkHourPerMachine = zeros(1, nTotalMachType);
for qq = 1:1:nTotalAgent
    for mm = 1:1:nTotalMachType
        if afMaxWorkHourPerMachine(mm) < astAgentMachineHourInfo(qq).afTotalWorkHourPerMachine(mm)
            afMaxWorkHourPerMachine(mm) = astAgentMachineHourInfo(qq).afTotalWorkHourPerMachine(mm);
        end
    end
end
for qq = 1:1:nTotalAgent
    for mm = 1:1:nTotalMachType
        astAgentMachineLoad(qq).afNormalMachHourWeight(mm) = astAgentMachineHourInfo(qq).afTotalWorkHourPerMachine(mm) / afMaxWorkHourPerMachine(mm);
    end
end

%%% calculate the priority of each agents, and find the agent with smallest priority
fMinGeneralPriority = inf;
idxMinGeneralPriority = 1;
for qq = 1:1:nTotalAgent
    iTimeFrameStartJobListPerAgent(qq) = round((stResAllocGenJspAgent.stAgentJobInfo(qq).tTimeAgentJobStart.aTimeIn24HourFormat(1) + 1)/ stSystemMasterConfig.fTimeFrameUnitInHour);
    iTimeFrameDueTimePerAgent(qq) = round((stResAllocGenJspAgent.stAgentJobInfo(qq).tTimeAgentJobDue.aTimeIn24HourFormat(1) + 1)/stSystemMasterConfig.fTimeFrameUnitInHour);
    tStartTimePerAgent_datenum(qq) = datenum(stResAllocGenJspAgent.stAgentJobInfo(qq).atClockAgentJobStart.aClockYearMonthDateHourMinSec);
    fTimeSlot_inMin(qq) = stJobListInfoAgentJspCfg(qq).fTimeUnit_Min;
    tCompleteTimePerAgent_datenum(qq) = ...
        tStartTimePerAgent_datenum(qq) + datenum(stResAllocSystemJspCfg.iTotalTimeFrame * stSystemMasterConfig.fTimeFrameUnitInHour /24);
    iCompleteTimeFramePerAgent(qq) = ceil((tCompleteTimePerAgent_datenum(qq) - floor(tCompleteTimePerAgent_datenum(qq)))*24 /stSystemMasterConfig.fTimeFrameUnitInHour);
    fPriceWeightPerAgent(qq) = stResAllocGenJspAgent.stAgentJobInfo(qq).fPriceAgentDollarPerFrame + ...
                                            (stResAllocGenJspAgent.stAgentJobInfo(qq).fLatePenalty_DollarPerFrame * ...
                                             max(iCompleteTimeFramePerAgent(qq) - iTimeFrameDueTimePerAgent(qq), 0));
%     fGeneralPriorityPerAgent(qq) = fPriceWeightPerAgent(qq) * exp(afNormalPrimeMoverLoadWeight(qq) + afNormalYardCraneLoadWeight(qq));
    fGeneralPriorityPerAgent(qq) = fPriceWeightPerAgent(qq) * exp( sum(astAgentMachineLoad(qq).afNormalMachHourWeight) );
    
    if fMinGeneralPriority > fGeneralPriorityPerAgent(qq)
        fMinGeneralPriority = fGeneralPriorityPerAgent(qq);
        idxMinGeneralPriority = qq;
    end
end
%%%[fMinGeneralPriority, idxMinGeneralPriority] = min(fGeneralPriorityPerAgent);
fGeneralPriorityPerAgent
idxMinGeneralPriority
[fSortedPriority, aiAgentIdIncreasingPrio] = sort(fGeneralPriorityPerAgent); %% higher value, higher priority

%%%%%  get the machine usage from the linear relexation solution, first
%%%%%  allocation
nTotalPeriodPerAgent = zeros(1, nTotalAgent);
iFlagReAllocation = 0;
for ii = 1:1:nTotalAgent
    idxAgent = aiAgentIdIncreasingPrio(nTotalAgent + 1 - ii); %% higher priority first
    for kk = 1:1:nTotalMachType
        iVarableStartIndex = astAgentFormulateInfo(idxAgent).stMachineUsageVariable(kk).iVarableStartIndex;
        iVarableEndIndex   = astAgentFormulateInfo(idxAgent).stMachineUsageVariable(kk).iVarableEndIndex;
        nTotalPeriodPerAgent(ii) = iVarableEndIndex - iVarableStartIndex + 1; %% all
        astMachineBiddingPerAgent(idxAgent).astMachineUsage(kk).aUsageAtFrame = zeros(nTotalPeriodPerAgent(ii), 1);
        %% first half agents, with highest priority
        if ii <= round(nTotalAgent/2)
            astMachineBiddingPerAgent(idxAgent).astMachineUsage(kk).aUsageAtFrame = ceil(iXip(iVarableStartIndex:  iVarableEndIndex));
        %% following half agents, with middle priority (except the agent with lowest priority)
        elseif ii < nTotalAgent  % round
%             for tt = iVarableStartIndex:1:iVarableEndIndex
%                 idxFrame = tt +1 - iVarableStartIndex;
%                 if bitand(ii + tt, 1) == 1
%                     astMachineBiddingPerAgent(idxAgent).astMachineUsage(kk).aUsageAtFrame(idxFrame)= ceil(iXip(tt));
%                 else
%                     astMachineBiddingPerAgent(idxAgent).astMachineUsage(kk).aUsageAtFrame(idxFrame)= round(iXip(tt));
%                 end
%             end
            astMachineBiddingPerAgent(idxAgent).astMachineUsage(kk).aUsageAtFrame = ceil(iXip(iVarableStartIndex: iVarableEndIndex));
        else % only for the lowest priority agent
            if idxAgent ~= idxMinGeneralPriority
                error('Check Priority ranking');
            end
            for tt = 1:1:nTotalPeriodPerAgent(ii)
                astMachineBiddingPerAgent(idxAgent).astMachineUsage(kk).aUsageAtFrame(tt) = ...
                            stResAllocSystemJspCfg.astMachineCapAtPeriod(tt).aiMaxMachineCapacity(kk) - astMachineGlobalUsage(kk).aUsageAtFrame(tt);
                        
                if astMachineBiddingPerAgent(idxAgent).astMachineUsage(kk).aUsageAtFrame(tt) <= 0
                    disp('negative or zero allocation happens!!! , reallocate from 2nd lowest priority agent');
                    if tt == 1
                        astMachineBiddingPerAgent(idxAgent).astMachineUsage(kk).aUsageAtFrame(tt) = 1;
                    else
                        astMachineBiddingPerAgent(idxAgent).astMachineUsage(kk).aUsageAtFrame(tt) = ...
                            astMachineBiddingPerAgent(idxAgent).astMachineUsage(kk).aUsageAtFrame(tt - 1);
                    end
                    iFlagReAllocation = 1;
                end
            end
            if iPlotFlag >= 2
                Machine_k_usage_AtPeriod_agent_min_priority = astMachineBiddingPerAgent(idxAgent).astMachineUsage(kk).aUsageAtFrame'
            end
        end
        astMachineGlobalUsage(kk).aUsageAtFrame = astMachineGlobalUsage(kk).aUsageAtFrame + ...
                astMachineBiddingPerAgent(idxAgent).astMachineUsage(kk).aUsageAtFrame';

    end
end
nTotalPeriod = max(nTotalPeriodPerAgent);
if nTotalPeriod ~= min(nTotalPeriodPerAgent)
    disp('Total Number of Periods different from agents')
end
%% ReAllocation if needed
nMaxIterResolveConflict = 50;
iIter = 0;
while iFlagReAllocation == 1
    fSumInversePriority = 0; %% Inverse Priority, lower value, higher priority
    fDeductFactorAgent = zeros(1, nTotalAgent);
    fInversePriorityPerAgent = zeros(1, nTotalAgent);
    nTotalViolation = zeros(nTotalMachType, nTotalPeriod);
    for ii = 1:1:nTotalAgent - 1
        idxAgent = aiAgentIdIncreasingPrio(nTotalAgent + 1 - ii); %% higher priority first
        fInversePriorityPerAgent(idxAgent) = 1/fGeneralPriorityPerAgent(idxAgent);
        fSumInversePriority = fSumInversePriority + fInversePriorityPerAgent(idxAgent);
    end
    for ii = 1:1:nTotalAgent - 1
        idxAgent = aiAgentIdIncreasingPrio(nTotalAgent + 1 - ii); %% higher priority first
        fDeductFactorAgent(idxAgent) = fInversePriorityPerAgent(idxAgent) / fSumInversePriority;
    end
    for kk = 1:1:nTotalMachType
        for tt = 1:1:nTotalPeriod
            if astMachineGlobalUsage(kk).aUsageAtFrame(tt) > stResAllocSystemJspCfg.astMachineCapAtPeriod(tt).aiMaxMachineCapacity(kk);
                nTotalViolation(kk, tt) = astMachineGlobalUsage(kk).aUsageAtFrame(tt) - stResAllocSystemJspCfg.astMachineCapAtPeriod(tt).aiMaxMachineCapacity(kk)
                if nTotalViolation(kk, tt) > 1
                    for ii = 1:1:nTotalAgent - 1
                        idxAgent = aiAgentIdIncreasingPrio(nTotalAgent + 1 - ii); %% higher priority first
                        nDeductPerAgent(idxAgent) = round(nTotalViolation(kk, tt) * fDeductFactorAgent(idxAgent))
                        if nDeductPerAgent(idxAgent) < astMachineBiddingPerAgent(idxAgent).astMachineUsage(kk).aUsageAtFrame(tt) & ...
                                nDeductPerAgent(idxAgent) >= 1 & nTotalViolation(kk, tt) >= 1
                            astMachineBiddingPerAgent(idxAgent).astMachineUsage(kk).aUsageAtFrame(tt) = ...
                                astMachineBiddingPerAgent(idxAgent).astMachineUsage(kk).aUsageAtFrame(tt) - nDeductPerAgent(idxAgent);
                            astMachineGlobalUsage(kk).aUsageAtFrame(tt) = astMachineGlobalUsage(kk).aUsageAtFrame(tt) - nDeductPerAgent(idxAgent);
                            nTotalViolation(kk, tt) = nTotalViolation(kk, tt) - nDeductPerAgent(idxAgent);
                        end
                    end
                else %% violation is 1
                    for ii = 1:1:nTotalAgent - 1
                        idxAgent = aiAgentIdIncreasingPrio(nTotalAgent + 1 - ii); %% higher priority first
                        if ii == 1
                            nMaxMachineUsage = astMachineBiddingPerAgent(idxAgent).astMachineUsage(kk).aUsageAtFrame(tt);
                            idxAgentWithMaxMach = idxAgent;
                        else
                            if nMaxMachineUsage <= astMachineBiddingPerAgent(idxAgent).astMachineUsage(kk).aUsageAtFrame(tt)
                                nMaxMachineUsage = astMachineBiddingPerAgent(idxAgent).astMachineUsage(kk).aUsageAtFrame(tt);
                                idxAgentWithMaxMach = idxAgent;
                            end
                        end
                    end
                    nDeductPerAgent(idxAgentWithMaxMach) = nTotalViolation(kk, tt);
                    astMachineBiddingPerAgent(idxAgentWithMaxMach).astMachineUsage(kk).aUsageAtFrame(tt) = ...
                        astMachineBiddingPerAgent(idxAgentWithMaxMach).astMachineUsage(kk).aUsageAtFrame(tt) - nDeductPerAgent(idxAgentWithMaxMach);
                    astMachineGlobalUsage(kk).aUsageAtFrame(tt) = astMachineGlobalUsage(kk).aUsageAtFrame(tt) - nDeductPerAgent(idxAgentWithMaxMach);
                    
                end
            end
        end
    end
    iFlagReAllocation = 0;
    for kk = 1:1:nTotalMachType
        if max(nTotalViolation(kk, :)) >= 1 & iFlagReAllocation == 0
            iFlagReAllocation = 1;
        end
    end
    iIter = iIter + 1
    if iIter >= nMaxIterResolveConflict
        error('Too little resource, failure to allocate');
    end
end

%%%% Build the ResourceConfig Structure
for ii = 1:1:nTotalAgent
    %%% Template for resource bidding config
    stResourceConfig_ii = stResAllocSystemJspCfg.stJspConfigList(ii).stResourceConfig;
    for mm = 1:1:nTotalMachType
        if mm == stSystemMasterConfig.iCriticalMachType
            stResourceConfig_ii.stMachineConfig(mm).iNumPointTimeCap = 1;
        else
            stResourceConfig_ii.stMachineConfig(mm).iNumPointTimeCap = stResAllocSystemJspCfg.iTotalTimeFrame;
        end
    end
    
    for mm = 1:1:nTotalMachType
        if  mm == stSystemMasterConfig.iCriticalMachType
            stResourceConfig_ii.stMachineConfig(mm).afMaCapAtTimePoint = 1;
        else
            for pp = 1:1:nTotalPeriod
%                 if astMachineBiddingPerAgent(ii).astMachineUsage(mm).aUsageAtFrame(pp) <= 1 & pp >= 2
%                     stResourceConfig_ii.stMachineConfig(mm).afMaCapAtTimePoint(pp) = stResourceConfig_ii.stMachineConfig(mm).afMaCapAtTimePoint(pp - 1);
%                 else
                    stResourceConfig_ii.stMachineConfig(mm).afMaCapAtTimePoint(pp) = astMachineBiddingPerAgent(ii).astMachineUsage(mm).aUsageAtFrame(pp);
%                 end
                stResourceConfig_ii.stMachineConfig(mm).afTimePointAtCap(pp) = tSlotInPeriod * (pp -1);

            end
        end
    end
    astAgentResourceConfig_LPR(ii) = stResourceConfig_ii;
    if iPlotFlag >= 1
%         Mach4UsageByAgent_ii = stResourceConfig_ii.stMachineConfig(4).afMaCapAtTimePoint
    end
end

%% check whether there is any violation
nTotalCaseViolation = 0;
for kk = 1:1:nTotalMachType
    for tt = 1:1:stResAllocSystemJspCfg.iTotalTimeFrame
        if astMachineGlobalUsage(kk).aUsageAtFrame(tt) > stResAllocSystemJspCfg.astMachineCapAtPeriod(tt).aiMaxMachineCapacity(kk)
            nTotalCaseViolation = nTotalCaseViolation + 1;
            astCaseViolation(nTotalCaseViolation).iTimeFrameWithViolation = tt + floor((stResAllocSystemJspCfg.tEarlistStartTime_datenum - floor(stResAllocSystemJspCfg.tEarlistStartTime_datenum)) * 24);
            astCaseViolation(nTotalCaseViolation).iMachineResourceViolation = kk;
            astCaseViolation(nTotalCaseViolation).nTotalViolation = astMachineGlobalUsage(kk).aUsageAtFrame(tt) - stResAllocSystemJspCfg.astMachineCapAtPeriod(tt).aiMaxMachineCapacity(kk);
        end
    end
    if iPlotFlag >= 1
        res_k_before_resolving_conflict = astMachineGlobalUsage(kk).aUsageAtFrame
    end
end

if nTotalCaseViolation > 0
    nTotalCaseViolation
%    [astAgentResourceConfig] = psa_resalloc_by_priority(stSystemMasterConfig, astCaseViolation, nTotalCaseViolation, astAgentResourceConfig_LPR, stResAllocSystemJspCfg.iTotalTimeFrame);
%    [stAgent_Solution, stDebugOutputSolveByPriority] = psa_resalloc_solve_by_priority(stBerthJobInfo, stAgent_Solution, stJobListInfoAgentJspCfg);
%            stConstraintVialationInfo.nTotalCaseViolation = stDebugOutputSolveByPriority.nTotalCaseViolation;
%            stConstraintVialationInfo.astCaseViolation    = stDebugOutputSolveByPriority.astCaseViolation;
%      aPosnNameDot = strfind(stResAllocGenJspAgent.strInputFilename, '.');
%      if length(aPosnNameDot) == 0
%          strCmd_SaveMatFileResvConflt = sprintf('save %s_resolve_conflt.mat stResAllocGenJspAgent stAgent_Solution stJobListInfoAgentJspCfg', stResAllocGenJspAgent.strInputFilename)
%      else
%          strCmd_SaveMatFileResvConflt = sprintf('save %s_resolve_conflt.mat stResAllocGenJspAgent stAgent_Solution stJobListInfoAgentJspCfg', ...
%              stResAllocGenJspAgent.strInputFilename(1:(aPosnNameDot(end)-1)));
%      end
%      eval(strCmd_SaveMatFileResvConflt);
%     stResAllocGenJspAgent.fTimeFrameUnitInHour = stSystemMasterConfig.fTimeFrameUnitInHour;
%     stResAllocGenJspAgent.iTotalAgent = nTotalAgent;
%     stResAllocGenJspAgent.iPlotFlag = stSystemMasterConfig.iPlotFlag;
%     stResAllocGenJspAgent.tPlanningWindow_Hours = stSystemMasterConfig.tPlanningWindow_Hours;
%     stResAllocGenJspAgent.iTotalMachType = nTotalMachType;
%     [stAgent_Solution, stDebugOutputSolveByPriority] = psa_resalloc_solve_by_priority(stResAllocGenJspAgent, stAgent_Solution, stJobListInfoAgentJspCfg);
%     for ii = 1:1:nTotalAgent
%         astAgentResourceConfig(ii) = stAgent_Solution(ii).stSchedule_MinCost.stResourceConfig;
%     end
    error('There is still violation of feasibility');
else
    astAgentResourceConfig = astAgentResourceConfig_LPR;
end
% to be replaced by cofigure input
% iOptRuleSchedule = 8;

for ii = 1:1:nTotalAgent
    stJobListInfoAgentJspCfg(ii).stResourceConfig = astAgentResourceConfig(ii);
    stJobListInfoAgentJspCfg(ii).iSlotStartTime = floor((datenum(stResAllocSystemJspCfg.stJspConfigList(ii).atClockJobStart.aClockYearMonthDateHourMinSec) - stResAllocSystemJspCfg.tEarlistStartTime_datenum)*24*60 ...
        /stResAllocSystemJspCfg.tMinmumTimeUnit_Min + stResAllocSystemJspCfg.stJspConfigList(ii).iTimeStartFirstJobFirstProcess);

    % to be replaced by setted sequence.
    iJobSeqInJspCfg = stJobListInfoAgentJspCfg(ii).aiJobSeqInJspCfg
    iOptRuleSchedule = stJobListInfoAgentJspCfg(ii).iOptRule; % astAgentJobListBiFspCfg(ii).stAgentBiFSPJobMachConfig.iOptRule;
%    iOptRuleSchedule = stJobListInfoAgentJspCfg(ii)
    if iOptRuleSchedule == 2
        [stFspSchedule] = jsp_constr_sche_struct_by_cfg(stJobListInfoAgentJspCfg(ii));
    %% Greedy  
        [stContainerPartialSchedule_ii] = fsp_bd_multi_m_t_greedy_by_seq(stFspSchedule, stJobListInfoAgentJspCfg(ii), iJobSeqInJspCfg);
    else %% CH
        astAgentJobListBiFspCfg(ii).stResourceConfig = astAgentResourceConfig(ii);
        astAgentJobListBiFspCfg(ii).iSlotStartTime   = stJobListInfoAgentJspCfg(ii).iSlotStartTime;  %% volatile
        [stContainerPartialSchedule_ii] = fsp_gen_job_sche_ch_seq_(astAgentJobListBiFspCfg(ii), iJobSeqInJspCfg);
%         stJobListInfoAgentJspCfg(ii).stResourceConfig = astAgentResourceConfig(ii);
%         stJobListInfoAgentJspCfg(ii).iSlotStartTime   = stJobListInfoAgentJspCfg(ii).iSlotStartTime;  %% volatile
%         [stContainerPartialSchedule_ii] = fsp_gen_job_sche_ch_seq_(stJobListInfoAgentJspCfg(ii), iJobSeqInJspCfg);
    end    
%     ResourceCfg_Machine2 = stJobListInfoAgentJspCfg(ii).stResourceConfig.stMachineConfig(2).afMaCapAtTimePoint;
%     ResourceCfg_Machine3 = stJobListInfoAgentJspCfg(ii).stResourceConfig.stMachineConfig(3).afMaCapAtTimePoint;
%     tStartTime = stJobListInfoAgentJspCfg(ii).iSlotStartTime;
%     stContainerPartialSchedule_ii.iMaxEndTime;

    stContainerPartialSchedule_ii.stResourceConfig = astAgentResourceConfig(ii);
    
    [container_jsp_schedule, stSpecificMachineTimeInfo] = psa_jsp_dispatch_machine_02(stContainerPartialSchedule_ii);
    stCostAtAgent(ii).stSolutionMinCost.stSchedule = container_jsp_schedule;
    
    if iPlotFlag >= 5
        figure_id = ii;
        psa_jsp_plot_jobsolution(container_jsp_schedule, figure_id);
        title('Job Sequence Generation, Y-Group is Machine');
    elseif iPlotFlag >= 5
%         aiLocationPathChar = strfind(astAgentJobListBiFspCfg(ii).strJobListInputFilename, '\');
%         strFileNamePrefix = sprintf('%sAgent%d_', astAgentJobListBiFspCfg(ii).strJobListInputFilename(1:aiLocationPathChar(end)), ii);
%         [strFileName] = fsp_save_joblist(astAgentJobListBiFspCfg(ii),strFileNamePrefix);
%         strDisp = sprintf('Save BiFSP, Agent-%d, Joblist: %s', ii, strFileName);
        aiLocationPathChar = strfind(stJobListInfoAgentJspCfg(ii).strJobListInputFilename, '\');
        strFileNamePrefix = sprintf('%sAgent%d_', stJobListInfoAgentJspCfg(ii).strJobListInputFilename(1:aiLocationPathChar(end)), ii);
        [strFileName] = fsp_save_joblist(stJobListInfoAgentJspCfg(ii),strFileNamePrefix);
        strDisp = sprintf('Save BiFSP, Agent-%d, Joblist: %s', ii, strFileName);
        strDisp
    end
    
    
end

if iPlotFlag >= 5
    figure(10);
    for kk = 1:1:nTotalMachType
        subplot(nTotalMachType,1,kk);
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
end

for ii = 1:1:nTotalAgent
    stCostAtAgent(ii).tSolutionTime_sec = stSolverSolutionInfo.tSolutionTime_sec/nTotalAgent;
    stAgent_Solution(ii).stCostAtAgent = stCostAtAgent(ii);
    stAgent_Solution(ii).stSchedule_MinCost = stCostAtAgent(ii).stSolutionMinCost.stSchedule;
end
