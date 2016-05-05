function [stMachineUsageInfoSystem] = resalloc_bld_glb_mach_usage(stResAllocGenJspAgent, stMachineUsageInfoByAgent)
%resource allocation, build total machine usage in the berth
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
% Input: 
%   stResAllocGenJspAgent
%   stMachineUsageInfoByAgent
% Output:
%   stMachineUsageInfoSystem
%
%
% History
% YYYYMMDD  Notes
% 20071128  Partial
% epsilon_time = 0.001 / 60/24;
global epsilon_time;

stResourceConfig = stResAllocGenJspAgent.stResourceConfig;
stSystemMasterConfig  = stResAllocGenJspAgent.stSystemMasterConfig;
iTotalMachType = stSystemMasterConfig.iTotalMachType;
% stBerthJobInfo

for mm = 1:1:iTotalMachType
    astMachineUsage(mm).strName = stResourceConfig.stMachineConfig(mm).strName;
    astMachineUsage(mm).iTotalTimePoint = 0;
    astMachineUsage(mm).nInitialUsage = 0;
    astMachineUsage(mm).iMaxCapacity = stResourceConfig.iaMachCapOnePer(mm);
end

nTotalFrame = stSystemMasterConfig.iMaxFramesForPlanning; % round(stSystemMasterConfig.tPlanningWindow_Hours /stSystemMasterConfig.fTimeFrameUnitInHour); % 20070913

for qq=1:1:stSystemMasterConfig.iTotalAgent
    iTotalPeriodPerAgent = stMachineUsageInfoByAgent.stMachineBiddingInfo(qq).stBiddingPeriod.iTotalTimePeriod;
    tStartTime_datenum = stMachineUsageInfoByAgent.stMachineBiddingInfo(qq).stBiddingPeriod.tPeriodStartTime(1);
    tCompleteTime_datenum = stMachineUsageInfoByAgent.stMachineBiddingInfo(qq).stBiddingPeriod.tPeriodEndTime(iTotalPeriodPerAgent);
    
    if qq == 1
        tEarliestStartTime = tStartTime_datenum;
        tLatestCompleteTime = tCompleteTime_datenum;
    else
        if tEarliestStartTime > tStartTime_datenum
            tEarliestStartTime = tStartTime_datenum;
        end
        if tLatestCompleteTime < tCompleteTime_datenum
            tLatestCompleteTime = tCompleteTime_datenum;
        end
    end
    for tt = 1:1: iTotalPeriodPerAgent + 1
        if tt == 1
            for mm = 1:1:iTotalMachType
                astMachineUsage(mm).aTimeArray(astMachineUsage(mm).iTotalTimePoint + tt) = tStartTime_datenum;
                astMachineUsage(mm).aDeltaStartEnd(astMachineUsage(mm).iTotalTimePoint + tt) = ...
                     stMachineUsageInfoByAgent.stMachineBiddingInfo(qq).astMachineBidding(mm).aMachineUsageAtPeriod(tt);
                astMachineUsage(mm).aJobArray(astMachineUsage(mm).iTotalTimePoint + tt) = qq;
            end
            %%% machine usage for prime mover
            %%% machine usage for yard crane
        elseif tt == iTotalPeriodPerAgent + 1
            for mm = 1:1:iTotalMachType
                astMachineUsage(mm).aTimeArray(astMachineUsage(mm).iTotalTimePoint + tt) = ...
                    stMachineUsageInfoByAgent.stMachineBiddingInfo(qq).stBiddingPeriod.tPeriodEndTime(iTotalPeriodPerAgent) ...
                    - epsilon_time;
                astMachineUsage(mm).aDeltaStartEnd(astMachineUsage(mm).iTotalTimePoint + tt) = ...
                     - stMachineUsageInfoByAgent.stMachineBiddingInfo(qq).astMachineBidding(mm).aMachineUsageAtPeriod(tt - 1);
                astMachineUsage(mm).aJobArray(astMachineUsage(mm).iTotalTimePoint + tt) = qq;
            end
            
        else
            for mm = 1:1:iTotalMachType
                astMachineUsage(mm).aDeltaStartEnd(astMachineUsage(mm).iTotalTimePoint + tt) = ...
                     stMachineUsageInfoByAgent.stMachineBiddingInfo(qq).astMachineBidding(mm).aMachineUsageAtPeriod(tt) - ...
                     stMachineUsageInfoByAgent.stMachineBiddingInfo(qq).astMachineBidding(mm).aMachineUsageAtPeriod(tt - 1);
                if astMachineUsage(mm).aDeltaStartEnd(astMachineUsage(mm).iTotalTimePoint + tt) < 0
                    astMachineUsage(mm).aTimeArray(astMachineUsage(mm).iTotalTimePoint + tt) = ...
                        stMachineUsageInfoByAgent.stMachineBiddingInfo(qq).stBiddingPeriod.tPeriodStartTime(tt) ...
                        - epsilon_time;
                else
                    astMachineUsage(mm).aTimeArray(astMachineUsage(mm).iTotalTimePoint + tt) = ...
                        stMachineUsageInfoByAgent.stMachineBiddingInfo(qq).stBiddingPeriod.tPeriodStartTime(tt);
                end
                astMachineUsage(mm).aJobArray(astMachineUsage(mm).iTotalTimePoint + tt) = qq;
            end
        end
    end
    for mm = 1:1:iTotalMachType
        astMachineUsage(mm).iTotalTimePoint = astMachineUsage(mm).iTotalTimePoint + ...
            stMachineUsageInfoByAgent.stMachineBiddingInfo(qq).stBiddingPeriod.iTotalTimePeriod + 1;
    end

