function [stBerthJobInfo] = psa_berth_load_parameter(strFileFullName)
% History
% YYYYMMDD  Notes
% 20070605  improve stoping criterion zzy
% 20070724  Add JSS(Job Shop Scheduling) Problem Config 
% 20070729  Add compatible with version 6.0
% 20070814  Add compatible content in stResourceConfig
% 20070912  Add GA, tPlanningWindow_Hours
% 20071001  Add BidGen SubSearch Setting
% 20071126  merge some constant string definition into
%           jsp_def_cnst_str_in_file
%           auction_def_cnst_str_in_file
% 20080301  InitPrice
% 20080321  

global OBJ_MINIMIZE_MAKESPAN;                 % 20070724
global OBJ_MINIMIZE_SUM_TARDINESS;
global OBJ_MINIMIZE_SUM_TARD_MAKESPAN;        
% OBJ_MINIMIZE_MAKESPAN = 0;
% OBJ_MINIMIZE_SUM_TARDINESS = 1;
% OBJ_MINIMIZE_SUM_TARD_MAKESPAN = 2;           % 20070724

stBerthJobInfo = struct('iTotalAgent', [], 'iTotalQuayCrane', [], 'iTotalYardCrane', [], 'iTotalPrimeMover', [], ...
    'fTimeFrameUnitInHour', [], 'iObjFunction', [], 'iAlgoChoice', [], 'iSolverPackage', 2, 'iPlotFlag', [], ...
    'iNumPointPM_TimeCap', [], 'iNumPointYC_TimeCap', [], 'iFlagScheByGA', [], 'tPlanningWindow_Hours', [], 'strPlanningStart_date', [],  ... % 20070912
    'stAgentJobInfo', [], ... 
    'fPricePrimeMoverDollarPerFrame', [], 'fPriceYardCraneDollarPerFrame', [], ...
    'stResourceConfig', [], 'strInputFilename', [], 'stPriceAjustment', [], 'stAuctionStrategy', [], ...
    'stJssProbStructConfig', []);  % 20070724

% stResourceConfig = struct('iTotalMachine', [], 'stMachineConfig', []);
% stMachineConfig = struct('strName', [], 'iNumPointTimeCap', [], 'afTimePointAtCap', [], 'afMaCapAtTimePoint', []);
[stResourceConfig, stMachineConfig] = jsp_def_struct_res_cfg();

stPriceAjustment = struct('iFlagStrategy', [], 'fAlpha', []);
%% iFlagStrategy: the choice formular of updating new price, given the
%% current price and current supply and current demand
%% fAlpha: a step-size factor to be multiplied and generate s_r

% 20070605
stAuctionStrategy = struct('iFlagMakeSpanFuncation', [], 'iSynchUpdatingBid', [], 'iHasWinnerDetermination', [], ...
    'iMinIteration', [], 'iMaxIteration', [], 'fDeltaObj', [], 'fDeltaPrice', [], 'iMinNumFeasibleSolution', [], ...
    'iConvergingRule', [], 'iNumIterDeOscilating', []);
%% iFlagMakeSpanFuncation: choice of formular of calculating the objective function
%% iSynchUpdatingBid:  choice of updating the bid, synchronous updating or asynchronous updating
%% iHasWinnerDetermination: choice whether the auction has actual winner (if 1), or a win-win solution for resource allocation problem
%% iMinIteration: Minimum Number of Iteration, in case for small step size
%% iMaxIteration: Maximum Number of Iteration
%% fDeltaObj    : Delta (a maximum band) for variation of objective function value
%% fDeltaPrice  : Delta (a maximum band) for variation of price
%% iMinNumFeasibleSolution: Minimum number of feasible solution, 
%% iConvergingRule : choice of converging rule, 
%%       0: (by default) price variation is small enough, (SP)
%%       1: The Objective Function value variation is Small enough (SOF)
%%       2: SP and SOF
%%       3: 
%% iNumIterDeOscilating: number of iterations to check not oscilating

%% structure for JobShopScheduling Problem Configuration %20070724 
% [stConfigOnePerMachCapLabel, stConfigMachNameLabel, stConfigMachTotalPeriodLabel, astrJSSProbStructCfg, ...
%     stJspMasterPropertyLabel, stBiFspStrCfgMstrLabel] = jsp_def_cnst_str_in_file(); % 20071126
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

stBerthConfigLabel.astrJSSProbStructCfg = astrJSSProbStructCfg; % 20071126

