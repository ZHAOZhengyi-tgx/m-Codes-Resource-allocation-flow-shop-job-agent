function [stSystemJobInfo] = resalloc_load_glb_parameter(strFileFullName)
% load global parameters
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
% History
% YYYYMMDD  Notes
% 20070828  Create from berth template
% 20071115  jsp_def_struct
% 20071123  merge some constant string definition into
%           jsp_def_cnst_str_in_file
%           auction_def_cnst_str_in_file
% 20071130  version compatible
% 20071220  add iSolverPackage
% 20080301  add [BIDGEN_SUBSEARCH_SETTING], 20071126
% TBA
jsp_glb_define();

global OBJ_MINIMIZE_MAKESPAN;                 
global OBJ_MINIMIZE_SUM_TARDINESS;
global OBJ_MINIMIZE_SUM_TARD_MAKESPAN;        
global DEF_MAX_NUM_MACHINE_TYPE;
global DEF_MAXIMUM_LENGTH_PRICE_LIST;


% [stConfigOnePerMachCapLabel, stConfigMachNameLabel, stConfigMachTotalPeriodLabel, astrJSSProbStructCfg, ...
%     stJspMasterPropertyLabel, stBiFspStrCfgMstrLabel,astMachineProcLabel, stResAllocStrCfgMstrLabel] = jsp_def_cnst_str_in_file(); % 20071123
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

%%% Master Config
stSystemConfigLabel.stResAllocStrCfgMstrLabel = stResAllocStrCfgMstrLabel;

stSystemMasterConfig = struct('iTotalAgent', [], 'iTotalMachType', [], ...
    'fTimeFrameUnitInHour', [], 'iObjFunction', [], 'iAlgoChoice', [], ...
    'iPlotFlag', [], 'iCriticalMachType', [], 'iMaxFramesForPlanning', DEF_MAXIMUM_LENGTH_PRICE_LIST, ...
    'tPlanningWindow_Hours', [], 'iSolverPackage', 1); % 20071130, % 20071220 add iSolverPackage 

[stResourceConfig, stMachineConfig] = jsp_def_struct_res_cfg();  % 20071115

%% OnePeriodMachine Capacity, depends on num. of machine type
lenConstMachineNumOnPer_cfg = length(stConfigOnePerMachCapLabel.strConstMachineNumOnPer_cfg); % 20071123
%% Machine Name information
lenConstMachineName_cfg =length(stConfigMachNameLabel.strConstMachineName_cfg);               % 20071123
%% Machine Multi-Period Information
lenConstMachineInfo_cfg = length(stConfigMachTotalPeriodLabel.strConstMachineInfo_cfg);       % 20071123

%%
for mm = 1:1:DEF_MAX_NUM_MACHINE_TYPE
    %% Machine Capacity Lookup Table
    astMachineProcLabel(mm).strConstMachLUTTimePt_cfg = sprintf('[TIME_POINT_MACH_CAPACITY_TYPE_%d]', mm);
    astMachineProcLabel(mm).strConstMachLUTTimePt_hdr = sprintf('TIME_POINT_MACH_TYPE_%d_CAP_', mm);
    astMachineProcLabel(mm).strConstMachLUTCapPt_cfg = sprintf('[MACH_CAPACITY_TIME_TYPE_%d]', mm);
    astMachineProcLabel(mm).strConstMachLUTCapPt_hdr = sprintf('MACH_TYPE_%d_CAP_TIME_POINT_', mm);
    
    %%% Machine Price
    astMachineProcLabel(mm).strConstMachPrice_cfg = sprintf('[MACHINE_TYPE_%d_PRICE_PER_TIME_FRAME_IN_PLANNING]', mm);
    astMachineProcLabel(mm).strConstMachPrice_hdr = sprintf('MACHINE_TYPE_%d_PRICE_T_FRAME_', mm);
end
stSystemConfigLabel.astMachineProcLabel = astMachineProcLabel;

