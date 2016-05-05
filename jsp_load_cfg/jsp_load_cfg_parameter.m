function [jobshop_config, stBatchJobCfg] = jsp_load_cfg_parameter(strJobListInputFilename)

% History
% YYYYMMDD  Notes
% 20071115  Port from JobShop testing bench
% 20071211  Add aiJobSeqInJspCfg
% 20080110  Add Lagrangian Relaxation struct loading from file
% 20080115  Sheet Priority
% 20091216  Job Arrival
global OPT_MIN_MAKE_SPAN;

strConstProcessConfig = '[PROCESS_CONFIG]';
strConstProcessTotal = 'TOTAL_PROCESS_JOB_';

strConstTimeProcessConfig = '[TIME_PROCESS_PARAMETER]';
strConstTimeProcessHeader = 'TIME_JOB_';

strConstMachineProcessConfig = '[MACHINE_PROCESS_PARAMETER]';
strConstMachineProcessHeader = 'MACHINE_JOB_';

strConstJobWeightConfig = '[JOB_WEIGHT_CONFIG]';
strConstJobWeightHeader = 'WEIGHT_JOB_';

strConstJobDueTimeConfig = '[JOB_DUE_TIME]';
strConstJobDueTimeHeader = 'DUE_TIME_JOB_';

lenConstProcessConfig = length(strConstProcessConfig);
lenConstTimeProcessConfig = length(strConstTimeProcessConfig);
lenConstMachineProcessConfig = length(strConstMachineProcessConfig);
lenConstJobWeightConfig = length(strConstJobWeightConfig);
lenConstJobDueTimeConfig = length(strConstJobDueTimeConfig);

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
astrDynamicBatchJobArrival     =   stJspConstStringLoadFile.astrDynamicBatchJobArrival;  % 20091216


lenConstMachineNumOnPer_cfg = length(stConfigOnePerMachCapLabel.strConstMachineNumOnPer_cfg);  %% OnePeriodMachine Capacity, depends on num. of machine type
lenConstJSSProbStructCfgLabel = length(astrJSSProbStructCfg.strConstJSSProbStructCfgLabel);
lenConstMachineName_cfg =length(stConfigMachNameLabel.strConstMachineName_cfg);
lenConstMachineInfo_cfg = length(stConfigMachTotalPeriodLabel.strConstMachineInfo_cfg);
lenConstConfigLagel = length(stJspMasterPropertyLabel.strConstWholeConfigLabel);
lenConstJobSeqConfig = length(stJobSequencingStrCfgLabel.strConstJobSeqConfig);  % 20071211
lenConstDynamicBatchJobArriveMeanTimeCfg = length(astrDynamicBatchJobArrival.strConstJobArrivalStructMeanTimeCfgLabel);  % 20091216
lenConstDynamicBatchJobArriveStDevTimeCfg = length(astrDynamicBatchJobArrival.strConstJobArrivalStructStDevTimeCfgLabel);  % 20091216

strConstGASettingCfgLabel = '[GA_SETTING]';
charComment = '%';

%% Excel Reference Input Machine processing cycle, machine id, machine release time for each job process, 20071023
stConstStringRefXlsInput.strConstRefXlsStructCfgLabel = '[TABLE_XLS_INPUT_MACH_PROC_CYCLE_ID_REL]';
stConstStringRefXlsInput.strConstStringFilename  = 'XLS_FILE_NAME';
stConstStringRefXlsInput.strConstStringSheetname = 'XLS_SHEET_NAME';
stConstStringRefXlsInput.strConstStringColStart  = 'XLS_COL_START';
stConstStringRefXlsInput.strConstRowStart        = 'XLS_ROW_START';
stConstStringRefXlsInput.strConstFlagTableFormat = 'XLS_TABLE_FORMAT';
stConstStringRefXlsInput.strConstStrPrioritySheet = 'XLS_SHEET_PRIORITY';  % 20080115

%% Excel reference input, machine type for each process, 20071116
stConstStringRefXlsInput.strConstRefXlsMachTypCfgLabel = '[TABLE_XLS_INPUT_PROC_MACH_TYPE]';
stConstStringRefXlsInput.strConstRefXlsOutputCfgLabel = '[TABLE_XLS_OUTPUT_SCHEDULE]';