stAgentJobInfo = struct(    'strFileAgentJobList', [], 'tDateAgentJobStart', [], 'tDateAgentJobDue', [], ...
    'tTimeAgentJobStart', [], 'tTimeAgentJobDue', [], ...
    'fLatePenalty_DollarPerFrame', [], 'fPriceAgentDollarPerFrame', [], 'stJobListInfoAgent', []);

stBerthConfigLabel.strBerthResourceConfig = '[BERTH_RESOURCE_CONFIG]';
stBerthConfigLabel.strConfigQuayCraneJobListFile = '[QUAY_CRANE_JOB_LIST]';
stBerthConfigLabel.strConfigQuayCraneJobStartDate = '[QUAY_CRANE_JOB_START_DATE]';
stBerthConfigLabel.strConfigQuayCraneJobDueDate = '[QUAY_CRANE_JOB_DUE_DATE]';
stBerthConfigLabel.strConfigQuayCraneJobStartTime = '[QUAY_CRANE_JOB_START_TIME]';
stBerthConfigLabel.strConfigQuayCraneJobDueTime = '[QUAY_CRANE_JOB_DUE_TIME]';
stBerthConfigLabel.strConfigQuayCranePrice = '[QUAY_CRANE_PRICE_PER_FRAME]';

[stConstStringAucionStrategy, stConstStringPriceAdjust, stConstBidGenSubProbSearch] = auction_def_cnst_str_in_file(); % 20071126
%% structure for Price Adjustment
% stBerthConfigLabel.stConstStringPriceAdjust.strPriceAjustStructConfig = '[PRICE_ADJUSTMENT_IN_AUCTION]';
% stBerthConfigLabel.stConstStringPriceAdjust.strConstFlagStrategy = 'PA_STRATEGY';
% stBerthConfigLabel.stConstStringPriceAdjust.strConstFlagAlpha = 'ALPHA_STEP_SIZE';

%% structur for Auction Stretegy, 
% stBerthConfigLabel.stConstStringAucionStrategy.strAuctionStrategyConfig = '[AUCTION_STRATEGY]';
% stBerthConfigLabel.stConstStringAucionStrategy.strConstMakeSpanFunction = 'FLAG_MAKESPAN_FUNCTION';
% stBerthConfigLabel.stConstStringAucionStrategy.strConstSynchronousBid = 'FLAG_SYNCHRONOUS_BIDDING_ADJUSTING';
% stBerthConfigLabel.stConstStringAucionStrategy.strConstHasWinnerDetermination = 'FLAG_WINNER_DETERMINATION';
% stBerthConfigLabel.stConstStringAucionStrategy.strConstMinIteration = 'MIN_NUM_ITERATION';
% stBerthConfigLabel.stConstStringAucionStrategy.strConstMaxIteration = 'MAX_NUM_ITERATION';
% stBerthConfigLabel.stConstStringAucionStrategy.strDeltaObj = 'DELTA_OBJECTIVE_VALUE';   % 20070605
% stBerthConfigLabel.stConstStringAucionStrategy.strDeltaPrice = 'DELTA_PRICE';
% stBerthConfigLabel.stConstStringAucionStrategy.strMinNumFeasibleSolution = 'MIN_NUM_FEASIBLE_SOLUTION';
% stBerthConfigLabel.stConstStringAucionStrategy.strConvergingRule = 'CONVERGING_RULE';   
% stBerthConfigLabel.stConstStringAucionStrategy.strNumIterDeOscilating = 'NUM_ITER_DEOSCILATING';  % 20070605
stBerthConfigLabel.stConstStringPriceAdjust = stConstStringPriceAdjust;         % 20071126
stBerthConfigLabel.stConstStringAucionStrategy = stConstStringAucionStrategy;   % 20071126


%% 20071001 
% stConstBidGenSubProbSearch.strConstMasterConfig = '[BIDGEN_SUBSEARCH_SETTING]';
% stConstBidGenSubProbSearch.strConstFlagBidGenAlgo = 'BIDGEN_SUBSEARCH_ALGO';
% stConstBidGenSubProbSearch.strConstFlagSortingPrice = 'BIDGEN_FLAG_SORTING_PRICE';
% stConstBidGenSubProbSearch.strConstMaxIterSubSearch = 'BIDGEN_MAX_ITER_SUB_SEARCH';
% stConstBidGenSubProbSearch.strConstFlagRunStrictSrch = 'BIDGEN_OPTION_STRICT_SEARCH';
stBerthConfigLabel.stConstBidGenSubProbSearch = stConstBidGenSubProbSearch;     % 20071126

