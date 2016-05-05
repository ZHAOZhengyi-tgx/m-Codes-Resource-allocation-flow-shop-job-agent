function [stAgent_Solution] = bidgen_fsp_agent_ful_combo(stInputResAllocAgent)
% bid generation, flow-shop-problem, agent full combination
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
% 20080301  compatible for gen-resalloc
% 20080406  legacy
%%%% Local Constant Parameter
iFlagSorting                 = stInputResAllocAgent.iFlagSorting                ;
iMaxIter                     = stInputResAllocAgent.iMaxIter_BidGenOpt          ;
iFlag_RunGenSch2             = stInputResAllocAgent.iFlag_RunGenSch2            ;
if isfield(stInputResAllocAgent, 'stBerthJobInfo')  % 20080301
    stBerthJobInfo               = stInputResAllocAgent.stBerthJobInfo              ;
elseif isfield(stInputResAllocAgent, 'stResAllocGenJspAgent')
    stBerthJobInfo               = stInputResAllocAgent.stResAllocGenJspAgent   ;
else
    error('struct not exist in bidgen_fsp_agent_ful_combo ')
end % 20080301

stResourceConfigGenSch0      = stInputResAllocAgent.stResourceConfigGenSch0     ;
stResourceConfigSrchSinglePeriod = stInputResAllocAgent.stResourceConfigSrchSinglePeriod;
stAgentJobInfo        = stInputResAllocAgent.stAgentJobInfo         ;

%%%% Local Volatile Structure Template
if isfield(stInputResAllocAgent, 'stJobListInfoAgent')  % 20080301
    stJobListInfoAgent           = stInputResAllocAgent.stJobListInfoAgent            ;
elseif isfield(stInputResAllocAgent, 'stAgentJobListJspCfg')
    stJobListInfoAgent           = stInputResAllocAgent.stAgentJobListJspCfg;
else
    error('struct not exist in bidgen_fsp_agent_ful_combo ')
end % 20080301

t_start = cputime;

atClockAgentJobStart     = stAgentJobInfo.atClockAgentJobStart;
tStartHour            = mod(atClockAgentJobStart.aClockYearMonthDateHourMinSec(4), 24);
iPriceHourStartIndex  = tStartHour + 1;
if isfield(stResourceConfigGenSch0, 'stResourceConfig') % 20080406 legacy
    tMaxPeriodGenSch0     = stResourceConfigGenSch0.stResourceConfig.stMachineConfig(2).iNumPointTimeCap;
else
    tMaxPeriodGenSch0     = stResourceConfigGenSch0.stMachineConfig(2).iNumPointTimeCap;
    stResourceConfigGenSch0.stResourceConfig = stResourceConfigGenSch0;
end
tMaxHalfPeriodGenSch0 = ceil(tMaxPeriodGenSch0/2);
fFactorHourPerSlot    = stJobListInfoAgent.fTimeUnit_Min/60 /stBerthJobInfo.fTimeFrameUnitInHour;

iLenNameNoExt = strfind(stBerthJobInfo.strInputFilename, '.') - 1;


if stBerthJobInfo.fTimeFrameUnitInHour ~= 1
    error('Currently unit of time period must be 1 hour');
end

iAgentId_dbg                = stInputResAllocAgent.iAgentId_dbg               ;
strFilenameDebug = sprintf('%s_mp_srch_agent%d.txt', ...
                    stBerthJobInfo.strInputFilename(1:iLenNameNoExt), ...
                    iAgentId_dbg);

if isfield(stInputResAllocAgent,'stAgent_Solution') ...
        & isfield(stInputResAllocAgent.stAgent_Solution, 'astSearchVectorSpace')
    if stBerthJobInfo.iPlotFlag >= 3
        fptr = fopen(strFilenameDebug, 'a');  %% appending to the file
        fprintf(fptr, '\nCaseId,  ResourcePM, ResourceYC,  MakeSpan, CostMakeSpan, CostTardiness, CostResource, TotalCost\n');
    end
    stSolution = stInputResAllocAgent.stAgent_Solution;