% 20080110
stConstStringLagRelax = lgrlx_def_cnst_str_in_file();
stLagrangianRelax = lgrlx_struct_def();

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%  Assemble for loading configuration
stJspNameLabel.stJspMasterPropertyLabel = stJspMasterPropertyLabel;
stJspNameLabel.strConstProcessConfig = strConstProcessConfig;
stJspNameLabel.strConstProcessTotal = strConstProcessTotal;
stJspNameLabel.strConstTimeProcessHeader = strConstTimeProcessHeader;
stJspNameLabel.strConstMachineProcessHeader = strConstMachineProcessHeader;
stJspNameLabel.strConstJobWeightHeader = strConstJobWeightHeader;
stJspNameLabel.strConstJobDueTimeHeader = strConstJobDueTimeHeader;
stJspNameLabel.stConstStringLagRelax = stConstStringLagRelax; % 20080110
stJspNameLabel.stJobSequencingStrCfgLabel = stJobSequencingStrCfgLabel;  %20071211
stJspNameLabel.strConstJobArrivalTimeMean = astrDynamicBatchJobArrival.strConstJobArrivalTimeMean; % 20091216
stJspNameLabel.strConstJobArrivalTimeStDev = astrDynamicBatchJobArrival.strConstJobArrivalTimeStDev;

%%% default value for return structure
stJssProbStructConfig = jsp_def_struct_prob_cfg();  % 20071115
stGASetting = ga_struct_def(); % 20071023
stRefXlsOutput = xls_ref_struct_def();  %% default value
stRefXlsOutput.strFilenameRelativePath = '.\TempSche.xls';
stRefXlsOutput.strSheetname            = 'JobSchedule';
stProcTimeRefXlsInput = [];   % 20071116
stProcMachTypeRefXlsInp = []; % 20071116
jsp_weight_whole = [];
jsp_due_time = [];
jsp_process_time = [];
jsp_process_machine = [];
jsp_weight_whole = []; 
jsp_due_time     = [];
stResourceConfig = [];
iTotalMachineNum = [];
iActualTotalMachineType = 0;
stJobArrivalMeanTimePerBatch = []; % 20091216
stJobArrivalStDevTimePerBatch = []; % 20091216


if ~exist('strJobListInputFilename')
    disp('Input the data file --- *.*');
    [Filename, Pathname] = uigetfile('*.ini', 'Pick an Text file as Job Shop Configurations');
    strJobListInputFilename = strcat(Pathname , Filename);
end

fptr = fopen(strJobListInputFilename, 'r');
stJspNameLabel.fptr = fptr;

strLine = fgets(fptr);

while(~feof(fptr))
   strLine = sprintf('%sMINIMIMLENGTH_TO_BE_COMPATIBLE_WITH_READER', strLine);
   strBakReadLine = strLine;   %% 20071116
   if strLine(1) == '%'
   else
       if strLine(1:lenConstConfigLagel) == stJspMasterPropertyLabel.strConstWholeConfigLabel;
           [jsp_whole, strLine, iReadCount] = jsp_load_total(stJspMasterPropertyLabel, fptr);
           strDebug = sprintf('Totally %d parameters for Jsp Master Config', iReadCount);
           disp(strDebug);
           iTotalJob = jsp_whole.iTotalJob;
           iTotalMachine = jsp_whole.iTotalMachine;
           iTotalTimeSlot = jsp_whole.iTotalTimeSlot;
           iActualTotalMachineType = iTotalMachine;
           nTotalBatchProd = jsp_whole.nTotalBatchProd; % 20091216
           for mm = 1:1:iActualTotalMachineType
               stResourceConfig.stMachineConfig(mm).iNumPointTimeCap = 0;                %% initial value
           end
           stResourceConfig.iaMachCapOnePer = ones(1, iTotalMachine); % by default, it is ONE-machine problem
           aiJobSeqInJspCfg = 1:iTotalJob;    %% 20071211, default value
           jsp_weight_whole = ones(1, iTotalJob);
           jsp_due_time = zeros(1, iTotalJob);
       end
     
       if strLine(1:lenConstDynamicBatchJobArriveMeanTimeCfg) == astrDynamicBatchJobArrival.strConstJobArrivalStructMeanTimeCfgLabel
