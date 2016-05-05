function [astQuayCraneResourceConfig] = psa_resalloc_by_priority(stBerthJobInfo, astCaseViolation, nTotalCaseViolation, astQuayCraneResourceConfig, iTotalTimeFrame)

nMaxIterAdaptToFeasibility = 10;
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
                    fWeightPerAgent(qq) = 1 /(stBerthJobInfo.stAgentJobInfo(qq).fPriceQuayCraneDollarPerFrame + ...
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
                        if astQuayCraneResourceConfig(qq).stMachineConfig(iMachineResourceViolation + 1).afMaCapAtTimePoint(iRelativePeriodInAgent(qq)) ...
                                > iResourceReduction
                            astQuayCraneResourceConfig(qq).stMachineConfig(iMachineResourceViolation + 1).afMaCapAtTimePoint(iRelativePeriodInAgent(qq)) = ...
                                astQuayCraneResourceConfig(qq).stMachineConfig(iMachineResourceViolation + 1).afMaCapAtTimePoint(iRelativePeriodInAgent(qq)) - ...
                                iResourceReduction;
                        else
                            astQuayCraneResourceConfig(qq).stMachineConfig(iMachineResourceViolation + 1).afMaCapAtTimePoint(iRelativePeriodInAgent(qq)) = 1;
                        end

                        iMachineId = iMachineResourceViolation;
                        nInitResourceUsage = astQuayCraneResourceConfig(qq).stMachineConfig(iMachineResourceViolation + 1).afMaCapAtTimePoint(iRelativePeriodInAgent(qq));
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
                                        astQuayCraneResourceConfig(idxAgentId).stMachineConfig(iMachineResourceViolation + 1).afMaCapAtTimePoint(iRelativePeriodInAgent(idxAgentId)) ...
                                        );   %% to the smaller nearest integer;
                    astQuayCraneResourceConfig(idxAgentId).stMachineConfig(iMachineResourceViolation + 1).afMaCapAtTimePoint(iRelativePeriodInAgent(idxAgentId)) = ...
                        astQuayCraneResourceConfig(idxAgentId).stMachineConfig(iMachineResourceViolation + 1).afMaCapAtTimePoint(iRelativePeriodInAgent(idxAgentId)) ...
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
            stAgent_Solution(qq).stMinCostResourceConfig = astQuayCraneResourceConfig(qq);
        end
        
        [stMachineUsageInfoBerth, stMachineUsageInfoByAgent] = psa_bidgen_build_bid_by_cfg(stBerthJobInfo, stAgent_Solution);
        nTotalCaseViolation = 0;
        astCaseViolation = [];
        for mm =1:1:2
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
        if nTotalCaseViolation <= 0
            break; %% all confliction has been resolved
        end
        iter_totalVolation = [iIter, nTotalCaseViolation]
    end    