stJssProbStructConfig = jsp_def_struct_prob_cfg();

lenConstJSSProbStructCfgLabel = length(astrJSSProbStructCfg.strConstJSSProbStructCfgLabel);
stSystemConfigLabel.astrJSSProbStructCfg = astrJSSProbStructCfg;  % 20071123

[stConstStringAucionStrategy, stConstStringPriceAdjust, stConstBidGenSubProbSearch] = auction_def_cnst_str_in_file(); % 20071126

stSystemConfigLabel.stConstStringPriceAdjust = stConstStringPriceAdjust;         % 20071123
stSystemConfigLabel.stConstStringAucionStrategy = stConstStringAucionStrategy;   % 20071123
stBerthConfigLabel.stConstBidGenSubProbSearch = stConstBidGenSubProbSearch;     % 20071126

stPriceAjustment = struct('iFlagStrategy', [], 'fAlpha', []);
%% iFlagStrategy: the choice formular of updating new price, given the
%% current price and current supply and current demand
%% fAlpha: a step-size factor to be multiplied and generate s_r

stAuctionStrategy = struct('iFlagMakeSpanFunction', [], 'iSynchUpdatingBid', [], 'iHasWinnerDetermination', [], ...
    'iMinIteration', [], 'iMaxIteration', [], 'fDeltaObj', [], 'fDeltaPrice', [], 'iMinNumFeasibleSolution', [], ...
    'iConvergingRule', [], 'iNumIterDeOscilating', []);
%% iFlagMakeSpanFunction: choice of formular of calculating the objective function
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

%% Output Prototype
stAgentJobInfo = struct('strFileAgentJobList', [], 'tDateAgentJobStart', [], 'tDateAgentJobDue', [], ...
    'tTimeAgentJobStart', [], 'tTimeAgentJobDue', [], ...
    'fLatePenalty_DollarPerFrame', [], 'fPriceAgentDollarPerFrame', [], 'stJobListInfoAgent', []);

astResourceInitPrice = struct('strName', [], 'iTotalFrame4Pricing', 0, 'afMachinePriceListPerFrame', []);

stSystemJobInfo = struct('stSystemMasterConfig', stSystemMasterConfig,  'stAgentJobInfo', stAgentJobInfo, ...
    'astResourceInitPrice', astResourceInitPrice, ...
    'stResourceConfig', stResourceConfig, 'strInputFilename', [], 'stPriceAjustment', stPriceAjustment, 'stAuctionStrategy', stAuctionStrategy, ...
    'stJssProbStructConfig', []); 

stSystemConfigLabel.strConfigAgentJobListFile = '[AGENT_JOB_LIST]';
stSystemConfigLabel.strConfigAgentJobStartDate = '[AGENT_JOB_START_DATE]';
stSystemConfigLabel.strConfigAgentJobDueDate = '[AGENT_JOB_DUE_DATE]';
stSystemConfigLabel.strConfigAgentJobStartTime = '[AGENT_JOB_START_TIME]';
stSystemConfigLabel.strConfigAgentJobDueTime = '[AGENT_JOB_DUE_TIME]';
stSystemConfigLabel.strConfigAgentPrice = '[AGENT_PRICE_PER_FRAME]';

stSystemConfigLabel.strConfigAgentJobLatePenalty_SGD_PerFrame = '[AGENT_JOB_LATE_PENALTY_SGD_PER_FRAME]';
stSystemConfigLabel.strConstHeaderJobLatePenalty = 'LATE_PENALTY_AGENT_';

stSystemConfigLabel.strConstHeaderJobListFileAgent = 'JOB_LIST_FILE_AGENT_';
stSystemConfigLabel.strConstHeaderJobStartDate = 'START_DATE_AGENT_';
stSystemConfigLabel.strConstHeaderJobDueDate = 'DUE_DATE_AGENT_';
stSystemConfigLabel.strConstHeaderJobStartTime = 'START_TIME_AGENT_';
stSystemConfigLabel.strConstHeaderJobDueTime = 'DUE_TIME_AGENT_';
stSystemConfigLabel.strConstHeaderPriceAgent = 'PRICE_AGENT_';


