function [stOutputResAlloc] = resalloc_gen_fsp_by_auction(stInputResAlloc)
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
%%%%
stAgent_Solution   = stInputResAlloc.stAgent_Solution;
stResAllocGenJspAgent  = stInputResAlloc.stResAllocGenJspAgent;
astAgentJobListBiFspCfg         = stInputResAlloc.astAgentJobListBiFspCfg;
astAgentJobListJspCfg           = stInputResAlloc.astAgentJobListJspCfg;
astResourceConfigGenSch0        = stInputResAlloc.astResourceConfigGenSch0;

%stJobListInfoAgent = stInputResAlloc.stJobListInfoAgent;
stSystemMasterConfig  = stResAllocGenJspAgent.stSystemMasterConfig;

astMachinePrice = stResAllocGenJspAgent.astResourceInitPrice; % .afMachinePriceListPerFrame

%astResourceConfigSrchSinglePeriod = stInputResAlloc.astResourceConfigSrchSinglePeriod ;

stResAllocGenJspAgent.iTotalAgent           = stSystemMasterConfig.iTotalAgent;
stResAllocGenJspAgent.fTimeFrameUnitInHour  = stSystemMasterConfig.fTimeFrameUnitInHour;
stResAllocGenJspAgent.iTotalMachType        = stSystemMasterConfig.iTotalMachType;
stResAllocGenJspAgent.tPlanningWindow_Hours = stSystemMasterConfig.tPlanningWindow_Hours;
stResAllocGenJspAgent.iAlgoChoice = stSystemMasterConfig.iAlgoChoice;
iTotalMachType = stSystemMasterConfig.iTotalMachType;

%%%% Initial Price
for mm = 1:1:iTotalMachType
    stMachinePriceInfo.astMachinePrice(mm).fPricePerFrame = astMachinePrice(mm).afMachinePriceListPerFrame;
end

%%% Assignment for agent based structure
%stInputResAllocAgent.stResAllocGenJspAgent     = stResAllocGenJspAgent              ;
stInputResAllocAgent.iFlagSorting       = stInputResAlloc.iFlagSorting            ;
stInputResAllocAgent.iMaxIter_BidGenOpt = stInputResAlloc.iMaxIter_BidGenOpt      ;
stInputResAllocAgent.stSystemMasterConfig = stSystemMasterConfig;
stInputResAllocAgent.strInputFilename     = stResAllocGenJspAgent.strInputFilename;
stInputResAllocAgent.stJssProbStructConfig= stResAllocGenJspAgent.stJssProbStructConfig;
stInputResAllocAgent.stGlobalResourceConfig = stResAllocGenJspAgent.stResourceConfig;

% stInputResAllocAgent.anUppBoundSrchMachCap = stInputResAlloc.anUppBoundSrchMachCap;
iFlagPriceAdjust = stResAllocGenJspAgent.stPriceAjustment.iFlagStrategy; % 20071102
if iFlagPriceAdjust == 6
    stResAllocGenJspAgent.stPriceAjustment.iFlagStrategy = 5; %% for the initial iterations with unfeasible solutions
end  % 20071102

iPlotFlag = stResAllocGenJspAgent.iPlotFlag;
% == 0: no stop, plot least figure
% >= 1: stop for prompting
% >= 4: plot all figures, only for NUS-ECE_SMU collaborated users

t0 = cputime;


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
%iLenPriceVector = length(stResAllocGenJspAgent.fPricePrimeMoverDollarPerFrame) + length(stResAllocGenJspAgent.fPriceYardCraneDollarPerFrame);
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
iMaxIter = stResAllocGenJspAgent.stAuctionStrategy.iMaxIteration;
iMinIteration = stResAllocGenJspAgent.stAuctionStrategy.iMinIteration ;
iter = 1;
while iter <= iMaxIter

    %%%%% 20070602, following section should be actually implemented
    %%%%% decentrally
    if iSynchFlagPriceUpdating == 1 | iter == 1
        [stMachinePriceInfo, stMachineUsageInfoSystem, stMachineUsageInfoByAgent] = resalloc_calc_price(stResAllocGenJspAgent, stAgent_Solution, stMachinePriceInfo);
        %%% Update price
        stInputResAllocAgent.astMachinePrice = stMachinePriceInfo.astMachinePrice;
