function [stAgent_Solution] = psa_bidgen_mp_srch_grad(stInputResAlloc)
%
%
% adaptive from psa_bidgen_multiperiod_srch.m
% use GenSch3
%     decending order of price
%     local search by gradient, exit if local minimum is found
%

%%% 
t_start = cputime;

%%%% Local Constant Parameter
iFlagSorting                 = stInputResAlloc.iFlagSorting                ;
iMaxIter                     = stInputResAlloc.iMaxIter_BidGenOpt          ;
iFlag_RunGenSch2             = stInputResAlloc.iFlag_RunGenSch2            ;
iQuayCrane_id                = stInputResAlloc.iQuayCrane_id               ;
stBerthJobInfo               = stInputResAlloc.stBerthJobInfo              ;
iMaxPrimeMoverUsageByGenSch0 = stInputResAlloc.iMaxPrimeMoverUsageByGenSch0;
iMaxYardCraneUsageByGenSch0  = stInputResAlloc.iMaxYardCraneUsageByGenSch0 ;
stResourceConfigGenSch0      = stInputResAlloc.stResourceConfigGenSch0_ii  ;
stResourceConfigSrchSinglePeriod = stInputResAlloc.stResourceConfigSrchSinglePeriod_ii;

%%%% Local Volatile Structure Template
stJobListInfoAgent           = stInputResAlloc.stJobListInfoAgent_ii            ;

%% based on GenSch0
stResourceConfig_Curr = stResourceConfigGenSch0.stResourceConfig;

% based on SinglePeriodSearch
stResourceConfig_Curr = stResourceConfigSrchSinglePeriod.stResourceConfig;

atClockAgentJobStart     = stBerthJobInfo.stAgentJobInfo(iQuayCrane_id).atClockAgentJobStart;
tStartHour            = mod(atClockAgentJobStart.aClockYearMonthDateHourMinSec(4), 24);
iPriceHourStartIndex  = tStartHour + 1;
%tMaxPeriodGenSch0     = stResourceConfigSrchSinglePeriod.stResourceConfig.stMachineConfig(2).iNumPointTimeCap;
tMaxPeriodGenSch0     = stResourceConfigGenSch0.stResourceConfig.stMachineConfig(2).iNumPointTimeCap;
tMaxHalfPeriodGenSch0 = ceil(tMaxPeriodGenSch0/2);
fFactorHourPerSlot    = stJobListInfoAgent.fTimeUnit_Min/60 /stBerthJobInfo.fTimeFrameUnitInHour;

iLenNameNoExt = strfind(stBerthJobInfo.strInputFilename, '.') - 1;

strFilenameDebug = sprintf('%s_mp_srch_agent%d.txt', ...
					stBerthJobInfo.strInputFilename(1:iLenNameNoExt), ...
					iQuayCrane_id);
fptr = fopen(strFilenameDebug, 'a');
fprintf(fptr, '\n\n%%%New Interation Search \nCaseId,  ResourcePM, ResourceYC,  MakeSpan, CostMakeSpan, CostTardiness, CostResource, TotalCost\n');

if stBerthJobInfo.fTimeFrameUnitInHour ~= 1
    error('Currently unit of time period must be 1 hour');
end

