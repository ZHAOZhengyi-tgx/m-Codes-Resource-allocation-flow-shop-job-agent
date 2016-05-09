function [stQuayCraneJobList, stContainerDischargeJobSequence, stContainerLoadJobSequence] = jsp_load_port_bifsp_list(strFileFullName)
% History
% YYYYMMDD  Notes
% 20070724  Add JSS(Job Shop Scheduling) Problem Config 
% 20070729  Add version compatible with matlab 6.0
% 20070912  Add GA setting
% 20071023  ga default setting into a file
% 20071115  consolidate to common.jsp.
% 20080211  load default struct of stResourceConfig
% 20071211  Add aiJobSeqInJspCfg
% 20080322  Add iReleaseTimeSlotGlobal, stAgentBiFSPJobMachConfig

global OPT_MIN_MAKE_SPAN;
%global charComment;

%% to be moved for consolidation
strConstWholeConfigLabel = '[PORT_JOB_CONFIG]';
strConstAlgoChoice = 'IP_PACKAGE';
strConstTotalDischargeJob = 'TOTAL_DISCHARGE_CONTAINER';
strConstTotalLoadJob = 'TOTAL_LOAD_CONTAINER';
strConstOptRules = 'OPT_RULE';
strConstTimeUnit = 'TIME_UNIT_MINUTE';
strConstRatioPM_QC = 'TOTAL_PM_PER_QC';
strConstRatioYC_QC = 'TOTAL_YC_PER_QC';
strConstPlotFlag        = 'PLOT_FLAG';
strConstNumPointPM_TimeCap = 'NUM_TIME_POINT_SLOT_PM_CAP';
strConstNumPointYC_TimeCap = 'NUM_TIME_POINT_SLOT_YC_CAP';

astrJspProbCaseConfig.strConstAlgoChoice = strConstAlgoChoice;
astrJspProbCaseConfig.strConstTotalDischargeJob = strConstTotalDischargeJob;
astrJspProbCaseConfig.strConstTotalLoadJob = strConstTotalLoadJob;
astrJspProbCaseConfig.strConstRatioPM_QC = strConstRatioPM_QC;
astrJspProbCaseConfig.strConstRatioYC_QC = strConstRatioYC_QC;
astrJspProbCaseConfig.strConstTimeUnit = strConstTimeUnit;
astrJspProbCaseConfig.strConstOptRules = strConstOptRules;
astrJspProbCaseConfig.strConstPlotFlag = strConstPlotFlag;
astrJspProbCaseConfig.strConstNumPointPM_TimeCap = strConstNumPointPM_TimeCap;
astrJspProbCaseConfig.strConstNumPointYC_TimeCap = strConstNumPointYC_TimeCap;
astrJspProbCaseConfig.iTotalVarRead = 10;

%20070912
charComment = '%';
strConstGASettingCfgLabel = '[GA_SETTING]';
%%% default value
stGASetting = ga_struct_def(); % 20071023

% 20071115
% [stConfigOnePerMachCapLabel, stConfigMachNameLabel, stConfigMachTotalPeriodLabel, astrJSSProbStructCfg, ...
%     stJspMasterPropertyLabel, stBiFspStrCfgMstrLabel] = jsp_def_cnst_str_in_file(); % 20071115 
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
lenConstJobSeqConfig = length(stJobSequencingStrCfgLabel.strConstJobSeqConfig);  % 20071211


strConstDischargeTimeQC_Config = '[DISCHARGE_QC_TIME]';
strConstDischargeTimeQC_Header = 'QC_TIME_DISCHARGE_';
strConstDischargeTimeYC_Config = '[DISCHARGE_YC_TIME]';
strConstDischargeTimeYC_Header = 'YC_TIME_DISCHARGE_';
strConstDischargeTimePM_Config = '[DISCHARGE_PM_TIME]';
strConstDischargeTimePM_Header = 'PM_TIME_DISCHARGE_';
strConstDischargeIdQC_Config = '[DISCHARGE_QC_ID]';
strConstDischargeIdQC_Header = 'QC_ID_JOB_';
strConstDischargeIdYC_Config = '[DISCHARGE_YC_ID]';
strConstDischargeIdYC_Header = 'YC_ID_JOB_';
strConstDischargeIdPM_Config = '[DISCHARGE_PM_ID]';
strConstDischargeIdPM_Header = 'PM_ID_JOB_';