%         stInputResAllocAgent.stResAllocGenJspAgent.fPricePrimeMoverDollarPerFrame = stMachinePriceInfo.astMachinePrice(1).fPricePerFrame;
%         stInputResAllocAgent.stResAllocGenJspAgent.fPriceYardCraneDollarPerFrame = stMachinePriceInfo.astMachinePrice(2).fPricePerFrame;
    end
        %%%%%%%%%% multi-period bid generation, multi-period price adjustment
        for ii = 1:1:stSystemMasterConfig.iTotalAgent
            if iSynchFlagPriceUpdating == -1
                [stMachinePriceInfo, stMachineUsageInfoSystem, stMachineUsageInfoByAgent] = resalloc_calc_price(stResAllocGenJspAgent, stAgent_Solution, stMachinePriceInfo);
                %%% Update price
                stInputResAllocAgent.astMachinePrice = stMachinePriceInfo.astMachinePrice;
%                 stInputResAllocAgent.stResAllocGenJspAgent.fPricePrimeMoverDollarPerFrame = stMachinePriceInfo.astMachinePrice(1).fPricePerFrame;
%                 stInputResAllocAgent.stResAllocGenJspAgent.fPriceYardCraneDollarPerFrame = stMachinePriceInfo.astMachinePrice(2).fPricePerFrame;
            end
            
            stInputResAllocAgent.iFlag_RunGenSch2        = 1 ;
            stInputResAllocAgent.iQuayCrane_id      = ii;
            stInputResAllocAgent.stResourceConfigGenSch0          = astResourceConfigGenSch0(ii)  ;
