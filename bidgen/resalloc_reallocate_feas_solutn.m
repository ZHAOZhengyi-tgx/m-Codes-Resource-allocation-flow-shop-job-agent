function [stAgent_Solution, stDebugOutput] = resalloc_reallocate_feas_solutn(stResAllocGenJspAgent, stAgent_Solution, stJobListInfoAgent)
%function [stAgent_Solution] = resalloc_reallocate_feas_solutn(stResAllocGenJspAgent, stAgent_Solution, stJobListInfoAgent)
% Manually re-allocate resources if there is any resource not used
% 
% prototype
% [stAgent_Solution, stDebugOutput] =
% resalloc_reallocate_feas_solutn(stResAllocGenJspAgent, stAgent_Solution, stJobListInfoAgent)
% 
% Input: 
%  stResAllocGenJspAgent
%  stAgent_Solution
%  stJobListInfoAgent: legacy
% Output:
%  stAgent_Solution
%  stDebugOutput
%
% 20080415, initialize to be zero, 
%           replace psa_bidgen_build_bid_by_cfg to resalloc_bld_mach_usage?
% 20091201  Display some debug information
global epsilon_slot;
global iTeration;

stSystemMasterConfig = stResAllocGenJspAgent.stSystemMasterConfig;

%% Build machine usage information for each Agent and for whole berth
[stMachineUsageInfoSystem, stMachineUsageInfoByAgent] = psa_bidgen_build_bid_by_cfg(stResAllocGenJspAgent, stAgent_Solution);
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%%% Compare total Demand and total supply, record constraint FreeRes in
%%% nTotalCaseUnAllocate,  astCaseUnUsedRes
nTotalCaseUnAllocate = 0;
astCaseUnUsedRes = [];
iTotalFrame = ceil(24/stSystemMasterConfig.fTimeFrameUnitInHour);

for mm = 1:1:stSystemMasterConfig.iTotalMachType
    if mm ~= stSystemMasterConfig.iCriticalMachType
    % get the resource usage from clock (tt-1):0:0 to (t + epsilon_slot):0:0
    % epsilon_slot is introduced to avoid numerical trouncation error.
        for tt = 1:1:iTotalFrame
    %        [fValueLookup, iIndex] = ...
    %            calc_table_look_up_max(stMachineUsageInfoSystem.astMachineUsage(mm).aMachineUsageAfterTime, stMachineUsageInfoSystem.astMachineUsage(mm).aSortedTime_inHour, tt-1, epsilon_slot);
            [fValueLookup, iIndex] = calc_lut_max_between(stMachineUsageInfoSystem.astMachineUsage(mm).aMachineUsageAfterTime, stMachineUsageInfoSystem.astMachineUsage(mm).aSortedTime_inHour, ...
                tt-1-epsilon_slot, tt-epsilon_slot);
    %  PriceAtHour_i: price at clock (i-1):0:0 to i:0:0
    %  UsageAtHour_i: usage at clock i:0:0 to (i+1):0:0
    %  CapacityAtHour_i: Capacity at clock i:0:0 to (i+1):0:0

            stMachinePriceInfo.astMachineUsage(mm).aUsageAtFrame(tt) = fValueLookup;
            stMachinePriceInfo.astMachineCapacity(mm).aCapacityAtFrame(tt) = ...
                stMachineUsageInfoSystem.astMachineUsage(mm).iMaxCapacity;
            stMachinePriceInfo.astMachineFreeRes(mm).aViolateAtFrame(tt) = ...
                stMachinePriceInfo.astMachineUsage(mm).aUsageAtFrame(tt) - ...
                stMachineUsageInfoSystem.astMachineUsage(mm).iMaxCapacity;
            if stMachineUsageInfoSystem.astMachineUsageByPeriod(mm).aiFlagIsActiveFrame(tt) == 1
                if stMachinePriceInfo.astMachineFreeRes(mm).aViolateAtFrame(tt) <= -1
                    nTotalCaseUnAllocate = nTotalCaseUnAllocate + 1;
                    astCaseUnUsedRes(nTotalCaseUnAllocate).iTimeFrameWithFreeRes = tt;
                    astCaseUnUsedRes(nTotalCaseUnAllocate).idxResFree = mm;
                    astCaseUnUsedRes(nTotalCaseUnAllocate).nTotalFreeRes = ...
                        - stMachinePriceInfo.astMachineFreeRes(mm).aViolateAtFrame(tt);
                end
            end
        end
    end