strConstLoadTimeQC_Config = '[LOAD_QC_TIME]';
strConstLoadTimeQC_Header = 'QC_TIME_LOAD_';
strConstLoadTimeYC_Config = '[LOAD_YC_TIME]';
strConstLoadTimeYC_Header = 'YC_TIME_LOAD_';
strConstLoadTimePM_Config = '[LOAD_PM_TIME]';
strConstLoadTimePM_Header = 'PM_TIME_LOAD_';
strConstLoadIdQC_Config = '[LOAD_QC_ID]';
strConstLoadIdQC_Header = 'QC_ID_JOB_';
strConstLoadIdYC_Config = '[LOAD_YC_ID]';
strConstLoadIdYC_Header = 'YC_ID_JOB_';
strConstLoadIdPM_Config = '[LOAD_PM_ID]';
strConstLoadIdPM_Header = 'PM_ID_JOB_';

strConstTimePointPMCap_Config = '[TIME_POINT_PM_CAPACITY]';
strConstTimePointPMCap_Header = 'TIME_POINT_PM_CAP_';
strConstPMCapTimePoint_Config = '[PM_CAPACITY_TIME]';
strConstPMCapTimePoint_Header = 'PM_CAP_TIME_POINT_';
strConstTimePointYCCap_Config = '[TIME_POINT_YC_CAPACITY]';
strConstTimePointYCCap_Header = 'TIME_POINT_YC_CAP_';
strConstYCCapTimePoint_Config = '[YC_CAPACITY_TIME]';
strConstYCCapTimePoint_Header = 'YC_CAP_TIME_POINT_';

lenConstConfigLagel = length(strConstWholeConfigLabel);


%%%%%%%%%%%%% for version compatible
iNumPointPM_TimeCap = 0;
iNumPointYC_TimeCap = 0;

if ~exist('strFileFullName')
    disp('Input the data file --- *.*');
    [Filename, Pathname] = uigetfile('*.ini', 'Pick an Text file as Job Shop Configurations');
    strFileFullName = strcat(Pathname , Filename);
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
end

strQuayCraneJobListConfigurationFile = strFileFullName
stQuayCraneJobList.strJobListInputFilename = strFileFullName;
fptr = fopen(strFileFullName, 'r');
astrJspProbCaseConfig.fptr = fptr;

%%%%%%%%  20070724 Default Parameter
% stJssProbStructConfig.isCriticalOperateSeq = 1;
% stJssProbStructConfig.isWaitInProcess = 0;
% stJssProbStructConfig.isPreemptiveProcess = 0;
stJssProbStructConfig = jsp_def_struct_prob_cfg();

strLine = fgets(fptr);

