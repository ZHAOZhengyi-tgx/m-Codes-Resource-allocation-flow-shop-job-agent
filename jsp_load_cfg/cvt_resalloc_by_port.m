function stResAllocWithJspAgent = cvt_resalloc_by_port(stResAllocPortCfg)
% Convert a resource allocation configuration from a port to a genetic one
%
%% History
%% YYYYMMDD Notes
% 20080301 add stBidGenSubProbSearch

nTotalAgent = stResAllocPortCfg.iTotalAgent;

% Master Configuration Structure
          stSystemMasterConfig.iTotalAgent = stResAllocPortCfg.iTotalAgent;           %4
       stSystemMasterConfig.iTotalMachType = 3;                                       %3
 stSystemMasterConfig.fTimeFrameUnitInHour = stResAllocPortCfg.fTimeFrameUnitInHour;  %1
         stSystemMasterConfig.iObjFunction = stResAllocPortCfg.iObjFunction;          %4
          stSystemMasterConfig.iAlgoChoice = stResAllocPortCfg.iAlgoChoice;           %22
            stSystemMasterConfig.iPlotFlag = stResAllocPortCfg.iPlotFlag;             %1
    stSystemMasterConfig.iCriticalMachType = 1;                                       %1
stSystemMasterConfig.iMaxFramesForPlanning = stResAllocPortCfg.tPlanningWindow_Hours; %24
       stSystemMasterConfig.iSolverPackage = stResAllocPortCfg.iSolverPackage

stResAllocWithJspAgent.stSystemMasterConfig = stSystemMasterConfig;
iTotalMachType        = stSystemMasterConfig.iTotalMachType;
iMaxFramesForPlanning = stSystemMasterConfig.iMaxFramesForPlanning;

% other structure
       stResAllocWithJspAgent.stAgentJobInfo = stResAllocPortCfg.stAgentJobInfo;                   %[1x nTotalAgent struct]
     stResAllocWithJspAgent.stResourceConfig = stResAllocPortCfg.stResourceConfig;                     %[1x1 struct]
     stResAllocWithJspAgent.strInputFilename = stResAllocPortCfg.strInputFilename;   %'D:\ZhengYI\MyWork\Data\IMSS\Template\ResAlloc_FSP_Ag4_M2=16_M3=8_IP.ini'
     stResAllocWithJspAgent.stPriceAjustment = stResAllocPortCfg.stPriceAjustment;                     %[1x1 struct]
    stResAllocWithJspAgent.stAuctionStrategy = stResAllocPortCfg.stAuctionStrategy;                    %[1x1 struct]
    stResAllocWithJspAgent.stBidGenSubProbSearch = stResAllocPortCfg.stBidGenSubProbSearch;   % 20080301                 %[1x1 struct]
stResAllocWithJspAgent.stJssProbStructConfig = stResAllocPortCfg.stJssProbStructConfig;                %[1x1 struct]
  stResAllocWithJspAgent.strFileAgentJobList = stResAllocPortCfg.strFileAgentJobList;                  %[1x nTotalAgent struct]
%      stResAllocWithJspAgent.stSystemConfigLabel = ; %[1x1 struct]
      
% for mm = 1:1:iTotalMachType
% allocation memory and extend if needed
astResourceInitPrice(1).strName = 'QuayCrane';
astResourceInitPrice(1).iTotalFrame4Pricing             = iMaxFramesForPlanning;
astResourceInitPrice(1).afMachinePriceListPerFrame      = -1 * ones(iMaxFramesForPlanning, 1); %% price-less

astResourceInitPrice(2).strName = 'PrimeMover';
astResourceInitPrice(2).iTotalFrame4Pricing             = iMaxFramesForPlanning;
astResourceInitPrice(2).afMachinePriceListPerFrame      = stResAllocPortCfg.fPricePrimeMoverDollarPerFrame; %[1x iTotalMachType struct]
nTotalPeriodPriceMachine2 = length(stResAllocPortCfg.fPricePrimeMoverDollarPerFrame);
if  nTotalPeriodPriceMachine2 < iMaxFramesForPlanning
    for pp = nTotalPeriodPriceMachine2+1:1: iMaxFramesForPlanning
        astResourceInitPrice(2).afMachinePriceListPerFrame(pp) = stResAllocPortCfg.fPricePrimeMoverDollarPerFrame(nTotalPeriodPriceMachine2)
    end
    disp('warning: the length of price in 2nd machine is shorter than total maximum number of planning period, appending the last period''s price by default');
end

