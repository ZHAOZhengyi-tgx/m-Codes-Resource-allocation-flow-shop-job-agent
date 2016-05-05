function [stAgent_Solution] = bidgen_search_single_per(stInputResAlloc)

%% searching dimensions one after the other, keep other dimension fixed when searching any dimension, stop once makespan not decreasing.
%% At the same time, detect and quit if totalcost is less than the neighbouring four
%% 
%% constant to verify the decreasing of tMakeSpan_hour
tEpsilon = 1/3600;

%%
stResAllocGenJspAgent  = stInputResAlloc.stResAllocGenJspAgent;
astMachUsageInfRes = stInputResAlloc.astMachUsageInfRes;
astAgentJobListJspCfg                = stInputResAlloc.astAgentJobListJspCfg;
astMachUsageInfRes = stInputResAlloc.astMachUsageInfRes;
stSystemMasterConfig = stResAllocGenJspAgent.stSystemMasterConfig;
astAgentJobInfo = stResAllocGenJspAgent.stAgentJobInfo;
astResourceInitPrice = stResAllocGenJspAgent.astResourceInitPrice;

nTotalMachType = stSystemMasterConfig.iTotalMachType;

for ii = 1:1:stSystemMasterConfig.iTotalAgent

    tStartTimePoint = cputime;
    %% Generate a schedule with infinite resources (infinite: large enough for all jobs)

    anIniLowBoundMachNum = astAgentJobListJspCfg(ii).iTotalMachineNum;
    %%% initialize astMakespanInfo
    astMakespanInfo(ii).tMatrixMakespan_hour = zeros(stResAllocGenJspAgent.stResourceConfig.iaMachCapOnePer); % zeros(stBerthJobInfo.iTotalPrimeMover, stBerthJobInfo.iTotalYardCrane);
    
    for mm = 1:1:nTotalMachType
        if astMachUsageInfRes(ii).iaMaxMachUsageBySchOut(mm) > stResAllocGenJspAgent.stResourceConfig.iaMachCapOnePer(mm)
            anUppBoundSrchMachCap(mm) = stResAllocGenJspAgent.stResourceConfig.iaMachCapOnePer(mm);
        else
            anUppBoundSrchMachCap(mm) = astMachUsageInfRes(ii).iaMaxMachUsageBySchOut(mm);
        end
        if anIniLowBoundMachNum(mm) > anUppBoundSrchMachCap(mm)
            error('error: LowerBoundSearch > UpperBoundSearch');
        end
        if mm == stSystemMasterConfig.iCriticalMachType
            anIniLowBoundMachNum(mm) = 1;
            anUppBoundSrchMachCap(mm) = 1;
        end
    end
    
    %%% initialize preparation for searching
    iMaxSearchingCase = 1;
    for mm = 1:1:nTotalMachType
        iMaxSearchingCase = iMaxSearchingCase * (anUppBoundSrchMachCap(mm) - anIniLowBoundMachNum(mm) + 1);
    end
    iCaseMachCapSrch = 0;
    iFlagContinueSearch = 1;
    iaMachCapCurrSrch = anIniLowBoundMachNum;
    iaMachCapPrevDirStart = iaMachCapCurrSrch;
    iSearchDim = 1; %% spanning from 1 to iMaxDimension;
    if iSearchDim == stSystemMasterConfig.iCriticalMachType
        iSearchDim = 1;
    end
    iMaxDimension = nTotalMachType; %% for the case of [numPM, numYC]
    fTotalCostMatrix = zeros(anUppBoundSrchMachCap - anIniLowBoundMachNum + ones(1, nTotalMachType));

    [stJspSchedule] = jsp_constr_sche_struct_by_cfg(astAgentJobListJspCfg(ii));
    while iCaseMachCapSrch +1 <= iMaxSearchingCase & iFlagContinueSearch == 1
        iCaseMachCapSrch = iCaseMachCapSrch + 1;
        
        astAgentJobListJspCfg(ii).iTotalMachineNum = iaMachCapCurrSrch;
