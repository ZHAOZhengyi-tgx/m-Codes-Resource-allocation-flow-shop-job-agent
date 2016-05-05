function [stAgentBiFSPJobMachConfig, strLine] = fsp_bidir_load_total(fptr, stBiFspStrCfgMstrLabel, stAgentBiFSPJobMachConfig)

% default parameter
stAgentBiFSPJobMachConfig = fsp_def_struct_bidir_cfg();
% stAgentBiFSPJobMachConfig.iTotalForwardJobs = [];
% stAgentBiFSPJobMachConfig.iTotalReverseJobs = [];
% stAgentBiFSPJobMachConfig.iOptionPackageIP = [];
% stAgentBiFSPJobMachConfig.iOptRule = [];
% stAgentBiFSPJobMachConfig.iTotalMachType = [];
% stAgentBiFSPJobMachConfig.iPlotFlag = [];
% stAgentBiFSPJobMachConfig.fTimeUnit_Min = [];
% stAgentBiFSPJobMachConfig.iCriticalMachType = [];

strConstWholeConfigLabel = stBiFspStrCfgMstrLabel.strConstWholeConfigLabel;
strConstTotalForwardJob  = stBiFspStrCfgMstrLabel.strConstTotalForwardJob;
strConstTotalReverseJob  = stBiFspStrCfgMstrLabel.strConstTotalReverseJob;
strOptionPackageIP       = stBiFspStrCfgMstrLabel.strOptionPackageIP;
strConstOptRules         = stBiFspStrCfgMstrLabel.strConstOptRules;
strConstTotalMachineType = stBiFspStrCfgMstrLabel.strConstTotalMachineType;
strConstPlotFlag         = stBiFspStrCfgMstrLabel.strConstPlotFlag;
strConstTimeUnit         = stBiFspStrCfgMstrLabel.strConstTimeUnit;
strConstCriticalMachType = stBiFspStrCfgMstrLabel.strConstCriticalMachType;

lenConstTotalForwardJob  = length(strConstTotalForwardJob );
lenConstTotalReverseJob  = length(strConstTotalReverseJob );
lenOptionPackageIP       = length(strOptionPackageIP      );
lenConstOptRules         = length(strConstOptRules        );
lenConstTotalMachineType = length(strConstTotalMachineType);
lenConstPlotFlag         = length(strConstPlotFlag        );
lenConstTimeUnit         = length(strConstTimeUnit        );
lenConstCriticalMachType = length(strConstCriticalMachType);

iReadCount = 1;
strLine = fgets(fptr);

while strLine(1) ~= '['
   strLine = sprintf('%sMINIMIMLENGTH_TO_BE_COMPATIBLE_WITH_READER', strLine);
   if strcmp(strLine(1:lenConstTotalForwardJob) , strConstTotalForwardJob) == 1
       stAgentBiFSPJobMachConfig.iTotalForwardJobs = sscanf(strLine((lenConstTotalForwardJob + 1): end), ' = %d');
       iReadCount = iReadCount + 1;
   elseif strcmp(strLine(1:lenConstTotalReverseJob) , strConstTotalReverseJob ) == 1
       stAgentBiFSPJobMachConfig.iTotalReverseJobs = sscanf(strLine((lenConstTotalReverseJob + 1): end), ' = %d');
       iReadCount = iReadCount + 1;
   elseif strcmp(strLine(1:lenOptionPackageIP) , strOptionPackageIP ) == 1
       stAgentBiFSPJobMachConfig.iOptionPackageIP = sscanf(strLine((lenOptionPackageIP + 1): end), ' = %d');
       iReadCount = iReadCount + 1;
   elseif strcmp(strLine(1:lenConstOptRules) , strConstOptRules) == 1
       stAgentBiFSPJobMachConfig.iOptRule = sscanf(strLine((lenConstOptRules + 1): end), ' = %d');
       iReadCount = iReadCount + 1;
   elseif strcmp(strLine(1:lenConstTotalMachineType) , strConstTotalMachineType) == 1
       stAgentBiFSPJobMachConfig.iTotalMachType = sscanf(strLine((lenConstTotalMachineType + 1): end), ' = %d');
       iReadCount = iReadCount + 1;
   elseif strcmp(strLine(1:lenConstPlotFlag) , strConstPlotFlag) == 1
       stAgentBiFSPJobMachConfig.iPlotFlag = sscanf(strLine((lenConstPlotFlag + 1): end), ' = %d');
       iReadCount = iReadCount + 1;
   elseif strcmp(strLine(1:lenConstTimeUnit) , strConstTimeUnit) == 1
       stAgentBiFSPJobMachConfig.fTimeUnit_Min = sscanf(strLine((lenConstTimeUnit + 1): end), ' = %f');
       iReadCount = iReadCount + 1;
   elseif strcmp(strLine(1:lenConstCriticalMachType) , strConstCriticalMachType) == 1
       stAgentBiFSPJobMachConfig.iCriticalMachType = sscanf(strLine((lenConstCriticalMachType + 1): end), ' = %d');
       iReadCount = iReadCount + 1;
   end
   strLine = fgets(fptr);
end
strLine = sprintf('%sMINIMIMLENGTH_TO_BE_COMPATIBLE_WITH_READER', strLine);


