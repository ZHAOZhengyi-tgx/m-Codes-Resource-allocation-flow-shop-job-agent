function [stGASetting, strLine, iReadCount, stConstStringGASetting] = cfg_load_ga_setting(fptrConfigFile, charComment)
% config-file loader, load genetic algorithm settings
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
% YYYYMMDD Notes
% 20070912 Created for loading Genetic Algorithm setting
% 20071126 merge into ga_def_cnst_str_in_file

%%% initialize struct with default value
stGASetting = ga_struct_def(); % 20071126

%%% constant string in label
stConstStringGASetting = ga_def_cnst_str_in_file(); % 20071126

%%% 
strConstFlagSeqByGA         = stConstStringGASetting.strConstFlagSeqByGA         ;
strConstFlagLoadRandStateGA = stConstStringGASetting.strConstFlagLoadRandStateGA ;
strConstGenePopSize         = stConstStringGASetting.strConstGenePopSize         ;
strConstGeneXoverRate       = stConstStringGASetting.strConstGeneXoverRate       ;
strConstGeneMutateRate      = stConstStringGASetting.strConstGeneMutateRate      ;
strConstGeneMaxGeneration   = stConstStringGASetting.strConstGeneMaxGeneration   ;
strConstEpsStdByAveStopGA   = stConstStringGASetting.strConstEpsStdByAveStopGA   ;

lenConstFlagSeqByGA         = length(strConstFlagSeqByGA        );
lenConstFlagLoadRandStateGA = length(strConstFlagLoadRandStateGA);
lenConstGenePopSize         = length(strConstGenePopSize        );
lenConstGeneXoverRate       = length(strConstGeneXoverRate      );
lenConstGeneMutateRate      = length(strConstGeneMutateRate     );
lenConstGeneMaxGeneration   = length(strConstGeneMaxGeneration  );
lenConstEpsStdByAveStopGA   = length(strConstEpsStdByAveStopGA  );


iReadCount = 0;
strLine = fgets(fptrConfigFile);

while strLine(1) ~= '['
   strLine = sprintf('%sMINIMIMLENGTH_TO_BE_COMPATIBLE_WITH_READER', strLine);
   if strLine(1) ~= charComment
       if strLine(1:lenConstFlagSeqByGA) == strConstFlagSeqByGA
           stGASetting.isSequecingByGA = sscanf(strLine((lenConstFlagSeqByGA + 1): end), ' = %d');
           iReadCount = iReadCount + 1;

       elseif strLine(1:lenConstFlagLoadRandStateGA) == strConstFlagLoadRandStateGA
           stGASetting.iFlagInitRandGeneratorSeed = sscanf(strLine((lenConstFlagLoadRandStateGA + 1): end), ' = %d');
           iReadCount = iReadCount + 1;

       elseif strLine(1:lenConstGenePopSize) == strConstGenePopSize
           stGASetting.iPopSize = sscanf(strLine((lenConstGenePopSize + 1): end), ' = %d');
           iReadCount = iReadCount + 1;

       elseif strLine(1:lenConstGeneXoverRate) == strConstGeneXoverRate
           stGASetting.fXoverRate = sscanf(strLine((lenConstGeneXoverRate + 1): end), ' = %f');
           iReadCount = iReadCount + 1;

       elseif strLine(1:lenConstGeneMutateRate) == strConstGeneMutateRate
           stGASetting.fMutateRate = sscanf(strLine((lenConstGeneMutateRate + 1): end), ' = %f');
           iReadCount = iReadCount + 1;

       elseif strLine(1:lenConstGeneMaxGeneration) == strConstGeneMaxGeneration
           stGASetting.iTotalGen = sscanf(strLine((lenConstGeneMaxGeneration + 1): end), ' = %d');
           iReadCount = iReadCount + 1;

       elseif strLine(1:lenConstEpsStdByAveStopGA) == strConstEpsStdByAveStopGA
           stGASetting.fEpsStdByAveMakespan = sscanf(strLine((lenConstEpsStdByAveStopGA + 1): end), ' = %f');
           iReadCount = iReadCount + 1;

       elseif feof(fptrConfigFile)
           error('Not compatible input.');
       end
   end
   strLine = fgets(fptrConfigFile);
end

strLine = sprintf('%sMINIMIMLENGTH_TO_BE_COMPATIBLE_WITH_READER', strLine);