while(~feof(fptr))
   strLine = sprintf('%sMINIMIMLENGTH_TO_BE_COMPATIBLE_WITH_READER', strLine);
   if strLine(1) == '%'
   else
       if strLine(1:lenConstConfigLagel) == strConstWholeConfigLabel
           [jsp_whole, strLine] = jsp_load_port_job_total(astrJspProbCaseConfig);
           TotalContainer_Discharge = jsp_whole.TotalContainer_Discharge;
           TotalContainer_Load = jsp_whole.TotalContainer_Load;
           iNumPointPM_TimeCap = jsp_whole.iNumPointPM_TimeCap;
           iNumPointYC_TimeCap = jsp_whole.iNumPointYC_TimeCap;
           nTotalJobs = TotalContainer_Discharge + TotalContainer_Load;  %% 20071211, default value
           aiJobSeqInJspCfg = 1:nTotalJobs;    %% 20071211, default value
           %%%%%%%%%%%%%%% Discharging Parameters
       end
       
       if strcmp(strLine(1: length(astrJSSProbStructCfg.strConstJSSProbStructCfgLabel)) ,astrJSSProbStructCfg.strConstJSSProbStructCfgLabel) == 1
           [stJssProbStructConfig, strLine, iReadCount] = jssp_load_prob_struct(fptr, astrJSSProbStructCfg);
           strDebug = sprintf('Totally %d parameters for JSS Problem Struct Config', iReadCount);
           disp(strDebug);
       end
       %%%%%%%%  20070724 
       
       if strcmp(strLine(1:length(strConstGASettingCfgLabel)), strConstGASettingCfgLabel) == 1
           [stGASetting, strLine, iReadCount, stConstStringGASetting] = cfg_load_ga_setting(fptr, charComment);
           strDebug = sprintf('Totally %d parameters for Genetic Struct Config', iReadCount);
           disp(strDebug);
       end
       %%% 20070912
       if strcmp(strLine(1: lenConstJobSeqConfig) , stJobSequencingStrCfgLabel.strConstJobSeqConfig) == 1
           [aiJobSeqInJspCfgRet] = cfg_load_property_para(fptr, stJobSequencingStrCfgLabel.strConstJobSeqHeader, nTotalJobs);
           aiJobSeqInJspCfg = aiJobSeqInJspCfgRet;
       end  % 20071211
       
       if strLine(1:length(strConstDischargeTimeQC_Config)) == strConstDischargeTimeQC_Config
           [aForCycleTimeMachineType1] = cfg_load_property_para(fptr, strConstDischargeTimeQC_Header, TotalContainer_Discharge);
           for ii = 1:1:TotalContainer_Discharge
               stContainerDischargeJobSequence(ii).fCycleTimeMachineType1 = aForCycleTimeMachineType1(ii);
           end
       elseif strLine(1:length(strConstDischargeTimePM_Config)) == strConstDischargeTimePM_Config
           [aDischargeTimePM] = cfg_load_property_para(fptr, strConstDischargeTimePM_Header, TotalContainer_Discharge);
           for ii = 1:1:TotalContainer_Discharge
               stContainerDischargeJobSequence(ii).Time_PM = aDischargeTimePM(ii);
           end
       elseif strLine(1:length(strConstDischargeTimeYC_Config)) == strConstDischargeTimeYC_Config
           [aDischargeTimeYC] = cfg_load_property_para(fptr, strConstDischargeTimeYC_Header, TotalContainer_Discharge);
           for ii = 1:1:TotalContainer_Discharge
               stContainerDischargeJobSequence(ii).Time_YC = aDischargeTimeYC(ii);
           end
       elseif strLine(1:length(strConstDischargeIdQC_Config)) == strConstDischargeIdQC_Config
           [aDischargeIdQC] = cfg_load_property_para(fptr, strConstDischargeIdQC_Header, TotalContainer_Discharge);
           for ii = 1:1:TotalContainer_Discharge
               stContainerDischargeJobSequence(ii).QC_Id = aDischargeIdQC(ii);
           end
       elseif strLine(1:length(strConstDischargeIdPM_Config)) == strConstDischargeIdPM_Config
           [aDischargeIdPM] = cfg_load_property_para(fptr, strConstDischargeIdPM_Header, TotalContainer_Discharge);
           for ii = 1:1:TotalContainer_Discharge
               stContainerDischargeJobSequence(ii).PM_Id = aDischargeIdPM(ii);
           end
       elseif strLine(1:length(strConstDischargeIdYC_Config)) == strConstDischargeIdYC_Config
           [aDischargeIdYC] = cfg_load_property_para(fptr, strConstDischargeIdYC_Header, TotalContainer_Discharge);
           for ii = 1:1:TotalContainer_Discharge
               stContainerDischargeJobSequence(ii).YC_Id = aDischargeIdYC(ii);
           end
           %%%%%%%%%%%%%%% Loading Parameters
       elseif strLine(1:length(strConstLoadTimeQC_Config)) == strConstLoadTimeQC_Config
           [aRevCycleTimeMachineType1] = cfg_load_property_para(fptr, strConstLoadTimeQC_Header, TotalContainer_Load);
           for ii = 1:1:TotalContainer_Load
               stContainerLoadJobSequence(ii).fCycleTimeMachineType1 = aRevCycleTimeMachineType1(ii);
           end
       elseif strLine(1:length(strConstLoadTimePM_Config)) == strConstLoadTimePM_Config
           [aLoadTimePM] = cfg_load_property_para(fptr, strConstLoadTimePM_Header, TotalContainer_Load);
           for ii = 1:1:TotalContainer_Load
               stContainerLoadJobSequence(ii).Time_PM = aLoadTimePM(ii);
           end
       elseif strLine(1:length(strConstLoadTimeYC_Config)) == strConstLoadTimeYC_Config
           [aLoadTimeYC] = cfg_load_property_para(fptr, strConstLoadTimeYC_Header, TotalContainer_Load);
           for ii = 1:1:TotalContainer_Load
               stContainerLoadJobSequence(ii).Time_YC = aLoadTimeYC(ii);
           end
       elseif strLine(1:length(strConstLoadIdQC_Config)) == strConstLoadIdQC_Config
           [aLoadIdQC] = cfg_load_property_para(fptr, strConstLoadIdQC_Header, TotalContainer_Load);
           for ii = 1:1:TotalContainer_Load
               stContainerLoadJobSequence(ii).QC_Id = aLoadIdQC(ii);
           end
       elseif strLine(1:length(strConstLoadIdPM_Config)) == strConstLoadIdPM_Config
           [aLoadIdPM] = cfg_load_property_para(fptr, strConstLoadIdPM_Header, TotalContainer_Load);
           for ii = 1:1:TotalContainer_Load
               stContainerLoadJobSequence(ii).PM_Id = aLoadIdPM(ii);
           end
       elseif strLine(1:length(strConstLoadIdYC_Config)) == strConstLoadIdYC_Config
           [aLoadIdYC] = cfg_load_property_para(fptr, strConstLoadIdYC_Header, TotalContainer_Load);
           for ii = 1:1:TotalContainer_Load
               stContainerLoadJobSequence(ii).YC_Id = aLoadIdYC(ii);
           end
       elseif strLine(1:length(strConstTimePointPMCap_Config)) == strConstTimePointPMCap_Config & iNumPointPM_TimeCap >= 1
           [fListTimePointPMCap] = cfg_load_property_para(fptr, strConstTimePointPMCap_Header, iNumPointPM_TimeCap); 
       elseif strLine(1:length(strConstPMCapTimePoint_Config)) == strConstPMCapTimePoint_Config & iNumPointPM_TimeCap >= 1                                
           [fListPMCapTimePoint] = cfg_load_property_para(fptr, strConstPMCapTimePoint_Header, iNumPointPM_TimeCap);
       elseif strLine(1:length(strConstTimePointYCCap_Config)) == strConstTimePointYCCap_Config & iNumPointYC_TimeCap >= 1
           [fListTimePointYCCap] = cfg_load_property_para(fptr, strConstTimePointYCCap_Header, iNumPointYC_TimeCap); 
       elseif strLine(1:length(strConstYCCapTimePoint_Config)) == strConstYCCapTimePoint_Config & iNumPointYC_TimeCap >= 1                                
           [fListYCCapTimePoint] = cfg_load_property_para(fptr, strConstYCCapTimePoint_Header, iNumPointYC_TimeCap);
       end
   end
   strLine = fgets(fptr);