lenSystemResourceConfig = length(stResAllocStrCfgMstrLabel.strSystemResourceConfig);
lenConfigAgentJobListFile = length(stSystemConfigLabel.strConfigAgentJobListFile);
lenConfigAgentJobStartDate = length(stSystemConfigLabel.strConfigAgentJobStartDate);
lenConfigAgentJobDueDate = length(stSystemConfigLabel.strConfigAgentJobDueDate);
lenConfigAgentJobStartTime = length(stSystemConfigLabel.strConfigAgentJobStartTime);
lenConfigAgentJobDueTime = length(stSystemConfigLabel.strConfigAgentJobDueTime);
lenConfigAgentJobLatePenalty_SGD_PerFrame = length(stSystemConfigLabel.strConfigAgentJobLatePenalty_SGD_PerFrame);
lenConfigAgentPrice = length(stSystemConfigLabel.strConfigAgentPrice);

%%%%%%%%%%%%% for version compatible
iActualTotalMachineType = 0;
iTotalAgent = 0;
iTotalFrameInPlanning = DEF_MAXIMUM_LENGTH_PRICE_LIST;

%%% default value for version compatibility 
stJssProbStructConfig.isCriticalOperateSeq = 1;
stJssProbStructConfig.isWaitInProcess = 0;
stJssProbStructConfig.isPreemptiveProcess = 0;
stJssProbStructConfig.iFlagObjFuncDefine = OBJ_MINIMIZE_SUM_TARD_MAKESPAN;
stBidGenSubProbSearch = jsp_def_st_bidgen_subprobsrch(); % 20080301

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
[s, astrVer] = mtlb_system_version(); 

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
stSystemConfigLabel.fptr = fptr;

strSystemConfigurationFile =  strFileFullName;
disp(strSystemConfigurationFile);
%%%%%%%%%%%%% read parameter
strLine = fgets(fptr);