%           disp('Read Mean Arrival Time');
           [stJobArrivalMeanTimePerBatch, strLine] = jsp_load_dyn_batch_arrival_mean_time(stJspNameLabel, nTotalBatchProd);
       end
       if strLine(1:lenConstDynamicBatchJobArriveStDevTimeCfg) == astrDynamicBatchJobArrival.strConstJobArrivalStructStDevTimeCfgLabel
           [stJobArrivalStDevTimePerBatch, strLine] = jsp_load_dyn_batch_arrival_std_time(stJspNameLabel, nTotalBatchProd);
%           disp('Read StDev Arrival Time');
       end
       
       if strLine(1:lenConstProcessConfig) == strConstProcessConfig;
           [jsp_process_whole, strLine] = jsp_load_process_total(stJspNameLabel, iTotalJob);
       end
       if strLine(1:lenConstJobWeightConfig) == strConstJobWeightConfig;
           [jsp_weight_whole] = jsp_load_job_weight_total(stJspNameLabel, iTotalJob);
       end
       if strLine(1:lenConstJobDueTimeConfig) == strConstJobDueTimeConfig;
           [jsp_due_time] = jsp_load_job_due_time(stJspNameLabel, iTotalJob); 
       end
       if strLine(1:lenConstTimeProcessConfig) == strConstTimeProcessConfig;
           [jsp_process_time] = jsp_load_time_process_float(stJspNameLabel, iTotalJob, jsp_process_whole);
       end
       if strLine(1:lenConstMachineProcessConfig) == strConstMachineProcessConfig;
           [jsp_process_machine] = jsp_load_machine_process(stJspNameLabel, iTotalJob, jsp_process_whole);
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
       if strcmp(strLine(1:length(strConstGASettingCfgLabel)), strConstGASettingCfgLabel) == 1
           [stGASetting, strLine, iReadCount, stConstStringGASetting] = cfg_load_ga_setting(fptr, charComment);
           strDebug = sprintf('Totally %d parameters for Genetic Struct Config', iReadCount);
           disp(strDebug);
       end 
       if strcmp(strLine(1:length(stConstStringLagRelax.strConstCfgLabel)), stConstStringLagRelax.strConstCfgLabel) == 1   % 20080110
           [stLagrangianRelax, strLine, iReadCount] = cfg_load_lg_relax(fptr, stConstStringLagRelax)
           strDebug = sprintf('Totally %d parameters for LagrangianRelax Struct Config', iReadCount);
           disp(strDebug);
       end 
       
       if strcmp(strLine(1: lenConstMachineNumOnPer_cfg) , stConfigOnePerMachCapLabel.strConstMachineNumOnPer_cfg) == 1
           [aMachCapOnePeriod] = cfg_load_property_para( ...
               fptr, stConfigOnePerMachCapLabel.strConstMachineNumOnPer_hdr, iActualTotalMachineType);
           stResourceConfig.iaMachCapOnePer = aMachCapOnePeriod;
       end
       if strcmp(strLine(1: lenConstMachineName_cfg) , stConfigMachNameLabel.strConstMachineName_cfg) == 1
           [astrMachineNameList] = cfg_load_property_para_str( ...
               fptr, stConfigMachNameLabel.strConstMachineName_hdr, iActualTotalMachineType);
           for mm = 1:1:iActualTotalMachineType
               stResourceConfig.stMachineConfig(mm).strName = astrMachineNameList(mm).strText;
           end
       end
       if strcmp(strLine(1: lenConstMachineInfo_cfg) , stConfigMachTotalPeriodLabel.strConstMachineInfo_cfg) == 1
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
           end
        end
       
       %% 20071023
       if strcmp(strLine(1: length(stConstStringRefXlsInput.strConstRefXlsStructCfgLabel)), stConstStringRefXlsInput.strConstRefXlsStructCfgLabel) == 1
           [stProcTimeRefXlsInput, strLine, iReadCount] = cfg_load_ref_xls_input(fptr, stConstStringRefXlsInput);
           strDebug = sprintf('Totally %d parameters for Xls Ref Input', iReadCount);
           disp(strDebug);
       end %% 20071023
       %% 20071110
       if strcmp(strLine(1: length(stConstStringRefXlsInput.strConstRefXlsOutputCfgLabel)), stConstStringRefXlsInput.strConstRefXlsOutputCfgLabel) == 1
           [stRefXlsOutput, strLine, iReadCount] = cfg_load_ref_xls_input(fptr, stConstStringRefXlsInput);
           strDebug = sprintf('Totally %d parameters for Xls Ref Output', iReadCount);
           disp(strDebug);
       end %% 20071110
       %% 20071116
       if strcmp(strLine(1: length(stConstStringRefXlsInput.strConstRefXlsMachTypCfgLabel)), stConstStringRefXlsInput.strConstRefXlsMachTypCfgLabel) == 1
           [stProcMachTypeRefXlsInp, strLine, iReadCount] = cfg_load_ref_xls_input(fptr, stConstStringRefXlsInput);
           strDebug = sprintf('Totally %d parameters for Xls Mach Type Ref Input', iReadCount);
           disp(strDebug);
       end %% 20071116

   end
   if strcmp(strBakReadLine, strLine) == 1          %% 20071116
       strLine = fgets(fptr);
   end