%    if 
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
                fCostPMYC = fCostPMYC + stBerthJobInfo.astResourceInitPrice(2).afMachinePriceListPerFrame(iPriceHourIndex) * kUsagePM + ...
                    stBerthJobInfo.astResourceInitPrice(3).afMachinePriceListPerFrame(iPriceHourIndex) * kUsageYC;
                if iPriceHourIndex == 24
                    iPriceHourIndex = 0;
                end
                iPriceHourIndex = iPriceHourIndex + 1;
            end
            [fTardinessFine_Sgd, tAgentTardiness_hour] = resalloc_calc_tardi_fine(stBerthJobInfo, stAgentJobInfo, stSolution.aMakeSpan_hour(ii));
            stSolution.aTardiness_hour(ii) = tAgentTardiness_hour;
            stSolution.aCostTardinessMakespan(ii) = ...
                stSolution.aMakeSpan_hour(ii) * stAgentJobInfo.fPriceAgentDollarPerFrame + ...
                fTardinessFine_Sgd;
            stSolution.aTotalCost(ii) = stSolution.aCostTardinessMakespan(ii) + fCostPMYC;
            if ii == 1
                fMinCost = stSolution.aTotalCost(ii);
            else
                if fMinCost > stSolution.aTotalCost(ii)
                    fMinCost = stSolution.aTotalCost(ii);
                end
            end

            if stBerthJobInfo.iPlotFlag >= 3
                fsp_dbg_write_file(fptr, stSolution, ii);
            end
        end % for
        [fMinCost, iIndexMinCost] = min(stSolution.aTotalCost);
        stResourceConfig_Curr = stSolution.astCase(iIndexMinCost).stResourceConfig;
        iTotalPeriod_act = stResourceConfig_Curr.stMachineConfig(2).iNumPointTimeCap;
%    end % if
    
else
    if stBerthJobInfo.iPlotFlag >= 3
        fptr = fopen(strFilenameDebug, 'w');  %% open write to a new file
        fprintf(fptr, 'CaseId,  ResourcePM, ResourceYC,  MakeSpan, CostMakeSpan, CostTardiness, CostResource, TotalCost\n');
    end
    if isfield(stResourceConfigSrchSinglePeriod, 'stResourceConfig') % 20080406 legacy
        stResourceConfig_Curr = stResourceConfigSrchSinglePeriod.stResourceConfig;
    else
        stResourceConfig_Curr = stResourceConfigSrchSinglePeriod;
        stResourceConfig_Curr.stResourceConfig = stResourceConfigSrchSinglePeriod;
    end
    stResourceConfig_Curr.iCriticalMachType = stBerthJobInfo.stResourceConfig.iCriticalMachType;
    nTotalNumSolutionCaseIncHistory = 0;
    iTotalPeriod_act = stResourceConfig_Curr.stMachineConfig(2).iNumPointTimeCap;
    % temp default value
    %    stSolution.iCriticalMachType = stBerthJobInfo.stSystemMasterConfig.iCriticalMachType;
end

if stBerthJobInfo.iPlotFlag >= 3
    fprintf(fptr, 'StartHour: %d, idxPriceStart: %d, Current price - [PM, YC]: ', tStartHour, iPriceHourStartIndex);
%    for tt = 1:1:iTotalPeriod_act
%        fprintf(fptr, '[%5.1f, %5.1f]', stBerthJobInfo.astResourceInitPrice(2).afMachinePriceListPerFrame(iPriceHourStartIndex + tt - 1), ...
%            stBerthJobInfo.astResourceInitPrice(3).afMachinePriceListPerFrame(iPriceHourStartIndex + tt - 1));
%    end
    fprintf(fptr, '\n');
end

nCurrentSearchCase = nTotalNumSolutionCaseIncHistory;
nInitMachCap(1) = stJobListInfoAgent.stResourceConfig.iaMachCapOnePer(2);
nInitMachCap(2) = stJobListInfoAgent.stResourceConfig.iaMachCapOnePer(3);
nTotalMachineResource = 2;
tEpsilon = 1/3600;

iter = 1;
while iter <= iMaxIter
    iTotalPeriod = stResourceConfig_Curr.stMachineConfig(2).iNumPointTimeCap;
    iPriceHourIndex = iPriceHourStartIndex;
    
    %% loop for all time period
    stJobListInfoAgent.stResourceConfig = stResourceConfig_Curr;
    for tActualPeriod = 1:1:iTotalPeriod
        
%         if tActualPeriod <= tMaxHalfPeriodGenSch0
%             kMaxMachCapAtCurrPeriod(1) = stResourceConfigGenSch0.stResourceConfig.stMachineConfig(2).afMaCapAtTimePoint(tActualPeriod);
%             kMaxMachCapAtCurrPeriod(2) = stResourceConfigGenSch0.stResourceConfig.stMachineConfig(3).afMaCapAtTimePoint(tActualPeriod);
%         else
            kMaxMachCapAtCurrPeriod(1) = stBerthJobInfo.stResourceConfig.iaMachCapOnePer(2);
            kMaxMachCapAtCurrPeriod(2) = stBerthJobInfo.stResourceConfig.iaMachCapOnePer(3);
