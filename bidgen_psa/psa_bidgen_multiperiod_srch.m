function [stAgent_Solution] = psa_bidgen_multiperiod_srch(stInputResAlloc)
%
%
%

%%% 
t_start = cputime;

%%%
iQuayCrane_id                = stInputResAlloc.iQuayCrane_id               ;
stBerthJobInfo               = stInputResAlloc.stBerthJobInfo              ;
stAgentJobListBiFsp           = stInputResAlloc.stJobListInfoAgent_ii          ;
iMaxPrimeMoverUsageByGenSch0 = stInputResAlloc.iMaxPrimeMoverUsageByGenSch0;
iMaxYardCraneUsageByGenSch0  = stInputResAlloc.iMaxYardCraneUsageByGenSch0 ;
stResourceConfigGenSch0      = stInputResAlloc.stResourceConfigGenSch0_ii  ;

stResourceConfig_Curr = stResourceConfigGenSch0.stResourceConfig;
atClockAgentJobStart     = stBerthJobInfo.atClockAgentJobStart(iQuayCrane_id);
tStartHour            = mod(atClockAgentJobStart.aClockYearMonthDateHourMinSec(4), 24);
iPriceHourStartIndex  = tStartHour + 1;
tMaxPeriodGenSch0     = stResourceConfigGenSch0.stResourceConfig.stMachineConfig(2).iNumPointTimeCap;
tMaxHalfPeriodGenSch0 = ceil(tMaxPeriodGenSch0/2);
fFactorHourPerSlot    = stAgentJobListBiFsp.fTimeUnit_Min/60 /stBerthJobInfo.fTimeFrameUnitInHour;

if stBerthJobInfo.fTimeFrameUnitInHour ~= 1
    error('Currently unit of time period must be 1 hour');
end

