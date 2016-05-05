function [stAgent_Solution, stDebugOutput] = psa_resalloc_solve_by_priority(stBerthJobInfo, stAgent_Solution, stJobListInfoAgent)
%function [stAgent_Solution] = psa_resalloc_solve_by_priority(stBerthJobInfo, stAgent_Solution, stJobListInfoAgent)
% Manually adjust to resolve confliction if there is any resource usage confliction in Consolidated Agent Solution
% prototype
% [stAgent_Solution, stDebugOutput] =
% psa_resalloc_solve_by_priority(stBerthJobInfo, stAgent_Solution,
% stJobListInfoAgent)
% 
% Input: 
%  stBerthJobInfo
%  stAgent_Solution
%  stJobListInfoAgent
% Output:
%  stDebugOutput
%
% 20080406 modify psa_gen_sch_perform_rpt_by_cfg

%% Build machine usage information for each Agent and for whole berth
[stMachineUsageInfoBerth, stMachineUsageInfoByAgent] = psa_bidgen_build_bid_by_cfg(stBerthJobInfo, stAgent_Solution);
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
fTimeDelta = 0.1;

%%% Compare total Demand and total supply, record constraint violation in
%%% nTotalCaseViolation,  astCaseViolation
nTotalCaseViolation = 0;
astCaseViolation = [];
iTotalFrame = ceil(24/stBerthJobInfo.fTimeFrameUnitInHour);
for mm = 1:1:stBerthJobInfo.stSystemMasterConfig.iTotalMachType
    if mm ~= stBerthJobInfo.stSystemMasterConfig.iCriticalMachType
    % get the resource usage from clock (tt-1):0:0 to (t + fTimeDelta):0:0
    % fTimeDelta is introduced to avoid numerical trouncation error.
        for tt = 1:1:iTotalFrame
    %        [fValueLookup, iIndex] = ...
    %            calc_table_look_up_max(stMachineUsageInfoBerth.astMachineUsage(mm).aMachineUsageAfterTime, stMachineUsageInfoBerth.astMachineUsage(mm).aSortedTime_inHour, tt-1, fTimeDelta);
            [fValueLookup, iIndex] = calc_lut_max_between(stMachineUsageInfoBerth.astMachineUsage(mm).aMachineUsageAfterTime, stMachineUsageInfoBerth.astMachineUsage(mm).aSortedTime_inHour, ...
                tt-1-fTimeDelta, tt-fTimeDelta);
    %  PriceAtHour_i: price at clock (i-1):0:0 to i:0:0
    %  UsageAtHour_i: usage at clock i:0:0 to (i+1):0:0
    %  CapacityAtHour_i: Capacity at clock i:0:0 to (i+1):0:0

            stMachinePriceInfo.astMachineUsage(mm).aUsageAtFrame(tt) = fValueLookup;
            stMachinePriceInfo.astMachineCapacity(mm).aCapacityAtFrame(tt) = stMachineUsageInfoBerth.astMachineUsage(mm).iMaxCapacity;
            stMachinePriceInfo.astMachineViolation(mm).aViolateAtFrame(tt) = stMachinePriceInfo.astMachineUsage(mm).aUsageAtFrame(tt) - stMachineUsageInfoBerth.astMachineUsage(mm).iMaxCapacity;
            if stMachinePriceInfo.astMachineViolation(mm).aViolateAtFrame(tt) > 0
                nTotalCaseViolation = nTotalCaseViolation + 1;
                astCaseViolation(nTotalCaseViolation).iTimeFrameWithViolation = tt;
                astCaseViolation(nTotalCaseViolation).iMachineResourceViolation = mm;
                astCaseViolation(nTotalCaseViolation).nTotalViolation = stMachinePriceInfo.astMachineViolation(mm).aViolateAtFrame(tt);
            end
        end
    end
end

for qq = 1:1:stBerthJobInfo.iTotalAgent
    stQuayCraneResourceConfig(qq) = stAgent_Solution(qq).stMinCostResourceConfig;
end
stResourceConfigInfo.stQuayCraneResourceConfig = stQuayCraneResourceConfig;

%%% if there is any violation, display them
if stBerthJobInfo.iPlotFlag >= 0
    nTotalCaseViolation
    for ii = 1:1:nTotalCaseViolation
        astCaseViolation(ii)
    end
