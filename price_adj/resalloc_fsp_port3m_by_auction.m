function [stOutputResAlloc] = resalloc_fsp_port3m_by_auction(stInputResAlloc)
% resource allocation flow-shop-problem port 3 machine-type, by auction
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
%% interative adjust price for combinatorial item (2 resources) with multiple period problem
% History
% YYYYMMDD  Notes
% 20080301  port from psa case, detection of bad cycles, TBA
% 20080323  Reallocate, Resolve Confliction every round
% 20080420  Improving robustness
%%%%
stAgent_Solution_Init   = stInputResAlloc.stAgent_Solution;
stResAllocGenJspAgent  = stInputResAlloc.stResAllocGenJspAgent;
astAgentJobListJspCfg = stInputResAlloc.astAgentJobListJspCfg;
stJobListInfoAgent = stInputResAlloc.stJobListInfoAgent;

%%% stResourceConfigGenSch0 = stInputResAlloc.stResourceConfigGenSch0;
astResourceConfigSrchSinglePeriod = stInputResAlloc.astResourceConfigSrchSinglePeriod ;
astResourceConfigGenSch0          = stInputResAlloc.astResourceConfigGenSch0          ;

stResAllocGenJspAgent.stPriceDetectCycle.isCycle2 = 0; %%% 20080228
nTotalMachineType = 3; % TBA
nTotalAgent = stResAllocGenJspAgent.iTotalAgent;

%%% Assignment for agent based structure
stInputResAllocAgent.stResAllocGenJspAgent     = stResAllocGenJspAgent              ;
stInputResAllocAgent.iFlagSorting       = stResAllocGenJspAgent.stBidGenSubProbSearch.iFlagSortingPrice            ;
stInputResAllocAgent.iMaxIter_BidGenOpt = stResAllocGenJspAgent.stBidGenSubProbSearch.iMaxIter_LocalSearchBidGen      ;

for aa = 1:1:nTotalAgent
    astAgentJobListJspCfg(aa).jobshop_config   = astAgentJobListJspCfg(aa);
    astAgentJobListJspCfg(aa).aiJobSeqInJspCfg = astAgentJobListJspCfg(aa).aiJobSeqInJspCfg;
    astAgentJobListJspCfg(aa).stResourceConfig = astAgentJobListJspCfg(aa).stResourceConfig;
    astAgentJobListJspCfg(aa).stJspScheduleTemplate = jsp_constr_sche_struct_by_cfg(astAgentJobListJspCfg(aa));
end


iFlagPriceAdjust = stResAllocGenJspAgent.stPriceAjustment.iFlagStrategy; % 20071102
iPlotFlag = stResAllocGenJspAgent.stSystemMasterConfig.iPlotFlag;
% == 0: no stop, plot least figure
% >= 1: stop for prompting
% >= 4: plot all figures, only for NUS-ECE_SMU collaborated users
iAlgoChoice = stResAllocGenJspAgent.stSystemMasterConfig.iAlgoChoice;

t0 = cputime;

%%%% Initial Price
stMachinePriceInfo.astMachinePrice(2).fPricePerFrame = stResAllocGenJspAgent.astResourceInitPrice(2).afMachinePriceListPerFrame;
stMachinePriceInfo.astMachinePrice(3).fPricePerFrame = stResAllocGenJspAgent.astResourceInitPrice(3).afMachinePriceListPerFrame;

fDeltaObj = stResAllocGenJspAgent.stAuctionStrategy.fDeltaObj;               % 20070605
fDeltaPrice = stResAllocGenJspAgent.stAuctionStrategy.fDeltaPrice;
iMinNumFeasibleSolution = stResAllocGenJspAgent.stAuctionStrategy.iMinNumFeasibleSolution;
iConvergingRule = stResAllocGenJspAgent.stAuctionStrategy.iConvergingRule;   
iNumIterDeOscilating = stResAllocGenJspAgent.stAuctionStrategy.iNumIterDeOscilating;
%%% Synchonous flag for price updating
%%% 1: synchronously, trigger only after collecting bids from all the clients
%%% -1: unsynchronously, trigger each time by event of submitting bid
iSynchFlagPriceUpdating = stResAllocGenJspAgent.stAuctionStrategy.iSynchUpdatingBid;
n_feas = 0;   
%%% Initialization output
astFeasibleSolutionSet = [];