end

fclose(fptr);
for mm = 1:1:iActualTotalMachineType
    if stResourceConfig.stMachineConfig(mm).iNumPointTimeCap <= 1
        stResourceConfig.stMachineConfig(mm).iNumPointTimeCap = 1;
        stResourceConfig.stMachineConfig(mm).afTimePointAtCap(1) = 0;
        stResourceConfig.stMachineConfig(mm).afMaCapAtTimePoint(1) = stResourceConfig.iaMachCapOnePer(mm);
    end
end


jobshop_config.iTotalJob = jsp_whole.iTotalJob;
jobshop_config.iTotalMachine = jsp_whole.iTotalMachine;
jobshop_config.iTotalTimeSlot = jsp_whole.iTotalTimeSlot;
jobshop_config.iAlgoOption = jsp_whole.iAlgoOption;
jobshop_config.fTimeUnit_Min = jsp_whole.fTimeUnit;
jobshop_config.iOptRule = jsp_whole.iOptRule;
jobshop_config.iTotalMachineNum = stResourceConfig.iaMachCapOnePer;
jobshop_config.iPlotFlag = jsp_whole.iPlotFlag;
jobshop_config.nTotalBatchProd = jsp_whole.nTotalBatchProd;

jobshop_config.stResourceConfig = stResourceConfig; % 20071116
jobshop_config.stProcessPerJob = jsp_process_whole;
jobshop_config.aiJobSeqInJspCfg = aiJobSeqInJspCfg;  % 20071211
jobshop_config.stGASetting = stGASetting;
jobshop_config.stLagrangianRelax = stLagrangianRelax; % 20080110
jobshop_config.stProcTimeRefXlsInput = stProcTimeRefXlsInput;
jobshop_config.stRefXlsOutput = stRefXlsOutput; % 20071110
jobshop_config.stProcMachTypeRefXlsInp =stProcMachTypeRefXlsInp;
jobshop_config.jsp_process_time = jsp_process_time;
jobshop_config.jsp_process_machine = jsp_process_machine;
jobshop_config.aJobWeight = jsp_weight_whole;
jobshop_config.aJobDueTime = jsp_due_time;
jobshop_config.strJobListInputFilename = strJobListInputFilename;
jobshop_config.stJssProbStructConfig = stJssProbStructConfig;

stBatchJobCfg.stJobArrivalMeanTimePerBatch = stJobArrivalMeanTimePerBatch; % 20091216
stBatchJobCfg.stJobArrivalStDevTimePerBatch = stJobArrivalStDevTimePerBatch;
%% initialize default value for single/multiple batch 
jobshop_config.atArrivalTimePerJob = zeros([1, jobshop_config.iTotalJob]); % 20091216

if length(jsp_process_time) == 0 & length(stProcTimeRefXlsInput) >= 1
    [jsp_process_time, jsp_process_machine] = jsp_load_pij_mij_by_xls(jobshop_config);
    jobshop_config.jsp_process_time = jsp_process_time;
    jobshop_config.jsp_process_machine = jsp_process_machine;
end