%         end
%        maxMachCapCurrPeriod = [kMaxMachCapAtCurrPeriod(1), kMaxMachCapAtCurrPeriod(1)]

        %%% initialize preparation for searching
        iMaxSearchingCase = (kMaxMachCapAtCurrPeriod(1) - nInitMachCap(1) +1) * (kMaxMachCapAtCurrPeriod(2) - nInitMachCap(2) + 1);
        
        nMachCapAtCurrPeriod = zeros(nTotalMachineResource, 1);
        iCaseResourceCombo = 1;
        iFlagContinueSearch = 1;
        nMachCapAtCurrPeriod(1) = nInitMachCap(1);
        nMachCapAtCurrPeriod(2) = nInitMachCap(2);
        nMachCapPrevDirStart = nMachCapAtCurrPeriod;
        iSearchDim = 1; %% spanning from 1 to nTotalMachineResource;
        fTotalCostMatrix = zeros(kMaxMachCapAtCurrPeriod(1) - nInitMachCap(1) +1, kMaxMachCapAtCurrPeriod(2) - nInitMachCap(2) + 1);
        fMakespanMatrix = zeros(kMaxMachCapAtCurrPeriod(1), kMaxMachCapAtCurrPeriod(2));

        while iCaseResourceCombo <= iMaxSearchingCase & iFlagContinueSearch == 1
            %%% starting number of Prime Mover
            stJobListInfoAgent.stResourceConfig.stMachineConfig(2).afMaCapAtTimePoint(tActualPeriod) = ...
                nMachCapAtCurrPeriod(1);
            stJobListInfoAgent.stResourceConfig.stMachineConfig(3).afMaCapAtTimePoint(tActualPeriod) = ...
                nMachCapAtCurrPeriod(2);
        
            aNewSearchVector = [stJobListInfoAgent.stResourceConfig.stMachineConfig(2).afMaCapAtTimePoint, ...
                stJobListInfoAgent.stResourceConfig.stMachineConfig(3).afMaCapAtTimePoint];
            if nTotalNumSolutionCaseIncHistory == 0
                iFlagVectorAlreadySearched = 0;
            else
                iFlagVectorAlreadySearched = chk_search_vector(stSolution.astSearchVectorSpace, aNewSearchVector);
            end

            if iFlagVectorAlreadySearched == 0
                stGetSchduleCostInput.stJobListInfoAgent = stJobListInfoAgent;
                stGetSchduleCostInput.stBerthJobInfo     = stBerthJobInfo;
                stGetSchduleCostInput.fFactorHourPerSlot = fFactorHourPerSlot;
                stGetSchduleCostInput.iPriceHourStartIndex = iPriceHourStartIndex;
                stGetSchduleCostInput.iTotalPeriod         = iTotalPeriod;
                [stGetSchduleCostOutput] = fsp_get_sched_cost_by_agent(stGetSchduleCostInput);

                nTotalNumSolutionCaseIncHistory = nTotalNumSolutionCaseIncHistory + 1;
                stSolution.astSearchVectorSpace(nTotalNumSolutionCaseIncHistory).aVector = aNewSearchVector;
                %%%%% recalculate the makespan and cost
                iTotalPeriod_act = ceil(stGetSchduleCostOutput.tMakeSpan_hour);