%            stInputResAllocAgent.stResourceConfigSrchSinglePeriod = astResourceConfigSrchSinglePeriod(ii) ;
%            stInputResAlloc.stResourceConfigSrchSinglePeriod_ii; % only
%            for initialization
            stInputResAllocAgent.stAgentJobInfo = stResAllocGenJspAgent.stAgentJobInfo(ii);
            stInputResAllocAgent.astAgentJobListJspCfg    = astAgentJobListJspCfg(ii);
            % store the history
            stInputResAllocAgent.stAgent_Solution = stAgent_Solution(ii);
                %% By GenSch3, Algo 18, 19, 20
            [stAgent_Solution_ii] = bidgen_fsp_agent_ful_combo(stInputResAllocAgent);  % 20070921

            stAgent_Solution(ii) = stAgent_Solution_ii;
            
            
        end

    s_r(iter) = stMachinePriceInfo.s_r(1);
    alpha(iter) = stMachinePriceInfo.alpha;
    
    aPricePrimeMover_From8Clock = stInputResAllocAgent.stResAllocGenJspAgent.fPricePrimeMoverDollarPerFrame(8:24);
    aiNetusagePrimeMover = stMachineUsageInfoSystem.astMachineUsage(1).aMachineUsageAfterTime - stMachineUsageInfoSystem.astMachineUsage(1).iMaxCapacity;
    aPriceYardCrane_From8Clock  = stInputResAllocAgent.stResAllocGenJspAgent.fPriceYardCraneDollarPerFrame(8:24);
    aiNetusageYardCrane = stMachineUsageInfoSystem.astMachineUsage(2).aMachineUsageAfterTime - stMachineUsageInfoSystem.astMachineUsage(2).iMaxCapacity;
    
    aMaxNetDemandPrimeMover(iter) = max(aiNetusagePrimeMover);
    aMaxNetDemandYardCrane(iter) = max(aiNetusageYardCrane);
    [fMaxPricePrimeMover, idxMaxPricePrimeMover] = max(stMachinePriceInfo.astMachinePrice(1).fPricePerFrame);
    aMaxPricePrimeMover(iter) = fMaxPricePrimeMover;
    aidxMaxPricePrimeMover(iter) = idxMaxPricePrimeMover;
    [fMaxPriceYardCrane, idxMaxPriceYardCrane] = max(stMachinePriceInfo.astMachinePrice(2).fPricePerFrame);
    aMaxPriceYardCrane(iter)  = fMaxPriceYardCrane;
    aidxMaxPriceYardCrane(iter) = idxMaxPriceYardCrane;
    
    astMachinePriceInfo(iter) = stMachinePriceInfo;    % 20070704
    astMachineUsageInfoSystem(iter) = stMachineUsageInfoSystem; % 20070704
    
    Sr_Alpha_Iter = [s_r(iter), alpha(iter), iter]
    if iPlotFlag >= 5
        input('Press any key');
    end
    
    %%%%% Stopping Criterion, % 20070605
    if max(aiNetusagePrimeMover) <= 0 & max(aiNetusageYardCrane) <= 0
        %%% Machine usage confliction resolved
        if iFlagPriceAdjust == 6 & stResAllocGenJspAgent.stPriceAjustment.iFlagStrategy == 5
            stResAllocGenJspAgent.stPriceAjustment.iFlagStrategy = 6; %% for the later iterations with feasible solutions
        end  % 20071102
        
        n_feas = n_feas + 1;
        astFeasibleSolutionSet(n_feas).astAgent_Solution = stAgent_Solution;
        astFeasibleSolutionSet(n_feas).afPriceListPMandYC = [stInputResAllocAgent.stResAllocGenJspAgent.fPricePrimeMoverDollarPerFrame, stInputResAllocAgent.stResAllocGenJspAgent.fPriceYardCraneDollarPerFrame];
        fFeasibleObjValue = 0;
        for ii = 1:1:stSystemMasterConfig.iTotalAgent
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

    iter = iter + 1;
    if iter > iMaxIter
        %%% Still not resolve in the last iteration
        if n_feas >= 1
            stAgent_Solution = astFeasibleSolutionSet(iBestSolutionIndex).astAgent_Solution; 
            iFlagSolution = 1;  %% Best in history feasible solution
        else
            % 20070605 manually adjust to feasible solution
%            save temp_resolve_conflt.mat stResAllocGenJspAgent stAgent_Solution stJobListInfoAgent
             aPosnNameDot = strfind(stResAllocGenJspAgent.strInputFilename, '.');
             if length(aPosnNameDot) == 0
                 strCmd_SaveMatFileResvConflt = sprintf('save %s_resolve_conflt.mat stResAllocGenJspAgent stAgent_Solution astAgentJobListJspCfg', stResAllocGenJspAgent.strInputFilename)
             else
                 strCmd_SaveMatFileResvConflt = sprintf('save %s_resolve_conflt.mat stResAllocGenJspAgent stAgent_Solution astAgentJobListJspCfg', ...
                     stResAllocGenJspAgent.strInputFilename(1:(aPosnNameDot(end)-1)));
             end
             eval(strCmd_SaveMatFileResvConflt);

            [stAgent_Solution, stDebugOutputSolveByPriority] = psa_resalloc_solve_by_priority(stResAllocGenJspAgent, stAgent_Solution, stJobListInfoAgent);
            stConstraintVialationInfo.nTotalCaseViolation = stDebugOutputSolveByPriority.nTotalCaseViolation;
            stConstraintVialationInfo.astCaseViolation    = stDebugOutputSolveByPriority.astCaseViolation;
            iFlagSolution = 0;  %% Manually adjusted feasible solution
        end
    end
end

tSolutionTime_sec = cputime - t0;

fFeasibleObjValue = 0;
for ii = 1:1:stSystemMasterConfig.iTotalAgent
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
stSolutionInfo.astMachineUsageInfoSystem = astMachineUsageInfoSystem;    % 20070704
stSolutionInfo.astMachinePriceInfo      = astMachinePriceInfo;         % 20070704

stOutputResAlloc.stMachineUsageInfoSystem = stMachineUsageInfoSystem;
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