while(~feof(fptr))
   strLine = sprintf('%sMINIMUM_LENGTH_IN_ONE_LINE_TO_BE_COMPATIBLE_WITH_READER', strLine);
   if strLine(1) == '%'
   else
       if strLine(1:lenSystemResourceConfig) == stResAllocStrCfgMstrLabel.strSystemResourceConfig
           [stSystemMasterConfigRet, strLine] = resalloc_load_master_cfg(fptr, stResAllocStrCfgMstrLabel, stSystemMasterConfig);
           stSystemMasterConfig = stSystemMasterConfigRet;
           iActualTotalMachineType = stSystemMasterConfig.iTotalMachType;
           stResourceConfig.iTotalMachine = iActualTotalMachineType;
           for mm = 1:1:iActualTotalMachineType
               %% initial value
               stResourceConfig.stMachineConfig(mm).iNumPointTimeCap = 0;
           end
           if iActualTotalMachineType > DEF_MAX_NUM_MACHINE_TYPE
                for mm = (DEF_MAX_NUM_MACHINE_TYPE+1):1:iActualTotalMachineType
                    %% Machine Capacity Lookup Table
                    astMachineProcLabel(mm).strConstMachLUTTimePt_cfg = sprintf('[TIME_POINT_MACH_CAPACITY_TYPE_%d]', mm);
                    astMachineProcLabel(mm).strConstMachLUTTimePt_hdr = sprintf('TIME_POINT_MACH_TYPE_%d_CAP_', mm);
                    astMachineProcLabel(mm).strConstMachLUTCapPt_cfg = sprintf('[MACH_CAPACITY_TIME_TYPE_%d]', mm);
                    astMachineProcLabel(mm).strConstMachLUTCapPt_hdr = sprintf('MACH_TYPE_%d_CAP_TIME_POINT_', mm);
                    %%% Machine Price
                    astMachineProcLabel(mm).strConstMachPrice_cfg = sprintf('[MACHINE_TYPE_%d_PRICE_PER_TIME_FRAME_IN_PLANNING]', mm);
                    astMachineProcLabel(mm).strConstMachPrice_hdr = sprintf('MACHINE_TYPE_%d_PRICE_T_FRAME_', mm);
                end
           end
           iTotalAgent = stSystemMasterConfig.iTotalAgent;
           iTotalFrameInPlanning = stSystemMasterConfig.iMaxFramesForPlanning;
       end
       
       %% structure of price adjustment
       strLine = sprintf('%sMINIMUM_LENGTH_IN_ONE_LINE_TO_BE_COMPATIBLE_WITH_READER', strLine);
       if strLine(1:length(stSystemConfigLabel.stConstStringPriceAdjust.strPriceAjustStructConfig)) == stSystemConfigLabel.stConstStringPriceAdjust.strPriceAjustStructConfig
           [stPriceAdjust, strLine, iReadCount] = cfg_load_price_adjust(fptr, stSystemConfigLabel.stConstStringPriceAdjust);
           stPriceAjustment = stPriceAdjust;
       end
       
       %% structure of auction strategy
       strLine = sprintf('%sMINIMUM_LENGTH_IN_ONE_LINE_TO_BE_COMPATIBLE_WITH_READER', strLine);
       if strLine(1:length(stSystemConfigLabel.stConstStringAucionStrategy.strAuctionStrategyConfig)) == stSystemConfigLabel.stConstStringAucionStrategy.strAuctionStrategyConfig
           [stAuctionStrategy, strLine, iReadCount] = cfg_load_auction_strategy(fptr, stSystemConfigLabel.stConstStringAucionStrategy);
       end
       % 20071126
       if strcmp(strLine(1: length(stConstBidGenSubProbSearch.strConstMasterConfig)), stConstBidGenSubProbSearch.strConstMasterConfig) == 1
           [stBidGenSubProbSearch, strLine, iReadCount] = cfg_load_bidgen_subsearch(fptr, stConstBidGenSubProbSearch);
           strDebug = sprintf('Totally %d parameters for BidGen SubSearch Struct Config', iReadCount);
           disp(strDebug);
       end
       
       %% structure for JSS Problem config
       if strLine(1: length(astrJSSProbStructCfg.strConstJSSProbStructCfgLabel)) == astrJSSProbStructCfg.strConstJSSProbStructCfgLabel
           [stJssProbStructConfig, strLine, iReadCount] = jssp_load_prob_struct(fptr, astrJSSProbStructCfg);
           strDebug = sprintf('Totally %d parameters for JSS Problem Struct Config', iReadCount);
           %disp(strDebug);
       end

       if strcmp(strLine(1: lenConstMachineNumOnPer_cfg) , stConfigOnePerMachCapLabel.strConstMachineNumOnPer_cfg) == 1
           [aMachCapOnePeriod] = cfg_load_property_para( ...
               fptr, stConfigOnePerMachCapLabel.strConstMachineNumOnPer_hdr, iActualTotalMachineType);
           stResourceConfig.iaMachCapOnePer = aMachCapOnePeriod;
       elseif strcmp(strLine(1: lenConstMachineName_cfg) , stConfigMachNameLabel.strConstMachineName_cfg) == 1
           [astrMachineNameList] = cfg_load_property_para_str( ...
               fptr, stConfigMachNameLabel.strConstMachineName_hdr, iActualTotalMachineType);
           for mm = 1:1:iActualTotalMachineType
               stResourceConfig.stMachineConfig(mm).strName = astrMachineNameList(mm).strText;
               astResourceInitPrice(mm).strName = astrMachineNameList(mm).strText;
           end
       elseif strcmp(strLine(1: lenConstMachineInfo_cfg) , stConfigMachTotalPeriodLabel.strConstMachineInfo_cfg) == 1
           [aiTotalPeriod4MachCap] = cfg_load_property_para( ...
               fptr, stConfigMachTotalPeriodLabel.strConstMachineInfo_hdr, iActualTotalMachineType);
           for mm = 1:1:iActualTotalMachineType
               stResourceConfig.stMachineConfig(mm).iNumPointTimeCap = aiTotalPeriod4MachCap(mm);
           end
       end

       for mm = 1:1:iActualTotalMachineType
           if stResourceConfig.stMachineConfig(mm).iNumPointTimeCap >= 2 && ...
                   strcmp(strLine(1:length(astMachineProcLabel(mm).strConstMachLUTTimePt_cfg)), astMachineProcLabel(mm).strConstMachLUTTimePt_cfg) == 1
               [aTimePoint4MaCap_mm] = cfg_load_property_para( ...
                   fptr, astMachineProcLabel(mm).strConstMachLUTTimePt_hdr, stResourceConfig.stMachineConfig(mm).iNumPointTimeCap);
               stResourceConfig.stMachineConfig(mm).afTimePointAtCap = aTimePoint4MaCap_mm;
           elseif stResourceConfig.stMachineConfig(mm).iNumPointTimeCap >= 2 && ...
                   strcmp(strLine(1:length(astMachineProcLabel(mm).strConstMachLUTCapPt_cfg)), astMachineProcLabel(mm).strConstMachLUTCapPt_cfg) == 1
               [aMachCapAtTimePt_mm] = cfg_load_property_para( ...
                   fptr, astMachineProcLabel(mm).strConstMachLUTCapPt_hdr, stResourceConfig.stMachineConfig(mm).iNumPointTimeCap);
               stResourceConfig.stMachineConfig(mm).afMaCapAtTimePoint = aMachCapAtTimePt_mm;
               
           elseif strcmp(strLine(1:length(astMachineProcLabel(mm).strConstMachPrice_cfg)), astMachineProcLabel(mm).strConstMachPrice_cfg) == 1
               [afPriceListMachine_mm] = cfg_load_property_para(fptr, astMachineProcLabel(mm).strConstMachPrice_hdr, iTotalFrameInPlanning);
               astResourceInitPrice(mm).iTotalFrame4Pricing = iTotalFrameInPlanning;
               for tt = 1:1:iTotalFrameInPlanning
                  astResourceInitPrice(mm).afMachinePriceListPerFrame(tt) = afPriceListMachine_mm(tt);
               end
           end
       end
       
           %%%%%%%%%%%%%%% JobList Filename Parameters
       strLine = sprintf('%sMINIMUM_LENGTH_IN_ONE_LINE_TO_BE_COMPATIBLE_WITH_READER', strLine);           
       if strLine(1:lenConfigAgentJobListFile) == stSystemConfigLabel.strConfigAgentJobListFile
           [strFilenameAgent_JobList] = cfg_load_property_para_str(fptr, stSystemConfigLabel.strConstHeaderJobListFileAgent, iTotalAgent);
           for ii = 1:1:iTotalAgent
