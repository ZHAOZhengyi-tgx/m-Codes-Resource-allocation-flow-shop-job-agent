function [stAgent_Solution] = psa_bidgen_mp_srch_gensch3(stInputResAlloc)
%
%
% adaptive from psa_bidgen_multiperiod_srch.m
% use GenSch3
%     decending order of price
%     local search by gradient, exit if local minimum is found
%

%%% 
t_start = cputime;
iFlagSorting = 0;

%%%
iFlag_RunGenSch2             = stInputResAlloc.iFlag_RunGenSch2            ;
iQuayCrane_id                = stInputResAlloc.iQuayCrane_id               ;
stBerthJobInfo               = stInputResAlloc.stBerthJobInfo              ;
stAgentJobListBiFsp           = stInputResAlloc.stPortJobInfo_ii            ;
iMaxPrimeMoverUsageByGenSch0 = stInputResAlloc.iMaxPrimeMoverUsageByGenSch0;
iMaxYardCraneUsageByGenSch0  = stInputResAlloc.iMaxYardCraneUsageByGenSch0 ;
stResourceConfigGenSch0      = stInputResAlloc.stResourceConfigGenSch0_ii  ;

    %% based on GenSch0
stResourceConfig_Curr = stResourceConfigGenSch0.stResourceConfig;
if stBerthJobInfo.iAlgoChoice == 20
    %% based on basement resource
    for tt = 1:1:stResourceConfigGenSch0.stResourceConfig.stMachineConfig(2).iNumPointTimeCap
        stResourceConfig_Curr.stMachineConfig(2).afMaCapAtTimePoint(tt) = stAgentJobListBiFsp.MaxVirtualPrimeMover;
    end
    for tt = 1:1:stResourceConfigGenSch0.stResourceConfig.stMachineConfig(3).iNumPointTimeCap
        stResourceConfig_Curr.stMachineConfig(3).afMaCapAtTimePoint(tt) = stAgentJobListBiFsp.MaxVirtualYardCrane;
    end
end

atClockAgentJobStart     = stBerthJobInfo.atClockAgentJobStart(iQuayCrane_id);
tStartHour            = mod(atClockAgentJobStart.aClockYearMonthDateHourMinSec(4), 24);
iPriceHourStartIndex  = tStartHour + 1;
tMaxPeriodGenSch0     = stResourceConfigGenSch0.stResourceConfig.stMachineConfig(2).iNumPointTimeCap;
tMaxHalfPeriodGenSch0 = ceil(tMaxPeriodGenSch0/2);
fFactorHourPerSlot    = stAgentJobListBiFsp.fTimeUnit_Min/60 /stBerthJobInfo.fTimeFrameUnitInHour;

strFilenameDebug = sprintf('mp_srch_agent%d.txt', iQuayCrane_id);
fptr = fopen(strFilenameDebug, 'w');
fprintf(fptr, 'CaseId,  ResourcePM, ResourceYC,  MakeSpan, CostMakeSpan, CostResource, TotalCost\n');

if stBerthJobInfo.fTimeFrameUnitInHour ~= 1
    error('Currently unit of time period must be 1 hour');
end

%% loop for 2 iterations
iMaxIter = 2;
iter = 1;
iCaseSolution = 1;
while iter <= iMaxIter
    iTotalPeriod = stResourceConfig_Curr.stMachineConfig(2).iNumPointTimeCap;
    iPriceHourIndex = iPriceHourStartIndex;
    for tt = 1:1:iTotalPeriod
