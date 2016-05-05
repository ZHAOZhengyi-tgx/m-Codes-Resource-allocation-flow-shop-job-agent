function [stAgentJobListBiFsp, stForwardJobSequence, stReverseJobSequence] = fsp_load_joblist_parameter(strFileFullName)
% flow shop problem, load job-list (with a list of tasks) parameter
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
% 20070724  Add JSS(Job Shop Scheduling) Problem Config 
% 20070729  Add version compatible with matlab 6.0
% 20071023  Add Xls input reference, GA
% 20071110  Add loading stRefXlsOutput
% 20071115  Move to common.jsp.fsp_def_struct_bidir_cfg
% 20071211  Add aiJobSeqInJspCfg
% 20080322  Add iReleaseTimeSlotGlobal
global OPT_MIN_MAKE_SPAN;
global DEF_MAXIMUM_MACHINE_TYPE;
global CHAR_COMMENT_LINE;

jsp_glb_define();

stAgentBiFSPJobMachConfig = fsp_def_struct_bidir_cfg();

%% Master Structure
% stAgentMachCapOnePerConfig = struct(''); 
[stResourceConfig, stMachineConfig] = jsp_def_struct_res_cfg();  % 20071115  jsp_def_struct
stAgentJobListBiFsp = struct('stAgentBiFSPJobMachConfig', [], ...
         'stResourceConfig', []);

% 20071115
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

lenConstMachineNumOnPer_cfg = length(stConfigOnePerMachCapLabel.strConstMachineNumOnPer_cfg);
lenConstJSSProbStructCfgLabel = length(astrJSSProbStructCfg.strConstJSSProbStructCfgLabel);
lenConstMachineName_cfg =length(stConfigMachNameLabel.strConstMachineName_cfg);
lenConstMachineInfo_cfg = length(stConfigMachTotalPeriodLabel.strConstMachineInfo_cfg);
lenConstWholeConfigLabel = length(stBiFspStrCfgMstrLabel.strConstWholeConfigLabel);
lenConstJobSeqConfig = length(stJobSequencingStrCfgLabel.strConstJobSeqConfig);  % 20071211

stJssProbStructConfig = jsp_def_struct_prob_cfg();  % 20071115

%% Excel Reference Input, 20071023
stConstStringRefXlsInput.strConstRefXlsStructCfgLabel = '[TABLE_XLS_INPUT_MACH_PROC_CYCLE_ID_REL]';
stConstStringRefXlsInput.strConstStringFilename  = 'XLS_FILE_NAME';
stConstStringRefXlsInput.strConstStringSheetname = 'XLS_SHEET_NAME';
stConstStringRefXlsInput.strConstStringColStart  = 'XLS_COL_START';
stConstStringRefXlsInput.strConstRowStart        = 'XLS_ROW_START';
stConstStringRefXlsInput.strConstFlagTableFormat = 'XLS_TABLE_FORMAT';
stRefXlsInput = xls_ref_struct_def();  %% default value

%% 20071110 xls_output_ref
stConstStringRefXlsInput.strConstRefXlsOutputCfgLabel = '[TABLE_XLS_OUTPUT_SCHEDULE]';
stRefXlsOutput = xls_ref_struct_def();  %% default value
stRefXlsOutput.strFilenameRelativePath = '.\TempSche.xls';
stRefXlsOutput.strSheetname            = 'JobSchedule';

charComment = '%';
strConstGASettingCfgLabel = '[GA_SETTING]';
%%% default value
stGASetting = ga_struct_def(); % 20071023


%%%%%%%%%%%%% for version compatible
iActualTotalMachineType = 0;
astMachineProcTimeOnMachine = [];
stRefXlsInput = [];  %20071023

if ~exist('strFileFullName')
    disp('Input the data file --- *.*');
    [Filename, Pathname] = uigetfile('*.ini', 'Pick an Text file as Job Shop Configurations');
    strFileFullName = strcat(Pathname , Filename);
end
%%% Convert file name to be compatible with UNIX
[s, astrVer] = mtlb_system_version(); % 20070729