end


fclose(fptr);
if TotalContainer_Load == 0
    stContainerLoadJobSequence = [];
end
if TotalContainer_Discharge == 0
    stContainerDischargeJobSequence = [];
end

for ii = 1:1:TotalContainer_Load
    stContainerLoadJobSequence(ii).Time_PM_YC = stContainerLoadJobSequence(ii).Time_PM + stContainerLoadJobSequence(ii).Time_YC;
end
for ii = 1:1:TotalContainer_Discharge
    stContainerDischargeJobSequence(ii).Time_PM_YC = stContainerDischargeJobSequence(ii).Time_PM + stContainerDischargeJobSequence(ii).Time_YC;
end

stQuayCraneJobList.iAlgoOption = jsp_whole.iAlgoOption;
stQuayCraneJobList.fTimeUnit_Min = jsp_whole.fTimeUnit_Min;
stQuayCraneJobList.iOptRule = jsp_whole.iOptRule;
stQuayCraneJobList.TotalContainer_Discharge = jsp_whole.TotalContainer_Discharge;
stQuayCraneJobList.MaxVirtualPrimeMover = jsp_whole.MaxVirtualPrimeMover;
stQuayCraneJobList.MaxVirtualYardCrane = jsp_whole.MaxVirtualYardCrane;
stQuayCraneJobList.TotalContainer_Load = jsp_whole.TotalContainer_Load;
stQuayCraneJobList.stContainerDischargeJobSequence = stContainerDischargeJobSequence;
stQuayCraneJobList.stContainerLoadJobSequence  =stContainerLoadJobSequence;
stQuayCraneJobList.stJssProbStructConfig = stJssProbStructConfig; %% 20070724
stQuayCraneJobList.stGASetting = stGASetting; %% 20070912
stQuayCraneJobList.aiJobSeqInJspCfg = aiJobSeqInJspCfg;  % 20071211
stQuayCraneJobList.iReleaseTimeSlotGlobal = 0; % 20080322

%%%%%%%%%%%%%%% construct the stResourceConfig for the QC
[stResourceConfig, stMachineConfig] = jsp_def_struct_res_cfg(); % 20080211
stQuayCraneJobList.stResourceConfig = stResourceConfig; % 20080211

