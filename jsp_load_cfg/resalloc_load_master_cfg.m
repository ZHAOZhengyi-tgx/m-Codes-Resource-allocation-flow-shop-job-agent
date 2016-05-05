function [stSystemMasterConfig, strLine] = resalloc_load_master_cfg(fptr, stResAllocStrCfgMstrLabel, stSystemMasterConfig)
% resource allocation load master configuration
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

% 20080211
% default parameter
[stSystemMasterConfig] = resalloc_def_struct_master_cfg();

%%
strConstOptionPackageIP   = stResAllocStrCfgMstrLabel.strConstOptionPackageIP;
strConstTotalNumAgent     = stResAllocStrCfgMstrLabel.strConstTotalNumAgent;
strConstObjFunction       = stResAllocStrCfgMstrLabel.strConstObjFunction;
strConstAlgoChoice        = stResAllocStrCfgMstrLabel.strConstAlgoChoice;
strConstTotalMachineType  = stResAllocStrCfgMstrLabel.strConstTotalMachineType;
strConstPlotFlag          = stResAllocStrCfgMstrLabel.strConstPlotFlag;
strConstTimeFrameUnit_hour= stResAllocStrCfgMstrLabel.strConstTimeFrameUnit_hour;
strConstCriticalMachType  = stResAllocStrCfgMstrLabel.strConstCriticalMachType;
strConstMaxPlanningFrame  = stResAllocStrCfgMstrLabel.strConstMaxPlanningFrame;

lenConstOptionPackageIP  = length(strConstOptionPackageIP);
lenConstTotalNumAgent     = length(strConstTotalNumAgent );
lenConstObjFunction       = length(strConstObjFunction      );
lenConstAlgoChoice        = length(strConstAlgoChoice        );
lenConstTotalMachineType  = length(strConstTotalMachineType);
lenConstPlotFlag          = length(strConstPlotFlag        );
lenConstTimeFrameUnit_hour= length(strConstTimeFrameUnit_hour        );
lenConstCriticalMachType  = length(strConstCriticalMachType);
lenConstMaxPlanningFrame  = length(strConstMaxPlanningFrame);

iReadCount = 1;
strLine = fgets(fptr);

while strLine(1) ~= '['
   strLine = sprintf('%sMINIMIMLENGTH_TO_BE_COMPATIBLE_WITH_READER', strLine);
   if strcmp(strLine(1:lenConstTotalNumAgent) , strConstTotalNumAgent) == 1
       stSystemMasterConfig.iTotalAgent = sscanf(strLine((lenConstTotalNumAgent + 1): end), ' = %d');
       iReadCount = iReadCount + 1;
   elseif strcmp(strLine(1:lenConstObjFunction) , strConstObjFunction ) == 1
       stSystemMasterConfig.iObjFunction = sscanf(strLine((lenConstObjFunction + 1): end), ' = %d');
       iReadCount = iReadCount + 1;
   elseif strcmp(strLine(1:lenConstAlgoChoice) , strConstAlgoChoice) == 1
       stSystemMasterConfig.iAlgoChoice = sscanf(strLine((lenConstAlgoChoice + 1): end), ' = %d');
       iReadCount = iReadCount + 1;
   elseif strcmp(strLine(1:lenConstTotalMachineType) , strConstTotalMachineType) == 1
       stSystemMasterConfig.iTotalMachType = sscanf(strLine((lenConstTotalMachineType + 1): end), ' = %d');
       iReadCount = iReadCount + 1;
   elseif strcmp(strLine(1:lenConstPlotFlag) , strConstPlotFlag) == 1
       stSystemMasterConfig.iPlotFlag = sscanf(strLine((lenConstPlotFlag + 1): end), ' = %d');
       iReadCount = iReadCount + 1;
   elseif strcmp(strLine(1:lenConstTimeFrameUnit_hour) , strConstTimeFrameUnit_hour) == 1
       stSystemMasterConfig.fTimeFrameUnitInHour = sscanf(strLine((lenConstTimeFrameUnit_hour + 1): end), ' = %f');
       iReadCount = iReadCount + 1;
   elseif strcmp(strLine(1:lenConstCriticalMachType) , strConstCriticalMachType) == 1
       stSystemMasterConfig.iCriticalMachType = sscanf(strLine((lenConstCriticalMachType + 1): end), ' = %d');
       iReadCount = iReadCount + 1;
   % lenConstMaxPlanningFrame
   elseif strcmp(strLine(1:lenConstMaxPlanningFrame) , strConstMaxPlanningFrame) == 1
       stSystemMasterConfig.iMaxFramesForPlanning = sscanf(strLine((lenConstMaxPlanningFrame + 1): end), ' = %d');
       iReadCount = iReadCount + 1;
       
   elseif strcmp(strLine(1:lenConstOptionPackageIP) , strConstOptionPackageIP) == 1
       stSystemMasterConfig.iSolverPackage = sscanf(strLine((lenConstOptionPackageIP + 1): end), ' = %d');
       iReadCount = iReadCount + 1;
       
   end
   strLine = fgets(fptr);
end
strLine = sprintf('%sMINIMIMLENGTH_TO_BE_COMPATIBLE_WITH_READER', strLine);