% default parameter
stBidGenSubProbSearch = struct('iFlag_BidGenAlgo', 19, ...
    'iFlagSortingPrice', 0, ...
    'iMaxIter_LocalSearchBidGen', 2, ...
    'iFlagRunStrictSrch', 1 ...
    );

%% 20071001 

stBerthConfigLabel.strConfigQuayCraneJobLatePenalty_SGD_PerFrame = '[QUAY_CRANE_JOB_LATE_PENALTY_SGD_PER_FRAME]';
stBerthConfigLabel.strConfigPrimeMoverPrice_SGD_PerFrame = '[PRIME_MOVER_PRICE_PER_TIME_FRAME_IN_ONE_DAY]';
stBerthConfigLabel.strConfigPrimeMoverPrice_SGD_PerFrame_2 = '[PRIME_MOVRE_PRICE_PER_TIME_FRAME_IN_ONE_DAY]';
stBerthConfigLabel.strConfigYardCranePrice_SGD_PerFrame = '[YARD_CRANE_PRICE_PER_TIME_FRAME_IN_ONE_DAY]';

stBerthConfigLabel.strConstHeaderJobLatePenalty = 'LATE_PENALTY_QC_';
stBerthConfigLabel.strConstHeaderPMPrice = 'PM_PRICE_T_FRAME_'; 
stBerthConfigLabel.strConstHeaderYCPrice = 'YC_PRICE_T_FRAME_';

stBerthConfigLabel.strConstTotalQC_Berth = 'TOTAL_QUAY_CRANE';
stBerthConfigLabel.strConstTotalYC_Berth = 'TOTAL_YARD_CRANE';
stBerthConfigLabel.strConstTotalPM_Berth = 'TOTAL_PRIME_MOVER';
stBerthConfigLabel.strConstTimeFrameUnit_hour = 'TIME_FRAME_UNIT_HOUR';
stBerthConfigLabel.strConstObjFunction   = 'OBJ_FUNCTION';
stBerthConfigLabel.strConstAlgoChoice    = 'ALGO_CHOICE';
stBerthConfigLabel.strConstNumPointPM_TimeCap = 'NUM_TIME_POINT_FRAME_PM_CAP';
stBerthConfigLabel.strConstNumPointYC_TimeCap = 'NUM_TIME_POINT_FRAME_YC_CAP';
stBerthConfigLabel.strConstPlotFlag      = 'PLOT_FLAG';
stBerthConfigLabel.strConstFlagGA        = 'FLAG_SCHEDULE_BY_GA';  % 20070912
stBerthConfigLabel.strConstPlanningWindowHours = 'PLANNING_WINDOW_HOUR'; % 20070912
stBerthConfigLabel.strConstPlanningStartDate = 'PLANNING_START_DATE';    % 20070912

stBerthConfigLabel.iTotalParameterWhole = 10;  % 20070912

stBerthConfigLabel.strConstHeaderJobListFileQC = 'JOB_LIST_FILE_QC_';
stBerthConfigLabel.strConstHeaderJobStartDate = 'START_DATE_QC_';
stBerthConfigLabel.strConstHeaderJobDueDate = 'DUE_DATE_QC_';
stBerthConfigLabel.strConstHeaderJobStartTime = 'START_TIME_QC_';
stBerthConfigLabel.strConstHeaderJobDueTime = 'DUE_TIME_QC_';
stBerthConfigLabel.strConstHeaderPriceQC = 'PRICE_QC_';

stBerthConfigLabel.strConstConfig_TimePointPMCap = '[TIME_POINT_PM_CAPACITY]';
stBerthConfigLabel.strConstHeader_TimePointPMCap = 'TIME_POINT_PM_CAP_';
stBerthConfigLabel.strConstConfig_PMCapTimePoint = '[PM_CAPACITY_TIME]';
stBerthConfigLabel.strConstHeader_PMCapTimePoint = 'PM_CAP_TIME_POINT_';
stBerthConfigLabel.strConstConfig_TimePointYCCap = '[TIME_POINT_YC_CAPACITY]';
stBerthConfigLabel.strConstHeader_TimePointYCCap = 'TIME_POINT_YC_CAP_';
stBerthConfigLabel.strConstConfig_YCCapTimePoint = '[YC_CAPACITY_TIME]';
stBerthConfigLabel.strConstHeader_YCCapTimePoint = 'YC_CAP_TIME_POINT_';

