function [jsp_whole, strLine] = jsp_load_port_job_total(jsp_name_label)


fptr = jsp_name_label.fptr; 
strConstTotalDischargeJob = jsp_name_label.strConstTotalDischargeJob;
strConstTotalLoadJob = jsp_name_label.strConstTotalLoadJob;
strConstRatioPM_QC = jsp_name_label.strConstRatioPM_QC;
strConstRatioYC_QC = jsp_name_label.strConstRatioYC_QC;
strConstAlgoChoice = jsp_name_label.strConstAlgoChoice;
strConstTimeUnit = jsp_name_label.strConstTimeUnit;
strConstOptRules = jsp_name_label.strConstOptRules;
strConstPlotFlag = jsp_name_label.strConstPlotFlag;
strConstNumPointPM_TimeCap = jsp_name_label.strConstNumPointPM_TimeCap ;
strConstNumPointYC_TimeCap = jsp_name_label.strConstNumPointYC_TimeCap ;

lenConstAlgoChoice = length(strConstAlgoChoice);
lenConstTimeUnit = length(strConstTimeUnit);
lenConstOptRules = length(strConstOptRules);
lenConstTotalDischargeJob = length(strConstTotalDischargeJob);
lenConstTotalLoadJob = length(strConstTotalLoadJob);
lenConstRatioPM_QC = length(strConstRatioPM_QC);
lenConstRatioYC_QC = length(strConstRatioYC_QC);
lenConstPlotFlag = length(strConstPlotFlag);
lenConstNumPointPM_TimeCap = length(strConstNumPointPM_TimeCap);
lenConstNumPointYC_TimeCap = length(strConstNumPointYC_TimeCap);

iReadCount = 1;
strLine = fgets(fptr);

%while iReadCount <= jsp_name_label.iTotalVarRead
while strLine(1) ~= '['
   strLine = sprintf('%sMINIMIMLENGTH_TO_BE_COMPATIBLE_WITH_READER', strLine);
   if strLine(1:lenConstTotalDischargeJob) == strConstTotalDischargeJob
       TotalContainer_Discharge = sscanf(strLine((lenConstTotalDischargeJob + 1): end), ' = %d');
       iReadCount = iReadCount + 1;
   elseif strLine(1:lenConstTotalLoadJob) == strConstTotalLoadJob
       TotalContainer_Load = sscanf(strLine((lenConstTotalLoadJob + 1): end), ' = %d');
       iReadCount = iReadCount + 1;
   elseif strLine(1:lenConstAlgoChoice) == strConstAlgoChoice
       iAlgoOption = sscanf(strLine((lenConstAlgoChoice + 1): end), ' = %d');
       iReadCount = iReadCount + 1;
   elseif strLine(1:lenConstTimeUnit) == strConstTimeUnit
       fTimeUnit_Min = sscanf(strLine((lenConstTimeUnit + 1): end), ' = %f');
       iReadCount = iReadCount + 1;
   elseif strLine(1:lenConstOptRules) == strConstOptRules
       iOptRule = sscanf(strLine((lenConstOptRules + 1): end), ' = %d');
       iReadCount = iReadCount + 1;
   elseif strLine(1:lenConstRatioPM_QC) == strConstRatioPM_QC
       MaxVirtualPrimeMover = sscanf(strLine((lenConstRatioPM_QC + 1): end), ' = %d');
       iReadCount = iReadCount + 1;
   elseif strLine(1:lenConstRatioYC_QC) == strConstRatioYC_QC
       MaxVirtualYardCrane = sscanf(strLine((lenConstRatioYC_QC + 1): end), ' = %d');
       iReadCount = iReadCount + 1;
   elseif strLine(1:lenConstPlotFlag) == strConstPlotFlag
       iPlotFlag = sscanf(strLine((lenConstPlotFlag + 1): end), ' = %d');
       iReadCount = iReadCount + 1;
   elseif strLine(1:lenConstNumPointPM_TimeCap) == strConstNumPointPM_TimeCap
       iNumPointPM_TimeCap = sscanf(strLine((lenConstNumPointPM_TimeCap + 1): end), ' = %d');
       iReadCount = iReadCount + 1;
   elseif strLine(1:lenConstNumPointYC_TimeCap) == strConstNumPointYC_TimeCap
       iNumPointYC_TimeCap = sscanf(strLine((lenConstNumPointYC_TimeCap + 1): end), ' = %d');
       iReadCount = iReadCount + 1;
%   elseif feof(fptr)
%       error('Not compatible input.');
   end
   strLine = fgets(fptr);
end
strLine = sprintf('%sMINIMIMLENGTH_TO_BE_COMPATIBLE_WITH_READER', strLine);

jsp_whole.TotalContainer_Discharge     = TotalContainer_Discharge;
jsp_whole.TotalContainer_Load     = TotalContainer_Load;
jsp_whole.MaxVirtualPrimeMover     = MaxVirtualPrimeMover;
jsp_whole.MaxVirtualYardCrane     = MaxVirtualYardCrane;

jsp_whole.iAlgoOption   = iAlgoOption;
jsp_whole.fTimeUnit_Min     = fTimeUnit_Min;
jsp_whole.iOptRule = iOptRule;
if exist('iPlotFlag')
    jsp_whole.iPlotFlag = iPlotFlag;
end
if exist('iNumPointPM_TimeCap')
    jsp_whole.iNumPointPM_TimeCap = iNumPointPM_TimeCap;
else
    jsp_whole.iNumPointPM_TimeCap = 0;
end

if exist('iNumPointYC_TimeCap')
    jsp_whole.iNumPointYC_TimeCap = iNumPointYC_TimeCap;
else
    jsp_whole.iNumPointYC_TimeCap = 0;
end
