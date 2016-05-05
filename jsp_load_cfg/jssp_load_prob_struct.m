function [stJssProbStructConfig, strLine, iReadCount] = jssp_load_prob_struct(fptrConfigFile, astrJSSProbStructCfg, stJssProbStructConfig)
% job shop scheduling problem, load problem struct
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
%History
%YYYYDDMM Notes
%20070724 Created

global OBJ_MINIMIZE_MAKESPAN;
global OBJ_MINIMIZE_SUM_TARDINESS;
global OBJ_MINIMIZE_SUM_TARD_MAKESPAN;
%% Default Parameter
stJssProbStructConfig.isCriticalOperateSeq = 1;
stJssProbStructConfig.isWaitInProcess      = 0;
stJssProbStructConfig.isPreemptiveProcess  = 0;
stJssProbStructConfig.iFlagObjFuncDefine   = 4;
stJssProbStructConfig.isMachineReleaseImmediate = 1;
stJssProbStructConfig.isSemiCOS            = 0;
stJssProbStructConfig.isFlexiCOS           = 0;

%%%

strConstJSSP_PreemptLabel     = astrJSSProbStructCfg.strConstJSSP_PreemptLabel;
strConstJSSP_WaitInProcLabel  = astrJSSProbStructCfg.strConstJSSP_WaitInProcLabel;
strConstJSSP_COSLabel         = astrJSSProbStructCfg.strConstJSSP_COSLabel;
strConstJSSP_ObjFuncDefLabel  = astrJSSProbStructCfg.strConstJSSP_ObjFuncDefLabel;


lenConstJSSP_COSLabel         = length(strConstJSSP_COSLabel        );
lenConstJSSP_WaitInProcLabel  = length(strConstJSSP_WaitInProcLabel );
lenConstJSSP_PreemptLabel     = length(strConstJSSP_PreemptLabel    );
lenConstJSSP_ObjFuncDefLabel  = length(strConstJSSP_ObjFuncDefLabel );

if isfield(astrJSSProbStructCfg, 'strConstJSSP_MachReleaseLabel')
    strConstJSSP_MachReleaseLabel = astrJSSProbStructCfg.strConstJSSP_MachReleaseLabel;
    lenConstJSSP_MachReleaseLabel = length(strConstJSSP_MachReleaseLabel);
else
    strConstJSSP_MachReleaseLabel = 'ElderVersionReturnDefaultValue';
    lenConstJSSP_MachReleaseLabel = length(strConstJSSP_MachReleaseLabel);
end

if isfield(astrJSSProbStructCfg, 'strConstJSSP_SemiCOSLabel')
    strConstJSSP_SemiCOSLabel     = astrJSSProbStructCfg.strConstJSSP_SemiCOSLabel    ;
    lenConstJSSP_SemiCOSLabel     = length(strConstJSSP_SemiCOSLabel    );
else
    strConstJSSP_SemiCOSLabel     = 'ElderVersionReturnDefaultValue';
    lenConstJSSP_SemiCOSLabel     = length(strConstJSSP_SemiCOSLabel    );
end

if isfield(astrJSSProbStructCfg, 'strConstJSSP_FlexiCOSLabel')
    strConstJSSP_FlexiCOSLabel    = astrJSSProbStructCfg.strConstJSSP_FlexiCOSLabel   ;
    lenConstJSSP_FlexiCOSLabel    = length(strConstJSSP_FlexiCOSLabel   );
else
    strConstJSSP_FlexiCOSLabel    = 'ElderVersionReturnDefaultValue';
    lenConstJSSP_FlexiCOSLabel    = length(strConstJSSP_FlexiCOSLabel   );
end

iReadCount = 0;
strLine = fgets(fptrConfigFile);

while strLine(1) ~= '['
   strLine = sprintf('%sMINIMIMLENGTH_TO_BE_COMPATIBLE_WITH_READER', strLine);
   if strcmp(strLine(1:lenConstJSSP_COSLabel) , strConstJSSP_COSLabel ) == 1
%       strLine
       stJssProbStructConfig.isCriticalOperateSeq = sscanf(strLine((lenConstJSSP_COSLabel + 1): end), ' = %d');
       iReadCount = iReadCount + 1;

   elseif strcmp(strLine(1:lenConstJSSP_WaitInProcLabel) , strConstJSSP_WaitInProcLabel ) == 1
       stJssProbStructConfig.isWaitInProcess = sscanf(strLine((lenConstJSSP_WaitInProcLabel + 1): end), ' = %d');
       iReadCount = iReadCount + 1;

   elseif strcmp(strLine(1:lenConstJSSP_PreemptLabel) , strConstJSSP_PreemptLabel ) == 1
       stJssProbStructConfig.isPreemptiveProcess = sscanf(strLine((lenConstJSSP_PreemptLabel + 1): end), ' = %d');
       iReadCount = iReadCount + 1;

   elseif strcmp(strLine(1:lenConstJSSP_ObjFuncDefLabel) , strConstJSSP_ObjFuncDefLabel ) == 1
       stJssProbStructConfig.iFlagObjFuncDefine = sscanf(strLine((lenConstJSSP_ObjFuncDefLabel + 1): end), ' = %d');
       iReadCount = iReadCount + 1;

   elseif strcmp(strLine(1:lenConstJSSP_MachReleaseLabel) , strConstJSSP_MachReleaseLabel ) == 1
       stJssProbStructConfig.isMachineReleaseImmediate = sscanf(strLine((lenConstJSSP_MachReleaseLabel + 1): end), ' = %d');
       iReadCount = iReadCount + 1;

   elseif strcmp(strLine(1:lenConstJSSP_SemiCOSLabel) , strConstJSSP_SemiCOSLabel ) == 1
       stJssProbStructConfig.isSemiCOS = sscanf(strLine((lenConstJSSP_SemiCOSLabel + 1): end), ' = %d');
       iReadCount = iReadCount + 1;

   elseif strcmp(strLine(1:lenConstJSSP_FlexiCOSLabel) , strConstJSSP_FlexiCOSLabel ) == 1
       stJssProbStructConfig.isFlexiCOS = sscanf(strLine((lenConstJSSP_FlexiCOSLabel + 1): end), ' = %d');
       iReadCount = iReadCount + 1;

   elseif feof(fptrConfigFile)
       error('Not compatible input.');
   end
   strLine = fgets(fptrConfigFile);
end
strLine = sprintf('%sMINIMIMLENGTH_TO_BE_COMPATIBLE_WITH_READER', strLine);
