function fsp_dbg_save_figure(stBerthJobInfo, stIdFigure)
% flow-shop-problem debug to save figures
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

iPathStringList = strfind(stBerthJobInfo.strInputFilename, '\');
strPathName = stBerthJobInfo.strInputFilename(1:iPathStringList(end));

figure(stIdFigure.iAllScheGroupByMachine)
saveas(gcf, strcat(strPathName, 'ScheduleByMachine.jpg'), 'jpg')
figure(stIdFigure.iAllScheGroupByJob)
saveas(gcf, strcat(strPathName, 'ScheduleByJob.jpg'), 'jpg')

figure(stIdFigure.iAllScheGroupByMachine)
saveas(gcf, strcat(strPathName, 'ScheduleByMachine.eps'), 'eps')
figure(stIdFigure.iAllScheGroupByJob)
saveas(gcf, strcat(strPathName, 'ScheduleByJob.eps'), 'eps')

figure(stIdFigure.iGlobalMachUsage)
saveas(gcf, strcat(strPathName, 'GlobalMachUsage.jpg'), 'jpg')
% saveas(gcf, strcat(strPathName, 'GlobalMachUsage.eps'), 'eps')

figure(stIdFigure.iAllScheduleInOnePicByMach)
saveas(gcf, strcat(strPathName, 'GlobalDispatching.jpg'), 'jpg')
saveas(gcf, strcat(strPathName, 'GlobalDispatching.eps'), 'eps')