astResourceInitPrice(3).strName = 'YardCrane';
astResourceInitPrice(3).iTotalFrame4Pricing             = iMaxFramesForPlanning;
astResourceInitPrice(3).afMachinePriceListPerFrame      = stResAllocPortCfg.fPriceYardCraneDollarPerFrame; %[1x iTotalMachType struct]
nTotalPeriodPriceMachine3 = length(stResAllocPortCfg.fPriceYardCraneDollarPerFrame);
if  nTotalPeriodPriceMachine3 < iMaxFramesForPlanning
    for pp = nTotalPeriodPriceMachine3+1:1: iMaxFramesForPlanning
        astResourceInitPrice(3).afMachinePriceListPerFrame(pp) = stResAllocPortCfg.fPriceYardCraneDollarPerFrame(nTotalPeriodPriceMachine3)
    end
    disp('warning: the length of price in 3rd machine is shorter than total maximum number of planning period, appending the last period''s price by default');
end


stResAllocWithJspAgent.astResourceInitPrice = astResourceInitPrice; % assign the pointer

if isfield(stResAllocPortCfg ,'stJobListInfoAgent')
    if length(stResAllocPortCfg.stJobListInfoAgent) == nTotalAgent
        for aa = 1:1:nTotalAgent
            stGeneticCfgBiFsp(aa) = cvt_joblist_by_port(stResAllocPortCfg.stJobListInfoAgent(aa));
        end
    else
        error('Not compatible input, length of (stResAllocPortCfg.stJobListInfoAgent) less than stResAllocPortCfg.iTotalAgent ')
    end
else
    for aa = 1:1:stResAllocPortCfg.iTotalAgent
        stJobListInfoAgent(aa) = jsp_load_port_bifsp_list(stResAllocPortCfg.strFileAgentJobList(aa).strFilename);
        stGeneticCfgBiFsp(aa) = cvt_joblist_by_port(stJobListInfoAgent(aa));
    end
end
for aa = 1:1:stResAllocPortCfg.iTotalAgent
    if stResAllocPortCfg.iFlagScheByGA == 1
        stGeneticCfgBiFsp(aa).stGASetting.isSequecingByGA = 1;
    end
    if stResAllocPortCfg.stJssProbStructConfig.isCriticalOperateSeq == 0
        stGeneticCfgBiFsp(aa).stJssProbStructConfig.isCriticalOperateSeq = 0;
    end
end

%%% Add all the labels
% if ~isfield(stJobListInfoAgent, 'stConstStringConfigLabels') % later
[stConstStringAucionStrategy, stConstStringPriceAdjust, stConstBidGenSubProbSearch] = auction_def_cnst_str_in_file();
[stJspConstStringLoadFile] = jsp_def_cnst_str_in_file();
stConfigOnePerMachCapLabel      = stJspConstStringLoadFile.stConfigOnePerMachCapLabel; 
stConfigMachNameLabel           = stJspConstStringLoadFile.stConfigMachNameLabel;
stConfigMachTotalPeriodLabel    = stJspConstStringLoadFile.stConfigMachTotalPeriodLabel;
astrJSSProbStructCfg            = stJspConstStringLoadFile.astrJSSProbStructCfg;
stJspMasterPropertyLabel        = stJspConstStringLoadFile.stJspMasterPropertyLabel;
stBiFspStrCfgMstrLabel          = stJspConstStringLoadFile.stBiFspStrCfgMstrLabel;
astMachineProcLabel             = stJspConstStringLoadFile.astMachineProcLabel;
stResAllocStrCfgMstrLabel       = stJspConstStringLoadFile.stResAllocStrCfgMstrLabel;
stJobSequencingStrCfgLabel      = stJspConstStringLoadFile.stJobSequencingStrCfgLabel;

stConstStringGASetting = ga_def_cnst_str_in_file();

stConstStringConfigLabels.astMachineProcLabel = astMachineProcLabel;
stConstStringConfigLabels.stBiFspStrCfgMstrLabel = stBiFspStrCfgMstrLabel;
stConstStringConfigLabels.astrJSSProbStructCfg = astrJSSProbStructCfg;
stConstStringConfigLabels.stConfigOnePerMachCapLabel = stConfigOnePerMachCapLabel;
stConstStringConfigLabels.stConfigMachNameLabel = stConfigMachNameLabel;
stConstStringConfigLabels.stConfigMachTotalPeriodLabel = stConfigMachTotalPeriodLabel;
stConstStringConfigLabels.stConstStringGASetting = stConstStringGASetting;
stConstStringConfigLabels.stJobSequencingStrCfgLabel = stJobSequencingStrCfgLabel;
for aa = 1:1:nTotalAgent
    stGeneticCfgBiFsp(aa).stConstStringConfigLabels = stConstStringConfigLabels;
end

stResAllocWithJspAgent.stGeneticCfgBiFsp = stGeneticCfgBiFsp;
