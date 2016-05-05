function [stOutputResAlloc] = resalloc_fsp_by_auction(stInputResAlloc)
%% interative adjust price for combinatorial item (2 resources) with multiple period problem
% History
% YYYYMMDD  Notes
% 20070602  Release ComplementarySearch
% 20070605  improve stoping criterion zzy
% 20070704  Output complete price and netDemand history, required by JongHan, done by zzy
%           Add feasible solution information package into stSolutionInfo
% 20070921  Add full combo search
% 20070927  return the best solution even in equlibrium
% 20071102  combine price adj 5 into 6
% 20080228  detection of bad cycles, TBA
% 20080304  Debug
%%%%
stAgent_Solution   = stInputResAlloc.stAgent_Solution;
stBerthJobInfo  = stInputResAlloc.stBerthJobInfo;
stJobListInfoAgent = stInputResAlloc.stJobListInfoAgent;
%%% stResourceConfigGenSch0 = stInputResAlloc.stResourceConfigGenSch0;
astResourceConfigSrchSinglePeriod = stInputResAlloc.astResourceConfigSrchSinglePeriod ;
astResourceConfigGenSch0          = stInputResAlloc.astResourceConfigGenSch0          ;

stBerthJobInfo.stPriceDetectCycle.isCycle2 = 0; %%% 20080228
nTotalMachineType = 3;

%%% Assignment for agent based structure
stInputResAllocAgent.stBerthJobInfo     = stBerthJobInfo              ;
stInputResAllocAgent.iFlagSorting       = stInputResAlloc.iFlagSorting            ;
stInputResAllocAgent.iMaxIter_BidGenOpt = stInputResAlloc.iMaxIter_BidGenOpt      ;

iFlagPriceAdjust = stBerthJobInfo.stPriceAjustment.iFlagStrategy; % 20071102

iPlotFlag = stBerthJobInfo.iPlotFlag;
% == 0: no stop, plot least figure
% >= 1: stop for prompting
% >= 4: plot all figures, only for NUS-ECE_SMU collaborated users

t0 = cputime;

%%%% Initial Price
stMachinePriceInfo.astMachinePrice(2).fPricePerFrame = stBerthJobInfo.fPricePrimeMoverDollarPerFrame;
stMachinePriceInfo.astMachinePrice(3).fPricePerFrame = stBerthJobInfo.fPriceYardCraneDollarPerFrame;

fDeltaObj = stBerthJobInfo.stAuctionStrategy.fDeltaObj;               % 20070605
fDeltaPrice = stBerthJobInfo.stAuctionStrategy.fDeltaPrice;
iMinNumFeasibleSolution = stBerthJobInfo.stAuctionStrategy.iMinNumFeasibleSolution;
iConvergingRule = stBerthJobInfo.stAuctionStrategy.iConvergingRule;   
iNumIterDeOscilating = stBerthJobInfo.stAuctionStrategy.iNumIterDeOscilating;
%%% Synchonous flag for price updating
%%% 1: synchronously, trigger only after collecting bids from all the clients
%%% -1: unsynchronously, trigger each time by event of submitting bid
iSynchFlagPriceUpdating = stBerthJobInfo.stAuctionStrategy.iSynchUpdatingBid;
n_feas = 0;   
%%% Initialization output
astFeasibleSolutionSet = [];

%%% Initialization a circular buffer for latest feasible solution
%iLenPriceVector = length(stBerthJobInfo.fPricePrimeMoverDollarPerFrame) + length(stBerthJobInfo.fPriceYardCraneDollarPerFrame);
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

