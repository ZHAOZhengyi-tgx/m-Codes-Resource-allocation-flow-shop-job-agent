function [berth_whole, strLine] = psa_berth_load_total(stBerthConfigLabel)

%
% Default value
% 20070912 Zhengyi Add GA
% 20080319 Zhengyi Add iSolverPackage, this file is going to be replace by
%         resalloc_load_master_cfg
iPlotFlag =0;



fptr = stBerthConfigLabel.fptr; 
strConstTotalQC_Berth = stBerthConfigLabel.strConstTotalQC_Berth;
strConstTotalYC_Berth = stBerthConfigLabel.strConstTotalYC_Berth;
strConstTotalPM_Berth = stBerthConfigLabel.strConstTotalPM_Berth;
strConstTimeFrameUnit_hour = stBerthConfigLabel.strConstTimeFrameUnit_hour;
strConstObjFunction   = stBerthConfigLabel.strConstObjFunction;
strConstAlgoChoice    = stBerthConfigLabel.strConstAlgoChoice;
strConstNumPointPM_TimeCap = stBerthConfigLabel.strConstNumPointPM_TimeCap ;
strConstNumPointYC_TimeCap = stBerthConfigLabel.strConstNumPointYC_TimeCap ;
strConstPlotFlag           = stBerthConfigLabel.strConstPlotFlag;
strConstFlagGA             = stBerthConfigLabel.strConstFlagGA;  % 20070912
strConstPlanningWindowHours= stBerthConfigLabel.strConstPlanningWindowHours; % 20070912
strConstPlanningStartDate  = stBerthConfigLabel.strConstPlanningStartDate;
%strConstOptRules = stBerthConfigLabel.strConstOptRules;

lenConstTotalQC_Berth = length(strConstTotalQC_Berth);
lenConstTotalPM_Berth = length(strConstTotalPM_Berth);
lenConstTotalYC_Berth = length(strConstTotalYC_Berth);
lenConstTimeFrameUnit_hour = length(strConstTimeFrameUnit_hour);
%lenConstOptRules = length(strConstOptRules);
lenConstObjFunction = length(strConstObjFunction);
lenConstAlgoChoice = length(strConstAlgoChoice);
lenConstNumPointPM_TimeCap = length(strConstNumPointPM_TimeCap);
lenConstNumPointYC_TimeCap = length(strConstNumPointYC_TimeCap);
lenConstPlotFlag = length(strConstPlotFlag);
lenConstFlagGA = length(strConstFlagGA);   % 20070912
lenConstPlanningWindowHours = length(strConstPlanningWindowHours);
lenConstPlanningStartDate = length(strConstPlanningStartDate);

%% version compatible % 20080319
strConstSolverPackage = 'IP_PACKAGE';
lenConstSolverPackage = length(strConstSolverPackage);
berth_whole.iSolverPackage = 1;

%% default values
berth_whole.iNumPointPM_TimeCap = 0;
berth_whole.iNumPointYC_TimeCap = 0;
berth_whole.iFlagScheByGA = 0;             
berth_whole.tPlanningWindow_Hours = 24;    % 20070912
berth_whole.strPlanningStart_date = '01/01/2007'; % 20070912

iReadCount = 1;
strLine = fgets(fptr);

%while iReadCount <= stBerthConfigLabel.iTotalParameterWhole
while strLine(1) ~= '['
   strLine = sprintf('%sMINIMIMLENGTH_TO_BE_COMPATIBLE_WITH_READER', strLine);
   if strLine(1:lenConstTotalQC_Berth) == strConstTotalQC_Berth
       TotalQC_Berth = sscanf(strLine((lenConstTotalQC_Berth + 1): end), ' = %d');
       iReadCount = iReadCount + 1;
   elseif strLine(1:lenConstPlotFlag) == strConstPlotFlag
       iPlotFlag = sscanf(strLine((lenConstPlotFlag + 1): end), ' = %d');
       iReadCount = iReadCount + 1;
   elseif strLine(1:lenConstTimeFrameUnit_hour) == strConstTimeFrameUnit_hour
       fTimeUnit_Hour = sscanf(strLine((lenConstTimeFrameUnit_hour + 1): end), ' = %f');
       iReadCount = iReadCount + 1;
