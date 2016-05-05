function [stMachineUsageInfoSystem, stMachineUsageInfoByAgent] = psa_bidgen_build_bid_by_cfg(stResAllocGenJspAgent, stAgent_Solution)
% port of Singapore Authority, bid-generation build bid by configuration
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

%
%
% %%% Output:
% stMachineUsageInfoSystem
% stMachineUsageInfoByAgent
% History
% YYYYMMDD Notes
% 20071109 Add global parameter definition
% 20080211 Use iTotalMachine from stResourceConfig
% 20080302 Protection againt negative or zero
global epsilon_time; % 20071109

%%% First generate the bidding for each job list on each machine at time period

%%% First generate the bidding for each job list on each machine at time period
for qq=1:1:stResAllocGenJspAgent.iTotalAgent
    stResourceConfigAgent = stAgent_Solution(qq).stMinCostResourceConfig;
    
    fTimeSlot_inMin = stAgent_Solution(qq).stCostAtAgent.stSolutionMinCost.stSchedule.fTimeUnit_Min;
    fFactorFramePerSlot = fTimeSlot_inMin/60/stResAllocGenJspAgent.fTimeFrameUnitInHour;
    tStartTime_datenum = datenum(stResAllocGenJspAgent.stAgentJobInfo(qq).atClockAgentJobStart.aClockYearMonthDateHourMinSec)  + epsilon_time;
    tCompleteTime_datenum = tStartTime_datenum + datenum(stAgent_Solution(qq).stCostAtAgent.stSolutionMinCost.stSchedule.iMaxEndTime * fTimeSlot_inMin / 60/24);
    tStartTimeFrame = floor((tStartTime_datenum - floor(tStartTime_datenum))*24)/24 + floor(tStartTime_datenum);
    tEndTimeFrame = ceil((tCompleteTime_datenum - floor(tCompleteTime_datenum))*24)/24 + floor(tCompleteTime_datenum);

    iFrameStartTime = datestr(tStartTimeFrame);
    
    iTotalTimePeriod = round((tEndTimeFrame - tStartTimeFrame)*24);

    stMachineBiddingPeriodInfo(qq).strJobStartTime = datestr(tStartTime_datenum);
    stMachineBiddingPeriodInfo(qq).strJobCompleteTime = datestr(tCompleteTime_datenum);
    stMachineBiddingPeriodInfo(qq).iTotalTimePeriod = iTotalTimePeriod;
    for pp = 1:1:iTotalTimePeriod
        stMachineBiddingPeriodInfo(qq).tPeriodStartTime(pp) = tStartTimeFrame + (pp - 1)/24; %%% unit is day
        stMachineBiddingPeriodInfo(qq).tPeriodEndTime(pp)   = tStartTimeFrame + pp/24;
    end

    for mm = 1:1:stResourceConfigAgent.iTotalMachine % stResAllocGenJspAgent.iTotalMachType % 20080211
        astMachineBidding(mm).aMachineUsageAtPeriod = zeros(1, iTotalTimePeriod);
        for ii = 1:1:stResourceConfigAgent.stMachineConfig(mm).iNumPointTimeCap
            astMachineBidding(mm).aMachineUsageAtPeriod(ii) = stResourceConfigAgent.stMachineConfig(mm).afMaCapAtTimePoint(ii);
        end
    end
    stMachineUsageInfoByAgent.stMachineBiddingInfo(qq).stBiddingPeriod = stMachineBiddingPeriodInfo(qq);
    stMachineUsageInfoByAgent.stMachineBiddingInfo(qq).iTotalMachine = 3;
    stMachineUsageInfoByAgent.stMachineBiddingInfo(qq).astMachineBidding = astMachineBidding;
end

%%%%%%%%%%%%%%%%% build total machine usage in the berth
[stMachineUsageInfoSystem] = resalloc_bld_glb_mach_usage(stResAllocGenJspAgent, stMachineUsageInfoByAgent);

%%% calculate the utility price
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
                            && tt <= idxStartHourIndexAtAgent + stAgent_Solution(qq).stAgentUtilityPrice.iTotalPeriod - 1
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