%%% Interation, auction
iMaxIter = stBerthJobInfo.stAuctionStrategy.iMaxIteration;
iMinIteration = stBerthJobInfo.stAuctionStrategy.iMinIteration ;
iter = 1;
while iter <= iMaxIter

    %%%%% 20070602, following section should be actually implemented
    %%%%% decentrally
    if stBerthJobInfo.iAlgoChoice == 7 | ...
            stBerthJobInfo.iAlgoChoice == 18 | stBerthJobInfo.iAlgoChoice == 20  ...
            | stBerthJobInfo.iAlgoChoice == 19 | stBerthJobInfo.iAlgoChoice == 21 
        %%%%%%%%%% multi-period bid generation, multi-period price adjustment
        for ii = 1:1:stBerthJobInfo.iTotalAgent
            
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
            stInputResAllocAgent.stAgentJobInfo = stBerthJobInfo.stAgentJobInfo(ii);
            stInputResAllocAgent.stJobListInfoAgent    = stBerthJobInfo.stJobListInfoAgent(ii);
            % store the history
            stInputResAllocAgent.stAgent_Solution = stAgent_Solution(ii);
                %% By GenSch3, Algo 18, 19, 20
            if stBerthJobInfo.iAlgoChoice == 18
                [stAgent_Solution_ii] = bidgen_fsp_agent_ful_combo(stInputResAllocAgent);  % 20070921
            else
                [stAgent_Solution_ii] = bidgen_fsp_port_agent(stInputResAllocAgent);  %psa_bidgen_mp_srch_gensch3(stInputResAlloc);
            end

            stAgent_Solution(ii) = stAgent_Solution_ii;
            
            if iSynchFlagPriceUpdating == -1
                [stMachinePriceInfo, stMachineUsageInfoBerth, stMachineUsageInfoByAgent] = resalloc_bld_res_calc_price(stBerthJobInfo, stAgent_Solution, stMachinePriceInfo);
                %%% Update price
                stInputResAllocAgent.stBerthJobInfo.fPricePrimeMoverDollarPerFrame = stMachinePriceInfo.astMachinePrice(2).fPricePerFrame;
                stInputResAllocAgent.stBerthJobInfo.fPriceYardCraneDollarPerFrame = stMachinePriceInfo.astMachinePrice(3).fPricePerFrame;
                stInputResAllocAgent.stBerthJobInfo.astResourceInitPrice(2).afMachinePriceListPerFrame = stMachinePriceInfo.astMachinePrice(2).fPricePerFrame;
                stInputResAllocAgent.stBerthJobInfo.astResourceInitPrice(3).afMachinePriceListPerFrame = stMachinePriceInfo.astMachinePrice(3).fPricePerFrame;
            end
            
        end
    else
        error('Only enable multi-period bid-generation');
    end

    if iSynchFlagPriceUpdating == 1 | iter == 1
        [stMachinePriceInfo, stMachineUsageInfoBerth, stMachineUsageInfoByAgent] = resalloc_bld_res_calc_price(stBerthJobInfo, stAgent_Solution, stMachinePriceInfo);
        %%% Update price
        stInputResAllocAgent.stBerthJobInfo.fPricePrimeMoverDollarPerFrame = stMachinePriceInfo.astMachinePrice(2).fPricePerFrame;
        stInputResAllocAgent.stBerthJobInfo.fPriceYardCraneDollarPerFrame = stMachinePriceInfo.astMachinePrice(3).fPricePerFrame;
        stInputResAllocAgent.stBerthJobInfo.astResourceInitPrice(2).afMachinePriceListPerFrame = stMachinePriceInfo.astMachinePrice(2).fPricePerFrame;
        stInputResAllocAgent.stBerthJobInfo.astResourceInitPrice(3).afMachinePriceListPerFrame = stMachinePriceInfo.astMachinePrice(3).fPricePerFrame;
    end
    s_r(iter) = mean(stMachinePriceInfo.s_r);
    alpha(iter) = stMachinePriceInfo.alpha;
    fStepSizePerMachCurrIter = stMachinePriceInfo.s_r;

    aPricePrimeMover_From8Clock = stInputResAllocAgent.stBerthJobInfo.fPricePrimeMoverDollarPerFrame(8:24);
    aiNetusagePrimeMover = stMachineUsageInfoBerth.astMachineUsage(2).aMachineUsageAfterTime - stMachineUsageInfoBerth.astMachineUsage(2).iMaxCapacity;
    aPriceYardCrane_From8Clock  = stInputResAllocAgent.stBerthJobInfo.fPriceYardCraneDollarPerFrame(8:24);
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
        if mm ~= stBerthJobInfo.stSystemMasterConfig.iCriticalMachType
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
            if nTotalMachUsagePeriod ~= nTotalPricePeriod