%%% Initialization a circular buffer for latest feasible solution
%iLenPriceVector = length(stResAllocGenJspAgent.astResourceInitPrice(2).afMachinePriceListPerFrame) + length(stResAllocGenJspAgent.astResourceInitPrice(3).afMachinePriceListPerFrame);
%for ii = 1:1:iNumIterDeOscilating
%    stConvergingVariableSet(ii).afPriceList = zeros(iLenPriceVector, 1);
%    stConvergingVariableSet(ii).fObjValue = 0;
%end
aiCirBufIdxLastFeasiSolution = zeros(iNumIterDeOscilating, 1);
iIdxCirBufIdxLastFeasiSolution = 0;         % 20070605

%%% initialize output structure % 20070605
stConstraintVialationInfo.nTotalCaseViolation = 0;
stConstraintVialationInfo.astCaseViolation    = [];
iFlagSolution = -1;  %% initialize the solution type to be infeasible
fBestFeasibleSolution = 8888; % 20080323
%%% Interation, auction
iMaxIter = stResAllocGenJspAgent.stAuctionStrategy.iMaxIteration;
iMinIteration = stResAllocGenJspAgent.stAuctionStrategy.iMinIteration ;
iter = 1;

strText = sprintf('MeanSr, Alpha, Itr;\t Sr(1:K) \t IsFeasi, BestObj, IsCyc; \t Top3PriceIdx');
disp(strText);

while iter <= iMaxIter
%for iter = 1:1:7  % for debugging
    %%%%% 20070602, following section should be actually implemented
    %%%%% decentrally
    if iAlgoChoice == 18
        
        %%%%%%%%%% multi-period bid generation, multi-period price adjustment
        for ii = 1:1:nTotalAgent
            
            if iter >= iMinNumFeasibleSolution % 20080304
                stInputResAllocAgent.iFlag_RunGenSch2        = 1 ;
            else
                stInputResAllocAgent.iFlag_RunGenSch2        = 0 ;
            end
            stInputResAllocAgent.iAgentId_dbg      = ii;
            stInputResAllocAgent.stResourceConfigGenSch0          = astResourceConfigGenSch0(ii)  ;
            stInputResAllocAgent.stResourceConfigSrchSinglePeriod = astResourceConfigSrchSinglePeriod(ii) ;