%               strFilenameAgent_JobList(ii).strText
               stSystemJobInfo.strFileAgentJobList(ii).iAgent_Id = strFilenameAgent_JobList(ii).id;
               stSystemJobInfo.strFileAgentJobList(ii).strFilename = strcat(Pathname , strFilenameAgent_JobList(ii).strText);
           end
       elseif strLine(1:lenConfigAgentPrice) == stSystemConfigLabel.strConfigAgentPrice
%            strLine
%            iTotalAgent
           [fAgentPriceList] = cfg_load_property_para(fptr, stSystemConfigLabel.strConstHeaderPriceAgent, iTotalAgent);
%            fAgentPriceList
           for ii = 1:1:iTotalAgent
               stSystemJobInfo.stAgentJobInfo(ii).fPriceAgentDollarPerFrame = fAgentPriceList(ii);
           end
       elseif  strLine(1:lenConfigAgentJobStartDate) == stSystemConfigLabel.strConfigAgentJobStartDate 
           [strAgentJobStartDate] = cfg_load_property_para_str(fptr, stSystemConfigLabel.strConstHeaderJobStartDate, iTotalAgent);
           for ii = 1:1:iTotalAgent
%              strAgentJobStartDate(ii).strText
              stSystemJobInfo.stAgentJobInfo(ii).tDateAgentJobStart.aDateInYear = tm_get_date_by_sg_format(strAgentJobStartDate(ii).strText);
           end
       elseif  strLine(1:lenConfigAgentJobDueDate) == stSystemConfigLabel.strConfigAgentJobDueDate
           [strAgentJobDueDate] = cfg_load_property_para_str(fptr, stSystemConfigLabel.strConstHeaderJobDueDate, iTotalAgent);
           for ii = 1:1:iTotalAgent