%%%%% calculation of makespan, resource cost, penalty cost, etc.
        [jsp_schedule_partial] = fsp_multi_mach_greedy_by_seq(stJspSchedule, astAgentJobListJspCfg(ii), astAgentJobListJspCfg(ii).aiJobSeqInJspCfg);
        stCostAtAgent(ii).stCostList(iCaseMachCapSrch).stSchedule = jsp_schedule_partial;
        
        tMakeSpan_hour = jsp_schedule_partial.iMaxEndTime * jsp_schedule_partial.fTimeUnit_Min / 60;
        stCostAtAgent(ii).stCostList(iCaseMachCapSrch).tMakeSpan_hour = tMakeSpan_hour;
        %%% update astMakespanInfo
        astMakespanInfo(ii).tMatrixMakespan_hour(iaMachCapCurrSrch) = tMakeSpan_hour;
        
        %% INPUT:  
        %% stSystemMasterConfig, astAgentJobInfo(ii),
        %% tMakeSpan_hour, astResourceInitPrice
        %% OUTPUT: 
        %% fTardinessFine_dollar, tAgentTardiness_hour,
        %% afCostPerUnitRes, fCostMakespan
        [fTardinessFine_dollar, tAgentTardiness_frame, afCostPerUnitRes, fCostMakespan] = ...
            bidgen_calc_bid_cost(stSystemMasterConfig, astAgentJobInfo(ii), tMakeSpan_hour, astResourceInitPrice);
        
        stCostAtAgent(ii).stCostList(iCaseMachCapSrch).fTardiness = tAgentTardiness_frame;
        stCostAtAgent(ii).stCostList(iCaseMachCapSrch).fDelayPanelty = fTardinessFine_dollar;
        stCostAtAgent(ii).stCostList(iCaseMachCapSrch).fCostMakespan = fCostMakespan;
        afCostPerResource = zeros(1, nTotalMachType);
        for mm = 1:1:nTotalMachType
            afCostPerResource(mm) = iaMachCapCurrSrch(mm) * afCostPerUnitRes(mm);
        end
        stCostAtAgent(ii).stCostList(iCaseMachCapSrch).fCostResource = afCostPerResource;
        stCostAtAgent(ii).afTotalCost(iCaseMachCapSrch) = fTardinessFine_dollar + fCostMakespan + sum(afCostPerResource);
        
        stCostAtAgent(ii).astNumResAtCase(iCaseMachCapSrch).aiNumRes = iaMachCapCurrSrch;

           %%%% Update the fTotalCostMatrix
           for mm = 1:1:nTotalMachType
               idxCostMatrixDim(mm) = iaMachCapCurrSrch(mm) - anIniLowBoundMachNum(mm) +1;
           end
           fTotalCostMatrix(idxCostMatrixDim) = stCostAtAgent(ii).afTotalCost(iCaseMachCapSrch);
                         
       %%% update (mNumPM, mNumYC)
       if iCaseMachCapSrch > 1
           %%% if not decreasing, or have reached one boundary of searching region
           if (  (stCostAtAgent(ii).stCostList(iCaseMachCapSrch).tMakeSpan_hour <= tPrevMakeSpan ...
                    & stCostAtAgent(ii).stCostList(iCaseMachCapSrch).tMakeSpan_hour > tPrevMakeSpan - tEpsilon ...
                  ) ...
                | iaMachCapCurrSrch(iSearchDim) + 1 > anUppBoundSrchMachCap(iSearchDim) ...
              )
               iSearchDim = mod(iSearchDim, iMaxDimension) + 1;
               if iSearchDim == 1
                   iaMachCapPrevDirStart = iaMachCapPrevDirStart + ones(1, nTotalMachType);
                   for mm = 1:1:nTotalMachType
                       if iaMachCapPrevDirStart(mm) > anUppBoundSrchMachCap(mm)
                           iaMachCapPrevDirStart(mm) = anUppBoundSrchMachCap(mm);
                       end
                   end
                   iaMachCapNextCase = iaMachCapPrevDirStart;
               else
                   iaMachCapPrevDirStart(iSearchDim) = iaMachCapPrevDirStart(iSearchDim) + 1;
                   if iaMachCapPrevDirStart(iSearchDim) > anUppBoundSrchMachCap(iSearchDim)
                       iaMachCapPrevDirStart(iSearchDim) = anUppBoundSrchMachCap(iSearchDim);
                   end
                   iaMachCapNextCase = iaMachCapPrevDirStart;
               end
           else
               iaMachCapNextCase = iaMachCapCurrSrch;
               iaMachCapNextCase(iSearchDim) = iaMachCapCurrSrch(iSearchDim) + 1;
               if iaMachCapNextCase(iSearchDim) > anUppBoundSrchMachCap(iSearchDim)
                   iaMachCapNextCase(iSearchDim) = anUppBoundSrchMachCap(iSearchDim);
               end
           end
           
       else
           %% initial searching direction is along PM, or iSearchDim == 1
           iaMachCapNextCase = iaMachCapCurrSrch;
           iaMachCapNextCase(iSearchDim) = iaMachCapCurrSrch(iSearchDim) + 1;
           tPrevMakeSpan = stCostAtAgent(ii).stCostList(1).tMakeSpan_hour;
       end
       
       if stSystemMasterConfig.iPlotFlag >= 3
           iCase_PrevMksp_CurrMksp_FlagSearch_iaCurrRes_iDir_mPrevDirRes = ...
                  [iCaseMachCapSrch, tPrevMakeSpan, tMakeSpan_hour, iFlagContinueSearch, ...
                   iaMachCapCurrSrch, iSearchDim, iaMachCapPrevDirStart, iaMachCapNextCase, anUppBoundSrchMachCap]
       end
       
       iFlagContinueSearch = 0;
       for mm = 1:1:nTotalMachType
           if iaMachCapPrevDirStart(mm) < anUppBoundSrchMachCap(mm)
               iFlagContinueSearch = 1;
           end
       end