%            stInputResAlloc.stResourceConfigSrchSinglePeriod_ii; % only
%            for initialization
            stInputResAllocAgent.stAgentJobInfo = stResAllocGenJspAgent.stAgentJobInfo(ii);
            stInputResAllocAgent.stAgentJobListJspCfg    = astAgentJobListJspCfg(ii);
            % store the history
            if iter == 1
                stInputResAllocAgent.stAgent_Solution = stAgent_Solution_Init(ii);
            else
                stInputResAllocAgent.stAgent_Solution = stAgent_Solution_BidGen(ii);
            end
            [stAgent_Solution_BidGen_ii] = bidgen_fsp_agent_ful_combo(stInputResAllocAgent);  % 20070921

            stAgent_Solution_BidGen(ii) = stAgent_Solution_BidGen_ii;
            
            if iSynchFlagPriceUpdating == -1
                [stMachinePriceInfo, stMachineUsageInfoBerth, stMachineUsageInfoByAgent] = ...
                    resalloc_bld_res_calc_price(stResAllocGenJspAgent, stAgent_Solution_BidGen, stMachinePriceInfo);
                %%% Update price
                stInputResAllocAgent.stResAllocGenJspAgent.astResourceInitPrice(2).afMachinePriceListPerFrame = stMachinePriceInfo.astMachinePrice(2).fPricePerFrame;
                stInputResAllocAgent.stResAllocGenJspAgent.astResourceInitPrice(3).afMachinePriceListPerFrame = stMachinePriceInfo.astMachinePrice(3).fPricePerFrame;
            end
            
        end
    else
        error('Only enable multi-period bid-generation');
    end

    if iSynchFlagPriceUpdating == 1 || iter == 1
        [stMachinePriceInfo, stMachineUsageInfoBerth, stMachineUsageInfoByAgent] = ...
            resalloc_bld_res_calc_price(stResAllocGenJspAgent, stAgent_Solution_BidGen, stMachinePriceInfo);
        %%% Update price
        stInputResAllocAgent.stResAllocGenJspAgent.astResourceInitPrice(2).afMachinePriceListPerFrame = stMachinePriceInfo.astMachinePrice(2).fPricePerFrame;
        stInputResAllocAgent.stResAllocGenJspAgent.astResourceInitPrice(3).afMachinePriceListPerFrame = stMachinePriceInfo.astMachinePrice(3).fPricePerFrame;
    end
    s_r(iter) = mean(stMachinePriceInfo.s_r);
    alpha(iter) = stMachinePriceInfo.alpha;
    fStepSizePerMachCurrIter = stMachinePriceInfo.s_r;

    aiNetusagePrimeMover = stMachineUsageInfoBerth.astMachineUsage(2).aMachineUsageAfterTime - stMachineUsageInfoBerth.astMachineUsage(2).iMaxCapacity;
    aiNetusageYardCrane = stMachineUsageInfoBerth.astMachineUsage(3).aMachineUsageAfterTime - stMachineUsageInfoBerth.astMachineUsage(3).iMaxCapacity;
    
    aMaxNetDemandPrimeMover(iter) = max(aiNetusagePrimeMover);
    aMaxNetDemandYardCrane(iter) = max(aiNetusageYardCrane);
    [fMaxPricePrimeMover, idxMaxPricePrimeMover] = max(stMachinePriceInfo.astMachinePrice(2).fPricePerFrame);
    aMaxPricePrimeMover(iter) = fMaxPricePrimeMover;
    aidxMaxPricePrimeMover(iter) = idxMaxPricePrimeMover;
    [fMaxPriceYardCrane, idxMaxPriceYardCrane] = max(stMachinePriceInfo.astMachinePrice(3).fPricePerFrame);
    aMaxPriceYardCrane(iter)  = fMaxPriceYardCrane;
    aidxMaxPriceYardCrane(iter) = idxMaxPriceYardCrane;
    
    %%% 20080228
    idxMachPeriod = 0;
    idxPricePeriod = 0;
    for mm = 1:1:nTotalMachineType
        if mm ~= stResAllocGenJspAgent.stSystemMasterConfig.iCriticalMachType
            nTotalMachUsagePeriod = length(stMachineUsageInfoBerth.astMachineUsage(mm).aMachineUsageAfterTime);
            for pp = 1:1:nTotalMachUsagePeriod
                idxMachPeriod = idxMachPeriod + 1;
                aiNetUsageGenMachine(idxMachPeriod) = ...
                    stMachineUsageInfoBerth.astMachineUsage(mm).aMachineUsageAfterTime(pp) ...
                    - stMachineUsageInfoBerth.astMachineUsage(mm).iMaxCapacity;  %% to be generalize later
            end
            nTotalPricePeriod = length(stMachinePriceInfo.astMachinePrice(mm).fPricePerFrame);
            for pp = 1:1:nTotalPricePeriod
                idxPricePeriod = idxPricePeriod + 1;
                afPriceGenMachinePeriod(idxPricePeriod) = stMachinePriceInfo.astMachinePrice(mm).fPricePerFrame(pp);
            end
        end
    end
    [aiSortNetMachUsage, aiIdxSortNetMachUsage ]= sort(aiNetUsageGenMachine);
    [afSortPriceMachPeriod, aiIdxSortPriceMachPeriod] = sort(afPriceGenMachinePeriod);
    %%% 20080228
    
   
    if iPlotFlag >= 5
        input('Press any key');
    end
    
    %%%%% Stopping Criterion, % 20070605
    if max(aiNetUsageGenMachine) <= 0 % 20080304 % & max(aiNetusageYardCrane) <= 0
        iaFlagIsFeasibleSolution(iter) = 1;
        n_feas = n_feas + 1;
        
        %%% Reallocate Unused Resource 20080323
        [stAgent_Solution, stDebugOutput] = ...
            resalloc_reallocate_feas_solutn(stResAllocGenJspAgent, stAgent_Solution_BidGen, stJobListInfoAgent);
        [stMachineUsageInfoBerth, stMachineUsageInfoByAgent] = ...
            psa_bidgen_build_bid_by_cfg(stResAllocGenJspAgent, stAgent_Solution);

        %%% put into set, calculate
        astFeasibleSolutionSet(n_feas).astAgent_Solution = stAgent_Solution;
        
        astFeasibleSolutionSet(n_feas).afPriceListPMandYC = ...
            [stInputResAllocAgent.stResAllocGenJspAgent.astResourceInitPrice(2).afMachinePriceListPerFrame, ...
            stInputResAllocAgent.stResAllocGenJspAgent.astResourceInitPrice(3).afMachinePriceListPerFrame];
        astFeasibleSolutionSet(n_feas).astFeasiblePriceInfo.stMachinePriceInfo = stMachinePriceInfo; % 20080304
        
        fFeasibleObjValue = 0;
        for ii = 1:1:nTotalAgent
            fFeasibleObjValue = fFeasibleObjValue + stAgent_Solution(ii).stPerformReport.fCostMakespanTardiness;
        end
        astFeasibleSolutionSet(n_feas).fFeasibleObjValue = fFeasibleObjValue;
        astFeasibleSolutionSet(n_feas).iIterationInAuction = iter; % 20070704
        if n_feas == 1
            %% Initialization of the Best Feasible
            fBestFeasibleSolution = fFeasibleObjValue;
            iBestSolutionIndex = n_feas;
        else
            if fBestFeasibleSolution > fFeasibleObjValue
                fBestFeasibleSolution = fFeasibleObjValue;
                iBestSolutionIndex = n_feas;
            end
        end
        
        %%% Machine usage confliction resolved
        if iFlagPriceAdjust == 6 && ...
                stResAllocGenJspAgent.stPriceAjustment.iFlagStrategy == 5 ...
                && n_feas >= iMinNumFeasibleSolution/2 %% temperility hard-coded TBA, donot return to smaller step immediately, but seek some optimality
            stResAllocGenJspAgent.stPriceAjustment.iFlagStrategy = 6; %% for the later iterations with feasible solutions
            % 20080304
            stMachinePriceInfo.astMachinePrice(2).fPricePerFrame = ...
                astFeasibleSolutionSet(iBestSolutionIndex).astFeasiblePriceInfo.stMachinePriceInfo.astMachinePrice(2).fPricePerFrame;
            stMachinePriceInfo.astMachinePrice(3).fPricePerFrame = ...
                astFeasibleSolutionSet(iBestSolutionIndex).astFeasiblePriceInfo.stMachinePriceInfo.astMachinePrice(3).fPricePerFrame;
            % 20080304
        end  % 20071102
        
        %% update the circular buffer to the index
        iIdxCirBufIdxLastFeasiSolution = iIdxCirBufIdxLastFeasiSolution + 1;
        if iIdxCirBufIdxLastFeasiSolution > iNumIterDeOscilating
            iIdxCirBufIdxLastFeasiSolution = 1;
        end
        aiCirBufIdxLastFeasiSolution(iIdxCirBufIdxLastFeasiSolution) = n_feas;