if isfield(stInputResAlloc,'stAgent_Solution')
    stSolution = stInputResAlloc.stAgent_Solution(iQuayCrane_id);
    nTotalNumSolutionCaseIncHistory = length(stSolution.astSearchVectorSpace);
    for ii = 1:1:nTotalNumSolutionCaseIncHistory
        tMakeSpan_hour = stSolution.astCase(ii).stContainerSchedule.iMaxEndTime * fFactorHourPerSlot;
		iTotalPeriod_act = ceil(tMakeSpan_hour);
        iTotalPeriod = max([ stSolution.astCase(ii).stResourceConfig.stMachineConfig(2).iNumPointTimeCap, ...
            stSolution.astCase(ii).stResourceConfig.stMachineConfig(3).iNumPointTimeCap]);
		iPriceHourIndex = iPriceHourStartIndex;
		fCostPMYC = 0;
		for tt = 1:1:iTotalPeriod_act
            if tt > iTotalPeriod
                kUsagePM = stSolution.astCase(ii).stResourceConfig.stMachineConfig(2).afMaCapAtTimePoint(iTotalPeriod);
                kUsageYC = stSolution.astCase(ii).stResourceConfig.stMachineConfig(3).afMaCapAtTimePoint(iTotalPeriod);
            else
                kUsagePM = stSolution.astCase(ii).stResourceConfig.stMachineConfig(2).afMaCapAtTimePoint(tt);
                kUsageYC = stSolution.astCase(ii).stResourceConfig.stMachineConfig(3).afMaCapAtTimePoint(tt);
            end
		    fCostPMYC = fCostPMYC + stBerthJobInfo.fPricePrimeMoverDollarPerFrame(iPriceHourIndex) * kUsagePM + ...
		        stBerthJobInfo.fPriceYardCraneDollarPerFrame(iPriceHourIndex) * kUsageYC;
		    if iPriceHourIndex == 24
		        iPriceHourIndex = 0;
		    end
		    iPriceHourIndex = iPriceHourIndex + 1;
		end
	    [fTardinessFine_Sgd, tAgentTardiness_hour] = resalloc_calc_tardi_fine(stBerthJobInfo, stBerthJobInfo.stAgentJobInfo(iQuayCrane_id), stSolution.aMakeSpan_hour(ii));
	    stSolution.aTardiness_hour(ii) = tAgentTardiness_hour;
	    stSolution.aCostTardinessMakespan(ii) = ...
	        stSolution.aMakeSpan_hour(ii) * stBerthJobInfo.stAgentJobInfo(iQuayCrane_id).fPriceQuayCraneDollarPerFrame + ...
	        fTardinessFine_Sgd;
	    stSolution.aTotalCost(ii) = stSolution.aCostTardinessMakespan(ii) + fCostPMYC;
	    if ii == 1
	        fMinCost = stSolution.aTotalCost(ii);
	    else
	        if fMinCost > stSolution.aTotalCost(ii)
	            fMinCost = stSolution.aTotalCost(ii);
	        end
	    end
	    fsp_dbg_write_file(fptr, stSolution, ii);
	    [fMinCost, iIndexMinCost] = min(stSolution.aTotalCost);
	    stResourceConfig_Curr = stSolution.astCase(iIndexMinCost).stResourceConfig;
    end

else
    nTotalNumSolutionCaseIncHistory = 0;
end

nCurrentSearchCase = nTotalNumSolutionCaseIncHistory;

iter = 1;
while iter <= iMaxIter
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
    
    %%%% search Prime Mover first, by descending order
    %%% three options
    iSortIndexPricePM = 1:1:length(fPriceListPrimeMover);
    if iFlagSorting == 1
        [fSortedPriceListPrimeMover, iSortIndexPricePM] = sort(fPriceListPrimeMover);
    elseif iFlagSorting == -1
        [fSortedPriceListPrimeMover, iSortIndexPricePM] = sort(-fPriceListPrimeMover);
    end

    %% loop for all time frame
    stJobListInfoAgent.stResourceConfig = stResourceConfig_Curr;
    for ii = 1:1:iTotalPeriod
        tActualPeriod = iSortIndexPricePM(ii);
        if tActualPeriod <= tMaxHalfPeriodGenSch0
%            size(stResourceConfigGenSch0.stResourceConfig.stMachineConfig(2).afMaCapAtTimePoint)
%            tActualPeriod
            kMaxPrimeMoverSearchMP = stResourceConfigGenSch0.stResourceConfig.stMachineConfig(2).afMaCapAtTimePoint(tActualPeriod);
        else
            kMaxPrimeMoverSearchMP = stBerthJobInfo.iTotalPrimeMover;
        end