% stJobListInfoAgent.stResourceConfig.iCriticalMachType
% input('any key') TBA
                
                stSolution.astCase(nTotalNumSolutionCaseIncHistory).stResourceConfig = stJobListInfoAgent.stResourceConfig;
                if iTotalPeriod_act < stJobListInfoAgent.stResourceConfig.stMachineConfig(2).iNumPointTimeCap
                    stSolution.astCase(nTotalNumSolutionCaseIncHistory).stResourceConfig.stMachineConfig(2).iNumPointTimeCap = iTotalPeriod_act;
                    stSolution.astCase(nTotalNumSolutionCaseIncHistory).stResourceConfig.stMachineConfig(3).iNumPointTimeCap = iTotalPeriod_act;
                end

                stSolution.aMakeSpan_hour(nTotalNumSolutionCaseIncHistory) = stGetSchduleCostOutput.tMakeSpan_hour;
                stSolution.astCase(nTotalNumSolutionCaseIncHistory).stContainerSchedule = stGetSchduleCostOutput.stContainerSchedule;

                [fTardinessFine_Sgd, tAgentTardiness_hour] = ... 
                    resalloc_calc_tardi_fine(stBerthJobInfo, stAgentJobInfo, stSolution.aMakeSpan_hour(nTotalNumSolutionCaseIncHistory));
                stSolution.aTardiness_hour(nTotalNumSolutionCaseIncHistory) = tAgentTardiness_hour;
                stSolution.aCostTardinessMakespan(nTotalNumSolutionCaseIncHistory) = ...
                    stSolution.aMakeSpan_hour(nTotalNumSolutionCaseIncHistory) * stAgentJobInfo.fPriceAgentDollarPerFrame + ...
                    fTardinessFine_Sgd;
                stSolution.aTotalCost(nTotalNumSolutionCaseIncHistory) = stSolution.aCostTardinessMakespan(nTotalNumSolutionCaseIncHistory) + ...
                    stGetSchduleCostOutput.fCostPMYC;

                if stBerthJobInfo.iPlotFlag >= 3
                    fsp_dbg_write_file(fptr, stSolution, nTotalNumSolutionCaseIncHistory);
                end
                nCurrentSearchCase = nTotalNumSolutionCaseIncHistory;
            else
                nCurrentSearchCase = iFlagVectorAlreadySearched;
            end

            idxCostMatrixDim(1) = nMachCapAtCurrPeriod(1) - nInitMachCap(1) +1;
            idxCostMatrixDim(2) = nMachCapAtCurrPeriod(2) - nInitMachCap(2) +1;
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
        stJobListInfoAgent.stResourceConfig = stSolution.astCase(iIndexMinCost).stResourceConfig;

        %% 20071104
        iTotalPeriod_act = ceil(stSolution.aMakeSpan_hour(iIndexMinCost));
        iTotalPeriod_curr = stJobListInfoAgent.stResourceConfig.stMachineConfig(2).iNumPointTimeCap;
        if iTotalPeriod_act > iTotalPeriod_curr
            stJobListInfoAgent.stResourceConfig.stMachineConfig(2).iNumPointTimeCap = iTotalPeriod_act;
            stJobListInfoAgent.stResourceConfig.stMachineConfig(3).iNumPointTimeCap = iTotalPeriod_act;
            nNumSlotPerFrame = round(stBerthJobInfo.fTimeFrameUnitInHour * 60 / stJobListInfoAgent.fTimeUnit_Min);
            for pp = iTotalPeriod_curr + 1:1:iTotalPeriod_act
                stJobListInfoAgent.stResourceConfig.stMachineConfig(2).afMaCapAtTimePoint(pp) = ...
                    stJobListInfoAgent.stResourceConfig.stMachineConfig(2).afMaCapAtTimePoint(iTotalPeriod_curr);
                stJobListInfoAgent.stResourceConfig.stMachineConfig(3).afMaCapAtTimePoint(pp) = ...
                    stJobListInfoAgent.stResourceConfig.stMachineConfig(3).afMaCapAtTimePoint(iTotalPeriod_curr);
                stJobListInfoAgent.stResourceConfig.stMachineConfig(2).afTimePointAtCap(pp) = ...
                    stJobListInfoAgent.stResourceConfig.stMachineConfig(2).afTimePointAtCap(iTotalPeriod_curr) + ...
                    (pp - iTotalPeriod_curr) * nNumSlotPerFrame;
                stJobListInfoAgent.stResourceConfig.stMachineConfig(3).afTimePointAtCap(pp) = ...
                    stJobListInfoAgent.stResourceConfig.stMachineConfig(3).afTimePointAtCap(iTotalPeriod_curr) + ...
                    (pp - iTotalPeriod_curr) * nNumSlotPerFrame;
                
            end
            stResourceConfig_Curr = stJobListInfoAgent.stResourceConfig;
            stSolution.astCase(iIndexMinCost).stResourceConfig = stResourceConfig_Curr;
        end
        %% 20071104
%         iter_period = [iter,  tActualPeriod]
    end % for tActualPeriod = 1:1:iTotalPeriod

    [fMinCost, iIndexMinCost] = min(stSolution.aTotalCost(1:nTotalNumSolutionCaseIncHistory));
    stJobListInfoAgent.stResourceConfig = stSolution.astCase(iIndexMinCost).stResourceConfig;
    stResourceConfig_Curr = stSolution.astCase(iIndexMinCost).stResourceConfig;
    
    iter = iter + 1;
end

%%%%% Calculate utility price
iTotalPeriod = stResourceConfig_Curr.stMachineConfig(2).iNumPointTimeCap;
stJobListInfoMinCostCfg = stJobListInfoAgent;
tMakespanMinCost_hour = stSolution.aMakeSpan_hour(iIndexMinCost);
astMachineConfigMinCost(1).aCfgVector = stJobListInfoAgent.stResourceConfig.stMachineConfig(2).afMaCapAtTimePoint;
astMachineConfigMinCost(2).aCfgVector = stJobListInfoAgent.stResourceConfig.stMachineConfig(3).afMaCapAtTimePoint;
stAgentUtilityPrice.iPriceHourStartIndex = iPriceHourStartIndex; % 20070923
stAgentUtilityPrice.iTotalPeriod = stJobListInfoAgent.stResourceConfig.stMachineConfig(2).iNumPointTimeCap;
for tActualPeriod = 1:1:stAgentUtilityPrice.iTotalPeriod
    idxCostMatrixDim(1) = astMachineConfigMinCost(1).aCfgVector(tActualPeriod);
    idxCostMatrixDim(2) = astMachineConfigMinCost(2).aCfgVector(tActualPeriod);
    