%        len_PricePrimeMover = length(stBerthJobInfo.fPricePrimeMoverDollarPerFrame)
        fPriceListPrimeMover(tt) = stBerthJobInfo.fPricePrimeMoverDollarPerFrame(iPriceHourIndex);
        fPriceListYardCrane(tt)  = stBerthJobInfo.fPriceYardCraneDollarPerFrame(iPriceHourIndex);
        if iPriceHourIndex == 24
            iPriceHourIndex = 0;
        end
        iPriceHourIndex = iPriceHourIndex + 1;
    end
    
    %%%% search Prime Mover first, by descending order
    %%% three options
    iSortIndexPricePM = 1:1:length(fPriceListPrimeMover);
    if iFlagSorting == 1
        [fSortedPriceListPrimeMover, iSortIndexPricePM] = sort(fPriceListPrimeMover);
    elseif iFlagSorting == -1
        [fSortedPriceListPrimeMover, iSortIndexPricePM] = sort(-fPriceListPrimeMover);
    end

    %% loop for all time frame
    stAgentJobListBiFsp.stResourceConfig = stResourceConfig_Curr;
    for ii = 1:1:iTotalPeriod
        tActualPeriod = iSortIndexPricePM(ii);
        if tActualPeriod <= tMaxHalfPeriodGenSch0
            kMaxPrimeMoverSearchMP = stResourceConfigGenSch0.stResourceConfig.stMachineConfig(2).afMaCapAtTimePoint(tActualPeriod);
        else
            kMaxPrimeMoverSearchMP = stBerthJobInfo.iTotalPrimeMover;
        end
        
        %%% starting number of Prime Mover
        stAgentJobListBiFsp.stResourceConfig.stMachineConfig(2).afMaCapAtTimePoint(tActualPeriod) = ...
            stAgentJobListBiFsp.MaxVirtualPrimeMover;
        numPrimeMover_MinCost_At_tActualPeriod = stAgentJobListBiFsp.stResourceConfig.stMachineConfig(2).afMaCapAtTimePoint(tActualPeriod);
        %%%%% recalculate the makespan and cost
        stSolution.astCase(iCaseSolution).stResourceConfig = stAgentJobListBiFsp.stResourceConfig;
        
        stGetSchduleCostInput.stAgentJobListBiFsp = stAgentJobListBiFsp;
        stGetSchduleCostInput.stBerthJobInfo     = stBerthJobInfo;
        stGetSchduleCostInput.fFactorHourPerSlot = fFactorHourPerSlot;
        stGetSchduleCostInput.iPriceHourStartIndex = iPriceHourStartIndex;
        stGetSchduleCostInput.iTotalPeriod         = iTotalPeriod;
        [stGetSchduleCostOutput] = fsp_get_sched_cost_by_agent(stGetSchduleCostInput);
        
        stSolution.aMakeSpan_hour(iCaseSolution) = stGetSchduleCostOutput.tMakeSpan_hour;
        stSolution.astCase(iCaseSolution).stContainerSchedule = stGetSchduleCostOutput.stContainerSchedule;
        
        [fTardinessFine_Sgd, tAgentTardiness_hour] = resalloc_calc_tardi_fine(stBerthJobInfo, iQuayCrane_id, stSolution.aMakeSpan_hour(iCaseSolution));
        stSolution.aTardiness_hour(iCaseSolution) = tAgentTardiness_hour;
        stSolution.aCostTardinessMakespan(iCaseSolution) = ...
            stSolution.aMakeSpan_hour(iCaseSolution) * stBerthJobInfo.fPriceQuayCraneDollarPerFrame(iQuayCrane_id) + ...
            fTardinessFine_Sgd;
        stSolution.aTotalCost(iCaseSolution) = stSolution.aCostTardinessMakespan(iCaseSolution) + ...
            stGetSchduleCostOutput.fCostPMYC;
        
        fsp_dbg_write_file(fptr, stSolution, iCaseSolution);
        iCaseSolution = iCaseSolution + 1;
        
        
        while stAgentJobListBiFsp.stResourceConfig.stMachineConfig(2).afMaCapAtTimePoint(tActualPeriod) ...
                < kMaxPrimeMoverSearchMP
            stAgentJobListBiFsp.stResourceConfig.stMachineConfig(2).afMaCapAtTimePoint(tActualPeriod) = ...
                stAgentJobListBiFsp.stResourceConfig.stMachineConfig(2).afMaCapAtTimePoint(tActualPeriod) + 1;

            %%%%% recalculate the makespan and cost
            stSolution.astCase(iCaseSolution).stResourceConfig = stAgentJobListBiFsp.stResourceConfig;

            stGetSchduleCostInput.stAgentJobListBiFsp = stAgentJobListBiFsp;
            stGetSchduleCostInput.stBerthJobInfo     = stBerthJobInfo;
            stGetSchduleCostInput.fFactorHourPerSlot = fFactorHourPerSlot;
            stGetSchduleCostInput.iPriceHourStartIndex = iPriceHourStartIndex;
            stGetSchduleCostInput.iTotalPeriod         = iTotalPeriod;
            [stGetSchduleCostOutput] = fsp_get_sched_cost_by_agent(stGetSchduleCostInput);

            stSolution.aMakeSpan_hour(iCaseSolution) = stGetSchduleCostOutput.tMakeSpan_hour;
            stSolution.astCase(iCaseSolution).stContainerSchedule = stGetSchduleCostOutput.stContainerSchedule;

            [fTardinessFine_Sgd, tAgentTardiness_hour] = resalloc_calc_tardi_fine(stBerthJobInfo, iQuayCrane_id, stSolution.aMakeSpan_hour(iCaseSolution));
            stSolution.aTardiness_hour(iCaseSolution) = tAgentTardiness_hour;
            stSolution.aCostTardinessMakespan(iCaseSolution) = ...
                stSolution.aMakeSpan_hour(iCaseSolution) * stBerthJobInfo.fPriceQuayCraneDollarPerFrame(iQuayCrane_id) + ...
                fTardinessFine_Sgd;
            stSolution.aTotalCost(iCaseSolution) = stSolution.aCostTardinessMakespan(iCaseSolution) + ...
                stGetSchduleCostOutput.fCostPMYC;
            
            if stSolution.aMakeSpan_hour(iCaseSolution) < stSolution.aMakeSpan_hour(iCaseSolution - 1)
                if stSolution.aTotalCost(iCaseSolution) < stSolution.aTotalCost(iCaseSolution-1)
                    numPrimeMover_MinCost_At_tActualPeriod = stAgentJobListBiFsp.stResourceConfig.stMachineConfig(2).afMaCapAtTimePoint(tActualPeriod);
                end
                fsp_dbg_write_file(fptr, stSolution, iCaseSolution);
                iCaseSolution = iCaseSolution + 1;
                
                %%% Gradient detect whether a local minimum has be detected