%        kMaxPrimeMoverSearchMP
        
        %%% starting number of Prime Mover
        stJobListInfoAgent.stResourceConfig.stMachineConfig(2).afMaCapAtTimePoint(tActualPeriod) = ...
            stJobListInfoAgent.MaxVirtualPrimeMover;
        numPrimeMover_MinCost_At_tActualPeriod = stJobListInfoAgent.stResourceConfig.stMachineConfig(2).afMaCapAtTimePoint(tActualPeriod);
        %%% Complementariness
        if stJobListInfoAgent.fTotalTimeRatioPM_OverYC > 1.0
            stJobListInfoAgent.stResourceConfig.stMachineConfig(3).afMaCapAtTimePoint(tActualPeriod) = ...
                round(stJobListInfoAgent.stResourceConfig.stMachineConfig(2).afMaCapAtTimePoint(tActualPeriod) / stJobListInfoAgent.fTotalTimeRatioPM_OverYC);
            if stJobListInfoAgent.stResourceConfig.stMachineConfig(3).afMaCapAtTimePoint(tActualPeriod) == 0
                stJobListInfoAgent.stResourceConfig.stMachineConfig(3).afMaCapAtTimePoint(tActualPeriod) = 1;
            elseif stJobListInfoAgent.stResourceConfig.stMachineConfig(3).afMaCapAtTimePoint(tActualPeriod) > stBerthJobInfo.iTotalYardCrane
                stJobListInfoAgent.stResourceConfig.stMachineConfig(3).afMaCapAtTimePoint(tActualPeriod) = stBerthJobInfo.iTotalYardCrane;
            end
        end
        
        aNewSearchVector = [stJobListInfoAgent.stResourceConfig.stMachineConfig(2).afMaCapAtTimePoint, ...
            stJobListInfoAgent.stResourceConfig.stMachineConfig(3).afMaCapAtTimePoint];
        iFlagVectorAlreadySearched = 0;
        if nTotalNumSolutionCaseIncHistory == 0
            nTotalNumSolutionCaseIncHistory = nTotalNumSolutionCaseIncHistory + 1;
            stSolution.astSearchVectorSpace(nTotalNumSolutionCaseIncHistory).aVector = aNewSearchVector;
        else
            iFlagVectorAlreadySearched = chk_search_vector(stSolution.astSearchVectorSpace, aNewSearchVector);
        end

        stGetSchduleCostInput.stJobListInfoAgent = stJobListInfoAgent;
        stGetSchduleCostInput.stBerthJobInfo     = stBerthJobInfo;
        stGetSchduleCostInput.fFactorHourPerSlot = fFactorHourPerSlot;
        stGetSchduleCostInput.iPriceHourStartIndex = iPriceHourStartIndex;
        stGetSchduleCostInput.iTotalPeriod         = iTotalPeriod;
        [stGetSchduleCostOutput] = fsp_get_sched_cost_by_agent(stGetSchduleCostInput);
        
        if iFlagVectorAlreadySearched == 0
            %%%%% recalculate the makespan and cost
            stSolution.astCase(nTotalNumSolutionCaseIncHistory).stResourceConfig = stJobListInfoAgent.stResourceConfig;

            stSolution.aMakeSpan_hour(nTotalNumSolutionCaseIncHistory) = stGetSchduleCostOutput.tMakeSpan_hour;
            stSolution.astCase(nTotalNumSolutionCaseIncHistory).stContainerSchedule = stGetSchduleCostOutput.stContainerSchedule;

            [fTardinessFine_Sgd, tAgentTardiness_hour] = ... 
                resalloc_calc_tardi_fine(stBerthJobInfo, stBerthJobInfo.stAgentJobInfo(iQuayCrane_id), stSolution.aMakeSpan_hour(nTotalNumSolutionCaseIncHistory));
            stSolution.aTardiness_hour(nTotalNumSolutionCaseIncHistory) = tAgentTardiness_hour;
            stSolution.aCostTardinessMakespan(nTotalNumSolutionCaseIncHistory) = ...
                stSolution.aMakeSpan_hour(nTotalNumSolutionCaseIncHistory) * stBerthJobInfo.stAgentJobInfo(iQuayCrane_id).fPriceQuayCraneDollarPerFrame + ...
                fTardinessFine_Sgd;
            stSolution.aTotalCost(nTotalNumSolutionCaseIncHistory) = stSolution.aCostTardinessMakespan(nTotalNumSolutionCaseIncHistory) + ...
                stGetSchduleCostOutput.fCostPMYC;

            fsp_dbg_write_file(fptr, stSolution, nTotalNumSolutionCaseIncHistory);
            nTotalNumSolutionCaseIncHistory = nTotalNumSolutionCaseIncHistory + 1;
        end
        nCurrentSearchCase = nCurrentSearchCase + 1;
        
        while stJobListInfoAgent.stResourceConfig.stMachineConfig(2).afMaCapAtTimePoint(tActualPeriod) ...
                < kMaxPrimeMoverSearchMP
            stJobListInfoAgent.stResourceConfig.stMachineConfig(2).afMaCapAtTimePoint(tActualPeriod) = ...
                stJobListInfoAgent.stResourceConfig.stMachineConfig(2).afMaCapAtTimePoint(tActualPeriod) + 1;
            %%% Complementariness
            if stJobListInfoAgent.fTotalTimeRatioPM_OverYC > 1.0
                stJobListInfoAgent.stResourceConfig.stMachineConfig(3).afMaCapAtTimePoint(tActualPeriod) = ...
                    round(stJobListInfoAgent.stResourceConfig.stMachineConfig(2).afMaCapAtTimePoint(tActualPeriod) / stJobListInfoAgent.fTotalTimeRatioPM_OverYC);
                if stJobListInfoAgent.stResourceConfig.stMachineConfig(3).afMaCapAtTimePoint(tActualPeriod) == 0
                    stJobListInfoAgent.stResourceConfig.stMachineConfig(3).afMaCapAtTimePoint(tActualPeriod) = 1;
                elseif stJobListInfoAgent.stResourceConfig.stMachineConfig(3).afMaCapAtTimePoint(tActualPeriod) > stBerthJobInfo.iTotalYardCrane
                    stJobListInfoAgent.stResourceConfig.stMachineConfig(3).afMaCapAtTimePoint(tActualPeriod) = stBerthJobInfo.iTotalYardCrane;
                end
            end
            
            aNewSearchVector = [stJobListInfoAgent.stResourceConfig.stMachineConfig(2).afMaCapAtTimePoint, ...
                stJobListInfoAgent.stResourceConfig.stMachineConfig(3).afMaCapAtTimePoint];
            iFlagVectorAlreadySearched = chk_search_vector(stSolution.astSearchVectorSpace, aNewSearchVector);

            %%%%%%%%%%%%%% Template Search, evaluate cost in new price,
            stGetSchduleCostInput.stJobListInfoAgent = stJobListInfoAgent;
            stGetSchduleCostInput.stBerthJobInfo     = stBerthJobInfo;
            stGetSchduleCostInput.fFactorHourPerSlot = fFactorHourPerSlot;
            stGetSchduleCostInput.iPriceHourStartIndex = iPriceHourStartIndex;
            stGetSchduleCostInput.iTotalPeriod         = iTotalPeriod;
            [stGetSchduleCostOutput] = fsp_get_sched_cost_by_agent(stGetSchduleCostInput);

	        if iFlagVectorAlreadySearched == 0
	            %%%%% recalculate the makespan and cost
	            stSolution.astCase(nTotalNumSolutionCaseIncHistory).stResourceConfig = stJobListInfoAgent.stResourceConfig;
	
	            stSolution.aMakeSpan_hour(nTotalNumSolutionCaseIncHistory) = stGetSchduleCostOutput.tMakeSpan_hour;
	            stSolution.astCase(nTotalNumSolutionCaseIncHistory).stContainerSchedule = stGetSchduleCostOutput.stContainerSchedule;
	
	            [fTardinessFine_Sgd, tAgentTardiness_hour] = ... 
	                resalloc_calc_tardi_fine(stBerthJobInfo, stBerthJobInfo.stAgentJobInfo(iQuayCrane_id), stSolution.aMakeSpan_hour(nTotalNumSolutionCaseIncHistory));
	            stSolution.aTardiness_hour(nTotalNumSolutionCaseIncHistory) = tAgentTardiness_hour;
	            stSolution.aCostTardinessMakespan(nTotalNumSolutionCaseIncHistory) = ...
	                stSolution.aMakeSpan_hour(nTotalNumSolutionCaseIncHistory) * stBerthJobInfo.stAgentJobInfo(iQuayCrane_id).fPriceQuayCraneDollarPerFrame + ...
	                fTardinessFine_Sgd;
	            stSolution.aTotalCost(nTotalNumSolutionCaseIncHistory) = stSolution.aCostTardinessMakespan(nTotalNumSolutionCaseIncHistory) + ...
	                stGetSchduleCostOutput.fCostPMYC;
	
	            fsp_dbg_write_file(fptr, stSolution, nTotalNumSolutionCaseIncHistory);
	            nTotalNumSolutionCaseIncHistory = nTotalNumSolutionCaseIncHistory + 1;
                nCurrentSearchCase = nCurrentSearchCase + 1;
            else
                nCurrentSearchCase = iFlagVectorAlreadySearched;
            end