%     for rr = 1:1:2 %Currently 2 resources
    % resource No.rr, maps to
    % stJobListInfoAgent_CurrCfg.stResourceConfig.stMachineConfig(rr + 1);
    % astMachineConfigMinCost(rr)
    aNewVector = astMachineConfigMinCost(1).aCfgVector;
    stJobListInfoAgent_CurrCfg = stJobListInfoMinCostCfg;

    if aNewVector(tActualPeriod) - 1 == 0

        aNewVector(tActualPeriod) = aNewVector(tActualPeriod) + 1;
        stJobListInfoAgent_CurrCfg.stResourceConfig.stMachineConfig(2).afMaCapAtTimePoint(tActualPeriod) = aNewVector(tActualPeriod);
        aSearchVectorNearMinCost = [aNewVector, astMachineConfigMinCost(2).aCfgVector];
        iFlagVectorAlreadySearched = chk_search_vector(stSolution.astSearchVectorSpace, aSearchVectorNearMinCost);
        if iFlagVectorAlreadySearched == 0
            stGetSchduleCostInput.stJobListInfoAgent = stJobListInfoAgent_CurrCfg;
            stGetSchduleCostInput.stBerthJobInfo     = stBerthJobInfo;
            stGetSchduleCostInput.fFactorHourPerSlot = fFactorHourPerSlot;
            stGetSchduleCostInput.iPriceHourStartIndex = iPriceHourStartIndex;
            stGetSchduleCostInput.iTotalPeriod         = iTotalPeriod;
            [stGetSchduleCostOutput] = fsp_get_sched_cost_by_agent(stGetSchduleCostInput);

            nTotalNumSolutionCaseIncHistory = nTotalNumSolutionCaseIncHistory + 1;
            stSolution.astSearchVectorSpace(nTotalNumSolutionCaseIncHistory).aVector = aNewSearchVector;
            stSolution.astCase(nTotalNumSolutionCaseIncHistory).stResourceConfig = stJobListInfoAgent_CurrCfg.stResourceConfig;

            stSolution.aMakeSpan_hour(nTotalNumSolutionCaseIncHistory) = stGetSchduleCostOutput.tMakeSpan_hour;
            stSolution.astCase(nTotalNumSolutionCaseIncHistory).stContainerSchedule = stGetSchduleCostOutput.stContainerSchedule;

            [fTardinessFine_Sgd, tAgentTardiness_hour] = ... 
                resalloc_calc_tardi_fine(stBerthJobInfo, stAgentJobInfo, stSolution.aMakeSpan_hour(nTotalNumSolutionCaseIncHistory));
            stSolution.aTardiness_hour(nTotalNumSolutionCaseIncHistory) = tAgentTardiness_hour;
            stSolution.aCostTardinessMakespan(nTotalNumSolutionCaseIncHistory) = ...
                stSolution.aMakeSpan_hour(nTotalNumSolutionCaseIncHistory) * stAgentJobInfo.fPriceAgentDollarPerFrame + ...
                fTardinessFine_Sgd;
            stSolution.aTotalCost(nTotalNumSolutionCaseIncHistory) = stSolution.aCostTardinessMakespan(nTotalNumSolutionCaseIncHistory) + ...
                stGetSchduleCostOutput.fCostPMYC;

            if stBerthJobInfo.iPlotFlag >= 3
                fsp_dbg_write_file(fptr, stSolution, nTotalNumSolutionCaseIncHistory);
            end
            nCurrentSearchCase = nTotalNumSolutionCaseIncHistory;
        else
            nCurrentSearchCase = iFlagVectorAlreadySearched;
        end
        fDeltaMakespan_hour = tMakespanMinCost_hour - stSolution.aMakeSpan_hour(nCurrentSearchCase); % new makespan should be less than MinCostMakespan

    else
        aNewVector(tActualPeriod) = aNewVector(tActualPeriod) - 1;
        stJobListInfoAgent_CurrCfg.stResourceConfig.stMachineConfig(2).afMaCapAtTimePoint(tActualPeriod) = aNewVector(tActualPeriod);
        aSearchVectorNearMinCost = [aNewVector, astMachineConfigMinCost(2).aCfgVector];
        iFlagVectorAlreadySearched = chk_search_vector(stSolution.astSearchVectorSpace, aSearchVectorNearMinCost);
        if iFlagVectorAlreadySearched == 0
            stGetSchduleCostInput.stJobListInfoAgent = stJobListInfoAgent_CurrCfg;
            stGetSchduleCostInput.stBerthJobInfo     = stBerthJobInfo;
            stGetSchduleCostInput.fFactorHourPerSlot = fFactorHourPerSlot;
            stGetSchduleCostInput.iPriceHourStartIndex = iPriceHourStartIndex;
            stGetSchduleCostInput.iTotalPeriod         = iTotalPeriod;
            [stGetSchduleCostOutput] = fsp_get_sched_cost_by_agent(stGetSchduleCostInput);

            nTotalNumSolutionCaseIncHistory = nTotalNumSolutionCaseIncHistory + 1;
            stSolution.astSearchVectorSpace(nTotalNumSolutionCaseIncHistory).aVector = aNewSearchVector;
            stSolution.astCase(nTotalNumSolutionCaseIncHistory).stResourceConfig = stJobListInfoAgent_CurrCfg.stResourceConfig;

            stSolution.aMakeSpan_hour(nTotalNumSolutionCaseIncHistory) = stGetSchduleCostOutput.tMakeSpan_hour;
            stSolution.astCase(nTotalNumSolutionCaseIncHistory).stContainerSchedule = stGetSchduleCostOutput.stContainerSchedule;

            [fTardinessFine_Sgd, tAgentTardiness_hour] = ... 
                resalloc_calc_tardi_fine(stBerthJobInfo, stAgentJobInfo, stSolution.aMakeSpan_hour(nTotalNumSolutionCaseIncHistory));
            stSolution.aTardiness_hour(nTotalNumSolutionCaseIncHistory) = tAgentTardiness_hour;
            stSolution.aCostTardinessMakespan(nTotalNumSolutionCaseIncHistory) = ...
                stSolution.aMakeSpan_hour(nTotalNumSolutionCaseIncHistory) * stAgentJobInfo.fPriceAgentDollarPerFrame + ...
                fTardinessFine_Sgd;
            stSolution.aTotalCost(nTotalNumSolutionCaseIncHistory) = stSolution.aCostTardinessMakespan(nTotalNumSolutionCaseIncHistory) + ...
                stGetSchduleCostOutput.fCostPMYC;

            if stBerthJobInfo.iPlotFlag >= 3
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
    stAgentUtilityPrice.astUtilityPrice(tActualPeriod).fDeltaUtiPriceAtMach(2).iResourceBidding = idxCostMatrixDim(1);

    %%%%%%%% 2nd resource
    aNewVector = astMachineConfigMinCost(2).aCfgVector; %% differ
    stJobListInfoAgent_CurrCfg = stJobListInfoMinCostCfg;

    if aNewVector(tActualPeriod) - 1 == 0

        aNewVector(tActualPeriod) = aNewVector(tActualPeriod) + 1;  
        stJobListInfoAgent_CurrCfg.stResourceConfig.stMachineConfig(3).afMaCapAtTimePoint(tActualPeriod) = aNewVector(tActualPeriod); %% differ
        aSearchVectorNearMinCost = [astMachineConfigMinCost(2).aCfgVector, aNewVector]; %% differ, need to think for improving
        iFlagVectorAlreadySearched = chk_search_vector(stSolution.astSearchVectorSpace, aSearchVectorNearMinCost);
        if iFlagVectorAlreadySearched == 0
            stGetSchduleCostInput.stJobListInfoAgent = stJobListInfoAgent_CurrCfg;
            stGetSchduleCostInput.stBerthJobInfo     = stBerthJobInfo;
            stGetSchduleCostInput.fFactorHourPerSlot = fFactorHourPerSlot;
            stGetSchduleCostInput.iPriceHourStartIndex = iPriceHourStartIndex;
            stGetSchduleCostInput.iTotalPeriod         = iTotalPeriod;
            [stGetSchduleCostOutput] = fsp_get_sched_cost_by_agent(stGetSchduleCostInput);

            nTotalNumSolutionCaseIncHistory = nTotalNumSolutionCaseIncHistory + 1;
            stSolution.astSearchVectorSpace(nTotalNumSolutionCaseIncHistory).aVector = aNewSearchVector;
            stSolution.astCase(nTotalNumSolutionCaseIncHistory).stResourceConfig = stJobListInfoAgent_CurrCfg.stResourceConfig;

            stSolution.aMakeSpan_hour(nTotalNumSolutionCaseIncHistory) = stGetSchduleCostOutput.tMakeSpan_hour;
            stSolution.astCase(nTotalNumSolutionCaseIncHistory).stContainerSchedule = stGetSchduleCostOutput.stContainerSchedule;

            [fTardinessFine_Sgd, tAgentTardiness_hour] = ... 
                resalloc_calc_tardi_fine(stBerthJobInfo, stAgentJobInfo, stSolution.aMakeSpan_hour(nTotalNumSolutionCaseIncHistory));
            stSolution.aTardiness_hour(nTotalNumSolutionCaseIncHistory) = tAgentTardiness_hour;
            stSolution.aCostTardinessMakespan(nTotalNumSolutionCaseIncHistory) = ...
                stSolution.aMakeSpan_hour(nTotalNumSolutionCaseIncHistory) * stAgentJobInfo.fPriceAgentDollarPerFrame + ...
                fTardinessFine_Sgd;
            stSolution.aTotalCost(nTotalNumSolutionCaseIncHistory) = stSolution.aCostTardinessMakespan(nTotalNumSolutionCaseIncHistory) + ...
                stGetSchduleCostOutput.fCostPMYC;

            if stBerthJobInfo.iPlotFlag >= 3
                fsp_dbg_write_file(fptr, stSolution, nTotalNumSolutionCaseIncHistory);
            end
            nCurrentSearchCase = nTotalNumSolutionCaseIncHistory;
        else
            nCurrentSearchCase = iFlagVectorAlreadySearched;
        end
        fDeltaMakespan_hour = tMakespanMinCost_hour - stSolution.aMakeSpan_hour(nCurrentSearchCase); % new makespan should be less than MinCostMakespan

    else
        aNewVector(tActualPeriod) = aNewVector(tActualPeriod) - 1;
        stJobListInfoAgent_CurrCfg.stResourceConfig.stMachineConfig(3).afMaCapAtTimePoint(tActualPeriod) = aNewVector(tActualPeriod);  %% differ
        aSearchVectorNearMinCost = [astMachineConfigMinCost(2).aCfgVector, aNewVector];        %% differ
        iFlagVectorAlreadySearched = chk_search_vector(stSolution.astSearchVectorSpace, aSearchVectorNearMinCost);
        if iFlagVectorAlreadySearched == 0
            stGetSchduleCostInput.stJobListInfoAgent = stJobListInfoAgent_CurrCfg;
            stGetSchduleCostInput.stBerthJobInfo     = stBerthJobInfo;
            stGetSchduleCostInput.fFactorHourPerSlot = fFactorHourPerSlot;
            stGetSchduleCostInput.iPriceHourStartIndex = iPriceHourStartIndex;
            stGetSchduleCostInput.iTotalPeriod         = iTotalPeriod;
            [stGetSchduleCostOutput] = fsp_get_sched_cost_by_agent(stGetSchduleCostInput);

            nTotalNumSolutionCaseIncHistory = nTotalNumSolutionCaseIncHistory + 1;
            stSolution.astSearchVectorSpace(nTotalNumSolutionCaseIncHistory).aVector = aNewSearchVector;
            stSolution.astCase(nTotalNumSolutionCaseIncHistory).stResourceConfig = stJobListInfoAgent_CurrCfg.stResourceConfig;

            stSolution.aMakeSpan_hour(nTotalNumSolutionCaseIncHistory) = stGetSchduleCostOutput.tMakeSpan_hour;
            stSolution.astCase(nTotalNumSolutionCaseIncHistory).stContainerSchedule = stGetSchduleCostOutput.stContainerSchedule;

            [fTardinessFine_Sgd, tAgentTardiness_hour] = ... 
                resalloc_calc_tardi_fine(stBerthJobInfo, stAgentJobInfo, stSolution.aMakeSpan_hour(nTotalNumSolutionCaseIncHistory));
            stSolution.aTardiness_hour(nTotalNumSolutionCaseIncHistory) = tAgentTardiness_hour;
            stSolution.aCostTardinessMakespan(nTotalNumSolutionCaseIncHistory) = ...
                stSolution.aMakeSpan_hour(nTotalNumSolutionCaseIncHistory) * stAgentJobInfo.fPriceAgentDollarPerFrame + ...
                fTardinessFine_Sgd;
            stSolution.aTotalCost(nTotalNumSolutionCaseIncHistory) = stSolution.aCostTardinessMakespan(nTotalNumSolutionCaseIncHistory) + ...
                stGetSchduleCostOutput.fCostPMYC;

            if stBerthJobInfo.iPlotFlag >= 3
                fsp_dbg_write_file(fptr, stSolution, nTotalNumSolutionCaseIncHistory);
            end
            nCurrentSearchCase = nTotalNumSolutionCaseIncHistory;
        else
            nCurrentSearchCase = iFlagVectorAlreadySearched;
        end
        fDeltaMakespan_hour = stSolution.aMakeSpan_hour(nCurrentSearchCase) - tMakespanMinCost_hour;
    end

    stAgentUtilityPrice.astUtilityPrice(tActualPeriod).fDeltaUtiPriceAtMach(3).fDeltaMakespan_hour = fDeltaMakespan_hour;
    stAgentUtilityPrice.astUtilityPrice(tActualPeriod).fDeltaUtiPriceAtMach(3).fUtilityPrice = fDeltaMakespan_hour * stAgentJobInfo.fPriceAgentDollarPerFrame;
    stAgentUtilityPrice.astUtilityPrice(tActualPeriod).fDeltaUtiPriceAtMach(3).iResourceBidding = idxCostMatrixDim(2);
    