%                [fSortedTotalCost, iSortedIndex] = sort(stSolution.aTotalCost);
%                if iSortedIndex(1) ~= 1 | iSortedIndex(1) ~= length(stSolution.aTotalCost)
%                    break;
%                end

            else
                break;
            end
            %%%%%%%%%
        end
        [fMinCost, iIndexMinCost] = min(stSolution.aTotalCost);
         stAgentJobListBiFsp.stResourceConfig.stMachineConfig(2).afMaCapAtTimePoint(tActualPeriod) = ...
             numPrimeMover_MinCost_At_tActualPeriod;
    end
    
    %%%% update stResourceConfig_Curr and iTotalPeriod
    stResourceConfig_Curr = stSolution.astCase(iIndexMinCost).stResourceConfig;
    iTotalPeriod = stResourceConfig_Curr.stMachineConfig(2).iNumPointTimeCap;
    iPriceHourIndex = iPriceHourStartIndex;
    for tt = 1:1:iTotalPeriod
        fPriceListPrimeMover(tt) = stBerthJobInfo.fPricePrimeMoverDollarPerFrame(iPriceHourIndex);
        fPriceListYardCrane(tt)  = stBerthJobInfo.fPriceYardCraneDollarPerFrame(iPriceHourIndex);
        if iPriceHourIndex == 24
            iPriceHourIndex = 0;
        end
        iPriceHourIndex = iPriceHourIndex + 1;
    end
    
    %%%% Then search Yard Crane, 
    %%%% 1: ascending order
    %%%% -1: descending order
    %%%% else, 0: not sorting
    %%%% by descending order
    iSortIndexPriceYardCrane = 1:1:length(fPriceListYardCrane);
    if iFlagSorting == 1
        [fSortedPriceListYardCrane, iSortIndexPriceYardCrane] = sort(fPriceListYardCrane);
    elseif iFlagSorting == -1
        [fSortedPriceListYardCrane, iSortIndexPriceYardCrane] = sort(-fPriceListYardCrane);
    end

    %% loop for all time frame
    stAgentJobListBiFsp.stResourceConfig = stResourceConfig_Curr;
    for ii = 1:1:iTotalPeriod
        tActualPeriod = iSortIndexPriceYardCrane(ii);
        if tActualPeriod <= tMaxHalfPeriodGenSch0
            kMaxYardCraneSearchMP = stResourceConfigGenSch0.stResourceConfig.stMachineConfig(3).afMaCapAtTimePoint(tActualPeriod);
        else
            kMaxYardCraneSearchMP = stBerthJobInfo.iTotalYardCrane;
        end
        
        %%% starting number of Prime Mover
        stAgentJobListBiFsp.stResourceConfig.stMachineConfig(3).afMaCapAtTimePoint(tActualPeriod) = ...
            stAgentJobListBiFsp.MaxVirtualYardCrane;
        numYardCrane_MinCost_At_tActualPeriod = stAgentJobListBiFsp.stResourceConfig.stMachineConfig(3).afMaCapAtTimePoint(tActualPeriod);
        %%%%% recalculate the makespan and cost
        stSolution.astCase(iCaseSolution).stResourceConfig = stAgentJobListBiFsp.stResourceConfig;
        
        stGetSchduleCostInput.stAgentJobListBiFsp = stAgentJobListBiFsp;
        stGetSchduleCostInput.stBerthJobInfo     = stBerthJobInfo;
        stGetSchduleCostInput.fFactorHourPerSlot = fFactorHourPerSlot;
        stGetSchduleCostInput.iPriceHourStartIndex = iPriceHourStartIndex;
        stGetSchduleCostInput.iTotalPeriod         = iTotalPeriod;
        [stGetSchduleCostOutput] = fsp_get_sched_cost_by_agent(stGetSchduleCostInput);
        
        stSolution.aMakeSpan_hour(iCaseSolution) = stGetSchduleCostOutput.tMakeSpan_hour;
        stSolution.astCase(iCaseSolution).stContainerSchedule = stGetSchduleCostOutput.stContainerSchedule;
        
        [fTardinessFine_Sgd, tAgentTardiness_hour] = resalloc_calc_tardi_fine(stBerthJobInfo, iQuayCrane_id, stSolution.aMakeSpan_hour(iCaseSolution));
        stSolution.aTardiness_hour(iCaseSolution) = tAgentTardiness_hour;
        stSolution.aCostTardinessMakespan(iCaseSolution) = ...
            stSolution.aMakeSpan_hour(iCaseSolution) * stBerthJobInfo.fPriceQuayCraneDollarPerFrame(iQuayCrane_id) + ...
            fTardinessFine_Sgd;
        stSolution.aTotalCost(iCaseSolution) = stSolution.aCostTardinessMakespan(iCaseSolution) + ...
            stGetSchduleCostOutput.fCostPMYC;
        
        fsp_dbg_write_file(fptr, stSolution, iCaseSolution);
        iCaseSolution = iCaseSolution + 1;
        
        
        while stAgentJobListBiFsp.stResourceConfig.stMachineConfig(3).afMaCapAtTimePoint(tActualPeriod) ...
                < kMaxYardCraneSearchMP
            stAgentJobListBiFsp.stResourceConfig.stMachineConfig(3).afMaCapAtTimePoint(tActualPeriod) = ...
                stAgentJobListBiFsp.stResourceConfig.stMachineConfig(3).afMaCapAtTimePoint(tActualPeriod) + 1;

            %%%%% recalculate the makespan and cost
            stSolution.astCase(iCaseSolution).stResourceConfig = stAgentJobListBiFsp.stResourceConfig;

            stGetSchduleCostInput.stAgentJobListBiFsp = stAgentJobListBiFsp;
            stGetSchduleCostInput.stBerthJobInfo     = stBerthJobInfo;
            stGetSchduleCostInput.fFactorHourPerSlot = fFactorHourPerSlot;
            stGetSchduleCostInput.iPriceHourStartIndex = iPriceHourStartIndex;
            stGetSchduleCostInput.iTotalPeriod         = iTotalPeriod;
            [stGetSchduleCostOutput] = fsp_get_sched_cost_by_agent(stGetSchduleCostInput);

            stSolution.aMakeSpan_hour(iCaseSolution) = stGetSchduleCostOutput.tMakeSpan_hour;
            stSolution.astCase(iCaseSolution).stContainerSchedule = stGetSchduleCostOutput.stContainerSchedule;

            [fTardinessFine_Sgd, tAgentTardiness_hour] = resalloc_calc_tardi_fine(stBerthJobInfo, iQuayCrane_id, stSolution.aMakeSpan_hour(iCaseSolution));
            stSolution.aTardiness_hour(iCaseSolution) = tAgentTardiness_hour;
            stSolution.aCostTardinessMakespan(iCaseSolution) = ...
                stSolution.aMakeSpan_hour(iCaseSolution) * stBerthJobInfo.fPriceQuayCraneDollarPerFrame(iQuayCrane_id) + ...
                fTardinessFine_Sgd;
            stSolution.aTotalCost(iCaseSolution) = stSolution.aCostTardinessMakespan(iCaseSolution) + ...
                stGetSchduleCostOutput.fCostPMYC;
            
            if stSolution.aMakeSpan_hour(iCaseSolution) < stSolution.aMakeSpan_hour(iCaseSolution - 1)
                if stSolution.aTotalCost(iCaseSolution) < stSolution.aTotalCost(iCaseSolution-1)
                    numYardCrane_MinCost_At_tActualPeriod = stAgentJobListBiFsp.stResourceConfig.stMachineConfig(2).afMaCapAtTimePoint(tActualPeriod);
                end
                fsp_dbg_write_file(fptr, stSolution, iCaseSolution);
                iCaseSolution = iCaseSolution + 1;
            else
                break;
            end
                %%% Gradient detect whether a local minimum has be detected
