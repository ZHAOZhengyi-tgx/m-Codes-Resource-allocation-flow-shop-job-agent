function [stRefXlsInput, strLine, iReadCount] = cfg_load_ref_xls_input(fptrConfigFile, stConstStringRefXlsInput)
% config-file loader, load reference xls-type-table-file input
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

%%%
% History
% YYYYMMDD  Notes
% 20071023  default value is in xls_ref_struct_def.m
% 20080115
stRefXlsInput = xls_ref_struct_def();  %% default value

strConstStrPrioritySheet = stConstStringRefXlsInput.strConstStrPrioritySheet;  % 20080115
lenConstStrPrioritySheet = length(strConstStrPrioritySheet);                   % 20080115

strConstStringFilename = stConstStringRefXlsInput.strConstStringFilename;
lenConstStringFilename = length(strConstStringFilename);

strConstStringSheetname = stConstStringRefXlsInput.strConstStringSheetname;
lenConstStringSheetname = length(strConstStringSheetname);

strConstStringColStart = stConstStringRefXlsInput.strConstStringColStart;
lenConstStringColStart = length(strConstStringColStart);

strConstRowStart = stConstStringRefXlsInput.strConstRowStart;
lenConstRowStart = length(strConstRowStart);

%stConstStringRefXlsInput.strConstFlagTableFormat
strConstFlagTableFormat = stConstStringRefXlsInput.strConstFlagTableFormat;
lenConstFlagTableFormat = length(strConstFlagTableFormat);


iReadCount = 0;
strLine = fgets(fptrConfigFile);

while strLine(1) ~= '['
%     stRefXlsInput
   strLine = sprintf('%sMINIMIMLENGTH_TO_BE_COMPATIBLE_WITH_READER', strLine);
   if strLine(1:lenConstRowStart) == strConstRowStart
%       strLine
       stRefXlsInput.iRowStart = sscanf(strLine((lenConstRowStart + 1): end), ' = %d');
       iReadCount = iReadCount + 1;

   elseif strLine(1:lenConstStringFilename) == strConstStringFilename
       stRefXlsInput.strFilenameRelativePath = sscanf(strLine((lenConstStringFilename + 1): end), ' = %s');
       iReadCount = iReadCount + 1;
       
   elseif strLine(1:lenConstStringSheetname) == strConstStringSheetname
       stRefXlsInput.strSheetname = sscanf(strLine((lenConstStringSheetname + 1): end), ' = %s');
       iReadCount = iReadCount + 1;

       % 20080115
   elseif strLine(1:lenConstStrPrioritySheet) == strConstStrPrioritySheet
       stRefXlsInput.strSheetnamePriority = sscanf(strLine((lenConstStrPrioritySheet + 1): end), ' = %s');
       iReadCount = iReadCount + 1;
       
   elseif strLine(1:lenConstStringColStart) == strConstStringColStart
       stRefXlsInput.strColStart = sscanf(strLine((lenConstStringColStart + 1): end), ' = %s');
       iReadCount = iReadCount + 1;
       
   elseif strLine(1:lenConstFlagTableFormat) == strConstFlagTableFormat
       stRefXlsInput.iFlagXlsTableFormat = sscanf(strLine((lenConstFlagTableFormat + 1): end), ' = %d');
       iReadCount = iReadCount + 1;

   elseif feof(fptrConfigFile)
       %% only Xls input reference could be put at the end of the file
       break;
   end
   strLine = fgets(fptrConfigFile);
end

strLine = sprintf('%sMINIMIMLENGTH_TO_BE_COMPATIBLE_WITH_READER', strLine);