stQuayCraneJobList.stResourceConfig.iTotalMachine = 3;
stQuayCraneJobList.stResourceConfig.stMachineConfig(1).strName = 'QC';
stQuayCraneJobList.stResourceConfig.stMachineConfig(1).iNumPointTimeCap = 0;
stQuayCraneJobList.stResourceConfig.stMachineConfig(1).afTimePointAtCap = 0;
stQuayCraneJobList.stResourceConfig.stMachineConfig(1).afMaCapAtTimePoint = 1;

stQuayCraneJobList.stResourceConfig.stMachineConfig(2).strName = 'PM';
stQuayCraneJobList.stResourceConfig.stMachineConfig(2).iNumPointTimeCap = iNumPointPM_TimeCap;
if iNumPointPM_TimeCap == 0
    stQuayCraneJobList.stResourceConfig.stMachineConfig(2).iNumPointTimeCap = 1;
    stQuayCraneJobList.stResourceConfig.stMachineConfig(2).afTimePointAtCap(1) = 0;
    stQuayCraneJobList.stResourceConfig.stMachineConfig(2).afMaCapAtTimePoint(1) = stQuayCraneJobList.MaxVirtualPrimeMover;
else
    for ii = 1:1:iNumPointPM_TimeCap
        stQuayCraneJobList.stResourceConfig.stMachineConfig(2).afTimePointAtCap(ii) = fListTimePointPMCap(ii);
        stQuayCraneJobList.stResourceConfig.stMachineConfig(2).afMaCapAtTimePoint(ii) = fListPMCapTimePoint(ii);
    end
end

stQuayCraneJobList.stResourceConfig.stMachineConfig(3).strName = 'YC';
stQuayCraneJobList.stResourceConfig.stMachineConfig(3).iNumPointTimeCap = iNumPointYC_TimeCap;
if iNumPointYC_TimeCap == 0
    stQuayCraneJobList.stResourceConfig.stMachineConfig(3).iNumPointTimeCap = 1;
    stQuayCraneJobList.stResourceConfig.stMachineConfig(3).afTimePointAtCap(1) = 0;
    stQuayCraneJobList.stResourceConfig.stMachineConfig(3).afMaCapAtTimePoint(1) = stQuayCraneJobList.MaxVirtualYardCrane;
else
    for ii = 1:1:iNumPointYC_TimeCap
        stQuayCraneJobList.stResourceConfig.stMachineConfig(3).afTimePointAtCap(ii) = fListTimePointYCCap(ii);
        stQuayCraneJobList.stResourceConfig.stMachineConfig(3).afMaCapAtTimePoint(ii) = fListYCCapTimePoint(ii);
    end
end
stQuayCraneJobList.stResourceConfig.iaMachCapOnePer = [1, max(stQuayCraneJobList.stResourceConfig.stMachineConfig(2).afMaCapAtTimePoint), ...
    max(stQuayCraneJobList.stResourceConfig.stMachineConfig(3).afMaCapAtTimePoint)];

if isfield(jsp_whole, 'iPlotFlag')
    stQuayCraneJobList.iPlotFlag = jsp_whole.iPlotFlag;
else
    stQuayCraneJobList.iPlotFlag = 0;
end

% 20080322
[stJobListBiFsp] = cvt_joblist_by_port(stQuayCraneJobList);
stQuayCraneJobList.stAgentBiFSPJobMachConfig = stJobListBiFsp.stAgentBiFSPJobMachConfig;  % 20080322
stQuayCraneJobList.stJobListBiFsp = stJobListBiFsp;

% stQuayCraneJobList.stAgentBiFSPJobMachConfig = fsp_def_struct_bidir_cfg(); % default parameter
% stAgentBiFSPJobMachConfig.iTotalForwardJobs  = stQuayCraneJobList.TotalContainer_Discharge;
% stAgentBiFSPJobMachConfig.iTotalReverseJobs  = stQuayCraneJobList.TotalContainer_Load;
% stAgentBiFSPJobMachConfig.iOptionPackageIP   = stQuayCraneJobList.iAlgoOption;
% stAgentBiFSPJobMachConfig.iOptRule           = stQuayCraneJobList.iOptRule;
% stAgentBiFSPJobMachConfig.iTotalMachType     = 3;
% stAgentBiFSPJobMachConfig.iPlotFlag          = stQuayCraneJobList.iPlotFlag;
% stAgentBiFSPJobMachConfig.fTimeUnit_Min      = stQuayCraneJobList.fTimeUnit_Min;
% stAgentBiFSPJobMachConfig.iCriticalMachType  = 1;