%                [fSortedTotalCost, iSortedIndex] = sort(stSolution.aTotalCost);
%                if iSortedIndex(1) ~= 1 | iSortedIndex(1) ~= length(stSolution.aTotalCost)
%                    break;
%                end


        end
        [fMinCost, iIndexMinCost] = min(stSolution.aTotalCost);
         stAgentJobListBiFsp.stResourceConfig.stMachineConfig(3).afMaCapAtTimePoint(tActualPeriod) = ...
             numYardCrane_MinCost_At_tActualPeriod;
    end
    
    stResourceConfig_Curr = stSolution.astCase(iIndexMinCost).stResourceConfig;
    
    iter = iter + 1
end

%%%%% dispatching
if iFlag_RunGenSch2 == 1
    [stBuildMachConfigOutput] = psa_fsp_bld_machfig_by_sch ...
                (stBerthJobInfo.fTimeFrameUnitInHour, stAgentJobListBiFsp.stResourceConfig, stSolution.astCase(iIndexMinCost).stContainerSchedule);
    stAgentJobListBiFsp.stResourceConfig = stBuildMachConfigOutput.stResourceConfigSchOut.stResourceConfig;
    [stPartialScheduleGenSch2, jobshop_config] = psa_jsp_gen_job_schedule_28(stAgentJobListBiFsp);