end

nMaxIterAdaptToFeasibility = 10;
iFlagHasInitialConfliction = 0;
%%% resolve confliction by priority
if nTotalCaseViolation > 0
    iFlagHasInitialConfliction = 1;
    iMaxIter = nMaxIterAdaptToFeasibility;
    iIter = 1;
    while iIter <= iMaxIter
        
        for qq = 1:1:stBerthJobInfo.iTotalAgent
            iTimeFrameStartJobListPerAgent(qq) = stBerthJobInfo.stAgentJobInfo(qq).tTimeAgentJobStart.aTimeIn24HourFormat(1) + 1;
            iTimeFrameDueTimePerAgent(qq) = stBerthJobInfo.stAgentJobInfo(qq).tTimeAgentJobDue.aTimeIn24HourFormat(1) + 1;
            tStartTimePerAgent_datenum(qq) = datenum(stBerthJobInfo.stAgentJobInfo(qq).atClockAgentJobStart.aClockYearMonthDateHourMinSec);
            fTimeSlot_inMin(qq) = stAgent_Solution(qq).stCostAtAgent.stSolutionMinCost.stSchedule.fTimeUnit_Min;
            tCompleteTimePerAgent_datenum(qq) = ...
                tStartTimePerAgent_datenum(qq) + datenum(stAgent_Solution(qq).stCostAtAgent.stSolutionMinCost.stSchedule.iMaxEndTime * fTimeSlot_inMin(qq) / 60/24);
            iCompleteTimeFramePerAgent(qq) = ceil((tCompleteTimePerAgent_datenum(qq) - floor(tCompleteTimePerAgent_datenum(qq)))*24);
        end

        for vv =1:1:nTotalCaseViolation
            %%%%% Acording to each violation instance
            %%% get the Id of the machine in confliction, and total number
            %%% of violation
            iTimeFrameWithViolation = astCaseViolation(vv).iTimeFrameWithViolation;
            iMachineResourceViolation = astCaseViolation(vv).iMachineResourceViolation;
            nTotalViolation = astCaseViolation(vv).nTotalViolation;
            fTotalWeightResAlloc(vv) = 0;
            for qq = 1:1:stBerthJobInfo.iTotalAgent
                fWeightPerAgent(qq) = 0;
                bFlagAgentInResourceConfict(qq) = 0;
                if iTimeFrameWithViolation >= iTimeFrameStartJobListPerAgent(qq) & iTimeFrameWithViolation <= iCompleteTimeFramePerAgent(qq)
                    bFlagAgentInResourceConfict(qq) = 1;
                    iRelativePeriodInAgent(qq) = iTimeFrameWithViolation - iTimeFrameStartJobListPerAgent(qq) + 1;
                    %% Calculate the weight of current job list
    %                fWeightPerAgent(qq) = psa_jsp_calc_priority()
                    fWeightPerAgent(qq) = 1 /(stBerthJobInfo.stAgentJobInfo(qq).fPriceAgentDollarPerFrame + ...
                                                (stBerthJobInfo.stAgentJobInfo(qq).fLatePenalty_DollarPerFrame * ...
                                                  max(iCompleteTimeFramePerAgent(qq) - iTimeFrameDueTimePerAgent(qq), 0)) );
                    fTotalWeightResAlloc(vv) = fTotalWeightResAlloc(vv) + fWeightPerAgent(qq);
                else
                    fWeightPerAgent(qq) = inf;
                end
            end

            %%% resolve conflicaiton,  
            if nTotalViolation >= stBerthJobInfo.iTotalAgent
                %%% for large  number of violation
                for qq = 1:1:stBerthJobInfo.iTotalAgent
                    if bFlagAgentInResourceConfict(qq) == 1
                        iResourceReduction = floor(nTotalViolation * fWeightPerAgent(qq)/fTotalWeightResAlloc(vv));
                        if stQuayCraneResourceConfig(qq).stMachineConfig(iMachineResourceViolation + 1).afMaCapAtTimePoint(iRelativePeriodInAgent(qq)) ...
                                > iResourceReduction
                            stQuayCraneResourceConfig(qq).stMachineConfig(iMachineResourceViolation + 1).afMaCapAtTimePoint(iRelativePeriodInAgent(qq)) = ...
                                stQuayCraneResourceConfig(qq).stMachineConfig(iMachineResourceViolation + 1).afMaCapAtTimePoint(iRelativePeriodInAgent(qq)) - ...
                                iResourceReduction;
                        else
                            stQuayCraneResourceConfig(qq).stMachineConfig(iMachineResourceViolation + 1).afMaCapAtTimePoint(iRelativePeriodInAgent(qq)) = 1;
                        end

                        iMachineId = iMachineResourceViolation;
                        nInitResourceUsage = stQuayCraneResourceConfig(qq).stMachineConfig(iMachineResourceViolation + 1).afMaCapAtTimePoint(iRelativePeriodInAgent(qq));
                        iResourceReduction = - round(nTotalViolation * fWeightPerAgent(qq)/fTotalWeightResAlloc(vv));
                    end
                end        
            else
                %%% for small number of violation
                [fSortMinWeight, idxAgentWithLowestPriority] = sort(fWeightPerAgent);
                fReductionFactorAtAgent = 0.5; %% reduce 50 percentage usage for the agent with lowest priority
                ii = 1;
                while ii <= stBerthJobInfo.iTotalAgent & nTotalViolation > 0
                    
                    idxAgentId = idxAgentWithLowestPriority(ii);
                    
                    fResourceReduction = floor(fReductionFactorAtAgent * ...
                                        stQuayCraneResourceConfig(idxAgentId).stMachineConfig(iMachineResourceViolation + 1).afMaCapAtTimePoint(iRelativePeriodInAgent(idxAgentId)) ...
                                        );   %% to the smaller nearest integer;
                    stQuayCraneResourceConfig(idxAgentId).stMachineConfig(iMachineResourceViolation + 1).afMaCapAtTimePoint(iRelativePeriodInAgent(idxAgentId)) = ...
                        stQuayCraneResourceConfig(idxAgentId).stMachineConfig(iMachineResourceViolation + 1).afMaCapAtTimePoint(iRelativePeriodInAgent(idxAgentId)) ...
                             - fResourceReduction;
                    %%% remaining number of violation
                    nTotalViolation = nTotalViolation - fResourceReduction;
                    %%% reduction percentage half for the following 
                    fReductionFactorAtAgent = fReductionFactorAtAgent / 2;
                    
                    % for the next quay crane with lowest priority
                    ii = ii + 1;
                end

            end
        end
        
        iIter = iIter + 1;
        for qq= 1:1:stBerthJobInfo.iTotalAgent
            stAgent_Solution(qq).stMinCostResourceConfig = stQuayCraneResourceConfig(qq);
        end
        
        [stMachineUsageInfoBerth, stMachineUsageInfoByAgent] = psa_bidgen_build_bid_by_cfg(stBerthJobInfo, stAgent_Solution);
        nTotalCaseViolation = 0;
        astCaseViolation = [];
        for mm = 1:1:stBerthJobInfo.stSystemMasterConfig.iTotalMachType
            if mm ~= stBerthJobInfo.stSystemMasterConfig.iCriticalMachType
                for tt = 1:1:iTotalFrame
                    [fValueLookup, iIndex] = calc_lut_max_between(stMachineUsageInfoBerth.astMachineUsage(mm).aMachineUsageAfterTime, stMachineUsageInfoBerth.astMachineUsage(mm).aSortedTime_inHour, ...
                        tt-1-fTimeDelta, tt-fTimeDelta);

                    stMachinePriceInfo.astMachineUsage(mm).aUsageAtFrame(tt) = fValueLookup;
                    stMachinePriceInfo.astMachineCapacity(mm).aCapacityAtFrame(tt) = stMachineUsageInfoBerth.astMachineUsage(mm).iMaxCapacity;
                    stMachinePriceInfo.astMachineViolation(mm).aViolateAtFrame(tt) = stMachinePriceInfo.astMachineUsage(mm).aUsageAtFrame(tt) - stMachineUsageInfoBerth.astMachineUsage(mm).iMaxCapacity;
                    if stMachinePriceInfo.astMachineViolation(mm).aViolateAtFrame(tt) > 0
                        nTotalCaseViolation = nTotalCaseViolation + 1;
                        astCaseViolation(nTotalCaseViolation).iTimeFrameWithViolation = tt;
                        astCaseViolation(nTotalCaseViolation).iMachineResourceViolation = mm;
                        astCaseViolation(nTotalCaseViolation).nTotalViolation = stMachinePriceInfo.astMachineViolation(mm).aViolateAtFrame(tt);
                    end
                end
            end
        end
        if nTotalCaseViolation <= 0
            break; %% all confliction has been resolved
        end
        iter_totalVolation = [iIter, nTotalCaseViolation]
    end    