%   elseif strLine(1:lenConstOptRules) == strConstOptRules
%       iOptRule = sscanf(strLine((lenConstOptRules + 1): end), ' = %d');
%       iReadCount = iReadCount + 1;
   elseif strLine(1:lenConstTotalPM_Berth) == strConstTotalPM_Berth
       TotalPM_Berth = sscanf(strLine((lenConstTotalPM_Berth + 1): end), ' = %d');
       iReadCount = iReadCount + 1;
   elseif strLine(1:lenConstTotalYC_Berth) == strConstTotalYC_Berth
       TotalYC_Berth = sscanf(strLine((lenConstTotalYC_Berth + 1): end), ' = %d');
       iReadCount = iReadCount + 1;
   elseif strLine(1:lenConstObjFunction) == strConstObjFunction
       iObjFunction = sscanf(strLine((lenConstObjFunction + 1): end), ' = %d');
       iReadCount = iReadCount + 1;
   elseif strLine(1:lenConstAlgoChoice) == strConstAlgoChoice
       iAlgoChoice = sscanf(strLine((lenConstAlgoChoice + 1): end), ' = %d');
       iReadCount = iReadCount + 1;
   elseif strLine(1:lenConstSolverPackage) == strConstSolverPackage   % 20080319
       berth_whole.iSolverPackage = sscanf(strLine((lenConstSolverPackage + 1): end), ' = %d');
       iReadCount = iReadCount + 1;
   elseif strLine(1:lenConstNumPointPM_TimeCap) == strConstNumPointPM_TimeCap
       berth_whole.iNumPointPM_TimeCap = sscanf(strLine((lenConstNumPointPM_TimeCap + 1): end), ' = %d');
       iReadCount = iReadCount + 1;
   elseif strLine(1:lenConstNumPointYC_TimeCap) == strConstNumPointYC_TimeCap
       berth_whole.iNumPointYC_TimeCap = sscanf(strLine((lenConstNumPointYC_TimeCap + 1): end), ' = %d');
       iReadCount = iReadCount + 1;
   elseif strLine(1:lenConstFlagGA) == strConstFlagGA       % 20070912
       berth_whole.iFlagScheByGA = sscanf(strLine((lenConstFlagGA + 1): end), ' = %d');
       iReadCount = iReadCount + 1;                         % 20070912
   elseif strLine(1:lenConstPlanningWindowHours) == strConstPlanningWindowHours       % 20070912
       berth_whole.tPlanningWindow_Hours = sscanf(strLine((lenConstPlanningWindowHours + 1): end), ' = %f');
       iReadCount = iReadCount + 1;                         % 20070912
   elseif strLine(1:lenConstPlanningStartDate) == strConstPlanningStartDate       % 20070912
       berth_whole.strPlanningStart_date = sscanf(strLine((lenConstPlanningStartDate + 1): end), ' = %f');
       iReadCount = iReadCount + 1;                         % 20070912
   elseif feof(fptr)
       error('Not compatible input.');
   end
   strLine = fgets(fptr);
end

%%% For version compatibility
if ~exist('fTimeUnit_Hour')
   fTimeUnit_Hour = 1.0;
end
if ~exist('iObjFunction')
   iObjFunction = 0; %% For version compatible
end

if ~exist('iAlgoChoice')
   iAlgoChoice = 1; %% 
end


berth_whole.iTotalQC_Berth     = TotalQC_Berth;
berth_whole.iTotalYC_Berth     = TotalYC_Berth;
berth_whole.iTotalPM_Berth     = TotalPM_Berth;
berth_whole.fTimeUnit_Hour     = fTimeUnit_Hour;
berth_whole.iObjFunction       = iObjFunction;
berth_whole.iAlgoChoice        = iAlgoChoice;
berth_whole.iPlotFlag          = iPlotFlag;

%berth_whole.iAlgoOption   = iAlgoOption;
%berth_whole.fTimeUnit_Min     = fTimeUnit_Min;
%berth_whole.iOptRule = iOptRule;