%        stConvergingVariableSet(iIdxCirBufIdxLastFeasiSolution).afPriceList = ;
    else
        iaFlagIsFeasibleSolution(iter) = 0;
        
        %%% Resolve Confliction 20080323
 %       [stAgent_Solution, stDebugOutputSolveByPriority] = ...
 %           psa_resalloc_solve_by_priority(stResAllocGenJspAgent, stAgent_Solution, astAgentJobListJspCfg);
        
        if iFlagPriceAdjust == 6 && iter >= 3 && n_feas == 0  % nIterInfeasAdjustByFunc = 10
            stResAllocGenJspAgent.stPriceAjustment.iFlagStrategy = 5; %% for the initial iterations with unfeasible solutions
        end  % 20071102
    end
    
    astMachinePriceInfo(iter) = stMachinePriceInfo;    % 20070704
    astMachineUsageInfoGlobal(iter) = stMachineUsageInfoBerth; % 20070704
    
    
    if iter >= 4 % detection of cyclation % 20080228
        if (abs(alpha(iter) - alpha(iter - 2)) < 0.0001 && ... 
                abs(alpha(iter - 1) - alpha(iter - 3)) < 0.0001) || ...
                (abs(s_r(iter) - s_r(iter - 2)) < 0.0001 && abs(s_r(iter - 1) - s_r(iter - 3)) < 0.0001)
            stResAllocGenJspAgent.stPriceDetectCycle.isCycle2 = 1;
        else
            stResAllocGenJspAgent.stPriceDetectCycle.isCycle2 = 0;
        end
    end
    
    %% Checking not oscilating
    if n_feas >= iMinNumFeasibleSolution && iter >= iMinIteration
        %%%
        iFlagConverging = 1;
        for ii = 2:1:iNumIterDeOscilating
            iCurrIdxInFeasibleSolutionSet = aiCirBufIdxLastFeasiSolution(ii);
            iPrevIdxInFeasibleSolutionSet = aiCirBufIdxLastFeasiSolution(ii-1);
            if iConvergingRule == 0  %%% price only
                if norm(astFeasibleSolutionSet(iCurrIdxInFeasibleSolutionSet).afPriceListPMandYC - ...
                        astFeasibleSolutionSet(iPrevIdxInFeasibleSolutionSet).afPriceListPMandYC) > fDeltaPrice
                    iFlagConverging = 0;
                end
            elseif iConvergingRule == 1  %%% obj value only
                if norm(astFeasibleSolutionSet(iCurrIdxInFeasibleSolutionSet).fFeasibleObjValue - ...
                        astFeasibleSolutionSet(iPrevIdxInFeasibleSolutionSet).fFeasibleObjValue) > fDeltaObj
                    iFlagConverging = 0;
                end
            elseif iConvergingRule == 2
                if (norm(astFeasibleSolutionSet(iCurrIdxInFeasibleSolutionSet).afPriceListPMandYC - ...
                        astFeasibleSolutionSet(iPrevIdxInFeasibleSolutionSet).afPriceListPMandYC) > fDeltaPrice)  ...
                        && ...
                        (norm(astFeasibleSolutionSet(iCurrIdxInFeasibleSolutionSet).fFeasibleObjValue - ...
                        astFeasibleSolutionSet(iPrevIdxInFeasibleSolutionSet).fFeasibleObjValue) > fDeltaObj)
                    
                    iFlagConverging = 0;
                end
            elseif iConvergingRule == 3
                if (norm(astFeasibleSolutionSet(iCurrIdxInFeasibleSolutionSet).afPriceListPMandYC - ...
                        astFeasibleSolutionSet(iPrevIdxInFeasibleSolutionSet).afPriceListPMandYC) > fDeltaPrice)  ...
                        || ...
                        (norm(astFeasibleSolutionSet(iCurrIdxInFeasibleSolutionSet).fFeasibleObjValue - ...
                        astFeasibleSolutionSet(iPrevIdxInFeasibleSolutionSet).fFeasibleObjValue) > fDeltaObj)
                    
                    iFlagConverging = 0;
                end
                
            else
                disp('warning: not recognized converging rule')
                %% always think it is converging
            end
        end
        
        if iFlagConverging == 1
            %% Equilibrium solution has achieved. 20070927
            stAgent_Solution = astFeasibleSolutionSet(iBestSolutionIndex).astAgent_Solution; 
            iFlagSolution = 2; %% Equilibrium Solution
            break;    
        end
    else
    end
    if iPlotFlag >= 0