end    

%%%%%%
if iFlagHasInitialConfliction == 1
    if stBerthJobInfo.iPlotFlag >= 3
        for qq = 1:1:stBerthJobInfo.iTotalAgent
            stQuayCraneResourceConfig(qq).stMachineConfig(2).afMaCapAtTimePoint
            stQuayCraneResourceConfig(qq).stMachineConfig(3).afMaCapAtTimePoint
        end
    end

    %% Reschedule
    for qq = 1:1:stBerthJobInfo.iTotalAgent
        if bFlagAgentInResourceConfict(qq) == 1

            % 20080406 modify psa_gen_sch_perform_rpt_by_cfg, To Be Test
            stJobListInfoAgent(qq).stResourceConfig = stQuayCraneResourceConfig(qq);
            stJobListInfoAgent(qq).stJobListBiFsp.stResourceConfig = stQuayCraneResourceConfig(qq);
            [stAgent_Solution_qq] = psa_gen_sch_perform_rpt_by_cfg(stBerthJobInfo, ...
                    stBerthJobInfo.stAgentJobInfo(qq), stJobListInfoAgent(qq));
%            [stAgent_Solution_qq] = psa_gen_sch_perform_rpt_by_cfg(stBerthJobInfo, stQuayCraneResourceConfig, qq);
            stAgent_Solution(qq).stMinCostResourceConfig = stAgent_Solution_qq.stMinCostResourceConfig;
            stAgent_Solution(qq).stPerformReport.tMinCostMakeSpan_hour         = stAgent_Solution_qq.stPerformReport.tMinCostMakeSpan_hour;
            stAgent_Solution(qq).stPerformReport.tMinCostGrossCraneRate        = stAgent_Solution_qq.stPerformReport.tMinCostGrossCraneRate;
            stAgent_Solution(qq).stPerformReport.fCostMakespanTardiness        = stAgent_Solution_qq.stPerformReport.fCostMakespanTardiness;
            stAgent_Solution(qq).stPerformReport.fMinCost                      = stAgent_Solution_qq.stPerformReport.fMinCost;
            stAgent_Solution(qq).stSchedule_MinCost                            = stAgent_Solution_qq.stSchedule_MinCost;
            stAgent_Solution(qq).stCostAtAgent.stSolutionMinCost.stSchedule       = stAgent_Solution(qq).stSchedule_MinCost;
        end    
    end

    [stMachineUsageInfoBerth, stMachineUsageInfoByAgent] = psa_bidgen_build_bid_by_cfg(stBerthJobInfo, stAgent_Solution);

    %%%update output
    stDebugOutput.stMachineUsageInfoBerth = stMachineUsageInfoBerth;
    stDebugOutput.stMachineUsageInfoByAgent  = stMachineUsageInfoByAgent;
    stDebugOutput.stResourceConfigInfo    = stResourceConfigInfo;
    stDebugOutput.nTotalCaseViolation     = nTotalCaseViolation;
    stDebugOutput.astCaseViolation        = astCaseViolation;

else
%    disp('No resource conflict');
%    stAgent_Solution, stMachineUsageInfoBerth, stMachineUsageInfoByAgent, stResourceConfigInfo, astCaseViolation
    %%%init output
    stDebugOutput.nTotalCaseViolation     = nTotalCaseViolation;
    stDebugOutput.stMachineUsageInfoBerth = stMachineUsageInfoBerth;
    stDebugOutput.stMachineUsageInfoByAgent  = stMachineUsageInfoByAgent;
    stDebugOutput.stResourceConfigInfo    = stResourceConfigInfo;
    stDebugOutput.astCaseViolation        = astCaseViolation;

end

