function [stAgent_Solution] = bidgen_agent_ful_combo(stInputResAllocAgent)
%
%
% adaptive from psa_bidgen_multiperiod_srch.m
% use GenSch3
%     decending order of price
%     local search by gradient, exit if local minimum is found
%     decentralized version
% History
% YYYYMMDD  Notes
% 20070921  Created
% 20070923  add stAgentUtilityPrice
% 20071104  add case for extending periods

%%%% Local Constant Parameter
iFlagSorting                 = stInputResAllocAgent.iFlagSorting                ;
iMaxIter                     = stInputResAllocAgent.iMaxIter_BidGenOpt          ;
iFlag_RunGenSch2             = stInputResAllocAgent.iFlag_RunGenSch2            ;
iAgentId                     = stInputResAllocAgent.iAgentId               ;
%stResAllocGenJspAgent        = stInputResAllocAgent.stResAllocGenJspAgent              ;
stResourceConfigGenSch0      = stInputResAllocAgent.stResourceConfigGenSch0     ;
stResourceConfigSrchSinglePeriod = stInputResAllocAgent.stResourceConfigSrchSinglePeriod;
stAgentJobInfo        = stInputResAllocAgent.stAgentJobInfo;
strInputFilename      = stInputResAllocAgent.strInputFilename;
stSystemMasterConfig  = stInputResAllocAgent.stSystemMasterConfig;
stJssProbStructConfig = stInputResAllocAgent.stJssProbStructConfig;
astMachinePrice       = stInputResAllocAgent.astMachinePrice;
stGlobalResourceConfig= stInputResAllocAgent.stGlobalResourceConfig;
%%%% Local Volatile Structure Template
astAgentJobListJspCfg           = stInputResAllocAgent.astAgentJobListJspCfg            ;

nTotalMachType = stSystemMasterConfig.iTotalMachType;

t_start = cputime;

atClockAgentJobStart     = stAgentJobInfo.atClockAgentJobStart;
tStartHour            = mod(atClockAgentJobStart.aClockYearMonthDateHourMinSec(4), 24);
iPriceHourStartIndex  = tStartHour + 1;
tMaxPeriodGenSch0     = stResourceConfigGenSch0.stMachineConfig(nTotalMachType).iNumPointTimeCap;
tMaxHalfPeriodGenSch0 = ceil(tMaxPeriodGenSch0/2);
fFactorHourPerSlot    = astAgentJobListJspCfg.fTimeUnit_Min/60 /stSystemMasterConfig.fTimeFrameUnitInHour;

iLenNameNoExt = strfind(strInputFilename, '.') - 1;

strFilenameDebug = sprintf('%s_mp_srch_agent%d.txt', ...
					strInputFilename(1:iLenNameNoExt), ...
					iAgentId);

if stSystemMasterConfig.fTimeFrameUnitInHour ~= 1
    error('Currently unit of time period must be 1 hour');
end

if isfield(stInputResAllocAgent,'stAgent_Solution')
    if stSystemMasterConfig.iPlotFlag >= 3
        fptr = fopen(strFilenameDebug, 'a');  %% appending to the file
        fprintf(fptr, '\nCaseId,  ResourcePM, ResourceYC,  MakeSpan, CostMakeSpan, CostTardiness, CostResource, TotalCost\n');
    end
    stSolution = stInputResAllocAgent.stAgent_Solution;
    nTotalNumSolutionCaseIncHistory = length(stSolution.astSearchVectorSpace);
    for ii = 1:1:nTotalNumSolutionCaseIncHistory
        tMakeSpan_hour = stSolution.astCase(ii).stContainerSchedule.iMaxEndTime * fFactorHourPerSlot;
		iTotalPeriod_act = ceil(tMakeSpan_hour);
        iTotalPeriod = stSolution.astCase(ii).stResourceConfig.stMachineConfig(nTotalMachType).iNumPointTimeCap;
		iPriceHourIndex = iPriceHourStartIndex;
% 		fCostPMYC = 0;
        kUsageAtMach = zeros(1, nTotalMachType);
        fCostTotalMach = 0;
		for tt = 1:1:iTotalPeriod_act
            for mm = 1:1:nTotalMachType
                if tt > iTotalPeriod
                    kUsageAtMach(mm) = stSolution.astCase(ii).stResourceConfig.stMachineConfig(mm).afMaCapAtTimePoint(iTotalPeriod);
                else
                    kUsageAtMach(mm) = stSolution.astCase(ii).stResourceConfig.stMachineConfig(mm).afMaCapAtTimePoint(tt);;
                end
                fCostTotalMach = fCostTotalMach + kUsageAtMach(mm) * astMachinePrice(mm).fPricePerFrame(iPriceHourIndex)
            end
		    if iPriceHourIndex == 24
		        iPriceHourIndex = 0;
		    end
		    iPriceHourIndex = iPriceHourIndex + 1;
		end
	    [fTardinessFine_Sgd, tAgentTardiness_hour] = resalloc_calc_tardi_fine(stSystemMasterConfig, stAgentJobInfo, stSolution.aMakeSpan_hour(ii)); %resalloc_calc_tardi_fine(stBerthJobInfo, stAgentJobInfo, stSolution.aMakeSpan_hour(ii));
	    stSolution.aTardiness_hour(ii) = tAgentTardiness_hour;
	    stSolution.aCostTardinessMakespan(ii) = ...
	        stSolution.aMakeSpan_hour(ii) * stAgentJobInfo.fPriceAgentDollarPerFrame + ...
	        fTardinessFine_Sgd;
	    stSolution.aTotalCost(ii) = stSolution.aCostTardinessMakespan(ii) + fCostTotalMach;
	    if ii == 1
	        fMinCost = stSolution.aTotalCost(ii);
	    else
	        if fMinCost > stSolution.aTotalCost(ii)
	            fMinCost = stSolution.aTotalCost(ii);
	        end
        end
        
        if stSystemMasterConfig.iPlotFlag >= 3
    	    fsp_dbg_write_file(fptr, stSolution, ii);
        end
    end
    [fMinCost, iIndexMinCost] = min(stSolution.aTotalCost);
    stResourceConfig_Curr = stSolution.astCase(iIndexMinCost).stResourceConfig;
    iTotalPeriod_act = stResourceConfig_Curr.stMachineConfig(nTotalMachType).iNumPointTimeCap;
    
