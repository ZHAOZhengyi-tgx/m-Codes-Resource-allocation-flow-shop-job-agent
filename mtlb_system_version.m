function [s, astrVer] = mtlb_system_version()
% to check matlab system versions, especially adaptive from 2006 to 2007
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
% History ToDo
% YYYYMMDD  Notes
% 20070816  Created for version control, adaptive to different matlab versions

s = 0;   % 20070729, by default a DOS-Windows
astrVer = [];

astrVer = ver;
lenVer = length(astrVer);
if lenVer == 0
    disp('Matlab package doesnot support this function -- ver, assume it is UNIX compiled system');
    s = 127;
end
%fMatlabVersion = 0;
iMatlabDateRelease = 0;
for ii = 1:1:lenVer
    if strcmp(astrVer(ii).Name, 'MATLAB') == 1
%        fMatlabVersion = str2num(astrVer(ii).Version); % version can be 7.0.4, not a floating point
        iMatlabDateRelease = datenum(astrVer(ii).Date);
    end
%    astrVer(ii).Name
%    iMatlabDateRelease
%    fMatlabVersion
end

datenumMatlabVersion_R14SP2 = datenum('21-Jan-2005');

%if fMatlabVersion >= 7.0
if iMatlabDateRelease >= datenumMatlabVersion_R14SP2
    s = isunix;
    %[s,strSystem] = system('ver');
end      % 20070729