%                anPeriod_MachineUsage_Price = [nTotalMachUsagePeriod, nTotalPricePeriod]
                 strText = sprintf('mType:%d, TotalUsagePeriod-%d TotalPricingPeriod-%d', ...
                     mm, nTotalMachUsagePeriod, nTotalPricePeriod);
                 disp(strText);
            end
        end
    end
    [aiSortNetMachUsage, aiIdxSortNetMachUsage ]= sort(aiNetUsageGenMachine);
    [afSortPriceMachPeriod, aiIdxSortPriceMachPeriod] = sort(afPriceGenMachinePeriod);
    %%% 20080228
    astConvergingInfo(iter).aiSortNetMachUsage = aiSortNetMachUsage;
    astConvergingInfo(iter).aiIdxSortNetMachUsage = aiIdxSortNetMachUsage;
    astConvergingInfo(iter).afSortPriceMachPeriod = afSortPriceMachPeriod;
    astConvergingInfo(iter).aiIdxSortPriceMachPeriod = aiIdxSortPriceMachPeriod;
    
    astMachinePriceInfo(iter) = stMachinePriceInfo;    % 20070704
    astMachineUsageInfoGlobal(iter) = stMachineUsageInfoBerth; % 20070704
    if iPlotFlag >= 5
        input('Press any key');
    end
    
    %%%%% Stopping Criterion, % 20070605
    if max(aiNetUsageGenMachine) <= 0 % & max(aiNetusageYardCrane) <= 0
        iaFlagIsFeasibleSolution(iter) = 1;
        n_feas = n_feas + 1;
        
        %%% Machine usage confliction resolved
        if iFlagPriceAdjust == 6 & stBerthJobInfo.stPriceAjustment.iFlagStrategy == 5 ...
                & n_feas >= iMinNumFeasibleSolution %% temperility hard-coded TBA, donot return to smaller step immediately, but seek some optimality
            stBerthJobInfo.stPriceAjustment.iFlagStrategy = 6; %% for the later iterations with feasible solutions
            % 20080304
            stMachinePriceInfo.astMachinePrice(2).fPricePerFrame = ...
                astFeasibleSolutionSet(iBestSolutionIndex).astFeasiblePriceInfo.stMachinePriceInfo.astMachinePrice(2).fPricePerFrame;
            stMachinePriceInfo.astMachinePrice(3).fPricePerFrame = ...
                astFeasibleSolutionSet(iBestSolutionIndex).astFeasiblePriceInfo.stMachinePriceInfo.astMachinePrice(3).fPricePerFrame;
            % 20080304
        end  % 20071102
        
        for aa = 1:1:stBerthJobInfo.iTotalAgent % 20080304
            stPartialScheduleGenSch2 = stAgent_Solution(aa).stCostAtAgent.stSolutionMinCost.stSchedule;
            [stSchedule] = psa_jsp_dispatch_machine_02(stPartialScheduleGenSch2);
            stAgent_Solution(aa).stCostAtAgent.stSolutionMinCost.stSchedule = stSchedule;
        end % 20080304

        astFeasibleSolutionSet(n_feas).astAgent_Solution = stAgent_Solution;
        astFeasibleSolutionSet(n_feas).afPriceListPMandYC = ... % TBA
            [stInputResAllocAgent.stBerthJobInfo.fPricePrimeMoverDollarPerFrame, stInputResAllocAgent.stBerthJobInfo.fPriceYardCraneDollarPerFrame];
        astFeasibleSolutionSet(n_feas).astFeasiblePriceInfo.stMachinePriceInfo = stMachinePriceInfo; % 20080304
        fFeasibleObjValue = 0;
        for ii = 1:1:stBerthJobInfo.iTotalAgent
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
        
        %% update the circular buffer to the index
        iIdxCirBufIdxLastFeasiSolution = iIdxCirBufIdxLastFeasiSolution + 1;
        if iIdxCirBufIdxLastFeasiSolution > iNumIterDeOscilating
            iIdxCirBufIdxLastFeasiSolution = 1;
        end
        aiCirBufIdxLastFeasiSolution(iIdxCirBufIdxLastFeasiSolution) = n_feas;
%        stConvergingVariableSet(iIdxCirBufIdxLastFeasiSolution).afPriceList = ;
    else
        iaFlagIsFeasibleSolution(iter) = 0;
        if iFlagPriceAdjust == 6 & iter >= 3 & n_feas == 0  % nIterInfeasAdjustByFunc = 10
            stBerthJobInfo.stPriceAjustment.iFlagStrategy = 5; %% for the initial iterations with unfeasible solutions
        end  % 20071102
    end
%     astConvergingInfo(iter).aiSortNetMachUsage;
%     astConvergingInfo(iter).aiIdxSortNetMachUsage;
%     astConvergingInfo(iter).afSortPriceMachPeriod;
%     astConvergingInfo(iter).aiIdxSortPriceMachPeriod;
    
    if iter >= 4 % detection of cyclation % 20080228
        if (abs(alpha(iter) - alpha(iter - 2)) < 0.0001 & abs(alpha(iter - 1) - alpha(iter - 3)) < 0.0001) ...
                | (abs(s_r(iter) - s_r(iter - 2)) < 0.0001 & abs(s_r(iter - 1) - s_r(iter - 3)) < 0.0001)