else
    if stSystemMasterConfig.iPlotFlag >= 4
        fptr = fopen(strFilenameDebug, 'w');  %% open write to a new file
        fprintf(fptr, 'CaseId,  ResourcePM, ResourceYC,  MakeSpan, CostMakeSpan, CostTardiness, CostResource, TotalCost\n');
    end
    stResourceConfig_Curr = stResourceConfigSrchSinglePeriod.stResourceConfig;
    nTotalNumSolutionCaseIncHistory = 0;
    iTotalPeriod_act = stResourceConfig_Curr.stMachineConfig(nTotalMachType).iNumPointTimeCap;

end

if stSystemMasterConfig.iPlotFlag >= 4
    fprintf(fptr, 'StartHour: %d, idxPriceStart: %d, Current price - [PM, YC]: ', tStartHour, iPriceHourStartIndex);
    for tt = 1:1:iTotalPeriod_act
        fprintf(fptr, '[');
        for mm = 1:1:nTotalMachType
            fprintf(fptr, '%5.1f', astMachinePrice(mm).fPricePerFrame(iPriceHourStartIndex + tt - 1);
        end
        fprintf(fptr, ']');
    end
    fprintf(fptr, '\n');
end

nCurrentSearchCase = nTotalNumSolutionCaseIncHistory;

% nInitMachCap(1) = stJobListInfoAgent.MaxVirtualPrimeMover;
% nInitMachCap(2) = stJobListInfoAgent.MaxVirtualYardCrane;
anIniLowBoundMachNum = astAgentJobListJspCfg.iTotalMachineNum;
nTotalMachineResource = nTotalMachType;
tEpsilon = 1/3600;

for mm = 1:1:nTotalMachType
    if mm == stSystemMasterConfig.iCriticalMachType
        anIniLowBoundMachNum(mm) = 1;
    end
end

iter = 1;
while iter <= iMaxIter
    iTotalPeriod = stResourceConfig_Curr.stMachineConfig(nTotalMachType).iNumPointTimeCap;
    iPriceHourIndex = iPriceHourStartIndex;
    
    %% loop for all time period
    astAgentJobListJspCfg.stResourceConfig = stResourceConfig_Curr;
    for tActualPeriod = 1:1:iTotalPeriod
        for mm = 1:1:nTotalMachType
            if tActualPeriod <= tMaxHalfPeriodGenSch0
                kMaxMachCapAtCurrPeriod(mm) = stResourceConfigGenSch0.stMachineConfig(mm).afMaCapAtTimePoint(tActualPeriod);
            else
                if stResourceConfigGenSch0.iaMachCapOnePer(mm) > stGlobalResourceConfig.iaMachCapOnePer(mm)
                    kMaxMachCapAtCurrPeriod(mm) = stGlobalResourceConfig.iaMachCapOnePer(mm);
                else
                    kMaxMachCapAtCurrPeriod(mm) = stResourceConfigGenSch0.iaMachCapOnePer(mm);
                end
                if anIniLowBoundMachNum(mm) > kMaxMachCapAtCurrPeriod(mm)
                    error('error: LowerBoundSearch > UpperBoundSearch');
                end
            end
            if mm == stSystemMasterConfig.iCriticalMachType
                kMaxMachCapAtCurrPeriod(mm) = 1;
            end
%            maxMachCapCurrPeriod = [kMaxMachCapAtCurrPeriod(1), kMaxMachCapAtCurrPeriod(1)]
        end

        %%% initialize preparation for searching
        iMaxSearchingCase = 1;
        for mm = 1:1:nTotalMachType
            iMaxSearchingCase = iMaxSearchingCase * (kMaxMachCapAtCurrPeriod(mm) - anIniLowBoundMachNum(mm) + 1);
        end

        iaMachCapCurrSrch = anIniLowBoundMachNum;
        iaMachCapPrevDirStart = iaMachCapCurrSrch;
        iSearchDim = 1; %% spanning from 1 to iMaxDimension;
        if iSearchDim == stSystemMasterConfig.iCriticalMachType
            iSearchDim = iSearchDim + 1;
        end
        iMaxDimension = nTotalMachType; %% for the case of [numPM, numYC]
        fTotalCostMatrix = zeros(kMaxMachCapAtCurrPeriod - anIniLowBoundMachNum + ones(1, nTotalMachType));

        [stJspSchedule] = jsp_constr_sche_struct_by_cfg(astAgentJobListJspCfg(ii));
        %%% Start Debug 20080107

%     iaMachCapCurrSrch = anIniLowBoundMachNum;
%     iaMachCapPrevDirStart = iaMachCapCurrSrch;
        
        nMachCapAtCurrPeriod = zeros(nTotalMachineResource, 1);
        iCaseResourceCombo = 1;
        iFlagContinueSearch = 1;
%         nMachCapAtCurrPeriod(1) = anIniLowBoundMachNum(1);
%         nMachCapAtCurrPeriod(2) = anIniLowBoundMachNum(2);
%         nMachCapPrevDirStart = nMachCapAtCurrPeriod;
        iSearchDim = 1; %% spanning from 1 to nTotalMachineResource;
        fTotalCostMatrix = zeros(kMaxMachCapAtCurrPeriod(1) - anIniLowBoundMachNum(1) +1, kMaxMachCapAtCurrPeriod(2) - anIniLowBoundMachNum(2) + 1);
        fMakespanMatrix = zeros(kMaxMachCapAtCurrPeriod(1), kMaxMachCapAtCurrPeriod(2));

        while iCaseResourceCombo <= iMaxSearchingCase & iFlagContinueSearch == 1
            %%% starting number of Prime Mover
            astAgentJobListJspCfg.stResourceConfig.stMachineConfig(2).afMaCapAtTimePoint(tActualPeriod) = ...
                nMachCapAtCurrPeriod(1);
            astAgentJobListJspCfg.stResourceConfig.stMachineConfig(3).afMaCapAtTimePoint(tActualPeriod) = ...
                nMachCapAtCurrPeriod(2);
        
            aNewSearchVector = [astAgentJobListJspCfg.stResourceConfig.stMachineConfig(2).afMaCapAtTimePoint, ...
                astAgentJobListJspCfg.stResourceConfig.stMachineConfig(3).afMaCapAtTimePoint];
            if nTotalNumSolutionCaseIncHistory == 0
                iFlagVectorAlreadySearched = 0;
            else
                iFlagVectorAlreadySearched = chk_search_vector(stSolution.astSearchVectorSpace, aNewSearchVector);
            end

            if iFlagVectorAlreadySearched == 0
                stGetSchduleCostInput.astAgentJobListJspCfg = astAgentJobListJspCfg;
                stGetSchduleCostInput.stSystemMasterConfig     = stSystemMasterConfig;
                stGetSchduleCostInput.fFactorHourPerSlot = fFactorHourPerSlot;
                stGetSchduleCostInput.iPriceHourStartIndex = iPriceHourStartIndex;
                stGetSchduleCostInput.iTotalPeriod         = iTotalPeriod;
                [stGetSchduleCostOutput] = fsp_get_sched_cost_by_agent(stGetSchduleCostInput);

                nTotalNumSolutionCaseIncHistory = nTotalNumSolutionCaseIncHistory + 1;
                stSolution.astSearchVectorSpace(nTotalNumSolutionCaseIncHistory).aVector = aNewSearchVector;
                %%%%% recalculate the makespan and cost
                iTotalPeriod_act = ceil(stGetSchduleCostOutput.tMakeSpan_hour);
                stSolution.astCase(nTotalNumSolutionCaseIncHistory).stResourceConfig = astAgentJobListJspCfg.stResourceConfig;
                if iTotalPeriod_act < astAgentJobListJspCfg.stResourceConfig.stMachineConfig(nTotalMachType).iNumPointTimeCap
                    stSolution.astCase(nTotalNumSolutionCaseIncHistory).stResourceConfig.stMachineConfig(2).iNumPointTimeCap = iTotalPeriod_act;
                    stSolution.astCase(nTotalNumSolutionCaseIncHistory).stResourceConfig.stMachineConfig(3).iNumPointTimeCap = iTotalPeriod_act;
                end

                stSolution.aMakeSpan_hour(nTotalNumSolutionCaseIncHistory) = stGetSchduleCostOutput.tMakeSpan_hour;
                stSolution.astCase(nTotalNumSolutionCaseIncHistory).stContainerSchedule = stGetSchduleCostOutput.stContainerSchedule;

                [fTardinessFine_Sgd, tAgentTardiness_hour] = ... 
                    resalloc_calc_tardi_fine(stSystemMasterConfig, stAgentJobInfo, stSolution.aMakeSpan_hour(nTotalNumSolutionCaseIncHistory));
                stSolution.aTardiness_hour(nTotalNumSolutionCaseIncHistory) = tAgentTardiness_hour;
                stSolution.aCostTardinessMakespan(nTotalNumSolutionCaseIncHistory) = ...
                    stSolution.aMakeSpan_hour(nTotalNumSolutionCaseIncHistory) * stAgentJobInfo.fPriceAgentDollarPerFrame + ...
                    fTardinessFine_Sgd;
                stSolution.aTotalCost(nTotalNumSolutionCaseIncHistory) = stSolution.aCostTardinessMakespan(nTotalNumSolutionCaseIncHistory) + ...
                    stGetSchduleCostOutput.fCostTotalMach;

                if stSystemMasterConfig.iPlotFlag >= 4
                    fsp_dbg_write_file(fptr, stSolution, nTotalNumSolutionCaseIncHistory);
                end
                nCurrentSearchCase = nTotalNumSolutionCaseIncHistory;
            else
                nCurrentSearchCase = iFlagVectorAlreadySearched;
            end

            idxCostMatrixDim(1) = nMachCapAtCurrPeriod(1) - anIniLowBoundMachNum(1) +1;
            idxCostMatrixDim(2) = nMachCapAtCurrPeriod(2) - anIniLowBoundMachNum(2) +1;
            fTotalCostMatrix(idxCostMatrixDim(1), idxCostMatrixDim(2)) = stSolution.aTotalCost(nCurrentSearchCase);
            fMakespanMatrix(nMachCapAtCurrPeriod(1), nMachCapAtCurrPeriod(2)) = stSolution.aMakeSpan_hour(nCurrentSearchCase);
            
            %%% update (mNumPM, mNumYC)
            if iCaseResourceCombo == 1
                %% initial searching direction is along 1st Resource or iSearchDim == 1
                nNextMachCapAtCurrPeriod(1) = nMachCapAtCurrPeriod(1) + 1;
                nNextMachCapAtCurrPeriod(2) = nMachCapAtCurrPeriod(2);
                tPrevMakeSpan = stSolution.aMakeSpan_hour(nCurrentSearchCase);
            else
                %%% if not decreasing, or have reached one boundary of searching region
                if (  stSolution.aMakeSpan_hour(nCurrentSearchCase) > tPrevMakeSpan - tEpsilon ...
                        | ( nMachCapAtCurrPeriod(1) + 1) > kMaxMachCapAtCurrPeriod(1) ...
                        | ( nMachCapAtCurrPeriod(2) + 1) > kMaxMachCapAtCurrPeriod(2) ...
                        )
                    iSearchDim = mod(iSearchDim, nTotalMachineResource) + 1;
                    if iSearchDim == 1
                        nMachCapPrevDirStart(1) = nMachCapPrevDirStart(1) + 1;
                        nMachCapPrevDirStart(2) = nMachCapPrevDirStart(2) + 1;
                        nNextMachCapAtCurrPeriod(1) = nMachCapPrevDirStart(1);
                        nNextMachCapAtCurrPeriod(2) = nMachCapPrevDirStart(2);
                    elseif iSearchDim == 2
                        nNextMachCapAtCurrPeriod(1) = nMachCapPrevDirStart(1);
                        nNextMachCapAtCurrPeriod(2) = nMachCapPrevDirStart(2) + 1;
                    end
                    
                else %% if decreasing and not yet meet boundary
                    nNextMachCapAtCurrPeriod(iSearchDim) = nMachCapAtCurrPeriod(iSearchDim) + 1;
                end
            end

            iCaseResourceCombo = iCaseResourceCombo + 1;
            if( (nMachCapPrevDirStart(1) >= kMaxMachCapAtCurrPeriod(1) ) ...
                    | (nMachCapPrevDirStart(2) >= kMaxMachCapAtCurrPeriod(2) ) ...
                    )
                iFlagContinueSearch = 0;
%                disp('complete iterative direction search.');
            else
                nMachCapAtCurrPeriod = nNextMachCapAtCurrPeriod;
            end

            tPrevMakeSpan = stSolution.aMakeSpan_hour(nCurrentSearchCase);
%             bFlagExistLocalMinimum = chk_cost_matrix_sub_grad(fTotalCostMatrix, idxCostMatrixDim(1), idxCostMatrixDim(2));
%             if iCaseResourceCombo >= 5
%                 if bFlagExistLocalMinimum == 1
%                     iFlagContinueSearch = 0;
% %                     disp('Local minimum has been detected.');
% %                     iter_period = [iter,  tActualPeriod]
% 
%                 end
%             end %% 20071104
        end
        [fMinCost, iIndexMinCost] = min(stSolution.aTotalCost(1:nTotalNumSolutionCaseIncHistory));
        astAgentJobListJspCfg.stResourceConfig = stSolution.astCase(iIndexMinCost).stResourceConfig;

        %% 20071104
        iTotalPeriod_act = ceil(stSolution.aMakeSpan_hour(iIndexMinCost));
        iTotalPeriod_curr = astAgentJobListJspCfg.stResourceConfig.stMachineConfig(nTotalMachType).iNumPointTimeCap;
        if iTotalPeriod_act > iTotalPeriod_curr
            astAgentJobListJspCfg.stResourceConfig.stMachineConfig(2).iNumPointTimeCap = iTotalPeriod_act;
            astAgentJobListJspCfg.stResourceConfig.stMachineConfig(3).iNumPointTimeCap = iTotalPeriod_act;
            nNumSlotPerFrame = round(stSystemMasterConfig.fTimeFrameUnitInHour * 60 / astAgentJobListJspCfg.fTimeUnit_Min);
            for pp = iTotalPeriod_curr + 1:1:iTotalPeriod_act
                astAgentJobListJspCfg.stResourceConfig.stMachineConfig(2).afMaCapAtTimePoint(pp) = ...
                    astAgentJobListJspCfg.stResourceConfig.stMachineConfig(2).afMaCapAtTimePoint(iTotalPeriod_curr);
                astAgentJobListJspCfg.stResourceConfig.stMachineConfig(3).afMaCapAtTimePoint(pp) = ...
                    astAgentJobListJspCfg.stResourceConfig.stMachineConfig(3).afMaCapAtTimePoint(iTotalPeriod_curr);
                astAgentJobListJspCfg.stResourceConfig.stMachineConfig(2).afTimePointAtCap(pp) = ...
                    astAgentJobListJspCfg.stResourceConfig.stMachineConfig(2).afTimePointAtCap(iTotalPeriod_curr) + ...
                    (pp - iTotalPeriod_curr) * nNumSlotPerFrame;
                astAgentJobListJspCfg.stResourceConfig.stMachineConfig(3).afTimePointAtCap(pp) = ...
                    astAgentJobListJspCfg.stResourceConfig.stMachineConfig(3).afTimePointAtCap(iTotalPeriod_curr) + ...
                    (pp - iTotalPeriod_curr) * nNumSlotPerFrame;
                
            end
            stResourceConfig_Curr = astAgentJobListJspCfg.stResourceConfig;
            stSolution.astCase(iIndexMinCost).stResourceConfig = stResourceConfig_Curr;
        end
        %% 20071104
%         iter_period = [iter,  tActualPeriod]
    end

    [fMinCost, iIndexMinCost] = min(stSolution.aTotalCost(1:nTotalNumSolutionCaseIncHistory));
    astAgentJobListJspCfg.stResourceConfig = stSolution.astCase(iIndexMinCost).stResourceConfig;
    stResourceConfig_Curr = stSolution.astCase(iIndexMinCost).stResourceConfig;
    
    iter = iter + 1;
end

%%%%% Calculate utility price
iTotalPeriod = stResourceConfig_Curr.stMachineConfig(nTotalMachType).iNumPointTimeCap;
stJobListInfoMinCostCfg = astAgentJobListJspCfg;
tMakespanMinCost_hour = stSolution.aMakeSpan_hour(iIndexMinCost);
astMachineConfigMinCost(1).aCfgVector = astAgentJobListJspCfg.stResourceConfig.stMachineConfig(2).afMaCapAtTimePoint;
astMachineConfigMinCost(2).aCfgVector = astAgentJobListJspCfg.stResourceConfig.stMachineConfig(3).afMaCapAtTimePoint;
stAgentUtilityPrice.iPriceHourStartIndex = iPriceHourStartIndex; % 20070923
stAgentUtilityPrice.iTotalPeriod = astAgentJobListJspCfg.stResourceConfig.stMachineConfig(nTotalMachType).iNumPointTimeCap;
for tActualPeriod = 1:1:stAgentUtilityPrice.iTotalPeriod
    idxCostMatrixDim(1) = astMachineConfigMinCost(1).aCfgVector(tActualPeriod);
    idxCostMatrixDim(2) = astMachineConfigMinCost(2).aCfgVector(tActualPeriod);
    
%     for rr = 1:1:2 %Currently 2 resources
    % resource No.rr, maps to
    % astAgentJobListJspCfg_CurrCfg.stResourceConfig.stMachineConfig(rr + 1);
    % astMachineConfigMinCost(rr)
    aNewVector = astMachineConfigMinCost(1).aCfgVector;
    astAgentJobListJspCfg_CurrCfg = stJobListInfoMinCostCfg;

    if aNewVector(tActualPeriod) - 1 == 0

        aNewVector(tActualPeriod) = aNewVector(tActualPeriod) + 1;
        astAgentJobListJspCfg_CurrCfg.stResourceConfig.stMachineConfig(2).afMaCapAtTimePoint(tActualPeriod) = aNewVector(tActualPeriod);
        aSearchVectorNearMinCost = [aNewVector, astMachineConfigMinCost(2).aCfgVector];
        iFlagVectorAlreadySearched = chk_search_vector(stSolution.astSearchVectorSpace, aSearchVectorNearMinCost);
        if iFlagVectorAlreadySearched == 0
            stGetSchduleCostInput.astAgentJobListJspCfg = astAgentJobListJspCfg_CurrCfg;
            stGetSchduleCostInput.stSystemMasterConfig     = stSystemMasterConfig;
            stGetSchduleCostInput.fFactorHourPerSlot = fFactorHourPerSlot;
            stGetSchduleCostInput.iPriceHourStartIndex = iPriceHourStartIndex;
            stGetSchduleCostInput.iTotalPeriod         = iTotalPeriod;
            [stGetSchduleCostOutput] = fsp_get_sched_cost_by_agent(stGetSchduleCostInput);

            nTotalNumSolutionCaseIncHistory = nTotalNumSolutionCaseIncHistory + 1;
            stSolution.astSearchVectorSpace(nTotalNumSolutionCaseIncHistory).aVector = aNewSearchVector;
            stSolution.astCase(nTotalNumSolutionCaseIncHistory).stResourceConfig = astAgentJobListJspCfg_CurrCfg.stResourceConfig;

            stSolution.aMakeSpan_hour(nTotalNumSolutionCaseIncHistory) = stGetSchduleCostOutput.tMakeSpan_hour;
            stSolution.astCase(nTotalNumSolutionCaseIncHistory).stContainerSchedule = stGetSchduleCostOutput.stContainerSchedule;

            [fTardinessFine_Sgd, tAgentTardiness_hour] = ... 
                resalloc_calc_tardi_fine(stSystemMasterConfig, stAgentJobInfo, stSolution.aMakeSpan_hour(nTotalNumSolutionCaseIncHistory));
            stSolution.aTardiness_hour(nTotalNumSolutionCaseIncHistory) = tAgentTardiness_hour;
            stSolution.aCostTardinessMakespan(nTotalNumSolutionCaseIncHistory) = ...
                stSolution.aMakeSpan_hour(nTotalNumSolutionCaseIncHistory) * stAgentJobInfo.fPriceAgentDollarPerFrame + ...
                fTardinessFine_Sgd;
            stSolution.aTotalCost(nTotalNumSolutionCaseIncHistory) = stSolution.aCostTardinessMakespan(nTotalNumSolutionCaseIncHistory) + ...
                stGetSchduleCostOutput.fCostTotalMach;

            if stSystemMasterConfig.iPlotFlag >= 4
                fsp_dbg_write_file(fptr, stSolution, nTotalNumSolutionCaseIncHistory);
            end
            nCurrentSearchCase = nTotalNumSolutionCaseIncHistory;
        else
            nCurrentSearchCase = iFlagVectorAlreadySearched;
        end
        fDeltaMakespan_hour = tMakespanMinCost_hour - stSolution.aMakeSpan_hour(nCurrentSearchCase); % new makespan should be less than MinCostMakespan

    else
        aNewVector(tActualPeriod) = aNewVector(tActualPeriod) - 1;
        astAgentJobListJspCfg_CurrCfg.stResourceConfig.stMachineConfig(2).afMaCapAtTimePoint(tActualPeriod) = aNewVector(tActualPeriod);
        aSearchVectorNearMinCost = [aNewVector, astMachineConfigMinCost(2).aCfgVector];
        iFlagVectorAlreadySearched = chk_search_vector(stSolution.astSearchVectorSpace, aSearchVectorNearMinCost);
        if iFlagVectorAlreadySearched == 0
            stGetSchduleCostInput.astAgentJobListJspCfg = astAgentJobListJspCfg_CurrCfg;
            stGetSchduleCostInput.stSystemMasterConfig     = stSystemMasterConfig;
            stGetSchduleCostInput.fFactorHourPerSlot = fFactorHourPerSlot;
            stGetSchduleCostInput.iPriceHourStartIndex = iPriceHourStartIndex;
            stGetSchduleCostInput.iTotalPeriod         = iTotalPeriod;
            [stGetSchduleCostOutput] = fsp_get_sched_cost_by_agent(stGetSchduleCostInput);

            nTotalNumSolutionCaseIncHistory = nTotalNumSolutionCaseIncHistory + 1;
            stSolution.astSearchVectorSpace(nTotalNumSolutionCaseIncHistory).aVector = aNewSearchVector;
            stSolution.astCase(nTotalNumSolutionCaseIncHistory).stResourceConfig = astAgentJobListJspCfg_CurrCfg.stResourceConfig;

            stSolution.aMakeSpan_hour(nTotalNumSolutionCaseIncHistory) = stGetSchduleCostOutput.tMakeSpan_hour;
            stSolution.astCase(nTotalNumSolutionCaseIncHistory).stContainerSchedule = stGetSchduleCostOutput.stContainerSchedule;

            [fTardinessFine_Sgd, tAgentTardiness_hour] = ... 
                resalloc_calc_tardi_fine(stSystemMasterConfig, stAgentJobInfo, stSolution.aMakeSpan_hour(nTotalNumSolutionCaseIncHistory));
            stSolution.aTardiness_hour(nTotalNumSolutionCaseIncHistory) = tAgentTardiness_hour;
            stSolution.aCostTardinessMakespan(nTotalNumSolutionCaseIncHistory) = ...
                stSolution.aMakeSpan_hour(nTotalNumSolutionCaseIncHistory) * stAgentJobInfo.fPriceAgentDollarPerFrame + ...
                fTardinessFine_Sgd;
            stSolution.aTotalCost(nTotalNumSolutionCaseIncHistory) = stSolution.aCostTardinessMakespan(nTotalNumSolutionCaseIncHistory) + ...
                stGetSchduleCostOutput.fCostTotalMach;

            if stSystemMasterConfig.iPlotFlag >= 4
                fsp_dbg_write_file(fptr, stSolution, nTotalNumSolutionCaseIncHistory);
            end
            nCurrentSearchCase = nTotalNumSolutionCaseIncHistory;
        else
            nCurrentSearchCase = iFlagVectorAlreadySearched;
        end
        fDeltaMakespan_hour = stSolution.aMakeSpan_hour(nCurrentSearchCase) - tMakespanMinCost_hour;
    end

    stAgentUtilityPrice.astUtilityPrice(tActualPeriod).fDeltaUtiPriceAtMach(1).fDeltaMakespan_hour = fDeltaMakespan_hour;
    stAgentUtilityPrice.astUtilityPrice(tActualPeriod).fDeltaUtiPriceAtMach(1).fUtilityPrice = fDeltaMakespan_hour * stAgentJobInfo.fPriceAgentDollarPerFrame;
    stAgentUtilityPrice.astUtilityPrice(tActualPeriod).fDeltaUtiPriceAtMach(1).iResourceBidding = idxCostMatrixDim(1);

    %%%%%%%% 2nd resource
    aNewVector = astMachineConfigMinCost(2).aCfgVector; %% differ
    astAgentJobListJspCfg_CurrCfg = stJobListInfoMinCostCfg;

    if aNewVector(tActualPeriod) - 1 == 0

        aNewVector(tActualPeriod) = aNewVector(tActualPeriod) + 1;  
        astAgentJobListJspCfg_CurrCfg.stResourceConfig.stMachineConfig(3).afMaCapAtTimePoint(tActualPeriod) = aNewVector(tActualPeriod); %% differ
        aSearchVectorNearMinCost = [astMachineConfigMinCost(2).aCfgVector, aNewVector]; %% differ, need to think for improving
        iFlagVectorAlreadySearched = chk_search_vector(stSolution.astSearchVectorSpace, aSearchVectorNearMinCost);
        if iFlagVectorAlreadySearched == 0
            stGetSchduleCostInput.astAgentJobListJspCfg = astAgentJobListJspCfg_CurrCfg;
            stGetSchduleCostInput.stSystemMasterConfig     = stSystemMasterConfig;
            stGetSchduleCostInput.fFactorHourPerSlot = fFactorHourPerSlot;
            stGetSchduleCostInput.iPriceHourStartIndex = iPriceHourStartIndex;
            stGetSchduleCostInput.iTotalPeriod         = iTotalPeriod;
            [stGetSchduleCostOutput] = fsp_get_sched_cost_by_agent(stGetSchduleCostInput);

            nTotalNumSolutionCaseIncHistory = nTotalNumSolutionCaseIncHistory + 1;
            stSolution.astSearchVectorSpace(nTotalNumSolutionCaseIncHistory).aVector = aNewSearchVector;
            stSolution.astCase(nTotalNumSolutionCaseIncHistory).stResourceConfig = astAgentJobListJspCfg_CurrCfg.stResourceConfig;

            stSolution.aMakeSpan_hour(nTotalNumSolutionCaseIncHistory) = stGetSchduleCostOutput.tMakeSpan_hour;
            stSolution.astCase(nTotalNumSolutionCaseIncHistory).stContainerSchedule = stGetSchduleCostOutput.stContainerSchedule;

            [fTardinessFine_Sgd, tAgentTardiness_hour] = ... 
                resalloc_calc_tardi_fine(stSystemMasterConfig, stAgentJobInfo, stSolution.aMakeSpan_hour(nTotalNumSolutionCaseIncHistory));
            stSolution.aTardiness_hour(nTotalNumSolutionCaseIncHistory) = tAgentTardiness_hour;
            stSolution.aCostTardinessMakespan(nTotalNumSolutionCaseIncHistory) = ...
                stSolution.aMakeSpan_hour(nTotalNumSolutionCaseIncHistory) * stAgentJobInfo.fPriceAgentDollarPerFrame + ...
                fTardinessFine_Sgd;
            stSolution.aTotalCost(nTotalNumSolutionCaseIncHistory) = stSolution.aCostTardinessMakespan(nTotalNumSolutionCaseIncHistory) + ...
                stGetSchduleCostOutput.fCostTotalMach;

            if stSystemMasterConfig.iPlotFlag >= 4
                fsp_dbg_write_file(fptr, stSolution, nTotalNumSolutionCaseIncHistory);
            end
            nCurrentSearchCase = nTotalNumSolutionCaseIncHistory;
        else
            nCurrentSearchCase = iFlagVectorAlreadySearched;
        end
        fDeltaMakespan_hour = tMakespanMinCost_hour - stSolution.aMakeSpan_hour(nCurrentSearchCase); % new makespan should be less than MinCostMakespan

    else
        aNewVector(tActualPeriod) = aNewVector(tActualPeriod) - 1;
        astAgentJobListJspCfg_CurrCfg.stResourceConfig.stMachineConfig(3).afMaCapAtTimePoint(tActualPeriod) = aNewVector(tActualPeriod);  %% differ
        aSearchVectorNearMinCost = [astMachineConfigMinCost(2).aCfgVector, aNewVector];        %% differ
        iFlagVectorAlreadySearched = chk_search_vector(stSolution.astSearchVectorSpace, aSearchVectorNearMinCost);
        if iFlagVectorAlreadySearched == 0
            stGetSchduleCostInput.astAgentJobListJspCfg = astAgentJobListJspCfg_CurrCfg;
            stGetSchduleCostInput.stSystemMasterConfig     = stSystemMasterConfig;
            stGetSchduleCostInput.fFactorHourPerSlot = fFactorHourPerSlot;
            stGetSchduleCostInput.iPriceHourStartIndex = iPriceHourStartIndex;
            stGetSchduleCostInput.iTotalPeriod         = iTotalPeriod;
            [stGetSchduleCostOutput] = fsp_get_sched_cost_by_agent(stGetSchduleCostInput);

            nTotalNumSolutionCaseIncHistory = nTotalNumSolutionCaseIncHistory + 1;
            stSolution.astSearchVectorSpace(nTotalNumSolutionCaseIncHistory).aVector = aNewSearchVector;
            stSolution.astCase(nTotalNumSolutionCaseIncHistory).stResourceConfig = astAgentJobListJspCfg_CurrCfg.stResourceConfig;

            stSolution.aMakeSpan_hour(nTotalNumSolutionCaseIncHistory) = stGetSchduleCostOutput.tMakeSpan_hour;
            stSolution.astCase(nTotalNumSolutionCaseIncHistory).stContainerSchedule = stGetSchduleCostOutput.stContainerSchedule;

            [fTardinessFine_Sgd, tAgentTardiness_hour] = ... 
                resalloc_calc_tardi_fine(stSystemMasterConfig, stAgentJobInfo, stSolution.aMakeSpan_hour(nTotalNumSolutionCaseIncHistory));
            stSolution.aTardiness_hour(nTotalNumSolutionCaseIncHistory) = tAgentTardiness_hour;
            stSolution.aCostTardinessMakespan(nTotalNumSolutionCaseIncHistory) = ...
                stSolution.aMakeSpan_hour(nTotalNumSolutionCaseIncHistory) * stAgentJobInfo.fPriceAgentDollarPerFrame + ...
                fTardinessFine_Sgd;
            stSolution.aTotalCost(nTotalNumSolutionCaseIncHistory) = stSolution.aCostTardinessMakespan(nTotalNumSolutionCaseIncHistory) + ...
                stGetSchduleCostOutput.fCostTotalMach;

            if stSystemMasterConfig.iPlotFlag >= 4
                fsp_dbg_write_file(fptr, stSolution, nTotalNumSolutionCaseIncHistory);
            end
            nCurrentSearchCase = nTotalNumSolutionCaseIncHistory;
        else
            nCurrentSearchCase = iFlagVectorAlreadySearched;
        end
        fDeltaMakespan_hour = stSolution.aMakeSpan_hour(nCurrentSearchCase) - tMakespanMinCost_hour;
    end

    stAgentUtilityPrice.astUtilityPrice(tActualPeriod).fDeltaUtiPriceAtMach(2).fDeltaMakespan_hour = fDeltaMakespan_hour;
    stAgentUtilityPrice.astUtilityPrice(tActualPeriod).fDeltaUtiPriceAtMach(2).fUtilityPrice = fDeltaMakespan_hour * stAgentJobInfo.fPriceAgentDollarPerFrame;
    stAgentUtilityPrice.astUtilityPrice(tActualPeriod).fDeltaUtiPriceAtMach(2).iResourceBidding = idxCostMatrixDim(2);
    
%     end
    
    if stSystemMasterConfig.iPlotFlag >= 3
        fprintf(fptr, '[DeltaMakespan, UtilityPrice, Bidding] [PM, YC] ', tStartHour, iPriceHourStartIndex);
        for mm = 1:1:2
            fprintf(fptr, '[%5.1f, %5.1f, %d],  ', ...
                stAgentUtilityPrice.astUtilityPrice(tActualPeriod).fDeltaUtiPriceAtMach(mm).fDeltaMakespan_hour, ...
                stAgentUtilityPrice.astUtilityPrice(tActualPeriod).fDeltaUtiPriceAtMach(mm).fUtilityPrice, ...
                stAgentUtilityPrice.astUtilityPrice(tActualPeriod).fDeltaUtiPriceAtMach(mm).iResourceBidding);
        end
        fprintf(fptr, '\n');
    end
end

%%%%% dispatching
if iFlag_RunGenSch2 == 1
    [stBuildMachConfigOutput] = psa_fsp_bld_machfig_by_sch ...
                (stSystemMasterConfig.fTimeFrameUnitInHour, astAgentJobListJspCfg.stResourceConfig, stSolution.astCase(iIndexMinCost).stContainerSchedule);
    astAgentJobListJspCfg.stResourceConfig = stBuildMachConfigOutput.stResourceConfigSchOut.stResourceConfig;
    if stJssProbStructConfig.isCriticalOperateSeq == 1
        [stPartialScheduleGenSch2, jobshop_config] = psa_jsp_gen_job_schedule_28(astAgentJobListJspCfg);
    else
        [stPartialScheduleGenSch2] = fsp_bidir_multi_m_t_ch_seq(astAgentJobListJspCfg);
    end
%    [stContainerDischargeJobSequence, container_jsp_discha_schedule, stContainerLoadJobSequence, container_jsp_load_schedule, stPartialScheduleGenSch2] = ...
%        psa_jsp_gen_sch3_multiperiod(astAgentJobListJspCfg);
%    stPartialScheduleGenSch2 = stSolution.astCase(iIndexMinCost).stContainerSchedule;
else
    stPartialScheduleGenSch2 = stSolution.astCase(iIndexMinCost).stContainerSchedule;
end

if stSystemMasterConfig.iPlotFlag >= 3
    fprintf(fptr, '\n\n%%%% Min Cost Schedule\n');
    fsp_dbg_write_file(fptr, stSolution, iIndexMinCost);
end
%stPartialScheduleGenSch2
%max(astAgentJobListJspCfg.stResourceConfig.stMachineConfig(2).afMaCapAtTimePoint)
stPartialScheduleGenSch2.iTotalMachineNum(2) = max(astAgentJobListJspCfg.stResourceConfig.stMachineConfig(2).afMaCapAtTimePoint);
stPartialScheduleGenSch2.iTotalMachineNum(3) = max(astAgentJobListJspCfg.stResourceConfig.stMachineConfig(3).afMaCapAtTimePoint);
[stSchedule, stSpecificMachineTimeInfo] = psa_jsp_dispatch_machine_02(stPartialScheduleGenSch2);
stSolution.stCostAtAgent.stSolutionMinCost.stSchedule = stSchedule;
[stBuildMachConfigOutput] = psa_fsp_bld_machfig_by_sch ...
    (stSystemMasterConfig.fTimeFrameUnitInHour, astAgentJobListJspCfg.stResourceConfig, stSolution.stCostAtAgent.stSolutionMinCost.stSchedule);
astAgentJobListJspCfg.stResourceConfig = stBuildMachConfigOutput.stResourceConfigSchOut.stResourceConfig;

%%%% MakeSpan and Tardiness
tMinCostMakeSpan_hour = stSolution.stCostAtAgent.stSolutionMinCost.stSchedule.iMaxEndTime * fFactorHourPerSlot;
[fTardinessFineMinCost_Sgd, tAgentTardiness_hour] = resalloc_calc_tardi_fine(stSystemMasterConfig, stAgentJobInfo, tMinCostMakeSpan_hour);

%%%% Resource Cost
iTotalPeriod_act = ceil(tMinCostMakeSpan_hour);
iPriceHourIndex = iPriceHourStartIndex;
% fCostPMYC = 0;
kUsageAtMach = zeros(1, nTotalMachType);
fCostTotalMach = 0;
for tt = 1:1:iTotalPeriod_act
    for mm = 1:1:nTotalMachType
        if tt > iTotalPeriod
            kUsageAtMach(mm) = astAgentJobListJspCfg.stResourceConfig.stMachineConfig(mm).afMaCapAtTimePoint(iTotalPeriod);
        else
            kUsageAtMach(mm) = astAgentJobListJspCfg.stResourceConfig.stMachineConfig(mm).afMaCapAtTimePoint(tt);;
        end
        fCostTotalMach = fCostTotalMach + kUsageAtMach(mm) * astMachinePrice(mm).fPricePerFrame(iPriceHourIndex)
    end
    if iPriceHourIndex == 24
        iPriceHourIndex = 0;
    end
    iPriceHourIndex = iPriceHourIndex + 1;
end

%%%%% Timing
if stSystemMasterConfig.iPlotFlag >= 3
    fclose(fptr);
end

tSolution_sec = cputime - t_start;

%%%%% Output
stAgent_Solution = stSolution;
stAgent_Solution.stMinCostResourceConfig = stBuildMachConfigOutput.stResourceConfigSchOut.stResourceConfig;

stAgent_Solution.stPerformReport.tMinCostMakeSpan_hour = tMinCostMakeSpan_hour;
stAgent_Solution.stPerformReport.tMinCostGrossCraneRate = (astAgentJobListJspCfg.TotalContainer_Load + astAgentJobListJspCfg.TotalContainer_Discharge)/ stAgent_Solution.stPerformReport.tMinCostMakeSpan_hour;
stAgent_Solution.stPerformReport.fCostMakespanTardiness = tMinCostMakeSpan_hour * stAgentJobInfo.fPriceAgentDollarPerFrame + fTardinessFineMinCost_Sgd;

stAgent_Solution.stPerformReport.fMinCost              = fCostTotalMach  + ...
                                                      stAgent_Solution.stPerformReport.fCostMakespanTardiness;
stAgent_Solution.stPerformReport.tSolutionTime_sec = tSolution_sec;
stAgent_Solution.stSchedule_MinCost                   = stAgent_Solution.stCostAtAgent.stSolutionMinCost.stSchedule;
stAgent_Solution.stAgentUtilityPrice                  = stAgentUtilityPrice;
