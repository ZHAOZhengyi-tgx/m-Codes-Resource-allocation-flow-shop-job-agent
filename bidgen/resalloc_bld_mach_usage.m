function [stMachineUsageInfoSystem, stMachineUsageInfoByAgent] = resalloc_bld_mach_usage(stResAllocGenJspAgent, stAgent_Solution)
%
% build usage from schedule
% %%% Output:
% stMachineUsageInfoSystem
% stMachineUsageInfoByAgent
%
% For multiple period resoure allocation problem,
% The usage for each kind of machine might change from period to period for each job, the usage
% for each period in that job is the maximum number of machines used by the job in that period.
%
% History
% YYYYMMDD  Notes
% 20071128  epsilon_time = 0.001 / 60/24;
% 20080415 port from psa_bidgen_build_bid_by_cfg

stSystemMasterConfig  = stResAllocGenJspAgent.stSystemMasterConfig;
iTotalMachType = stSystemMasterConfig.iTotalMachType;

% epsilon_time = 0.001 / 60/24;  % unit in minute.
global epsilon_time; % 20071128

%%% First generate the bidding for each job list on each machine at time period
for qq=1:1:stSystemMasterConfig.iTotalAgent
    [astMachineUsageTimeSlotInfo] = jsp_build_machine_usage_con_tm(stAgent_Solution(qq).stCostAtAgent.stSolutionMinCost.stSchedule);
    fTimeSlot_inMin = stAgent_Solution(qq).stCostAtAgent.stSolutionMinCost.stSchedule.fTimeUnit_Min;
    fFactorFramePerSlot = fTimeSlot_inMin/60/stSystemMasterConfig.fTimeFrameUnitInHour;
    iTotalNumTimePoints = length(astMachineUsageTimeSlotInfo(1).aSortedTime);
    tStartTime_datenum = datenum(stResAllocGenJspAgent.stAgentJobInfo(qq).atClockAgentJobStart.aClockYearMonthDateHourMinSec); 
    % + epsilon_time; % 20071128
    tCompleteTime_datenum = tStartTime_datenum + datenum(stAgent_Solution(qq).stCostAtAgent.stSolutionMinCost.stSchedule.iMaxEndTime * fTimeSlot_inMin / 60/24);
    tStartTimeFrame = floor((tStartTime_datenum + epsilon_time - floor(tStartTime_datenum))*24)/24 + floor(tStartTime_datenum);
    tEndTimeFrame = ceil((tCompleteTime_datenum - floor(tCompleteTime_datenum))*24)/24 + floor(tCompleteTime_datenum);
%    datenum_StartTime = datestr(tStartTime_datenum)
%    datenum_CompleteTime = datestr(tCompleteTime_datenum)
%    datenum_StartTimeFrame = datestr(tStartTimeFrame)
%    datenum_EndTimeFrame = datestr(tEndTimeFrame)
    iTotalTimePeriod = round((tEndTimeFrame - tStartTimeFrame)*24);
    
    stMachineBiddingPeriodInfo(qq).strJobStartTime = datestr(tStartTime_datenum);
    stMachineBiddingPeriodInfo(qq).strJobCompleteTime = datestr(tCompleteTime_datenum);
    stMachineBiddingPeriodInfo(qq).iTotalTimePeriod = iTotalTimePeriod;
    for pp = 1:1:iTotalTimePeriod
        stMachineBiddingPeriodInfo(qq).tPeriodStartTime(pp) = tStartTimeFrame + (pp - 1)/24;
        stMachineBiddingPeriodInfo(qq).tPeriodEndTime(pp)   = tStartTimeFrame + pp/24;
    end
    
    for mm = 1:1:iTotalMachType
        astMachineBidding(mm).aMachineUsageAtPeriod = zeros(1, iTotalTimePeriod);
        %% Error adding following line
%        astMachineBidding(mm).aMachineUsageAtPeriod(1) = astMachineUsageTimeSlotInfo(mm).aMachineUsageAfterTime(1);
        for ii = 1:1:iTotalNumTimePoints
            tPointSlotFrame_datanum = astMachineUsageTimeSlotInfo(mm).aSortedTime(ii) * fTimeSlot_inMin /60/24 + tStartTime_datenum;
            iPoint_UnitHour = ceil((tPointSlotFrame_datanum - stMachineBiddingPeriodInfo(qq).tPeriodStartTime(1))*24);
            if iPoint_UnitHour <= 0
                iPoint_UnitHour = 1;
            end
            %% each Agent job starts at the beginning of a specific time period
            if astMachineBidding(mm).aMachineUsageAtPeriod(iPoint_UnitHour) < astMachineUsageTimeSlotInfo(mm).aMachineUsageAfterTime(ii)
                astMachineBidding(mm).aMachineUsageAtPeriod(iPoint_UnitHour) = astMachineUsageTimeSlotInfo(mm).aMachineUsageAfterTime(ii);
            end
        end
    end
    
    stMachineUsageInfoByAgent.stMachineBiddingInfo(qq).stBiddingPeriod = stMachineBiddingPeriodInfo(qq);
    stMachineUsageInfoByAgent.stMachineBiddingInfo(qq).iTotalMachine = iTotalMachType;
    stMachineUsageInfoByAgent.stMachineBiddingInfo(qq).astMachineBidding = astMachineBidding;