end

for qq = 1:1:stSystemMasterConfig.iTotalAgent
    stAgentResourceConfig(qq) = stAgent_Solution(qq).stMinCostResourceConfig; %% stAgent_Solution(qq).stMinCostResourceConfig
end
stResourceConfigInfo.stAgentResourceConfig = stAgentResourceConfig;

strSheetName = sprintf('Iter%d', iTeration);
strFilenameXls = sprintf('%s_ResRealloc.xls', stResAllocGenJspAgent.strInputFilename);

%%% Debug if there is any FreeRes, display them
if stSystemMasterConfig.iPlotFlag >= 3 % 20091201
    disp('Before reallocation. ')
    for mm = 1:1:stSystemMasterConfig.iTotalMachType
        if mm ~= stSystemMasterConfig.iCriticalMachType
            for qq = 1:1:stSystemMasterConfig.iTotalAgent
                stAgentResourceConfig(qq).stMachineConfig(mm).afMaCapAtTimePoint
            end
        end
    end
    
    atAgentMakespan_bf_ResReAlloc_hour = zeros(1, stSystemMasterConfig.iTotalAgent);
    for qq = 1:1:stSystemMasterConfig.iTotalAgent
        atAgentMakespan_bf_ResReAlloc_hour(1, qq) = stAgent_Solution(qq).stPerformReport.tMinCostMakeSpan_hour;
        tTotalPeriod = length(stAgentResourceConfig(qq).stMachineConfig(2).afMaCapAtTimePoint);
        for tt = 1:1:tTotalPeriod
            strText = sprintf('(%d, %d)', stAgentResourceConfig(qq).stMachineConfig(2).afMaCapAtTimePoint(tt), stAgentResourceConfig(qq).stMachineConfig(3).afMaCapAtTimePoint(tt));
            cellMatrix(qq, tt) = {strText};
        end
        cellMatrix(qq, tTotalPeriod+1) = {stAgent_Solution(qq).stPerformReport.tMinCostMakeSpan_hour};
        cellMatrix(qq, tTotalPeriod+2) = {stAgent_Solution(qq).stPerformReport.fCostMakespanTardiness};
    end
    xlswrite(strFilenameXls, cellMatrix, strSheetName, 'D8');
    % XLSWRITE(FILE,ARRAY,SHEET,RANGE)
    atAgentMakespan_bf_ResReAlloc_hour
    nTotalCaseUnAllocate
    for ii = 1:1:nTotalCaseUnAllocate
        iTimeFrame_idxRes_nFreeRes = [astCaseUnUsedRes(ii).iTimeFrameWithFreeRes, astCaseUnUsedRes(ii).idxResFree, astCaseUnUsedRes(ii).nTotalFreeRes]
    end
end

%%%% Main Iteration
nMaxIter = stSystemMasterConfig.iTotalAgent;
iTer = 1;
iFlagHasFreeResource = 0;
%%% resolve confliction by priority
if nTotalCaseUnAllocate > 0
    iFlagHasFreeResource = 1;

    while iTer <= nMaxIter ... 
            & nTotalCaseUnAllocate >= 1
        iTer = iTer + 1;