%% loop for 2 iterations
iMaxIter = 2;
iter = 1;
iCaseSolution = 1;
while iter <= iMaxIter
    iTotalPeriod = stResourceConfig_Curr.stMachineConfig(2).iNumPointTimeCap;
    iPriceHourIndex = iPriceHourStartIndex
    for tt = 1:1:iTotalPeriod
        fPriceListPrimeMover(tt) = stBerthJobInfo.fPricePrimeMoverDollarPerFrame(iPriceHourIndex);
        fPriceListYardCrane(tt)  = stBerthJobInfo.fPriceYardCraneDollarPerFrame(iPriceHourIndex);
        if iPriceHourIndex == 24
            iPriceHourIndex = 0;
        end
        iPriceHourIndex = iPriceHourIndex + 1;
    end
    
    %%%% search Prime Mover first
    [fSortedPriceListPrimeMover, iSortIndexPricePM] = sort(fPriceListPrimeMover);
    %% loop for all time frame
    stAgentJobListBiFsp.stResourceConfig = stResourceConfig_Curr;
    for ii = 1:1:iTotalPeriod
        tActualPeriod = iSortIndexPricePM(ii);
        if tActualPeriod <= tMaxHalfPeriodGenSch0
            kMaxPrimeMoverSearchMP = stResourceConfig_Curr.stMachineConfig(2).afMaCapAtTimePoint(tActualPeriod);
        else
            kMaxPrimeMoverSearchMP = stBerthJobInfo.iTotalPrimeMover;
        end
        
        %%% starting number of Prime Mover
        stAgentJobListBiFsp.stResourceConfig.stMachineConfig(2).afMaCapAtTimePoint(tActualPeriod) = ...
            stAgentJobListBiFsp.MaxVirtualPrimeMover;
        numPrimeMover_MinCost_At_tActualPeriod = stAgentJobListBiFsp.stResourceConfig.stMachineConfig(2).afMaCapAtTimePoint(tActualPeriod);
        [container_sequence_jsp, jobshop_config] = psa_jsp_gen_job_schedule_28(stAgentJobListBiFsp);
        
        stSolution.astCase(iCaseSolution).stResourceConfig = stAgentJobListBiFsp.stResourceConfig;
        stSolution.astCase(iCaseSolution).stContainerSchedule = container_sequence_jsp;
        stSolution.aMakeSpan_hour(iCaseSolution) = container_sequence_jsp.iMaxEndTime * fFactorHourPerSlot;
        [fTardinessFine_Sgd, tAgentTardiness_hour] = resalloc_calc_tardi_fine(stBerthJobInfo, iQuayCrane_id, stSolution.aMakeSpan_hour(iCaseSolution));
        stSolution.aTardiness_hour(iCaseSolution) = tAgentTardiness_hour;
        %%% adjusting price vector length, 
        %%% and calculate ResourceCost = fCostPMYC
        iTotalPeriod_act = ceil(stSolution.aMakeSpan_hour(iCaseSolution));
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
            fCostPMYC = fCostPMYC + stBerthJobInfo.fPricePrimeMoverDollarPerFrame(iPriceHourIndex) * kUsagePM + ...
                                    stBerthJobInfo.fPriceYardCraneDollarPerFrame(iPriceHourIndex) * kUsageYC;
            if iPriceHourIndex == 24
                iPriceHourIndex = 0;
            end
            iPriceHourIndex = iPriceHourIndex + 1;
        end
         
        stSolution.aCostTardinessMakespan(iCaseSolution) = ...
            stSolution.aMakeSpan_hour(iCaseSolution) * stBerthJobInfo.fPriceQuayCraneDollarPerFrame(iQuayCrane_id) + ...
            fTardinessFine_Sgd;
        
        stSolution.aTotalCost(iCaseSolution) = stSolution.aCostTardinessMakespan(iCaseSolution) + ...
            fCostPMYC;
        iCaseSolution = iCaseSolution + 1;
        
        
        while stAgentJobListBiFsp.stResourceConfig.stMachineConfig(2).afMaCapAtTimePoint(tActualPeriod) ...
                < kMaxPrimeMoverSearchMP
            stAgentJobListBiFsp.stResourceConfig.stMachineConfig(2).afMaCapAtTimePoint(tActualPeriod) = ...
                stAgentJobListBiFsp.stResourceConfig.stMachineConfig(2).afMaCapAtTimePoint(tActualPeriod) + 1;

            %%%%% recalculate the makespan and cost
            [container_sequence_jsp, jobshop_config] = psa_jsp_gen_job_schedule_28(stAgentJobListBiFsp);
            stSolution.astCase(iCaseSolution).stResourceConfig = stAgentJobListBiFsp.stResourceConfig;
            stSolution.astCase(iCaseSolution).stContainerSchedule = container_sequence_jsp;
            stSolution.aMakeSpan_hour(iCaseSolution) = container_sequence_jsp.iMaxEndTime * fFactorHourPerSlot;
            [fTardinessFine_Sgd, tAgentTardiness_hour] = resalloc_calc_tardi_fine(stBerthJobInfo, iQuayCrane_id, stSolution.aMakeSpan_hour(iCaseSolution));
            stSolution.aTardiness_hour(iCaseSolution) = tAgentTardiness_hour;
            %%% adjusting price vector length, 
            %%% and calculate ResourceCost = fCostPMYC
            iTotalPeriod_act = ceil(stSolution.aMakeSpan_hour(iCaseSolution));
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
                fCostPMYC = fCostPMYC + stBerthJobInfo.fPricePrimeMoverDollarPerFrame(iPriceHourIndex) * kUsagePM + ...
                                        stBerthJobInfo.fPriceYardCraneDollarPerFrame(iPriceHourIndex) * kUsageYC;
                if iPriceHourIndex == 24
                    iPriceHourIndex = 0;
                end
                iPriceHourIndex = iPriceHourIndex + 1;
            end

            %%%%%%%% iCaseSolution updating must in the same block
            stSolution.aCostTardinessMakespan(iCaseSolution) = ...
                stSolution.aMakeSpan_hour(iCaseSolution) * stBerthJobInfo.fPriceQuayCraneDollarPerFrame(iQuayCrane_id) + ...
                fTardinessFine_Sgd;

            stSolution.aTotalCost(iCaseSolution) = stSolution.aCostTardinessMakespan(iCaseSolution) + ...
                fCostPMYC;
            
            if stSolution.aMakeSpan_hour(iCaseSolution) < stSolution.aMakeSpan_hour(iCaseSolution - 1)
                if stSolution.aTotalCost(iCaseSolution) < stSolution.aTotalCost(iCaseSolution-1)
                    numPrimeMover_MinCost_At_tActualPeriod = stAgentJobListBiFsp.stResourceConfig.stMachineConfig(2).afMaCapAtTimePoint(tActualPeriod);
                end
                iCaseSolution = iCaseSolution + 1;
            else
                break;
            end
            
            %%%%%%%%%
        end
        [fMinCost, iIndexMinCost] = min(stSolution.aTotalCost)
         stAgentJobListBiFsp.stResourceConfig.stMachineConfig(2).afMaCapAtTimePoint(tActualPeriod) = ...
             numPrimeMover_MinCost_At_tActualPeriod;
    end
    
    %%%% update stResourceConfig_Curr and iTotalPeriod
    stResourceConfig_Curr = stSolution.astCase(iIndexMinCost).stResourceConfig;
    iTotalPeriod = stResourceConfig_Curr.stMachineConfig(2).iNumPointTimeCap;
    iPriceHourIndex = iPriceHourStartIndex
    for tt = 1:1:iTotalPeriod
        fPriceListPrimeMover(tt) = stBerthJobInfo.fPricePrimeMoverDollarPerFrame(iPriceHourIndex);
        fPriceListYardCrane(tt)  = stBerthJobInfo.fPriceYardCraneDollarPerFrame(iPriceHourIndex);
        if iPriceHourIndex == 24
            iPriceHourIndex = 0;
        end
        iPriceHourIndex = iPriceHourIndex + 1;
    end
    
    %%%% Then search Yard Crane
    [fSortedPriceListPrimeMover, iSortIndexPricePM] = sort(fPriceListYardCrane);
    %% loop for all time frame
    stAgentJobListBiFsp.stResourceConfig = stResourceConfig_Curr;
    for ii = 1:1:iTotalPeriod
        tActualPeriod = iSortIndexPricePM(ii);
        if tActualPeriod <= tMaxHalfPeriodGenSch0
            kMaxYardCraneSearchMP = stResourceConfig_Curr.stMachineConfig(3).afMaCapAtTimePoint(tActualPeriod);
        else
            kMaxYardCraneSearchMP = stBerthJobInfo.iTotalYardCrane;
        end
        
        %%% starting number of Prime Mover
        stAgentJobListBiFsp.stResourceConfig.stMachineConfig(3).afMaCapAtTimePoint(tActualPeriod) = ...
            stAgentJobListBiFsp.MaxVirtualYardCrane;
        numYardCrane_MinCost_At_tActualPeriod = stAgentJobListBiFsp.stResourceConfig.stMachineConfig(3).afMaCapAtTimePoint(tActualPeriod);
        [container_sequence_jsp, jobshop_config] = psa_jsp_gen_job_schedule_28(stAgentJobListBiFsp);
        
        stSolution.astCase(iCaseSolution).stResourceConfig = stAgentJobListBiFsp.stResourceConfig;
        stSolution.astCase(iCaseSolution).stContainerSchedule = container_sequence_jsp;
        stSolution.aMakeSpan_hour(iCaseSolution) = container_sequence_jsp.iMaxEndTime * fFactorHourPerSlot;
        [fTardinessFine_Sgd, tAgentTardiness_hour] = resalloc_calc_tardi_fine(stBerthJobInfo, iQuayCrane_id, stSolution.aMakeSpan_hour(iCaseSolution));
        stSolution.aTardiness_hour(iCaseSolution) = tAgentTardiness_hour;
        %%% adjusting price vector length, 
        %%% and calculate ResourceCost = fCostPMYC
        iTotalPeriod_act = ceil(stSolution.aMakeSpan_hour(iCaseSolution));
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
            fCostPMYC = fCostPMYC + stBerthJobInfo.fPricePrimeMoverDollarPerFrame(iPriceHourIndex) * kUsagePM + ...
                                    stBerthJobInfo.fPriceYardCraneDollarPerFrame(iPriceHourIndex) * kUsageYC;
            if iPriceHourIndex == 24
                iPriceHourIndex = 0;
            end
            iPriceHourIndex = iPriceHourIndex + 1;
        end
        stSolution.aCostTardinessMakespan(iCaseSolution) = ...
            stSolution.aMakeSpan_hour(iCaseSolution) * stBerthJobInfo.fPriceQuayCraneDollarPerFrame(iQuayCrane_id) + ...
            fTardinessFine_Sgd;
        
        stSolution.aTotalCost(iCaseSolution) = stSolution.aCostTardinessMakespan(iCaseSolution) + ...
            fCostPMYC;
        iCaseSolution = iCaseSolution + 1;
        
        
        while stAgentJobListBiFsp.stResourceConfig.stMachineConfig(3).afMaCapAtTimePoint(tActualPeriod) ...
                < kMaxYardCraneSearchMP
            stAgentJobListBiFsp.stResourceConfig.stMachineConfig(3).afMaCapAtTimePoint(tActualPeriod) = ...
                stAgentJobListBiFsp.stResourceConfig.stMachineConfig(3).afMaCapAtTimePoint(tActualPeriod) + 1;

            %%%%% recalculate the makespan and cost
            [container_sequence_jsp, jobshop_config] = psa_jsp_gen_job_schedule_28(stAgentJobListBiFsp);
            stSolution.astCase(iCaseSolution).stResourceConfig = stAgentJobListBiFsp.stResourceConfig;
            stSolution.astCase(iCaseSolution).stContainerSchedule = container_sequence_jsp;
            stSolution.aMakeSpan_hour(iCaseSolution) = container_sequence_jsp.iMaxEndTime * fFactorHourPerSlot;
            [fTardinessFine_Sgd, tAgentTardiness_hour] = resalloc_calc_tardi_fine(stBerthJobInfo, iQuayCrane_id, stSolution.aMakeSpan_hour(iCaseSolution));
            stSolution.aTardiness_hour(iCaseSolution) = tAgentTardiness_hour;
            %%% adjusting price vector length, 
            %%% and calculate ResourceCost = fCostPMYC
            iTotalPeriod_act = ceil(stSolution.aMakeSpan_hour(iCaseSolution));
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
                fCostPMYC = fCostPMYC + stBerthJobInfo.fPricePrimeMoverDollarPerFrame(iPriceHourIndex) * kUsagePM + ...
                                        stBerthJobInfo.fPriceYardCraneDollarPerFrame(iPriceHourIndex) * kUsageYC;
                if iPriceHourIndex == 24
                    iPriceHourIndex = 0;
                end
                iPriceHourIndex = iPriceHourIndex + 1;
            end

            stSolution.aCostTardinessMakespan(iCaseSolution) = ...
                stSolution.aMakeSpan_hour(iCaseSolution) * stBerthJobInfo.fPriceQuayCraneDollarPerFrame(iQuayCrane_id) + ...
                fTardinessFine_Sgd;

            stSolution.aTotalCost(iCaseSolution) = stSolution.aCostTardinessMakespan(iCaseSolution) + ...
                fCostPMYC;
            
            if stSolution.aMakeSpan_hour(iCaseSolution) < stSolution.aMakeSpan_hour(iCaseSolution - 1)
                if stSolution.aTotalCost(iCaseSolution) < stSolution.aTotalCost(iCaseSolution-1)
                    numYardCrane_MinCost_At_tActualPeriod = stAgentJobListBiFsp.stResourceConfig.stMachineConfig(2).afMaCapAtTimePoint(tActualPeriod);
                end
                iCaseSolution = iCaseSolution + 1;
            else
                break;
            end
        end
        [fMinCost, iIndexMinCost] = min(stSolution.aTotalCost)
         stAgentJobListBiFsp.stResourceConfig.stMachineConfig(3).afMaCapAtTimePoint(tActualPeriod) = ...
             numYardCrane_MinCost_At_tActualPeriod;
    end
    
    stResourceConfig_Curr = stSolution.astCase(iIndexMinCost).stResourceConfig;
    
    iter = iter + 1