%              strAgentJobDueDate(ii).strText
              stSystemJobInfo.stAgentJobInfo(ii).tDateAgentJobDue.aDateInYear = tm_get_date_by_sg_format(strAgentJobDueDate(ii).strText);
           end
       elseif  strLine(1:lenConfigAgentJobStartTime) == stSystemConfigLabel.strConfigAgentJobStartTime
           [strAgentJobStartTime] = cfg_load_property_para_str(fptr, stSystemConfigLabel.strConstHeaderJobStartTime, iTotalAgent);
           for ii = 1:1:iTotalAgent
%              strAgentJobStartTime(ii).strText
              stSystemJobInfo.stAgentJobInfo(ii).tTimeAgentJobStart.aTimeIn24HourFormat = tm_get_time_by_24_hour(strAgentJobStartTime(ii).strText);
              stSystemJobInfo.stAgentJobInfo(ii).atClockAgentJobStart.aClockYearMonthDateHourMinSec = ...
                  [stSystemJobInfo.stAgentJobInfo(ii).tDateAgentJobStart.aDateInYear, stSystemJobInfo.stAgentJobInfo(ii).tTimeAgentJobStart.aTimeIn24HourFormat];
           end
       elseif  strLine(1:lenConfigAgentJobDueTime) == stSystemConfigLabel.strConfigAgentJobDueTime
           [strAgentJobDueTime] = cfg_load_property_para_str(fptr, stSystemConfigLabel.strConstHeaderJobDueTime, iTotalAgent);
           for ii = 1:1:iTotalAgent
%              strAgentJobDueTime(ii).strText
              stSystemJobInfo.stAgentJobInfo(ii).tTimeAgentJobDue.aTimeIn24HourFormat = tm_get_time_by_24_hour(strAgentJobDueTime(ii).strText);
              stSystemJobInfo.stAgentJobInfo(ii).atClockAgentJobDue.aClockYearMonthDateHourMinSec = ...
                  [stSystemJobInfo.stAgentJobInfo(ii).tDateAgentJobDue.aDateInYear, stSystemJobInfo.stAgentJobInfo(ii).tTimeAgentJobDue.aTimeIn24HourFormat];
           end
       elseif  strLine(1:lenConfigAgentJobLatePenalty_SGD_PerFrame) == stSystemConfigLabel.strConfigAgentJobLatePenalty_SGD_PerFrame
           [fAgentJobLatePanelty] = cfg_load_property_para(fptr, stSystemConfigLabel.strConstHeaderJobLatePenalty, iTotalAgent);
           for ii = 1:1:iTotalAgent
              stSystemJobInfo.stAgentJobInfo(ii).fLatePenalty_DollarPerFrame = fAgentJobLatePanelty(ii);
           end
        end
   end
   strLine = fgets(fptr);
end