%     end
    
    if stBerthJobInfo.iPlotFlag >= 3
        fprintf(fptr, '[DeltaMakespan, UtilityPrice, Bidding] [M1, M2] ', tStartHour, iPriceHourStartIndex);
        for mm = 2:1:3
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

    stJobListInfoAgent.stResourceConfig =  stSolution.astCase(iIndexMinCost).stResourceConfig; %stBuildMachConfigOutput.stResourceConfigSchOut.stResourceConfig;
%     if stBerthJobInfo.stJssProbStructConfig.isCriticalOperateSeq == 1
%         [stPartialScheduleGenSch2, jobshop_config] = psa_jsp_gen_job_schedule_28(stJobListInfoAgent);
%     else
        [stPartialScheduleGenSch2] = fsp_bidir_multi_m_t_ch_seq(stJobListInfoAgent); % must run CH or RH heuristics for strict feasibility
%     end
    stPartialScheduleGenSch2.stResourceConfig = stJobListInfoAgent.stResourceConfig;

else
    stPartialScheduleGenSch2 = stSolution.astCase(iIndexMinCost).stContainerSchedule;
end

if stBerthJobInfo.iPlotFlag >= 3
    fprintf(fptr, '\n\n%%%% Min Cost Schedule\n');
    fsp_dbg_write_file(fptr, stSolution, iIndexMinCost);