end

%%%%% dispatching
stSolution.astCase(iIndexMinCost).stContainerSchedule.iTotalMachineNum(2) = max(stResourceConfig_Curr.stMachineConfig(2).afMaCapAtTimePoint);
stSolution.astCase(iIndexMinCost).stContainerSchedule.iTotalMachineNum(3) = max(stResourceConfig_Curr.stMachineConfig(3).afMaCapAtTimePoint);

[stSolution.stCostAtAgent.stSolutionMinCost.stSchedule, stSpecificMachineTimeInfo] = psa_jsp_dispatch_machine_02(stSolution.astCase(iIndexMinCost).stContainerSchedule);

%%%%% Timing
tSolution_sec = cputime - t_start;

%%%%% Output
stAgent_Solution = stSolution;
stAgent_Solution.stMinCostResourceConfig = stResourceConfig_Curr;

stAgent_Solution.stPerformReport.tMinCostMakeSpan_hour = stSolution.stCostAtAgent.stSolutionMinCost.stSchedule.iMaxEndTime * fFactorHourPerSlot;
stAgent_Solution.stPerformReport.tMinCostGrossCraneRate = (stAgentJobListBiFsp.TotalContainer_Load + stAgentJobListBiFsp.TotalContainer_Discharge)/ stAgent_Solution.stPerformReport.tMinCostMakeSpan_hour;
stAgent_Solution.stPerformReport.fCostMakespanTardiness = stSolution.aCostTardinessMakespan(iIndexMinCost);
stAgent_Solution.stPerformReport.tSolutionTime_sec = tSolution_sec;