% 20070913 to be added, TBA
for ii = 1:1:iTotalAgent
    if ii == 1
        datenumEarlistStartJob = datenum(stSystemJobInfo.stAgentJobInfo(ii).atClockAgentJobStart.aClockYearMonthDateHourMinSec);
    else
        if datenumEarlistStartJob > datenum(stSystemJobInfo.stAgentJobInfo(ii).atClockAgentJobStart.aClockYearMonthDateHourMinSec)
            datenumEarlistStartJob = datenum(stSystemJobInfo.stAgentJobInfo(ii).atClockAgentJobStart.aClockYearMonthDateHourMinSec);
        end
    end
end

stSystemMasterConfig.strPlanningStart_date = datestr(datenumEarlistStartJob, 'dd/mm/yyyy');
aPlanningStartDateInYear = tm_get_date_by_sg_format(stSystemMasterConfig.strPlanningStart_date);
stSystemMasterConfig.stPlanningStartTime.aClockYearMonthDateHourMinSec = [aPlanningStartDateInYear, 0, 0, 0]; %% Planning is always start from the beginning of a day
stSystemMasterConfig.stPlanningStartTime.tPlanningStartTime_datenum = datenum(stSystemMasterConfig.stPlanningStartTime.aClockYearMonthDateHourMinSec);
stSystemMasterConfig.stPlanningStartTime.tPlanningStartTime_datestr = datestr(stSystemMasterConfig.stPlanningStartTime.tPlanningStartTime_datenum);
stSystemMasterConfig.stPlanningStartTime.cellPlanningStartTime = {stSystemMasterConfig.stPlanningStartTime.tPlanningStartTime_datestr};
stSystemMasterConfig.tPlanningWindow_Hours = ceil(stSystemMasterConfig.iMaxFramesForPlanning / stSystemMasterConfig.fTimeFrameUnitInHour); % 20071130

% %%%%%%%%%%%%%%% construct the stResourceConfig for the System
for mm = 1:1:iActualTotalMachineType
    if stResourceConfig.stMachineConfig(mm).iNumPointTimeCap <= 1
        stResourceConfig.stMachineConfig(mm).iNumPointTimeCap = 1;
        stResourceConfig.stMachineConfig(mm).afTimePointAtCap(1) = 0;
        stResourceConfig.stMachineConfig(mm).afMaCapAtTimePoint(1) = stResourceConfig.iaMachCapOnePer(mm);
    end
end
stResourceConfig.iCriticalMachType = stSystemMasterConfig.iCriticalMachType; %20080301

% stSystemMasterConfig.iPlotFlag = 3;

if stBidGenSubProbSearch.iFlag_BidGenAlgo ~= stSystemMasterConfig.iAlgoChoice % 20071126
    stBidGenSubProbSearch.iFlag_BidGenAlgo = stSystemMasterConfig.iAlgoChoice;
    disp('stSystemJobInfo.stBidGenSubProbSearch.iFlag_BidGenAlgo is set to the same as stSystemJobInfo.iAlgoChoice');
end

stSystemJobInfo.stSystemMasterConfig = stSystemMasterConfig;
stSystemJobInfo.stPlanningStartTime = stSystemMasterConfig.stPlanningStartTime;
stSystemJobInfo.strInputFilename = strFileFullName;
stSystemJobInfo.stPriceAjustment = stPriceAjustment;
stSystemJobInfo.stAuctionStrategy = stAuctionStrategy;
stSystemJobInfo.stBidGenSubProbSearch = stBidGenSubProbSearch;  % 20071126
stSystemJobInfo.stJssProbStructConfig = stJssProbStructConfig;
stSystemJobInfo.stResourceConfig = stResourceConfig;
stSystemJobInfo.astResourceInitPrice = astResourceInitPrice;
stSystemJobInfo.stSystemConfigLabel = stSystemConfigLabel;


% strSystemConfigurationFile =  strFileFullName