%            size(stSolution.aMakeSpan_hour)
%            nCurrentSearchCase

            %%%%%% Detection of makespan decreasing or not
%            if stSolution.aMakeSpan_hour(nCurrentSearchCase) < stSolution.aMakeSpan_hour(nCurrentSearchCase - 1)
%                if stSolution.aTotalCost(nCurrentSearchCase) < stSolution.aTotalCost(nCurrentSearchCase-1)
%                    numPrimeMover_MinCost_At_tActualPeriod = stJobListInfoAgent.stResourceConfig.stMachineConfig(2).afMaCapAtTimePoint(tActualPeriod);
%                end
%            else
%                break;
%            end
            
                    %%% Gradient detect whether a local minimum has be detected
    %                [fSortedTotalCost, iSortedIndex] = sort(stSolution.aTotalCost);
    %                if iSortedIndex(1) ~= 1 | iSortedIndex(1) ~= length(stSolution.aTotalCost)
    %                    break;
    %                end
            
        end
        [fMinCost, iIndexMinCost] = min(stSolution.aTotalCost(1:nTotalNumSolutionCaseIncHistory-1));
         stJobListInfoAgent.stResourceConfig.stMachineConfig(2).afMaCapAtTimePoint(tActualPeriod) = ...
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
    stJobListInfoAgent.stResourceConfig = stResourceConfig_Curr;
    for ii = 1:1:iTotalPeriod
        tActualPeriod = iSortIndexPriceYardCrane(ii);
        if tActualPeriod <= tMaxHalfPeriodGenSch0
            kMaxYardCraneSearchMP = stResourceConfigGenSch0.stResourceConfig.stMachineConfig(3).afMaCapAtTimePoint(tActualPeriod);
        else
            kMaxYardCraneSearchMP = stBerthJobInfo.iTotalYardCrane;
        end
 %       kMaxYardCraneSearchMP
        %%% starting number of YardCrane
        stJobListInfoAgent.stResourceConfig.stMachineConfig(3).afMaCapAtTimePoint(tActualPeriod) = ...
            stJobListInfoAgent.MaxVirtualYardCrane;
        numYardCrane_MinCost_At_tActualPeriod = stJobListInfoAgent.stResourceConfig.stMachineConfig(3).afMaCapAtTimePoint(tActualPeriod);
            %%% Complementariness
        if stJobListInfoAgent.fTotalTimeRatioPM_OverYC < 1.0 
            stJobListInfoAgent.stResourceConfig.stMachineConfig(2).afMaCapAtTimePoint(tActualPeriod) = ...
                round(stJobListInfoAgent.stResourceConfig.stMachineConfig(3).afMaCapAtTimePoint(tActualPeriod) * stJobListInfoAgent.fTotalTimeRatioPM_OverYC);
            if stJobListInfoAgent.stResourceConfig.stMachineConfig(2).afMaCapAtTimePoint(tActualPeriod) == 0
                stJobListInfoAgent.stResourceConfig.stMachineConfig(2).afMaCapAtTimePoint(tActualPeriod) = 1;
            elseif stJobListInfoAgent.stResourceConfig.stMachineConfig(2).afMaCapAtTimePoint(tActualPeriod) > stBerthJobInfo.iTotalPrimeMover
                stJobListInfoAgent.stResourceConfig.stMachineConfig(2).afMaCapAtTimePoint(tActualPeriod) = stBerthJobInfo.iTotalPrimeMover;
            end
        end
        
        aNewSearchVector = [stJobListInfoAgent.stResourceConfig.stMachineConfig(2).afMaCapAtTimePoint, ...
            stJobListInfoAgent.stResourceConfig.stMachineConfig(3).afMaCapAtTimePoint];
        iFlagVectorAlreadySearched = chk_search_vector(stSolution.astSearchVectorSpace, aNewSearchVector);

        stGetSchduleCostInput.stJobListInfoAgent = stJobListInfoAgent;
        stGetSchduleCostInput.stBerthJobInfo     = stBerthJobInfo;
        stGetSchduleCostInput.fFactorHourPerSlot = fFactorHourPerSlot;
        stGetSchduleCostInput.iPriceHourStartIndex = iPriceHourStartIndex;
        stGetSchduleCostInput.iTotalPeriod         = iTotalPeriod;
        [stGetSchduleCostOutput] = fsp_get_sched_cost_by_agent(stGetSchduleCostInput);
        
        if iFlagVectorAlreadySearched == 0
            %%%%% recalculate the makespan and cost
            stSolution.astCase(nTotalNumSolutionCaseIncHistory).stResourceConfig = stJobListInfoAgent.stResourceConfig;

            stSolution.aMakeSpan_hour(nTotalNumSolutionCaseIncHistory) = stGetSchduleCostOutput.tMakeSpan_hour;
            stSolution.astCase(nTotalNumSolutionCaseIncHistory).stContainerSchedule = stGetSchduleCostOutput.stContainerSchedule;

            [fTardinessFine_Sgd, tAgentTardiness_hour] = ... 
                resalloc_calc_tardi_fine(stBerthJobInfo, stBerthJobInfo.stAgentJobInfo(iQuayCrane_id), stSolution.aMakeSpan_hour(nTotalNumSolutionCaseIncHistory));
            stSolution.aTardiness_hour(nTotalNumSolutionCaseIncHistory) = tAgentTardiness_hour;
            stSolution.aCostTardinessMakespan(nTotalNumSolutionCaseIncHistory) = ...
                stSolution.aMakeSpan_hour(nTotalNumSolutionCaseIncHistory) * stBerthJobInfo.stAgentJobInfo(iQuayCrane_id).fPriceQuayCraneDollarPerFrame + ...
                fTardinessFine_Sgd;
            stSolution.aTotalCost(nTotalNumSolutionCaseIncHistory) = stSolution.aCostTardinessMakespan(nTotalNumSolutionCaseIncHistory) + ...
                stGetSchduleCostOutput.fCostPMYC;

            fsp_dbg_write_file(fptr, stSolution, nTotalNumSolutionCaseIncHistory);
            nTotalNumSolutionCaseIncHistory = nTotalNumSolutionCaseIncHistory + 1;
        end
        nCurrentSearchCase = nCurrentSearchCase + 1;
        
        
        while stJobListInfoAgent.stResourceConfig.stMachineConfig(3).afMaCapAtTimePoint(tActualPeriod) ...
                < kMaxYardCraneSearchMP
            stJobListInfoAgent.stResourceConfig.stMachineConfig(3).afMaCapAtTimePoint(tActualPeriod) = ...
                stJobListInfoAgent.stResourceConfig.stMachineConfig(3).afMaCapAtTimePoint(tActualPeriod) + 1;
            %%% Complementariness
            if stJobListInfoAgent.fTotalTimeRatioPM_OverYC < 1.0 
                stJobListInfoAgent.stResourceConfig.stMachineConfig(2).afMaCapAtTimePoint(tActualPeriod) = ...
                    round(stJobListInfoAgent.stResourceConfig.stMachineConfig(3).afMaCapAtTimePoint(tActualPeriod) * stJobListInfoAgent.fTotalTimeRatioPM_OverYC);
                if stJobListInfoAgent.stResourceConfig.stMachineConfig(2).afMaCapAtTimePoint(tActualPeriod) == 0
                    stJobListInfoAgent.stResourceConfig.stMachineConfig(2).afMaCapAtTimePoint(tActualPeriod) = 1;
                elseif stJobListInfoAgent.stResourceConfig.stMachineConfig(2).afMaCapAtTimePoint(tActualPeriod) > stBerthJobInfo.iTotalPrimeMover
                    stJobListInfoAgent.stResourceConfig.stMachineConfig(2).afMaCapAtTimePoint(tActualPeriod) = stBerthJobInfo.iTotalPrimeMover;
                end
            end
            aNewSearchVector = [stJobListInfoAgent.stResourceConfig.stMachineConfig(2).afMaCapAtTimePoint, ...
                stJobListInfoAgent.stResourceConfig.stMachineConfig(3).afMaCapAtTimePoint];
            iFlagVectorAlreadySearched = chk_search_vector(stSolution.astSearchVectorSpace, aNewSearchVector);

            %%%%%%%%%%%%%% Template Search, evaluate cost in new price,
	        stGetSchduleCostInput.stJobListInfoAgent = stJobListInfoAgent;
	        stGetSchduleCostInput.stBerthJobInfo     = stBerthJobInfo;
	        stGetSchduleCostInput.fFactorHourPerSlot = fFactorHourPerSlot;
	        stGetSchduleCostInput.iPriceHourStartIndex = iPriceHourStartIndex;
	        stGetSchduleCostInput.iTotalPeriod         = iTotalPeriod;
	        [stGetSchduleCostOutput] = fsp_get_sched_cost_by_agent(stGetSchduleCostInput);
	        
	        if iFlagVectorAlreadySearched == 0
	            %%%%% recalculate the makespan and cost
	            stSolution.astCase(nTotalNumSolutionCaseIncHistory).stResourceConfig = stJobListInfoAgent.stResourceConfig;
	
	            stSolution.aMakeSpan_hour(nTotalNumSolutionCaseIncHistory) = stGetSchduleCostOutput.tMakeSpan_hour;
	            stSolution.astCase(nTotalNumSolutionCaseIncHistory).stContainerSchedule = stGetSchduleCostOutput.stContainerSchedule;
	
	            [fTardinessFine_Sgd, tAgentTardiness_hour] = ... 
	                resalloc_calc_tardi_fine(stBerthJobInfo, stBerthJobInfo.stAgentJobInfo(iQuayCrane_id), stSolution.aMakeSpan_hour(nTotalNumSolutionCaseIncHistory));
	            stSolution.aTardiness_hour(nTotalNumSolutionCaseIncHistory) = tAgentTardiness_hour;
	            stSolution.aCostTardinessMakespan(nTotalNumSolutionCaseIncHistory) = ...
	                stSolution.aMakeSpan_hour(nTotalNumSolutionCaseIncHistory) * stBerthJobInfo.stAgentJobInfo(iQuayCrane_id).fPriceQuayCraneDollarPerFrame + ...
	                fTardinessFine_Sgd;
	            stSolution.aTotalCost(nTotalNumSolutionCaseIncHistory) = stSolution.aCostTardinessMakespan(nTotalNumSolutionCaseIncHistory) + ...
	                stGetSchduleCostOutput.fCostPMYC;
	
	            fsp_dbg_write_file(fptr, stSolution, nTotalNumSolutionCaseIncHistory);
	            nTotalNumSolutionCaseIncHistory = nTotalNumSolutionCaseIncHistory + 1;
                nCurrentSearchCase = nCurrentSearchCase + 1;
            else
                nCurrentSearchCase = iFlagVectorAlreadySearched;
	        end
            
            %%%%%% Detection of makespan decreasing or not