% ('MeanSr, Alpha, Itr;\t Sr(1:K) \t IsFeasi, BestObj, IsCyc; \t Top3PriceIdx');
        if nTotalMachUsagePeriod ~= nTotalPricePeriod
            anPeriod_MachineUsage_Price = [nTotalMachUsagePeriod, nTotalPricePeriod];
        end
        strText = sprintf('%4.2f, %4.2f, %d;\t', s_r(iter), alpha(iter), iter);
        for mm = 1:1:nTotalMachineType
            strText = sprintf('%s %4.2f,', strText, fStepSizePerMachCurrIter(mm));
        end
        strText = sprintf('%s \t %d, %4.1f, %d;\t', ...
            strText, iaFlagIsFeasibleSolution(iter), ...
            fBestFeasibleSolution, ...  % 20080323
            stResAllocGenJspAgent.stPriceDetectCycle.isCycle2);
        for ii = 1:1:3
            strText = sprintf('%s %4.1f, %d;', ...
                strText, afSortPriceMachPeriod(end + 1 - ii), floor(aiIdxSortPriceMachPeriod(end + 1 - ii)));

        end
        disp(strText);
    end
%     MeanSr_Alpha_Itr_Sr_IsFeasi_IsCyc_Top3PriceIdx = [s_r(iter), alpha(iter), floor(iter), ...
%                           fStepSizePerMachCurrIter, floor(iaFlagIsFeasibleSolution(iter)), ...
%                           floor(stResAllocGenJspAgent.stPriceDetectCycle.isCycle2), ...
%                           afSortPriceMachPeriod(end), floor(aiIdxSortPriceMachPeriod(end)), ...
%                           afSortPriceMachPeriod(end-1), floor(aiIdxSortPriceMachPeriod(end-1)), ...
%                           afSortPriceMachPeriod(end-2), floor(aiIdxSortPriceMachPeriod(end-2)), ...
%                           ]

    iter = iter + 1;
    if iter > iMaxIter
        %%% Still not resolve in the last iteration
        if n_feas >= 1
            stAgent_Solution = astFeasibleSolutionSet(iBestSolutionIndex).astAgent_Solution; 
            iFlagSolution = 1;  %% Best in history feasible solution
        else
            % 20070605 manually adjust to feasible solution