%        if( (mPrevDirStartNumPM >= iMaxPrimeMover ) ...
%            & (mPrevDirStartNumYC >= iMaxYardCrane) ...
%          )
%            iFlagContinueSearch = 0;
%            disp('complete iterative direction search.');
%            iCaseMachCapSrch
%        else
%             iaMachCapCurrSrch = iaMachCapNextCase;
%        end
         iaMachCapCurrSrch = iaMachCapNextCase;
         
       tPrevMakeSpan = stCostAtAgent(ii).stCostList(iCaseMachCapSrch).tMakeSpan_hour;
%            idxCostMatrixRow = mNumPM - IniVirtualPrimeMover +1;
%            idxCostMatrixCol = mNumYC - IniVirtualYardCrane + 1;
       
       %%% only used for iAlgoChoice == 4
%        if stSystemMasterConfig.iAlgoChoice == 4
%        if mPrevDirStartNumPM > IniVirtualPrimeMover & mPrevDirStartNumYC > IniVirtualYardCrane
% %            %%% Check whether a local minimum has come up in the TotalMatrix
%           bFlagExistLocalMinimum = chk_cost_matrix_sub_grad(fTotalCostMatrix, idxCostMatrixRow, idxCostMatrixCol);
%           if bFlagExistLocalMinimum == 1
%               iFlagContinueSearch = 0;
%               disp('Local minimum has been detected.');
%               iCaseMachCapSrch
%           end
%         end
    end  %%% while loop
    
    stCostAtAgent(ii).iTotalCase = iCaseMachCapSrch;
    [fMinTotalCost,idxMinCost] = min(stCostAtAgent(ii).afTotalCost);
    if stSystemMasterConfig.iAlgoChoice == 2 | stSystemMasterConfig.iAlgoChoice == 4 | stSystemMasterConfig.iAlgoChoice == 5
        [container_sequence_jsp, stSpecificMachineTimeInfo] = psa_jsp_dispatch_machine_02(stCostAtAgent(ii).stCostList(idxMinCost).stSchedule);
    else
        container_sequence_jsp = stCostAtAgent(ii).stCostList(idxMinCost).stSchedule;
    end

    tEndTimePoint = cputime;
    tSolutionTime_sec(ii) = tEndTimePoint - tStartTimePoint;
    
    stCostAtAgent(ii).stSolutionMinCost.stSchedule = container_sequence_jsp;
    stCostAtAgent(ii).stSolutionMinCost.aiNumRes = stCostAtAgent(ii).astNumResAtCase(idxMinCost).aiNumRes; %stCostAtAgent(ii).aiNumPM(idxMinCost);
    stCostAtAgent(ii).tSolutionTime_sec = tSolutionTime_sec(ii);
    aiMinCost(ii) = idxMinCost;
    stCostAtAgent(ii).anUppBoundSrchMachCap = anUppBoundSrchMachCap;
end

%%%% Assign Output
for ii = 1:1:stSystemMasterConfig.iTotalAgent
    stAgent_Solution(ii).stCostAtAgent = stCostAtAgent(ii);
    stAgent_Solution(ii).stResourceUsageGenSch0.aiMaxRes = astMachUsageInfRes(ii).iaMaxMachUsageBySchOut;
%    stAgent_Solution(ii).stResourceUsageGenSch0.iMaxYC = iMaxYardCraneUsageByGenSch0(ii);
    stAgent_Solution(ii).astMakespanInfo = astMakespanInfo(ii);
end

for ii = 1:1:stSystemMasterConfig.iTotalAgent
    tMinCostMakeSpan_hour = stCostAtAgent(ii).stCostList(aiMinCost(ii)).tMakeSpan_hour;
    stAgent_Solution(ii).stPerformReport.tMinCostMakeSpan_hour = tMinCostMakeSpan_hour;
%    stAgent_Solution(ii).stPerformReport.tMinCostGrossCraneRate = (astAgentJobListJspCfg(ii).TotalContainer_Load + astAgentJobListJspCfg(ii).TotalContainer_Discharge)/ stAgent_Solution(ii).stPerformReport.tMinCostMakeSpan_hour;
    stAgent_Solution(ii).stPerformReport.fCostMakespanTardiness = tMinCostMakeSpan_hour * astAgentJobInfo(ii).fPriceAgentDollarPerFrame + stCostAtAgent(ii).stCostList(aiMinCost(ii)).fDelayPanelty;
    stAgent_Solution(ii).stPerformReport.fMinCost              =   stCostAtAgent(ii).afTotalCost(aiMinCost(ii));
%       sum(stCostAtAgent(ii).stCostList(aiMinCost(ii)).) stCostAtAgent(ii).stCostList(aiMinCost(ii)).fCostPM ...
%                                                                 + stCostAtAgent(ii).stCostList().fCostYC ...
%                                                                 + stAgent_Solution(ii).stPerformReport.fCostMakespanTardiness;
    stAgent_Solution(ii).stPerformReport.tSolutionTime_sec = tSolutionTime_sec(ii);
end
%stInfoSinglePerSearch.anUppBoundSrchMachCap = anUppBoundSrchMachCap;