%            if stSolution.aMakeSpan_hour(nCurrentSearchCase) < stSolution.aMakeSpan_hour(nCurrentSearchCase - 1)
%                if stSolution.aTotalCost(nCurrentSearchCase) < stSolution.aTotalCost(nCurrentSearchCase-1)
%                    numPrimeMover_MinCost_At_tActualPeriod = stJobListInfoAgent.stResourceConfig.stMachineConfig(2).afMaCapAtTimePoint(tActualPeriod);
%                end
%            else
%                break;
%            end
            
                %%% Gradient detect whether a local minimum has be detected
%                [fSortedTotalCost, iSortedIndex] = sort(stSolution.aTotalCost);
%                if iSortedIndex(1) ~= 1 | iSortedIndex(1) ~= length(stSolution.aTotalCost)
%                    break;
%                end


        end
        [fMinCost, iIndexMinCost] = min(stSolution.aTotalCost(1:nTotalNumSolutionCaseIncHistory-1));
         stJobListInfoAgent.stResourceConfig.stMachineConfig(3).afMaCapAtTimePoint(tActualPeriod) = ...
             numYardCrane_MinCost_At_tActualPeriod;
    end
    
    stResourceConfig_Curr = stSolution.astCase(iIndexMinCost).stResourceConfig;
    
    iter = iter + 1;
    