%            save temp_resolve_conflt.mat stResAllocGenJspAgent stAgent_Solution astAgentJobListJspCfg
             aPosnNameDot = strfind(stResAllocGenJspAgent.strInputFilename, '.');
             if length(aPosnNameDot) == 0
                 strCmd_SaveMatFileResvConflt = sprintf('save %s_resolve_conflt.mat stResAllocGenJspAgent stAgent_Solution_BidGen astAgentJobListJspCfg', stResAllocGenJspAgent.strInputFilename);
             else
                 strCmd_SaveMatFileResvConflt = sprintf('save %s_resolve_conflt.mat stResAllocGenJspAgent stAgent_Solution_BidGen astAgentJobListJspCfg', ...
                     stResAllocGenJspAgent.strInputFilename(1:(aPosnNameDot(end)-1)));
             end
             eval(strCmd_SaveMatFileResvConflt);

            [stAgent_Solution, stDebugOutputSolveByPriority] = psa_resalloc_solve_by_priority(stResAllocGenJspAgent, stAgent_Solution_BidGen, astAgentJobListJspCfg);
            stConstraintVialationInfo.nTotalCaseViolation = stDebugOutputSolveByPriority.nTotalCaseViolation;
            stConstraintVialationInfo.astCaseViolation    = stDebugOutputSolveByPriority.astCaseViolation;
            iFlagSolution = 0;  %% Manually adjusted feasible solution
        end
    end