lenBerthResourceConfig = length(stBerthConfigLabel.strBerthResourceConfig);
lenConfigQuayCraneJobListFile = length(stBerthConfigLabel.strConfigQuayCraneJobListFile);
lenConfigQuayCraneJobStartDate = length(stBerthConfigLabel.strConfigQuayCraneJobStartDate);
lenConfigQuayCraneJobDueDate = length(stBerthConfigLabel.strConfigQuayCraneJobDueDate);
lenConfigQuayCraneJobStartTime = length(stBerthConfigLabel.strConfigQuayCraneJobStartTime);
lenConfigQuayCraneJobDueTime = length(stBerthConfigLabel.strConfigQuayCraneJobDueTime);
lenConfigQuayCraneJobLatePenalty_SGD_PerFrame = length(stBerthConfigLabel.strConfigQuayCraneJobLatePenalty_SGD_PerFrame);
lenConfigPrimeMoverPrice_SGD_PerFrame = length(stBerthConfigLabel.strConfigPrimeMoverPrice_SGD_PerFrame);
lenConfigYardCranePrice_SGD_PerFrame  = length(stBerthConfigLabel.strConfigYardCranePrice_SGD_PerFrame);
lenConfigQuayCranePrice = length(stBerthConfigLabel.strConfigQuayCranePrice);

%%%%%%%%%%%%% for version compatible
iNumPointPM_TimeCap = 0;
iNumPointYC_TimeCap = 0;
%%% default value for version compatibility % 20070724
stJssProbStructConfig = jsp_def_struct_prob_cfg();

stBerthJobInfo.iObjFunction = 0;

%%%%%%%%%%%%% start to locate the filename
if ~exist('strFileFullName')
    disp('Input the data file --- *.*');
    [Filename, Pathname] = uigetfile('*.ini', 'Pick an Text file as Job Shop Configurations');
    strFileFullName = strcat(Pathname , Filename);