end

%%%%%%%%%%%%%%%%% build total machine usage in the berth
[stMachineUsageInfoSystem] = resalloc_bld_glb_mach_usage(stResAllocGenJspAgent, stMachineUsageInfoByAgent);

%%% calculate the utility price, 
%%% 20080415 port from psa_bidgen_build_bid_by_cfg,
if isfield(stAgent_Solution, 'stAgentUtilityPrice')
    nTotalFrame = round(stResAllocGenJspAgent.tPlanningWindow_Hours /stResAllocGenJspAgent.fTimeFrameUnitInHour); % 20070913
    
    for mm = 1:1:stResAllocGenJspAgent.stSystemMasterConfig.iTotalMachType
        if mm ~= stResAllocGenJspAgent.stSystemMasterConfig.iCriticalMachType
            for tt = 1:1:nTotalFrame
                stUtilityPriceInfo.astMachinePrice(mm).fPricePerFrame(tt) = 0;
                stUtilityPriceInfo.astMachinePrice(mm).nTotalBidding(tt) = 0;
                stUtilityPriceInfo.astMachinePrice(mm).fSumPriceTimeBidding(tt) = 0;
                for qq=1:1:stResAllocGenJspAgent.iTotalAgent
                    idxStartHourIndexAtAgent = stAgent_Solution(qq).stAgentUtilityPrice.iPriceHourStartIndex;
                    if tt >= idxStartHourIndexAtAgent ...
                            & tt <= idxStartHourIndexAtAgent + stAgent_Solution(qq).stAgentUtilityPrice.iTotalPeriod - 1
%                         len_astMachinePrice = length(stUtilityPriceInfo.astMachinePrice)
%                         len_Period = length(stUtilityPriceInfo.astMachinePrice(mm).nTotalBidding)
                        stUtilityPriceInfo.astMachinePrice(mm).nTotalBidding(tt) = stUtilityPriceInfo.astMachinePrice(mm).nTotalBidding(tt) + ...
                            stAgent_Solution(qq).stAgentUtilityPrice.astUtilityPrice(tt - idxStartHourIndexAtAgent + 1).fDeltaUtiPriceAtMach(mm).iResourceBidding;
                        stUtilityPriceInfo.astMachinePrice(mm).fSumPriceTimeBidding(tt) = stUtilityPriceInfo.astMachinePrice(mm).fSumPriceTimeBidding(tt) ...
                            + ... 
                            ( stAgent_Solution(qq).stAgentUtilityPrice.astUtilityPrice(tt - idxStartHourIndexAtAgent + 1).fDeltaUtiPriceAtMach(mm).iResourceBidding ...
                              * stAgent_Solution(qq).stAgentUtilityPrice.astUtilityPrice(tt - idxStartHourIndexAtAgent + 1).fDeltaUtiPriceAtMach(mm).fUtilityPrice);
                    end
                end
                if stUtilityPriceInfo.astMachinePrice(mm).nTotalBidding(tt) > 0
                    stUtilityPriceInfo.astMachinePrice(mm).fPricePerFrame(tt) = abs...
                        ( stUtilityPriceInfo.astMachinePrice(mm).fSumPriceTimeBidding(tt) ...
                          / stUtilityPriceInfo.astMachinePrice(mm).nTotalBidding(tt) ...
                        ); % 20080302
                else % 20080302
                    stUtilityPriceInfo.astMachinePrice(mm).fPricePerFrame(tt) = 0;
                end
            end
        else
            for tt = 1:1:nTotalFrame
                stUtilityPriceInfo.astMachinePrice(mm).fPricePerFrame(tt) = 0;
                stUtilityPriceInfo.astMachinePrice(mm).nTotalBidding(tt) = stResAllocGenJspAgent.iTotalAgent;
                stUtilityPriceInfo.astMachinePrice(mm).fSumPriceTimeBidding(tt) = 0;
            end
        end % 20080302
    end
    
    stMachineUsageInfoSystem.stUtilityPriceInfo = stUtilityPriceInfo;
end