if s == 0 %% it is a dos-windows system
%    disp('it is a dos-windows system');
else %% it is a UNIX or Linux system
    disp('it is a UNIX or Linux system');
    iPathStringList = strfind(strFileFullName, '\');
    for ii = 1:1:length(iPathStringList)
        strFileFullName(iPathStringList(ii)) = '/';
    end
end

strAgentJobListConfigurationFile = strFileFullName;
stAgentJobListBiFsp.strJobListInputFilename = strFileFullName;
fptr = fopen(strFileFullName, 'r');
astrJspProbCaseConfig.fptr = fptr;

%%%%%%%%  20070724 Default Parameter
stJssProbStructConfig.isCriticalOperateSeq = 1;
stJssProbStructConfig.isWaitInProcess = 0;
stJssProbStructConfig.isPreemptiveProcess = 0;

strLine = fgets(fptr);

while(~feof(fptr))
   strLine = sprintf('%sMINIMIMLENGTH_TO_BE_COMPATIBLE_WITH_READER_TO_BE_COMPATIBLE_WITH_READER_TO_BE_COMPATIBLE_WITH_READER', strLine);
   if strLine(1) == CHAR_COMMENT_LINE
   else
%       strLine(1:lenConstWholeConfigLabel)
       if strcmp(strLine(1:lenConstWholeConfigLabel), stBiFspStrCfgMstrLabel.strConstWholeConfigLabel) == 1
           [stAgentBiFSPJobMachConfigRet, strLine] = ...
               fsp_bidir_load_total(fptr, stBiFspStrCfgMstrLabel, stAgentBiFSPJobMachConfig);
           stAgentBiFSPJobMachConfig = stAgentBiFSPJobMachConfigRet; %% verify struct
           iActualTotalMachineType = stAgentBiFSPJobMachConfig.iTotalMachType;
           stAgentBiFSPJobMachConfig.iReleaseTimeSlotGlobal = 0; % 20080322

           %% 20071211
           nTotalJobs = stAgentBiFSPJobMachConfig.iTotalForwardJobs + stAgentBiFSPJobMachConfig.iTotalReverseJobs;
           aiJobSeqInJspCfg = 1:nTotalJobs;    %% 20071211, default value
           
           stResourceConfig.iTotalMachine = iActualTotalMachineType;
           for mm = 1:1:iActualTotalMachineType
               %% initial value
               stResourceConfig.stMachineConfig(mm).iNumPointTimeCap = 0;
           end
           if stAgentBiFSPJobMachConfig.iTotalMachType > DEF_MAXIMUM_MACHINE_TYPE
               
                for mm = (DEF_MAXIMUM_MACHINE_TYPE+1):1:iActualTotalMachineType
                    %% Machine Capacity Lookup Table
                    astMachineProcLabel(mm).strConstMachLUTTimePt_cfg = sprintf('[TIME_POINT_MACH_CAPACITY_TYPE_%d]', mm);
                    astMachineProcLabel(mm).strConstMachLUTTimePt_hdr = sprintf('TIME_POINT_MACH_TYPE_%d_CAP_', mm);
                    astMachineProcLabel(mm).strConstMachLUTCapPt_cfg = sprintf('[MACH_CAPACITY_TIME_TYPE_%d]', mm);
                    astMachineProcLabel(mm).strConstMachLUTCapPt_hdr = sprintf('MACH_TYPE_%d_CAP_TIME_POINT_', mm);
                    %% process time
                    astMachineProcLabel(mm).strConstForwardJobMachTime_cfg = sprintf('[FORWARD_MACH_TIME_TYPE_%d]', mm);
                    astMachineProcLabel(mm).strConstForwardJobMachTime_hdr = sprintf('MACH_TYPE_%d_TIME_FORWARD_', mm);
                    astMachineProcLabel(mm).strConstReverseJobMachTime_cfg = sprintf('[REVERSE_MACH_TIME_TYPE_%d]', mm);
                    astMachineProcLabel(mm).strConstReverseJobMachTime_hdr = sprintf('MACH_TYPE_%d_TIME_REVERSE_', mm);
                    %% release time after process
                    astMachineProcLabel(mm).strConstForwardJobMachRelTime_cfg = sprintf('[FORWARD_MACH_RELEASE_TIME_TYPE_%d]', mm);
                    astMachineProcLabel(mm).strConstForwardJobMachRelTime_hdr = sprintf('MACH_TYPE_%d_RELEASE_TIME_AFTER_FORWARD_', mm);
                    astMachineProcLabel(mm).strConstReverseJobMachRelTime_cfg = sprintf('[REVERSE_MACH_RELEASE_TIME_TYPE_%d]', mm);
                    astMachineProcLabel(mm).strConstReverseJobMachRelTime_hdr = sprintf('MACH_TYPE_%d_RELEASE_TIME_AFTER_REVERSE_', mm);
                    
                    %% Mahine Id for manual dispatching
                    astMachineProcLabel(mm).strConstForwardJobMachId_cfg = sprintf('[FORWARD_MACH_ID_TYPE_%d]', mm);
                    astMachineProcLabel(mm).strConstForwardJobMachId_hdr = sprintf('MACH_TYPE_%d_ID_FORWARD_JOB_', mm);
                    astMachineProcLabel(mm).strConstReverseJobMachId_cfg = sprintf('[REVERSE_MACH_ID_TYPE_%d]', mm);
                    astMachineProcLabel(mm).strConstReverseJobMachId_hdr = sprintf('MACH_TYPE_%d_ID_REVERSE_JOB_', mm);
                end
           end
       end
       
       if strcmp(strLine(1: lenConstJSSProbStructCfgLabel) , astrJSSProbStructCfg.strConstJSSProbStructCfgLabel) == 1
           [stJssProbStructConfigRet, strLine, iReadCount] = jssp_load_prob_struct(fptr, astrJSSProbStructCfg, stJssProbStructConfig);
           stJssProbStructConfig = stJssProbStructConfigRet;
           strDebug = sprintf('Totally %d parameters for JSS Problem Struct Config', iReadCount);
           disp(strDebug);
       end
       if strcmp(strLine(1: lenConstJobSeqConfig) , stJobSequencingStrCfgLabel.strConstJobSeqConfig) == 1
           [aiJobSeqInJspCfgRet] = cfg_load_property_para(fptr, stJobSequencingStrCfgLabel.strConstJobSeqHeader, nTotalJobs);
           aiJobSeqInJspCfg = aiJobSeqInJspCfgRet;
       end  % 20071211
       % 20071023
       if strcmp(strLine(1:length(strConstGASettingCfgLabel)), strConstGASettingCfgLabel) == 1
           [stGASetting, strLine, iReadCount, stConstStringGASetting] = cfg_load_ga_setting(fptr, charComment);
           strDebug = sprintf('Totally %d parameters for Genetic Struct Config', iReadCount);
           disp(strDebug);
       end 
       
       %% 20071023
       if strcmp(strLine(1: length(stConstStringRefXlsInput.strConstRefXlsStructCfgLabel)), stConstStringRefXlsInput.strConstRefXlsStructCfgLabel) == 1
           [stRefXlsInput, strLine, iReadCount] = cfg_load_ref_xls_input(fptr, stConstStringRefXlsInput);
           strDebug = sprintf('Totally %d parameters for Xls Ref Input', iReadCount);
           disp(strDebug);
       end %% 20071023
       

       %% 20071110
       if strcmp(strLine(1: length(stConstStringRefXlsInput.strConstRefXlsOutputCfgLabel)), stConstStringRefXlsInput.strConstRefXlsOutputCfgLabel) == 1
           [stRefXlsOutput, strLine, iReadCount] = cfg_load_ref_xls_input(fptr, stConstStringRefXlsInput);
           strDebug = sprintf('Totally %d parameters for Xls Ref Output', iReadCount);
           disp(strDebug);
       end %% 20071110

       if strcmp(strLine(1: lenConstMachineNumOnPer_cfg) , stConfigOnePerMachCapLabel.strConstMachineNumOnPer_cfg) == 1
           [aMachCapOnePeriod] = cfg_load_property_para( ...
               fptr, stConfigOnePerMachCapLabel.strConstMachineNumOnPer_hdr, iActualTotalMachineType);
           stResourceConfig.iaMachCapOnePer = aMachCapOnePeriod;
       elseif strcmp(strLine(1: lenConstMachineName_cfg) , stConfigMachNameLabel.strConstMachineName_cfg) == 1
           [astrMachineNameList] = cfg_load_property_para_str( ...
               fptr, stConfigMachNameLabel.strConstMachineName_hdr, iActualTotalMachineType);
           for mm = 1:1:iActualTotalMachineType
               stResourceConfig.stMachineConfig(mm).strName = astrMachineNameList(mm).strText;
           end
       elseif strcmp(strLine(1: lenConstMachineInfo_cfg) , stConfigMachTotalPeriodLabel.strConstMachineInfo_cfg) == 1
           [aiTotalPeriod4MachCap] = cfg_load_property_para( ...
               fptr, stConfigMachTotalPeriodLabel.strConstMachineInfo_hdr, iActualTotalMachineType);
           for mm = 1:1:iActualTotalMachineType
               stResourceConfig.stMachineConfig(mm).iNumPointTimeCap = aiTotalPeriod4MachCap(mm);
           end
       end
       %strLine
       for mm = 1:1: iActualTotalMachineType
           
           if strcmp(strLine(1:length(astMachineProcLabel(mm).strConstForwardJobMachTime_cfg)), ...
                   astMachineProcLabel(mm).strConstForwardJobMachTime_cfg) == 1
%                strLine
%                astMachineProcLabel(mm).strConstForwardJobMachTime_hdr
%                stAgentBiFSPJobMachConfig.iTotalForwardJobs
               [aForwardTimeMachine_mm] = cfg_load_property_para( ...
                   fptr, astMachineProcLabel(mm).strConstForwardJobMachTime_hdr, stAgentBiFSPJobMachConfig.iTotalForwardJobs);
               astMachineProcTimeOnMachine(mm).aForwardTimeMachineCycle = aForwardTimeMachine_mm;
           elseif strcmp(strLine(1:length(astMachineProcLabel(mm).strConstReverseJobMachTime_cfg)), ...
                   astMachineProcLabel(mm).strConstReverseJobMachTime_cfg) == 1
               [aReverseTimeMachine_mm] = cfg_load_property_para( ...
                   fptr, astMachineProcLabel(mm).strConstReverseJobMachTime_hdr, stAgentBiFSPJobMachConfig.iTotalReverseJobs);
               astMachineProcTimeOnMachine(mm).aReverseTimeMachineCycle = aReverseTimeMachine_mm;
           elseif strcmp(strLine(1:length(astMachineProcLabel(mm).strConstForwardJobMachRelTime_cfg)), ...
                   astMachineProcLabel(mm).strConstForwardJobMachRelTime_cfg) == 1
               [aForwardRelTimeMachine_mm] = cfg_load_property_para( ...
                   fptr, astMachineProcLabel(mm).strConstForwardJobMachRelTime_hdr, stAgentBiFSPJobMachConfig.iTotalForwardJobs);
               astMachineProcTimeOnMachine(mm).aForwardRelTimeMachineCycle = aForwardRelTimeMachine_mm;
           elseif strcmp(strLine(1:length(astMachineProcLabel(mm).strConstReverseJobMachRelTime_cfg)), ...
                   astMachineProcLabel(mm).strConstReverseJobMachRelTime_cfg) == 1
               [aReverseRelTimeMachine_mm] = cfg_load_property_para( ...
                   fptr, astMachineProcLabel(mm).strConstReverseJobMachRelTime_hdr, stAgentBiFSPJobMachConfig.iTotalReverseJobs);
               astMachineProcTimeOnMachine(mm).aReverseRelTimeMachineCycle = aReverseRelTimeMachine_mm;
           elseif strcmp(strLine(1:length(astMachineProcLabel(mm).strConstForwardJobMachId_cfg)), ...
                   astMachineProcLabel(mm).strConstForwardJobMachId_cfg) == 1
               [aForwardJobMachineId_mm] = cfg_load_property_para( ...
                   fptr, astMachineProcLabel(mm).strConstForwardJobMachId_hdr, stAgentBiFSPJobMachConfig.iTotalForwardJobs);
               astMachineProcTimeOnMachine(mm).aForwardJobOnMachineId = aForwardJobMachineId_mm;
           elseif strcmp(strLine(1:length(astMachineProcLabel(mm).strConstReverseJobMachId_cfg)), ...
                   astMachineProcLabel(mm).strConstReverseJobMachId_cfg) == 1
               [aReverseJobMachineId_mm] = cfg_load_property_para( ...
                   fptr, astMachineProcLabel(mm).strConstReverseJobMachId_hdr, stAgentBiFSPJobMachConfig.iTotalReverseJobs);
               astMachineProcTimeOnMachine(mm).aReverseJobOnMachineId = aReverseJobMachineId_mm;
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
           end
       end
   end
   strLine = fgets(fptr);
end

fclose(fptr);

for mm = 1:1:iActualTotalMachineType
    if stResourceConfig.stMachineConfig(mm).iNumPointTimeCap <= 1
        stResourceConfig.stMachineConfig(mm).iNumPointTimeCap = 1;
        stResourceConfig.stMachineConfig(mm).afTimePointAtCap(1) = 0;
        stResourceConfig.stMachineConfig(mm).afMaCapAtTimePoint(1) = stResourceConfig.iaMachCapOnePer(mm);
    end
end

stAgentJobListBiFsp.stAgentBiFSPJobMachConfig = stAgentBiFSPJobMachConfig;
stAgentJobListBiFsp.stJssProbStructConfig = stJssProbStructConfig;
stForwardJobSequence = [];
stReverseJobSequence = [];
stAgentJobListBiFsp.astMachineProcTimeOnMachine = astMachineProcTimeOnMachine;
stAgentJobListBiFsp.stResourceConfig = stResourceConfig;

%% All the labels
stAgentJobListBiFsp.stConstStringConfigLabels.astMachineProcLabel = astMachineProcLabel;
stAgentJobListBiFsp.stConstStringConfigLabels.stBiFspStrCfgMstrLabel = stBiFspStrCfgMstrLabel;
stAgentJobListBiFsp.stConstStringConfigLabels.astrJSSProbStructCfg = astrJSSProbStructCfg;
stAgentJobListBiFsp.stConstStringConfigLabels.stConfigOnePerMachCapLabel = stConfigOnePerMachCapLabel;
stAgentJobListBiFsp.stConstStringConfigLabels.stConfigMachNameLabel = stConfigMachNameLabel;
stAgentJobListBiFsp.stConstStringConfigLabels.stConfigMachTotalPeriodLabel = stConfigMachTotalPeriodLabel;
stAgentJobListBiFsp.stConstStringConfigLabels.stConstStringGASetting = stConstStringGASetting;
stAgentJobListBiFsp.stConstStringConfigLabels.stJobSequencingStrCfgLabel = stJobSequencingStrCfgLabel;  %20071211

% Xls Reference Input, 20071023
stAgentJobListBiFsp.aiJobSeqInJspCfg = aiJobSeqInJspCfg;  % 20071211
stAgentJobListBiFsp.stGASetting = stGASetting;
stAgentJobListBiFsp.stRefXlsInput = stRefXlsInput;
stAgentJobListBiFsp.stRefXlsOutput = stRefXlsOutput; % 20071110
if length(astMachineProcTimeOnMachine) == 0 && length(stRefXlsInput) >= 1
    if stRefXlsInput.iFlagXlsTableFormat == 1
        astMachineProcTimeOnMachine = fsp_load_joblist_by_xls(stAgentJobListBiFsp);
        stAgentJobListBiFsp.astMachineProcTimeOnMachine = astMachineProcTimeOnMachine;
    elseif stRefXlsInput.iFlagXlsTableFormat == 2
        astMachineProcTimeOnMachine = fsp_load_pij_by_xls(stAgentJobListBiFsp);
        stAgentJobListBiFsp.astMachineProcTimeOnMachine = astMachineProcTimeOnMachine;
    end

end

