function [stQuayCraneJobList, stContainerDischargeJobSequence, stContainerLoadJobSequence] = psa_jsp_load_parameter(strFileFullName)

global OPT_MIN_MAKE_SPAN;

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

strConstJSSProblemConfigLabel = '[JSS_PROBLEM_CONFIG]';
strConstJSSP_PreemptiveLabel = 'IS_PREEMPTIVE';
strConstJSSP_WaitInProcessLabel  = 'IS_WAIT_IN_PROCESS';
strConstJSSP_COSLabel = 'IS_CRITICAL_OPERATION_SEQUENCE';

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


jsp_name_label.strConstAlgoChoice = strConstAlgoChoice;
jsp_name_label.strConstTotalDischargeJob = strConstTotalDischargeJob;
jsp_name_label.strConstTotalLoadJob = strConstTotalLoadJob;
jsp_name_label.strConstRatioPM_QC = strConstRatioPM_QC;
jsp_name_label.strConstRatioYC_QC = strConstRatioYC_QC;
jsp_name_label.strConstTimeUnit = strConstTimeUnit;
jsp_name_label.strConstOptRules = strConstOptRules;
jsp_name_label.strConstPlotFlag = strConstPlotFlag;
jsp_name_label.strConstNumPointPM_TimeCap = strConstNumPointPM_TimeCap;
jsp_name_label.strConstNumPointYC_TimeCap = strConstNumPointYC_TimeCap;
jsp_name_label.iTotalVarRead = 10;

%%%%%%%%%%%%% for version compatible
iNumPointPM_TimeCap = 0;
iNumPointYC_TimeCap = 0;

if ~exist('strFileFullName')
    disp('Input the data file --- *.*');
    [Filename, Pathname] = uigetfile('*.ini', 'Pick an Text file as Job Shop Configurations');
    strFileFullName = strcat(Pathname , Filename);
end
%%% Convert file name to be compatible with UNIX
s = 0;   % 20070729
strVer = ver;
if str2num(strVer(1).Version) >= 7.0
    [s,strSystem] = system('ver');
end      % 20070729

if s == 0 %% it is a dos-windows system
else %% it is a UNIX or Linux system
    iPathStringList = strfind(strFileFullName, '\');
    for ii = 1:1:length(iPathStringList)
        strFileFullName(iPathStringList(ii)) = '/';
    end
    
end

strQuayCraneJobListConfigurationFile = strFileFullName
stQuayCraneJobList.strJobListInputFilename = strFileFullName;
fptr = fopen(strFileFullName, 'r');
jsp_name_label.fptr = fptr;

strLine = fgets(fptr);

while(~feof(fptr))
   strLine = sprintf('%sMINIMIMLENGTH_TO_BE_COMPATIBLE_WITH_READER', strLine);
   if strLine(1) == '%'
   else
       if strLine(1:lenConstConfigLagel) == strConstWholeConfigLabel
           [jsp_whole, strLine] = jsp_load_port_job_total(jsp_name_label);
           TotalContainer_Discharge = jsp_whole.TotalContainer_Discharge;
           TotalContainer_Load = jsp_whole.TotalContainer_Load;
           iNumPointPM_TimeCap = jsp_whole.iNumPointPM_TimeCap;
           iNumPointYC_TimeCap = jsp_whole.iNumPointYC_TimeCap;
           %%%%%%%%%%%%%%% Discharging Parameters
       end
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

%%%%%%%%%%%%%%% construct the stResourceConfig for the QC
stQuayCraneJobList.stResourceConfig.iTotalMachine = 3;
stQuayCraneJobList.stResourceConfig.stMachineConfig(1).strName = 'QC';
stQuayCraneJobList.stResourceConfig.stMachineConfig(1).iNumPointTimeCap = 1;
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

if isfield(jsp_whole, 'iPlotFlag')
    stQuayCraneJobList.iPlotFlag = jsp_whole.iPlotFlag;
else
    stQuayCraneJobList.iPlotFlag = 0;
end