else
    stPartialScheduleGenSch2 = stSolution.astCase(iIndexMinCost).stContainerSchedule;
end

fprintf(fptr, '\n\n%%%% Min Cost Schedule\n');
fsp_dbg_write_file(fptr, stSolution, iIndexMinCost);

stPartialScheduleGenSch2.iTotalMachineNum(2) = max(stAgentJobListBiFsp.stResourceConfig.stMachineConfig(2).afMaCapAtTimePoint);
stPartialScheduleGenSch2.iTotalMachineNum(3) = max(stAgentJobListBiFsp.stResourceConfig.stMachineConfig(3).afMaCapAtTimePoint);
[stSchedule, stSpecificMachineTimeInfo] = psa_jsp_dispatch_machine_02(stPartialScheduleGenSch2);
stSolution.stCostAtAgent.stSolutionMinCost.stSchedule = stSchedule;
[stBuildMachConfigOutput] = psa_fsp_bld_machfig_by_sch ...
    (stBerthJobInfo.fTimeFrameUnitInHour, stAgentJobListBiFsp.stResourceConfig, stSolution.stCostAtAgent.stSolutionMinCost.stSchedule);
stAgentJobListBiFsp.stResourceConfig = stBuildMachConfigOutput.stResourceConfigSchOut.stResourceConfig;