else
    iPathStringList = strfind(strFileFullName, '\');
    Pathname = strFileFullName(1:iPathStringList(end));
end

%%% Convert file name to be compatible with UNIX
[s, astrVer] = mtlb_system_version(); % 20070729

if s == 0 %% it is a dos-windows system
    disp('it is a dos-windows system');
else %% it is a UNIX or Linux system
    disp('it is a UNIX or Linux system');
    iPathStringList = strfind(strFileFullName, '\');
    for ii = 1:1:length(iPathStringList)
        strFileFullName(iPathStringList(ii)) = '/';
    end
    Pathname = strFileFullName(1:iPathStringList(end));
end
%%%
fptr = fopen(strFileFullName, 'r');
stBerthConfigLabel.fptr = fptr;

strBerthConfigurationFile =  strFileFullName

%%%%%%%%%%%%% read parameter
strLine = fgets(fptr);

while(~feof(fptr))
   strLine = sprintf('%sMINIMUM_LENGTH_IN_ONE_LINE_TO_BE_COMPATIBLE_WITH_READER', strLine);
   if strLine(1) == '%'
   else
       if strLine(1:lenBerthResourceConfig) == stBerthConfigLabel.strBerthResourceConfig
           [berth_whole, strLine] = psa_berth_load_total(stBerthConfigLabel);
           TotalQC = berth_whole.iTotalQC_Berth;
           stBerthJobInfo.iTotalQuayCrane = TotalQC;
           stBerthJobInfo.iTotalAgent = stBerthJobInfo.iTotalQuayCrane;
           stBerthJobInfo.iTotalYardCrane = berth_whole.iTotalYC_Berth;
           stBerthJobInfo.iTotalPrimeMover= berth_whole.iTotalPM_Berth;
           stBerthJobInfo.iAlgoChoice     = berth_whole.iAlgoChoice;
           stBerthJobInfo.iNumPointPM_TimeCap  = berth_whole.iNumPointPM_TimeCap;
           stBerthJobInfo.iNumPointYC_TimeCap  = berth_whole.iNumPointYC_TimeCap;
           stBerthJobInfo.iFlagScheByGA        = berth_whole.iFlagScheByGA;  % 20070912
           stBerthJobInfo.tPlanningWindow_Hours = berth_whole.tPlanningWindow_Hours; % 20070912
           stBerthJobInfo.strPlanningStart_date = berth_whole.strPlanningStart_date; % 20070912
           iNumPointPM_TimeCap = berth_whole.iNumPointPM_TimeCap;
           iNumPointYC_TimeCap = berth_whole.iNumPointYC_TimeCap;
			if ~isfield(berth_whole, 'fTimeUnit_Hour')
			   stBerthJobInfo.fTimeUnit_Hour = 1.0;
			else
			   stBerthJobInfo.fTimeFrameUnitInHour= berth_whole.fTimeUnit_Hour;
			end
			if ~isfield(berth_whole, 'iObjFunction')
			   stBerthJobInfo.iObjFunction = 0; %% For version compatible
			else
			   stBerthJobInfo.iObjFunction = berth_whole.iObjFunction;
            end
            stBerthJobInfo.iPlotFlag       = berth_whole.iPlotFlag;
           iTotalTimeFramePerDay = ceil(24 / berth_whole.fTimeUnit_Hour);
       end
       
       %% structure of price adjustment
       strLine = sprintf('%sMINIMUM_LENGTH_IN_ONE_LINE_TO_BE_COMPATIBLE_WITH_READER', strLine);
       if strLine(1:length(stBerthConfigLabel.stConstStringPriceAdjust.strPriceAjustStructConfig)) == stBerthConfigLabel.stConstStringPriceAdjust.strPriceAjustStructConfig
           [stPriceAdjust, strLine, iReadCount] = cfg_load_price_adjust(fptr, stBerthConfigLabel.stConstStringPriceAdjust);
           stPriceAjustment = stPriceAdjust;
       end
       
       %% structure of auction strategy
       strLine = sprintf('%sMINIMUM_LENGTH_IN_ONE_LINE_TO_BE_COMPATIBLE_WITH_READER', strLine);
       if strLine(1:length(stBerthConfigLabel.stConstStringAucionStrategy.strAuctionStrategyConfig)) == stBerthConfigLabel.stConstStringAucionStrategy.strAuctionStrategyConfig
           [stAuctionStrategy, strLine, iReadCount] = cfg_load_auction_strategy(fptr, stBerthConfigLabel.stConstStringAucionStrategy);
       end
       
       %% structure for JSS Problem config
       if strLine(1: length(stBerthConfigLabel.astrJSSProbStructCfg.strConstJSSProbStructCfgLabel)) == stBerthConfigLabel.astrJSSProbStructCfg.strConstJSSProbStructCfgLabel
           [stJssProbStructConfig, strLine, iReadCount] = jssp_load_prob_struct(fptr, stBerthConfigLabel.astrJSSProbStructCfg);
           strDebug = sprintf('Totally %d parameters for JSS Problem Struct Config', iReadCount);
           %disp(strDebug);
       end
       %%%%%%%%  20070724 
       
       %% 20071001
       if strcmp(strLine(1: length(stConstBidGenSubProbSearch.strConstMasterConfig)), stConstBidGenSubProbSearch.strConstMasterConfig) == 1
           [stBidGenSubProbSearch, strLine, iReadCount] = cfg_load_bidgen_subsearch(fptr, stConstBidGenSubProbSearch);
           strDebug = sprintf('Totally %d parameters for BidGen SubSearch Struct Config', iReadCount);
           disp(strDebug);
       end
       %% 20071001
           %%%%%%%%%%%%%%% JobList Filename Parameters
       strLine = sprintf('%sMINIMUM_LENGTH_IN_ONE_LINE_TO_BE_COMPATIBLE_WITH_READER', strLine);           
       if strLine(1:lenConfigQuayCraneJobListFile) == stBerthConfigLabel.strConfigQuayCraneJobListFile
           [strFilenameQC_JobList] = cfg_load_property_para_str(fptr, stBerthConfigLabel.strConstHeaderJobListFileQC, TotalQC);
           for ii = 1:1:TotalQC
%               strFilenameQC_JobList(ii).strText
               stBerthJobInfo.strFileAgentJobList(ii).iQC_Id = strFilenameQC_JobList(ii).id;
               stBerthJobInfo.strFileAgentJobList(ii).strFilename = strcat(Pathname , strFilenameQC_JobList(ii).strText);
           end
       elseif strLine(1:lenConfigQuayCranePrice) == stBerthConfigLabel.strConfigQuayCranePrice & stBerthJobInfo.iObjFunction ~= 0
           [fQuayCranePriceList] = cfg_load_property_para(fptr, stBerthConfigLabel.strConstHeaderPriceQC, TotalQC);
           for ii = 1:1:TotalQC
               stBerthJobInfo.stAgentJobInfo(ii).fPriceQuayCraneDollarPerFrame = fQuayCranePriceList(ii);
               % 20080301
               stBerthJobInfo.stAgentJobInfo(ii).fPriceAgentDollarPerFrame = fQuayCranePriceList(ii);
           end
       elseif (stBerthJobInfo.iObjFunction ~= 0 )& strLine(1:lenConfigQuayCraneJobStartDate) == stBerthConfigLabel.strConfigQuayCraneJobStartDate 
           [strQCJobStartDate] = cfg_load_property_para_str(fptr, stBerthConfigLabel.strConstHeaderJobStartDate, TotalQC);
           for ii = 1:1:TotalQC
%              strQCJobStartDate(ii).strText
              stBerthJobInfo.stAgentJobInfo(ii).tDateAgentJobStart.aDateInYear = tm_get_date_by_sg_format(strQCJobStartDate(ii).strText);
           end
       elseif (stBerthJobInfo.iObjFunction ~= 0 )& strLine(1:lenConfigQuayCraneJobDueDate) == stBerthConfigLabel.strConfigQuayCraneJobDueDate
           [strQCJobDueDate] = cfg_load_property_para_str(fptr, stBerthConfigLabel.strConstHeaderJobDueDate, TotalQC);
           for ii = 1:1:TotalQC
%              strQCJobDueDate(ii).strText
              stBerthJobInfo.stAgentJobInfo(ii).tDateAgentJobDue.aDateInYear = tm_get_date_by_sg_format(strQCJobDueDate(ii).strText);
           end
       elseif (stBerthJobInfo.iObjFunction ~= 0 )& strLine(1:lenConfigQuayCraneJobStartTime) == stBerthConfigLabel.strConfigQuayCraneJobStartTime
           [strQCJobStartTime] = cfg_load_property_para_str(fptr, stBerthConfigLabel.strConstHeaderJobStartTime, TotalQC);
           for ii = 1:1:TotalQC
%              strQCJobStartTime(ii).strText
              stBerthJobInfo.stAgentJobInfo(ii).tTimeAgentJobStart.aTimeIn24HourFormat = tm_get_time_by_24_hour(strQCJobStartTime(ii).strText);
              stBerthJobInfo.stAgentJobInfo(ii).atClockAgentJobStart.aClockYearMonthDateHourMinSec = ...
                  [stBerthJobInfo.stAgentJobInfo(ii).tDateAgentJobStart.aDateInYear, stBerthJobInfo.stAgentJobInfo(ii).tTimeAgentJobStart.aTimeIn24HourFormat];
           end
       elseif (stBerthJobInfo.iObjFunction ~= 0 )& strLine(1:lenConfigQuayCraneJobDueTime) == stBerthConfigLabel.strConfigQuayCraneJobDueTime
           [strQCJobDueTime] = cfg_load_property_para_str(fptr, stBerthConfigLabel.strConstHeaderJobDueTime, TotalQC);
           for ii = 1:1:TotalQC
%              strQCJobDueTime(ii).strText
              stBerthJobInfo.stAgentJobInfo(ii).tTimeAgentJobDue.aTimeIn24HourFormat = tm_get_time_by_24_hour(strQCJobDueTime(ii).strText);
              stBerthJobInfo.stAgentJobInfo(ii).atClockAgentJobDue.aClockYearMonthDateHourMinSec = ...
                  [stBerthJobInfo.stAgentJobInfo(ii).tDateAgentJobDue.aDateInYear, stBerthJobInfo.stAgentJobInfo(ii).tTimeAgentJobDue.aTimeIn24HourFormat];
           end
       elseif (stBerthJobInfo.iObjFunction ~= 0 )& strLine(1:lenConfigQuayCraneJobLatePenalty_SGD_PerFrame) == stBerthConfigLabel.strConfigQuayCraneJobLatePenalty_SGD_PerFrame
           [fQCJobLatePanelty] = cfg_load_property_para(fptr, stBerthConfigLabel.strConstHeaderJobLatePenalty, TotalQC);
           for ii = 1:1:TotalQC
              stBerthJobInfo.stAgentJobInfo(ii).fLatePenalty_DollarPerFrame = fQCJobLatePanelty(ii);
           end
       elseif ((stBerthJobInfo.iObjFunction ~= 0 )& strLine(1:lenConfigPrimeMoverPrice_SGD_PerFrame) == stBerthConfigLabel.strConfigPrimeMoverPrice_SGD_PerFrame )| ...
               ((stBerthJobInfo.iObjFunction ~= 0 )& strLine(1:lenConfigPrimeMoverPrice_SGD_PerFrame) == stBerthConfigLabel.strConfigPrimeMoverPrice_SGD_PerFrame_2)
           [fPrimePriceList] = cfg_load_property_para(fptr, stBerthConfigLabel.strConstHeaderPMPrice, iTotalTimeFramePerDay);
           for tt = 1:1:iTotalTimeFramePerDay
              stBerthJobInfo.fPricePrimeMoverDollarPerFrame(tt) = fPrimePriceList(tt);
           end
       elseif (stBerthJobInfo.iObjFunction ~= 0 )& strLine(1:lenConfigYardCranePrice_SGD_PerFrame) == stBerthConfigLabel.strConfigYardCranePrice_SGD_PerFrame
           [fYardCranePriceList] = cfg_load_property_para(fptr, stBerthConfigLabel.strConstHeaderYCPrice, iTotalTimeFramePerDay);
           for tt = 1:1:iTotalTimeFramePerDay
              stBerthJobInfo.fPriceYardCraneDollarPerFrame(tt) = fYardCranePriceList(tt);
           end
       elseif strLine(1:length(stBerthConfigLabel.strConstConfig_TimePointPMCap)) == stBerthConfigLabel.strConstConfig_TimePointPMCap & iNumPointPM_TimeCap >= 1
           [fListTimePointPMCap] = cfg_load_property_para(fptr, stBerthConfigLabel.strConstHeader_TimePointPMCap, iNumPointPM_TimeCap); 
       elseif strLine(1:length(stBerthConfigLabel.strConstConfig_PMCapTimePoint)) == stBerthConfigLabel.strConstConfig_PMCapTimePoint & iNumPointPM_TimeCap >= 1                                
           [fListPMCapTimePoint] = cfg_load_property_para(fptr, stBerthConfigLabel.strConstHeader_PMCapTimePoint, iNumPointPM_TimeCap);
       elseif strLine(1:length(stBerthConfigLabel.strConstConfig_TimePointYCCap)) == stBerthConfigLabel.strConstConfig_TimePointYCCap & iNumPointYC_TimeCap >= 1
           [fListTimePointYCCap] = cfg_load_property_para(fptr, stBerthConfigLabel.strConstHeader_TimePointYCCap, iNumPointYC_TimeCap); 
       elseif strLine(1:length(stBerthConfigLabel.strConstConfig_YCCapTimePoint)) == stBerthConfigLabel.strConstConfig_YCCapTimePoint & iNumPointYC_TimeCap >= 1
           [fListYCCapTimePoint] = cfg_load_property_para(fptr, stBerthConfigLabel.strConstHeader_YCCapTimePoint, iNumPointYC_TimeCap);
       end
   end
   strLine = fgets(fptr);
end

% 20070913
aPlanningStartDateInYear = tm_get_date_by_sg_format(stBerthJobInfo.strPlanningStart_date);
stBerthJobInfo.stPlanningStartTime.aClockYearMonthDateHourMinSec = [aPlanningStartDateInYear, 0, 0, 0]; %% Planning is always start from the beginning of a day
stBerthJobInfo.stPlanningStartTime.tPlanningStartTime_datenum = datenum(stBerthJobInfo.stPlanningStartTime.aClockYearMonthDateHourMinSec);
stBerthJobInfo.stPlanningStartTime.tPlanningStartTime_datestr = datestr(stBerthJobInfo.stPlanningStartTime.tPlanningStartTime_datenum);
stBerthJobInfo.stPlanningStartTime.cellPlanningStartTime = {stBerthJobInfo.stPlanningStartTime.tPlanningStartTime_datestr};
% 20070913
%%%%%%%%%%%%%%% construct the stResourceConfig for the Berth
stBerthJobInfo.stResourceConfig = stResourceConfig;

stBerthJobInfo.stResourceConfig.iTotalMachine = 3;
stBerthJobInfo.stResourceConfig.stMachineConfig(1).strName = 'QC';
stBerthJobInfo.stResourceConfig.stMachineConfig(1).iNumPointTimeCap = 1;    % 20070814
stBerthJobInfo.stResourceConfig.stMachineConfig(1).afTimePointAtCap = 0;
stBerthJobInfo.stResourceConfig.stMachineConfig(1).afMaCapAtTimePoint = stBerthJobInfo.iTotalQuayCrane;    % 20070814

% 20070814
if iNumPointPM_TimeCap ~= 0
    stBerthJobInfo.stResourceConfig.stMachineConfig(2).strName = 'PM';
    stBerthJobInfo.stResourceConfig.stMachineConfig(2).iNumPointTimeCap = iNumPointPM_TimeCap;
    for ii = 1:1:iNumPointPM_TimeCap
        stBerthJobInfo.stResourceConfig.stMachineConfig(2).afTimePointAtCap(ii) = fListTimePointPMCap(ii);
        stBerthJobInfo.stResourceConfig.stMachineConfig(2).afMaCapAtTimePoint(ii) = fListPMCapTimePoint(ii);
    end
else  
    stBerthJobInfo.stResourceConfig.stMachineConfig(2).strName = 'PM';
    stBerthJobInfo.stResourceConfig.stMachineConfig(2).iNumPointTimeCap = 1;
    stBerthJobInfo.stResourceConfig.stMachineConfig(2).afTimePointAtCap(1) = 0;
    stBerthJobInfo.stResourceConfig.stMachineConfig(2).afMaCapAtTimePoint(1) = stBerthJobInfo.iTotalPrimeMover;
end

% iTotalYardCrane
if iNumPointYC_TimeCap ~= 0
    stBerthJobInfo.stResourceConfig.stMachineConfig(3).strName = 'YC';
    stBerthJobInfo.stResourceConfig.stMachineConfig(3).iNumPointTimeCap = iNumPointYC_TimeCap;
    for ii = 1:1:iNumPointYC_TimeCap
        stBerthJobInfo.stResourceConfig.stMachineConfig(3).afTimePointAtCap(ii) = fListTimePointYCCap(ii);
        stBerthJobInfo.stResourceConfig.stMachineConfig(3).afMaCapAtTimePoint(ii) = fListYCCapTimePoint(ii);
    end
else
    stBerthJobInfo.stResourceConfig.stMachineConfig(3).strName = 'YC';
    stBerthJobInfo.stResourceConfig.stMachineConfig(3).iNumPointTimeCap = 1;
    stBerthJobInfo.stResourceConfig.stMachineConfig(3).afTimePointAtCap(1) = 0;
    stBerthJobInfo.stResourceConfig.stMachineConfig(3).afMaCapAtTimePoint(1) = stBerthJobInfo.iTotalYardCrane;
end
stBerthJobInfo.stResourceConfig.iaMachCapOnePer = [stBerthJobInfo.iTotalQuayCrane, stBerthJobInfo.iTotalPrimeMover, stBerthJobInfo.iTotalYardCrane];
% 20070814

% default parameter
[stSystemMasterConfig] = resalloc_def_struct_master_cfg(); % 20080211
stSystemMasterConfig.iTotalAgent = stBerthJobInfo.iTotalAgent;
stSystemMasterConfig.iAlgoChoice = stBerthJobInfo.iAlgoChoice;  
stSystemMasterConfig.iTotalMachType = 3;
stSystemMasterConfig.iPlotFlag = stBerthJobInfo.iPlotFlag;
stSystemMasterConfig.fTimeFrameUnitInHour = stBerthJobInfo.fTimeFrameUnitInHour;
stSystemMasterConfig.iCriticalMachType = 1;
stSystemMasterConfig.iObjFunction = stBerthJobInfo.iObjFunction;
stSystemMasterConfig.iSolverPackage = berth_whole.iSolverPackage; % 'IP_PACKAGE';
stSystemMasterConfig.stPlanningStartTime = stBerthJobInfo.stPlanningStartTime;
stBerthJobInfo.stSystemMasterConfig = stSystemMasterConfig; %% 20080211
% 20080301
stBerthJobInfo.astResourceInitPrice(2).afMachinePriceListPerFrame = stBerthJobInfo.fPricePrimeMoverDollarPerFrame;
stBerthJobInfo.astResourceInitPrice(3).afMachinePriceListPerFrame = stBerthJobInfo.fPriceYardCraneDollarPerFrame;

stBerthJobInfo.strInputFilename = strFileFullName;
stBerthJobInfo.stPriceAjustment = stPriceAjustment;
stBerthJobInfo.stAuctionStrategy = stAuctionStrategy;
stBerthJobInfo.stJssProbStructConfig = stJssProbStructConfig;
if stBidGenSubProbSearch.iFlag_BidGenAlgo ~= stBerthJobInfo.iAlgoChoice
    stBidGenSubProbSearch.iFlag_BidGenAlgo = stBerthJobInfo.iAlgoChoice;
    disp('stBerthJobInfo.stBidGenSubProbSearch.iFlag_BidGenAlgo is set to the same as stBerthJobInfo.iAlgoChoice');
end
stBerthJobInfo.stBidGenSubProbSearch = stBidGenSubProbSearch;  % 20071001
% strBerthConfigurationFile =  strFileFullName