end

for mm = 1:1:iTotalMachType
    [aSortedTime, iSortIdx] = sort(astMachineUsage(mm).aTimeArray);
    astMachineUsage(mm).aSortedTime = aSortedTime;
    astMachineUsage(mm).aSortedDelta = astMachineUsage(mm).aDeltaStartEnd(iSortIdx);
    astMachineUsage(mm).aSortedJob = astMachineUsage(mm).aJobArray(iSortIdx);
    
    astMachineUsage(mm).aMachineUsageAfterTime(1) = astMachineUsage(mm).nInitialUsage + astMachineUsage(mm).aSortedDelta(1);
    for tt = 2:1:astMachineUsage(mm).iTotalTimePoint
        astMachineUsage(mm).aMachineUsageAfterTime(tt) = astMachineUsage(mm).aMachineUsageAfterTime(tt-1) + astMachineUsage(mm).aSortedDelta(tt);
    end
    astMachineUsage(mm).iMaxUsage = max(astMachineUsage(mm).aMachineUsageAfterTime);
    
    astMachineUsage(mm).aSortedTime_inHour = (astMachineUsage(mm).aSortedTime - floor(tEarliestStartTime))*24;
end

stMachineUsageInfoSystem.tEarliestStartTime = tEarliestStartTime;
stMachineUsageInfoSystem.tLatestCompleteTime = tLatestCompleteTime;
stMachineUsageInfoSystem.astMachineUsage = astMachineUsage;

%%% construct the adaptive length of machine usage information by period
% 20070704
nActiveTotalFrame = ceil((tLatestCompleteTime - tEarliestStartTime) * 24 /stSystemMasterConfig.fTimeFrameUnitInHour);


tEpsilon_datenum = 1/24/60; %% one minute

% for mm = 1:1:2
for mm = 1:1:iTotalMachType
    astMachineUsageByPeriod(mm).strName = astMachineUsage(mm).strName;
    astMachineUsageByPeriod(mm).nActiveTotalFrame = nActiveTotalFrame;
    astMachineUsageByPeriod(mm).cellStartTime = cell(nActiveTotalFrame);
    astMachineUsageByPeriod(mm).cellEndTime = cell(nActiveTotalFrame);
    for pp = 1:1:nActiveTotalFrame
        tPeriodStartTime_datenum = tEarliestStartTime + (pp - 1)*stSystemMasterConfig.fTimeFrameUnitInHour/24;
        strTimeStart = datestr(tPeriodStartTime_datenum);
        astMachineUsageByPeriod(mm).cellStartTime(pp) = {strTimeStart};
        
        tPeriodEndTime_datenum = tEarliestStartTime + pp*stSystemMasterConfig.fTimeFrameUnitInHour/24;
        strTimeEnd = datestr(tPeriodEndTime_datenum);
        astMachineUsageByPeriod(mm).cellEndTime(pp) = {strTimeEnd};
        
        [fValueLookup, iIndex] = calc_lut_max_between(stMachineUsageInfoSystem.astMachineUsage(mm).aMachineUsageAfterTime, ...
            stMachineUsageInfoSystem.astMachineUsage(mm).aSortedTime, ...
            tPeriodStartTime_datenum, ...
            tPeriodEndTime_datenum - tEpsilon_datenum); 
        astMachineUsageByPeriod(mm).aMachineMaxUsage(pp) = round(fValueLookup);
        
        astMachineUsageByPeriod(mm).aMachineNetDemand(pp) = astMachineUsageByPeriod(mm).aMachineMaxUsage(pp) - astMachineUsage(mm).iMaxCapacity;
    end
    
    % 20070913
    astMachineUsageByPeriod(mm).aiFlagIsActiveFrame = zeros(nTotalFrame, 1);
    % modify for genetic auction approach % 20071128
    for tt = 1:1:nTotalFrame
        tMidPointPlanningFrame_datenum = (tt - 0.5) * stSystemMasterConfig.fTimeFrameUnitInHour / 24 + stSystemMasterConfig.stPlanningStartTime.tPlanningStartTime_datenum;
%        % for debugging
%        strMidPointPlanningTime = datestr(tMidPointPlanningFrame_datenum)
        if tMidPointPlanningFrame_datenum > tEarliestStartTime && tMidPointPlanningFrame_datenum < tLatestCompleteTime
            astMachineUsageByPeriod(mm).aiFlagIsActiveFrame(tt) = 1;
        end
    end % 20070913
end
% astMachineUsageByPeriod(1).aiFlagIsActiveFrame
% astMachineUsageByPeriod(2).aiFlagIsActiveFrame
stMachineUsageInfoSystem.astMachineUsageByPeriod = astMachineUsageByPeriod;
stMachineUsageInfoSystem.nActiveTotalFrame = nActiveTotalFrame;
stMachineUsageInfoSystem.nTotalFrame = nTotalFrame; % 20070913
% 20070704