%           if (astConvergingInfo(iter).aiIdxSortNetMachUsage(end) ...
%                   == astConvergingInfo(iter-1).aiIdxSortNetMachUsage(end-1) ...
%                 & astConvergingInfo(iter-1).aiIdxSortNetMachUsage(end-1) ...
%                   == astConvergingInfo(iter-2).aiIdxSortNetMachUsage(end) ...
%                 & astConvergingInfo(iter-2).aiIdxSortNetMachUsage(end) ...
%                   == astConvergingInfo(iter-3).aiIdxSortNetMachUsage(end-1)) ...
%             & (astConvergingInfo(iter).aiIdxSortNetMachUsage(end-1) ...
%                   == astConvergingInfo(iter-1).aiIdxSortNetMachUsage(end) ...
%                 & astConvergingInfo(iter-1).aiIdxSortNetMachUsage(end) ...
%                   == astConvergingInfo(iter-2).aiIdxSortNetMachUsage(end-1) ...
%                 & astConvergingInfo(iter-2).aiIdxSortNetMachUsage(end-1) ...
%                   == astConvergingInfo(iter-3).aiIdxSortNetMachUsage(end)) ...
%             & (astConvergingInfo(iter).aiSortNetMachUsage(end) > 0 ...
%                 & astConvergingInfo(iter).aiSortNetMachUsage(end-1) > 0 )
            stBerthJobInfo.stPriceDetectCycle.isCycle2 = 1;
        else
            stBerthJobInfo.stPriceDetectCycle.isCycle2 = 0;
        end
    end
    
    %% Checking not oscilating
    if n_feas >= iMinNumFeasibleSolution & iter >= iMinIteration
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
                        & ...
                        (norm(astFeasibleSolutionSet(iCurrIdxInFeasibleSolutionSet).fFeasibleObjValue - ...
                        astFeasibleSolutionSet(iPrevIdxInFeasibleSolutionSet).fFeasibleObjValue) > fDeltaObj)
                    
                    iFlagConverging = 0;
                end
            elseif iConvergingRule == 3
                if (norm(astFeasibleSolutionSet(iCurrIdxInFeasibleSolutionSet).afPriceListPMandYC - ...
                        astFeasibleSolutionSet(iPrevIdxInFeasibleSolutionSet).afPriceListPMandYC) > fDeltaPrice)  ...
                        | ...
                        (norm(astFeasibleSolutionSet(iCurrIdxInFeasibleSolutionSet).fFeasibleObjValue - ...
                        astFeasibleSolutionSet(iPrevIdxInFeasibleSolutionSet).fFeasibleObjValue) > fDeltaObj)
                    
                    iFlagConverging = 0;
                end
                
            else
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
    
    if iPlotFlag >= 1
        strText = sprintf('MeanSr \t Alpha \t Itr \t Sr(1:K) \t IsFeasi \t IsCyc \t Top3PriceIdx');
        disp(strText);
        strText = sprintf('%4.2f , %4.2f , %d ;', s_r(iter), alpha(iter), iter);
        for mm = 1:1:nTotalMachineType
            strText = sprintf('%s %4.2f,', strText, fStepSizePerMachCurrIter(mm));
        end
        strText = sprintf('%s %d, %d; ', ...
            strText, iaFlagIsFeasibleSolution(iter), stBerthJobInfo.stPriceDetectCycle.isCycle2);
        for ii = 1:1:3
            strText = sprintf('%s %4.1f, %d;', ...
                strText, afSortPriceMachPeriod(end + 1 - ii), floor(aiIdxSortPriceMachPeriod(end + 1 - ii)));

        end
        disp(strText);
    end
%     MeanSr_Alpha_Itr_Sr_IsFeasi_IsCyc_Top3PriceIdx = [s_r(iter), alpha(iter), floor(iter), ...
%                           fStepSizePerMachCurrIter, floor(iaFlagIsFeasibleSolution(iter)), ...
%                           floor(stBerthJobInfo.stPriceDetectCycle.isCycle2), ...
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
%            save temp_resolve_conflt.mat stBerthJobInfo stAgent_Solution stJobListInfoAgent
             aPosnNameDot = strfind(stBerthJobInfo.strInputFilename, '.');
             if length(aPosnNameDot) == 0
                 strCmd_SaveMatFileResvConflt = sprintf('save %s_resolve_conflt.mat stBerthJobInfo stAgent_Solution stJobListInfoAgent', stBerthJobInfo.strInputFilename)
             else
                 strCmd_SaveMatFileResvConflt = sprintf('save %s_resolve_conflt.mat stBerthJobInfo stAgent_Solution stJobListInfoAgent', ...
                     stBerthJobInfo.strInputFilename(1:(aPosnNameDot(end)-1)));
             end
             eval(strCmd_SaveMatFileResvConflt);

            [stAgent_Solution, stDebugOutputSolveByPriority] = psa_resalloc_solve_by_priority(stBerthJobInfo, stAgent_Solution, stJobListInfoAgent);
            stConstraintVialationInfo.nTotalCaseViolation = stDebugOutputSolveByPriority.nTotalCaseViolation;
            stConstraintVialationInfo.astCaseViolation    = stDebugOutputSolveByPriority.astCaseViolation;
            iFlagSolution = 0;  %% Manually adjusted feasible solution
        end
    end
end

tSolutionTime_sec = cputime - t0;

fFeasibleObjValue = 0;
for ii = 1:1:stBerthJobInfo.iTotalAgent
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