%    iter_iTotalPeriod = [iter, iTotalPeriod]
%    nTotalNumSolutionCaseIncHistory
    
end

%%%%% dispatching
if iFlag_RunGenSch2 == 1
    [stBuildMachConfigOutput] = psa_fsp_bld_machfig_by_sch ...
                (stBerthJobInfo.fTimeFrameUnitInHour, stJobListInfoAgent.stResourceConfig, stSolution.astCase(iIndexMinCost).stContainerSchedule);
    stJobListInfoAgent.stResourceConfig = stBuildMachConfigOutput.stResourceConfigSchOut.stResourceConfig;
    [stPartialScheduleGenSch2, jobshop_config] = psa_jsp_gen_job_schedule_28(stJobListInfoAgent);
%    stPartialScheduleGenSch2 = psa_jsp_gen_sch3_multiperiod(stJobListInfoAgent);
%    stPartialScheduleGenSch2 = stSolution.astCase(iIndexMinCost).stContainerSchedule;
else
    stPartialScheduleGenSch2 = stSolution.astCase(iIndexMinCost).stContainerSchedule;
end

fprintf(fptr, '\n\n%%%% Min Cost Schedule\n');
fsp_dbg_write_file(fptr, stSolution, iIndexMinCost);
%stPartialScheduleGenSch2
stPartialScheduleGenSch2.iTotalMachineNum(2) = max(stJobListInfoAgent.stResourceConfig.stMachineConfig(2).afMaCapAtTimePoint);
stPartialScheduleGenSch2.iTotalMachineNum(3) = max(stJobListInfoAgent.stResourceConfig.stMachineConfig(3).afMaCapAtTimePoint);
[stSchedule, stSpecificMachineTimeInfo] = psa_jsp_dispatch_machine_02(stPartialScheduleGenSch2);
stSolution.stCostAtAgent.stSolutionMinCost.stSchedule = stSchedule;
[stBuildMachConfigOutput] = psa_fsp_bld_machfig_by_sch ...
    (stBerthJobInfo.fTimeFrameUnitInHour, stJobListInfoAgent.stResourceConfig, stSolution.stCostAtAgent.stSolutionMinCost.stSchedule);