end
%stPartialScheduleGenSch2
%max(stJobListInfoAgent.stResourceConfig.stMachineConfig(2).afMaCapAtTimePoint)
stSolution.stCostAtAgent.stSolutionMinCost.stSchedule = stPartialScheduleGenSch2;
% donot dispatch until global feasible 

% construct the real machine usage
[stBuildMachConfigOutput] = psa_fsp_bld_machfig_by_sch ...
    (stBerthJobInfo.fTimeFrameUnitInHour, stJobListInfoAgent.stResourceConfig, stSolution.stCostAtAgent.stSolutionMinCost.stSchedule);
stJobListInfoAgent.stResourceConfig = stBuildMachConfigOutput.stResourceConfigSchOut.stResourceConfig;

%%%% MakeSpan and Tardiness
tMinCostMakeSpan_hour = stSolution.stCostAtAgent.stSolutionMinCost.stSchedule.iMaxEndTime * fFactorHourPerSlot;
[fTardinessFineMinCost_Sgd, tAgentTardiness_hour] = resalloc_calc_tardi_fine(stBerthJobInfo, stAgentJobInfo, tMinCostMakeSpan_hour);

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
        fCostPMYC = fCostPMYC + stBerthJobInfo.astResourceInitPrice(2).afMachinePriceListPerFrame(iPriceHourIndex) * max([0, kUsagePM - stJobListInfoAgent.MaxVirtualPrimeMover]) + ...
            stBerthJobInfo.astResourceInitPrice(3).afMachinePriceListPerFrame(iPriceHourIndex) * max([0, kUsageYC - stJobListInfoAgent.MaxVirtualYardCrane]);
    else
        fCostPMYC = fCostPMYC + stBerthJobInfo.astResourceInitPrice(2).afMachinePriceListPerFrame(iPriceHourIndex) * kUsagePM + ...
            stBerthJobInfo.astResourceInitPrice(3).afMachinePriceListPerFrame(iPriceHourIndex) * kUsageYC;
    end
    
    if iPriceHourIndex == 24
        iPriceHourIndex = 0;
    end
    iPriceHourIndex = iPriceHourIndex + 1;
