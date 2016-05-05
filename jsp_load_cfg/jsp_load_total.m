function [jsp_whole, strLine, iReadCount] = jsp_load_total(stJspMasterPropertyLabel, fptrJspCfgFile)

% 20080113 iAlgoOption, 

% default parameter
jsp_whole.iPlotFlag = 0;
jsp_whole.nTotalBatchProd = 1;

% fptrJspCfgFile = stJspMasterPropertyLabel.fptr; 
strConstTotalJob        = stJspMasterPropertyLabel.strConstTotalJob;
strConstAlgoChoice      = stJspMasterPropertyLabel.strConstAlgoChoice;
strConstTotalTimeSlot   = stJspMasterPropertyLabel.strConstTotalTimeSlot;
strConstTotalMachine    = stJspMasterPropertyLabel.strConstTotalMachine;
strConstTimeUnit        = stJspMasterPropertyLabel.strConstTimeUnit;
strConstOptRules        = stJspMasterPropertyLabel.strConstOptRules;
strConstPlotFlag        = stJspMasterPropertyLabel.strConstPlotFlag;
strConstTotalBatchPlan  = stJspMasterPropertyLabel.strConstTotalBatchPlan;

lenConstTotalJob = length(strConstTotalJob);
lenConstAlgoChoice = length(strConstAlgoChoice);
lenConstTotalTimeSlot = length(strConstTotalTimeSlot);
lenConstTotalMachine = length(strConstTotalMachine);
lenConstTimeUnit = length(strConstTimeUnit);
lenConstOptRules = length(strConstOptRules);
lenConstPlotFlag = length(strConstPlotFlag);
lenConstTotalBatchPlan = length(strConstTotalBatchPlan);

iReadCount = 0;
strLine = fgets(fptrJspCfgFile);

while strLine(1) ~= '['
   strLine = sprintf('%sMINIMIMLENGTH_TO_BE_COMPATIBLE_WITH_READER', strLine);
   if strLine(1:lenConstTotalJob) == strConstTotalJob
       jsp_whole.iTotalJob = sscanf(strLine((lenConstTotalJob + 1): end), ' = %d');
       iReadCount = iReadCount + 1;
   elseif strLine(1:lenConstAlgoChoice) == strConstAlgoChoice
       jsp_whole.iAlgoOption = sscanf(strLine((lenConstAlgoChoice + 1): end), ' = %d');
       iReadCount = iReadCount + 1;
   elseif strLine(1:lenConstTotalTimeSlot) == strConstTotalTimeSlot
       jsp_whole.iTotalTimeSlot = sscanf(strLine((lenConstTotalTimeSlot + 1): end), ' = %d');
       iReadCount = iReadCount + 1;
   elseif strLine(1:lenConstTotalMachine) == strConstTotalMachine
       jsp_whole.iTotalMachine = sscanf(strLine((lenConstTotalMachine + 1): end), ' = %d');
       iReadCount = iReadCount + 1;
   elseif strLine(1:lenConstTimeUnit) == strConstTimeUnit
       jsp_whole.fTimeUnit = sscanf(strLine((lenConstTimeUnit + 1): end), ' = %f');
       iReadCount = iReadCount + 1;
   elseif strLine(1:lenConstOptRules) == strConstOptRules
       jsp_whole.iOptRule = sscanf(strLine((lenConstOptRules + 1): end), ' = %d');
       iReadCount = iReadCount + 1;
   elseif strLine(1:lenConstPlotFlag) == strConstPlotFlag
       jsp_whole.iPlotFlag = sscanf(strLine((lenConstPlotFlag + 1): end), ' = %d');
       iReadCount = iReadCount + 1;
   elseif strLine(1:lenConstTotalBatchPlan) == strConstTotalBatchPlan
       jsp_whole.nTotalBatchProd = sscanf(strLine((lenConstTotalBatchPlan + 1): end), ' = %d');
       iReadCount = iReadCount + 1;
   end
   strLine = fgets(fptrJspCfgFile);
end
strLine = sprintf('%sMINIMIMLENGTH_TO_BE_COMPATIBLE_WITH_READER', strLine);

% for version compatible
% 20080113
global IP_SOLVER_OPT_MSK;
global IP_SOLVER_OPT_SEDUMI;
global IP_SOLVER_OPT_CPLEX;

if jsp_whole.iOptRule == 17
    jsp_whole.iAlgoOption = IP_SOLVER_OPT_CPLEX;
end

% jsp_whole.iTotalJob     = iTotalJob;
% jsp_whole.iAlgoOption   = iAlgoOption;
% jsp_whole.iTotalMachine = iTotalMachine;
% jsp_whole.iTotalTimeSlot= iTotalTimeSlot;
% jsp_whole.fTimeUnit     = fTimeUnit;
% 
% if exist('iOptRule')
%     jsp_whole.iOptRule = iOptRule;
% end