%    for iTer = 1:1:2
        for qq = 1:1:stSystemMasterConfig.iTotalAgent
            iTimeFrameStartJobListPerAgent(qq) = ...
                stResAllocGenJspAgent.stAgentJobInfo(qq).tTimeAgentJobStart.aTimeIn24HourFormat(1) + 1;
            iTimeFrameDueTimePerAgent(qq) = ...
                stResAllocGenJspAgent.stAgentJobInfo(qq).tTimeAgentJobDue.aTimeIn24HourFormat(1) + 1;
            tStartTimePerAgent_datenum(qq) = ...
                datenum(stResAllocGenJspAgent.stAgentJobInfo(qq).atClockAgentJobStart.aClockYearMonthDateHourMinSec);
            fTimeSlot_inMin(qq) = stAgent_Solution(qq).stCostAtAgent.stSolutionMinCost.stSchedule.fTimeUnit_Min;
            tCompleteTimePerAgent_datenum(qq) = ...
                tStartTimePerAgent_datenum(qq) + ...
                datenum(stAgent_Solution(qq).stCostAtAgent.stSolutionMinCost.stSchedule.iMaxEndTime ...
                    * fTimeSlot_inMin(qq) / 60/24);
            iCompleteTimeFramePerAgent(qq) = ...
                ceil((tCompleteTimePerAgent_datenum(qq) - floor(tCompleteTimePerAgent_datenum(qq)))*24);
            bFlagAgentGetFreeRes(qq) = 0; %% initialize to be zero, 20080415, save half timing
        end

        for vv =1:1:nTotalCaseUnAllocate
            %%%%% Acording to each Free Resource instance
            %%% get the Id of the machine not-in-use, and total number
            %%% of Free Resource
            iTimeFrameWithFreeRes = astCaseUnUsedRes(vv).iTimeFrameWithFreeRes;
            idxResFree = astCaseUnUsedRes(vv).idxResFree;
            nTotalFreeRes = astCaseUnUsedRes(vv).nTotalFreeRes;
            fMaxWeight = 0;
            for qq = 1:1:stSystemMasterConfig.iTotalAgent
                if iTimeFrameWithFreeRes >= iTimeFrameStartJobListPerAgent(qq) & ...
                        iTimeFrameWithFreeRes <= iCompleteTimeFramePerAgent(qq)
                    iRelativePeriodInAgent(qq) = iTimeFrameWithFreeRes - iTimeFrameStartJobListPerAgent(qq) + 1;
                    fWeightPerAgent(qq) = stResAllocGenJspAgent.stAgentJobInfo(qq).fPriceAgentDollarPerFrame * ...
                        (stAgent_Solution(qq).stCostAtAgent.stSolutionMinCost.stSchedule.iMaxEndTime * ...
                          fTimeSlot_inMin(qq) / 60 /stSystemMasterConfig.fTimeFrameUnitInHour...
                        ) ...
                               + ...
                                    (stResAllocGenJspAgent.stAgentJobInfo(qq).fLatePenalty_DollarPerFrame * ...
                                      max(iCompleteTimeFramePerAgent(qq) - iTimeFrameDueTimePerAgent(qq), 0));
                    if fMaxWeight < fWeightPerAgent(qq)
                        fMaxWeight = fWeightPerAgent(qq);
                        idxAgentMaxWeight = qq;
                    end
                end
            end
            if stSystemMasterConfig.iPlotFlag >= 5 % 20091201
                fWeightPerAgent
            end
            bFlagAgentGetFreeRes(idxAgentMaxWeight) = 1;

            %%%%% Acording to each Free Resource instance
            %%% get the Id of the machine not-in-use, and total number
            %%% of Free Resource
            iTimeFrameWithFreeRes = astCaseUnUsedRes(vv).iTimeFrameWithFreeRes;
            idxResFree = astCaseUnUsedRes(vv).idxResFree;
            nTotalFreeRes = astCaseUnUsedRes(vv).nTotalFreeRes;
            idAgnt = idxAgentMaxWeight;

            if iRelativePeriodInAgent(idAgnt) <= ... % Protection
                length(stAgentResourceConfig(idAgnt).stMachineConfig(idxResFree).afMaCapAtTimePoint)
                stAgentResourceConfig(idAgnt).stMachineConfig(idxResFree).afMaCapAtTimePoint(iRelativePeriodInAgent(idAgnt)) = ...
                    stAgentResourceConfig(idAgnt).stMachineConfig(idxResFree).afMaCapAtTimePoint(iRelativePeriodInAgent(idAgnt)) ...
                         + nTotalFreeRes;
            end
            if stSystemMasterConfig.iPlotFlag >= 5 % 20091201
                if astCaseUnUsedRes(vv).iTimeFrameWithFreeRes == 11 & astCaseUnUsedRes(vv).idxResFree == 2
                    nTotalFreeRess_idAgent = [nTotalFreeRes, idAgnt]
                end
            end
        end % for vv =1:1:nTotalCaseUnAllocate
        if stSystemMasterConfig.iPlotFlag >= 4 % 20091201
            bFlagAgentGetFreeRes
        end

        %% generate schedule and performance report struct
        for aa = 1:1:stSystemMasterConfig.iTotalAgent
            if bFlagAgentGetFreeRes(aa) == 1