end

%%%%% Timing
if stBerthJobInfo.iPlotFlag >= 3
    fclose(fptr);
end

tSolution_sec = cputime - t_start;

%%%%% Output
stAgent_Solution = stSolution;
stAgent_Solution.stMinCostResourceConfig = stBuildMachConfigOutput.stResourceConfigSchOut.stResourceConfig;

stAgent_Solution.stPerformReport.tMinCostMakeSpan_hour = tMinCostMakeSpan_hour;
stAgent_Solution.stPerformReport.tMinCostGrossCraneRate = stJobListInfoAgent.jobshop_config.iTotalJob/ stAgent_Solution.stPerformReport.tMinCostMakeSpan_hour;
stAgent_Solution.stPerformReport.fCostMakespanTardiness = tMinCostMakeSpan_hour * stAgentJobInfo.fPriceAgentDollarPerFrame + fTardinessFineMinCost_Sgd;

stAgent_Solution.stPerformReport.fMinCost              = fCostPMYC  + ...
                                                      stAgent_Solution.stPerformReport.fCostMakespanTardiness;
stAgent_Solution.stPerformReport.tSolutionTime_sec = tSolution_sec;
stAgent_Solution.stSchedule_MinCost                   = stAgent_Solution.stCostAtAgent.stSolutionMinCost.stSchedule;
stAgent_Solution.stAgentUtilityPrice                  = stAgentUtilityPrice;
