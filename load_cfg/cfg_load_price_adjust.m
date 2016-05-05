function [stPriceAdjust, strLine, iReadCount] = cfg_load_price_adjust(fptrConfigFile, stConstStringPriceAdjust)
% configuration-loader, to load struct for price adjustment 
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
%
%%% default value
stPriceAdjust.iFlagStrategy = 1;
stPriceAdjust.fAlpha        = 1.5;
%%%

strConstFlagStrategy = stConstStringPriceAdjust.strConstFlagStrategy;
lenConstFlagStrategy = length(strConstFlagStrategy);

strConstFlagAlpha = stConstStringPriceAdjust.strConstFlagAlpha;
lenConstFlagAlpha = length(strConstFlagAlpha);

iReadCount = 0;
strLine = fgets(fptrConfigFile);

while strLine(1) ~= '['
   strLine = sprintf('%sMINIMIMLENGTH_TO_BE_COMPATIBLE_WITH_READER', strLine);
   if strLine(1:lenConstFlagStrategy) == strConstFlagStrategy
%       strLine
       stPriceAdjust.iFlagStrategy = sscanf(strLine((lenConstFlagStrategy + 1): end), ' = %d');
       iReadCount = iReadCount + 1;

   elseif strLine(1:lenConstFlagAlpha) == strConstFlagAlpha
       stPriceAdjust.fAlpha = sscanf(strLine((lenConstFlagAlpha + 1): end), ' = %f');
       iReadCount = iReadCount + 1;

   elseif feof(fptrConfigFile)
       error('Not compatible input.');
   end
   strLine = fgets(fptrConfigFile);
end

strLine = sprintf('%sMINIMIMLENGTH_TO_BE_COMPATIBLE_WITH_READER', strLine);