%                stAgent_Solution(aa).stMinCostResourceConfig = stAgentResourceConfig(aa);
                stJobListInfoAgent(aa).stResourceConfig = stAgentResourceConfig(aa);
                stJobListInfoAgent(aa).stJobListBiFsp.stResourceConfig = stAgentResourceConfig(aa);

                [stAgent_Solution_aa] = psa_gen_sch_perform_rpt_by_cfg(stResAllocGenJspAgent, ...
                    stResAllocGenJspAgent.stAgentJobInfo(aa), stJobListInfoAgent(aa));
                stAgent_Solution(aa).stMinCostResourceConfig = stAgent_Solution_aa.stMinCostResourceConfig;
                stAgent_Solution(aa).stPerformReport.tMinCostMakeSpan_hour         = stAgent_Solution_aa.stPerformReport.tMinCostMakeSpan_hour;
                stAgent_Solution(aa).stPerformReport.tMinCostGrossCraneRate        = stAgent_Solution_aa.stPerformReport.tMinCostGrossCraneRate;
                stAgent_Solution(aa).stPerformReport.fCostMakespanTardiness        = stAgent_Solution_aa.stPerformReport.fCostMakespanTardiness;
                stAgent_Solution(aa).stPerformReport.fMinCost                      = stAgent_Solution_aa.stPerformReport.fMinCost;
                stAgent_Solution(aa).stSchedule_MinCost                            = stAgent_Solution_aa.stSchedule_MinCost;
                stAgent_Solution(aa).stCostAtAgent.stSolutionMinCost.stSchedule    = stAgent_Solution(aa).stSchedule_MinCost;
            end
        end
        %%
        %% Build machine usage information for each Agent and for whole berth
        [stMachineUsageInfoSystem, stMachineUsageInfoByAgent] = ...
            psa_bidgen_build_bid_by_cfg(stResAllocGenJspAgent, stAgent_Solution);
        nTotalCaseUnAllocate = 0;
        astCaseUnUsedRes = [];
        iTotalFrame = ceil(24/stSystemMasterConfig.fTimeFrameUnitInHour);

        for mm = 1:1:stSystemMasterConfig.iTotalMachType
            if mm ~= stSystemMasterConfig.iCriticalMachType
                for tt = 1:1:iTotalFrame
                    [fValueLookup, iIndex] = calc_lut_max_between(stMachineUsageInfoSystem.astMachineUsage(mm).aMachineUsageAfterTime, stMachineUsageInfoSystem.astMachineUsage(mm).aSortedTime_inHour, ...
                        tt-1-epsilon_slot, tt-epsilon_slot);

                    stMachinePriceInfo.astMachineUsage(mm).aUsageAtFrame(tt) = fValueLookup;
                    stMachinePriceInfo.astMachineCapacity(mm).aCapacityAtFrame(tt) = ...
                        stMachineUsageInfoSystem.astMachineUsage(mm).iMaxCapacity;
                    stMachinePriceInfo.astMachineFreeRes(mm).aViolateAtFrame(tt) = ...
                        stMachinePriceInfo.astMachineUsage(mm).aUsageAtFrame(tt) - ...
                        stMachineUsageInfoSystem.astMachineUsage(mm).iMaxCapacity;
                    if stMachineUsageInfoSystem.astMachineUsageByPeriod(mm).aiFlagIsActiveFrame(tt) == 1
                        if stMachinePriceInfo.astMachineFreeRes(mm).aViolateAtFrame(tt) <= -1
                            nTotalCaseUnAllocate = nTotalCaseUnAllocate + 1;
                            astCaseUnUsedRes(nTotalCaseUnAllocate).iTimeFrameWithFreeRes = tt;
                            astCaseUnUsedRes(nTotalCaseUnAllocate).idxResFree = mm;
                            astCaseUnUsedRes(nTotalCaseUnAllocate).nTotalFreeRes = ...
                                - stMachinePriceInfo.astMachineFreeRes(mm).aViolateAtFrame(tt);
                        end
                    end
                end
            end
        end

        for qq = 1:1:stSystemMasterConfig.iTotalAgent
            stAgentResourceConfig(qq) = stAgent_Solution(qq).stMinCostResourceConfig;
        end
        stResourceConfigInfo.stAgentResourceConfig = stAgentResourceConfig;

        if stSystemMasterConfig.iPlotFlag >= 5 % 20091201
            for ii = 1:1:nTotalCaseUnAllocate
                if astCaseUnUsedRes(ii).iTimeFrameWithFreeRes == 11 & astCaseUnUsedRes(ii).idxResFree == 2
                    astCaseUnUsedRes(ii).nTotalFreeRes
                end
            end
        end

    end    % while