%%%% MakeSpan and Tardiness
tMinCostMakeSpan_hour = stSolution.stCostAtAgent.stSolutionMinCost.stSchedule.iMaxEndTime * fFactorHourPerSlot;
[fTardinessFineMinCost_Sgd, tAgentTardiness_hour] = resalloc_calc_tardi_fine(stBerthJobInfo, iQuayCrane_id, tMinCostMakeSpan_hour);

%%%% Resource Cost
iTotalPeriod_act = ceil(tMinCostMakeSpan_hour);
iPriceHourIndex = iPriceHourStartIndex;
fCostPMYC = 0;
for tt = 1:1:iTotalPeriod_act
    if tt > iTotalPeriod
        kUsagePM = stAgentJobListBiFsp.stResourceConfig.stMachineConfig(2).afMaCapAtTimePoint(iTotalPeriod);
        kUsageYC = stAgentJobListBiFsp.stResourceConfig.stMachineConfig(3).afMaCapAtTimePoint(iTotalPeriod);
    else
        kUsagePM = stAgentJobListBiFsp.stResourceConfig.stMachineConfig(2).afMaCapAtTimePoint(tt);
        kUsageYC = stAgentJobListBiFsp.stResourceConfig.stMachineConfig(3).afMaCapAtTimePoint(tt);
    end
    fCostPMYC = fCostPMYC + stBerthJobInfo.fPricePrimeMoverDollarPerFrame(iPriceHourIndex) * max([0, kUsagePM - stAgentJobListBiFsp.MaxVirtualPrimeMover]) + ...
        stBerthJobInfo.fPriceYardCraneDollarPerFrame(iPriceHourIndex) * max([0, kUsageYC - stAgentJobListBiFsp.MaxVirtualYardCrane]);
    if iPriceHourIndex == 24
        iPriceHourIndex = 0;
    end
    iPriceHourIndex = iPriceHourIndex + 1;
end

%%%%% Timing
fclose(fptr);

tSolution_sec = cputime - t_start;

%%%%% Output
stAgent_Solution = stSolution;
stAgent_Solution.stMinCostResourceConfig = stBuildMachConfigOutput.stResourceConfigSchOut.stResourceConfig;

stAgent_Solution.stPerformReport.tMinCostMakeSpan_hour = tMinCostMakeSpan_hour;
stAgent_Solution.stPerformReport.tMinCostGrossCraneRate = (stAgentJobListBiFsp.TotalContainer_Load + stAgentJobListBiFsp.TotalContainer_Discharge)/ stAgent_Solution.stPerformReport.tMinCostMakeSpan_hour;
stAgent_Solution.stPerformReport.fCostMakespanTardiness = tMinCostMakeSpan_hour * stBerthJobInfo.fPriceQuayCraneDollarPerFrame(iQuayCrane_id) + fTardinessFineMinCost_Sgd;

stAgent_Solution.stPerformReport.fMinCost              = fCostPMYC  + ...
                                                      stAgent_Solution.stPerformReport.fCostMakespanTardiness;
stAgent_Solution.stPerformReport.tSolutionTime_sec = tSolution_sec;