end

% run dispatching
for aa = 1:1:nTotalAgent % stBerthJobInfo.iTotalAgent % 20080304
    stPartialScheduleGenSch2 = stAgent_Solution(aa).stCostAtAgent.stSolutionMinCost.stSchedule;
    [stSchedule] = psa_jsp_dispatch_machine_02(stPartialScheduleGenSch2);
    stAgent_Solution(aa).stCostAtAgent.stSolutionMinCost.stSchedule = stSchedule;
end % 20080304

tSolutionTime_sec = cputime - t0;

fFeasibleObjValue = 0;
for ii = 1:1:nTotalAgent
    fFeasibleObjValue = fFeasibleObjValue + stAgent_Solution(ii).stPerformReport.fCostMakespanTardiness;
end

stSolutionInfo.fTotalCostMakespanTardiness = fFeasibleObjValue;
stSolutionInfo.s_r      = s_r;
stSolutionInfo.fAlphaList = alpha;
stSolutionInfo.iMaxIter = iMaxIter;
stSolutionInfo.iActualIter = iter;
stSolutionInfo.tSolutionTime_sec = tSolutionTime_sec;
stSolutionInfo.nTotalFeasibleSolution = n_feas;
stSolutionInfo.astFeasibleSolutionSet = astFeasibleSolutionSet;
stSolutionInfo.iFlagSolution = iFlagSolution;
stSolutionInfo.iMaxFramesForPlanning = stResAllocGenJspAgent.stSystemMasterConfig.iMaxFramesForPlanning; % 20080420

  %% 0; Manually adjusted feasible solution
  %% 1; Best in history feasible solution
  %% 2; Equilibrium Solution
stSolutionInfo.aMaxNetDemandPrimeMover = aMaxNetDemandPrimeMover;
stSolutionInfo.aMaxNetDemandYardCrane  = aMaxNetDemandYardCrane;
stSolutionInfo.aMaxPricePrimeMover     = aMaxPricePrimeMover;
stSolutionInfo.aMaxPriceYardCrane      = aMaxPriceYardCrane;
stSolutionInfo.aidxMaxPricePrimeMover  = aidxMaxPricePrimeMover;
stSolutionInfo.aidxMaxPriceYardCrane   = aidxMaxPriceYardCrane;
stSolutionInfo.astMachineUsageInfoGlobal = astMachineUsageInfoGlobal;    % 20070704
stSolutionInfo.astMachinePriceInfo      = astMachinePriceInfo;         % 20070704

stOutputResAlloc.stMachineUsageInfoBerth = stMachineUsageInfoBerth;
stOutputResAlloc.stMachineUsageInfoByAgent  = stMachineUsageInfoByAgent;
stOutputResAlloc.stAgent_Solution           = stAgent_Solution;
stOutputResAlloc.stSolutionInfo          = stSolutionInfo;
stOutputResAlloc.stMachinePriceInfo      = stMachinePriceInfo;       % 20070704
stOutputResAlloc.astFeasibleSolutionSet  = astFeasibleSolutionSet;
stOutputResAlloc.stConstraintVialationInfo = stConstraintVialationInfo;

stAgent_Solution.stPerformReport

%%% plotting solution
% if iPlotFlag >= 1
%     stIdFigure.iAllScheGroupByMachine = 101;
%     stIdFigure.iAllScheGroupByJob = 102;
%     psa_plot_resalloc_sch_all_in_1(stAgent_Solution, stIdFigure);
% end