stJobListInfoAgent.stResourceConfig = stBuildMachConfigOutput.stResourceConfigSchOut.stResourceConfig;
stSolution.stCostAtAgent.stSolutionMinCost.stSchedule.stResourceConfig = stJobListInfoAgent.stResourceConfig;

%stJobListInfoAgent.stResourceConfig.stMachineConfig(2).afMaCapAtTimePoint
%stJobListInfoAgent.stResourceConfig.stMachineConfig(3).afMaCapAtTimePoint
%input('any key');

%%%% MakeSpan and Tardiness
tMinCostMakeSpan_hour = stSolution.stCostAtAgent.stSolutionMinCost.stSchedule.iMaxEndTime * fFactorHourPerSlot;
[fTardinessFineMinCost_Sgd, tAgentTardiness_hour] = resalloc_calc_tardi_fine(stBerthJobInfo, stBerthJobInfo.stAgentJobInfo(iQuayCrane_id), tMinCostMakeSpan_hour);

%%%% Resource Cost
iTotalPeriod_act = ceil(tMinCostMakeSpan_hour);
iPriceHourIndex = iPriceHourStartIndex;
fCostPMYC = 0;
for tt = 1:1:iTotalPeriod_act
    if tt > iTotalPeriod
        kUsagePM = stJobListInfoAgent.stResourceConfig.stMachineConfig(2).afMaCapAtTimePoint(iTotalPeriod);
        kUsageYC = stJobListInfoAgent.stResourceConfig.stMachineConfig(3).afMaCapAtTimePoint(iTotalPeriod);
    else
        kUsagePM = stJobListInfoAgent.stResourceConfig.stMachineConfig(2).afMaCapAtTimePoint(tt);
        kUsageYC = stJobListInfoAgent.stResourceConfig.stMachineConfig(3).afMaCapAtTimePoint(tt);
    end
    if stBerthJobInfo.iObjFunction == 5
        fCostPMYC = fCostPMYC + stBerthJobInfo.fPricePrimeMoverDollarPerFrame(iPriceHourIndex) * max([0, kUsagePM - stJobListInfoAgent.MaxVirtualPrimeMover]) + ...
            stBerthJobInfo.fPriceYardCraneDollarPerFrame(iPriceHourIndex) * max([0, kUsageYC - stJobListInfoAgent.MaxVirtualYardCrane]);
    else
        fCostPMYC = fCostPMYC + stBerthJobInfo.fPricePrimeMoverDollarPerFrame(iPriceHourIndex) * kUsagePM + ...
            stBerthJobInfo.fPriceYardCraneDollarPerFrame(iPriceHourIndex) * kUsageYC;
    end
    
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
stAgent_Solution.stPerformReport.tMinCostGrossCraneRate = (stJobListInfoAgent.TotalContainer_Load + stJobListInfoAgent.TotalContainer_Discharge)/ stAgent_Solution.stPerformReport.tMinCostMakeSpan_hour;
stAgent_Solution.stPerformReport.fCostMakespanTardiness = tMinCostMakeSpan_hour * stBerthJobInfo.stAgentJobInfo(iQuayCrane_id).fPriceQuayCraneDollarPerFrame + fTardinessFineMinCost_Sgd;

stAgent_Solution.stPerformReport.fMinCost              = fCostPMYC  + ...
                                                      stAgent_Solution.stPerformReport.fCostMakespanTardiness;
stAgent_Solution.stPerformReport.tSolutionTime_sec = tSolution_sec;
stAgent_Solution.stSchedule_MinCost                   = stAgent_Solution.stCostAtAgent.stSolutionMinCost.stSchedule;