end    % if

%%%%%% Debug
if iFlagHasFreeResource == 1
    if stSystemMasterConfig.iPlotFlag >= 3 % 20091201
        for mm = 1:1:stSystemMasterConfig.iTotalMachType
            if mm ~= stSystemMasterConfig.iCriticalMachType
                for qq = 1:1:stSystemMasterConfig.iTotalAgent
                    stAgent_Solution(qq).stMinCostResourceConfig.stMachineConfig(mm).afMaCapAtTimePoint
                end
            end
        end
        atAgentMakespan_aft_ResReAlloc_hour = zeros(1, stSystemMasterConfig.iTotalAgent);
        for qq = 1:1:stSystemMasterConfig.iTotalAgent
            atAgentMakespan_aft_ResReAlloc_hour(1, qq) = stAgent_Solution(qq).stPerformReport.tMinCostMakeSpan_hour;
            tTotalPeriod = length(stAgent_Solution(qq).stMinCostResourceConfig.stMachineConfig(2).afMaCapAtTimePoint);
            for tt = 1:1:tTotalPeriod
                strText = sprintf('(%d, %d)', ...
                    stAgent_Solution(qq).stMinCostResourceConfig.stMachineConfig(2).afMaCapAtTimePoint(tt), ...
                    stAgent_Solution(qq).stMinCostResourceConfig.stMachineConfig(3).afMaCapAtTimePoint(tt));
                cellMatrixAfterReAlloc(qq, tt) = {strText};
            end
            cellMatrixAfterReAlloc(qq, tTotalPeriod+1) = {stAgent_Solution(qq).stPerformReport.tMinCostMakeSpan_hour};
            cellMatrixAfterReAlloc(qq, tTotalPeriod+2) = {stAgent_Solution(qq).stPerformReport.fCostMakespanTardiness};
        
        end
        atAgentMakespan_aft_ResReAlloc_hour
        
        strSheetName = sprintf('Iter%d', iTeration);
        xlswrite(strFilenameXls, cellMatrixAfterReAlloc, strSheetName, 'D18');
       
    end

    if stSystemMasterConfig.iPlotFlag >= 5 % 20091201
        [stMachineUsageInfoSystem, stMachineUsageInfoByAgent] = psa_bidgen_build_bid_by_cfg(stResAllocGenJspAgent, stAgent_Solution);
    end
    %%%update output
end

    iTeration = iTeration + 1;  % 20100128

stDebugOutput.stMachineUsageInfoSystem = stMachineUsageInfoSystem;
stDebugOutput.stMachineUsageInfoByAgent  = stMachineUsageInfoByAgent;
stDebugOutput.stResourceConfigInfo    = stResourceConfigInfo;
stDebugOutput.nTotalCaseUnAllocate     = nTotalCaseUnAllocate;
stDebugOutput.astCaseUnUsedRes        = astCaseUnUsedRes;
