function psa_jsp_plot_ycpm_usage(stMachineUsageInfo, figure_id)
% Port-of-Singapore Authority, job-shop-problem, plot YC, PM usage
% YC: Yard crane, crane in the yard
% PM: Prime mover, vehicles
% the job-list agent is QC: Quey Crane
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

astMachineUsageTimeInfo = stMachineUsageInfo.astMachineUsage;
iTotalMachine = length(astMachineUsageTimeInfo);
figure(figure_id);
for mm = 1:1:iTotalMachine
    subplot(iTotalMachine, 1, mm);
    hold off;
    
    iMaxMachinePlot = max(astMachineUsageTimeInfo(mm).iMaxCapacity, astMachineUsageTimeInfo(mm).iMaxUsage);
    tEarliestTimePlot = stMachineUsageInfo.tEarliestStartTime;
    tLatestTimePlot = stMachineUsageInfo.tLatestCompleteTime;
    tEarliestDate = floor(tEarliestTimePlot);
    tSortedTimeByHour = (astMachineUsageTimeInfo(mm).aSortedTime - tEarliestDate)*24;
    tEarliestTimeByHour = min(tSortedTimeByHour);
    tLatestTimeByHour = max(tSortedTimeByHour);

    axis([tEarliestTimeByHour - 0.1, tLatestTimeByHour + 0.1, -1, iMaxMachinePlot+6]);
    for jj = 1:1:astMachineUsageTimeInfo(mm).iTotalTimePoint
        if jj == 1
            hold on;
            grid on;
            tt_1 = (astMachineUsageTimeInfo(mm).aSortedTime(jj) - tEarliestDate)*24;
            usage_1 = 0;
            usage_2 = astMachineUsageTimeInfo(mm).aMachineUsageAfterTime(jj);
            plot([tt_1, tt_1], [usage_1, usage_2]);
            
        else
            tt_1 = (astMachineUsageTimeInfo(mm).aSortedTime(jj-1) - tEarliestDate)*24;
            tt_2 = (astMachineUsageTimeInfo(mm).aSortedTime(jj) - tEarliestDate)*24;
            usage_1 = astMachineUsageTimeInfo(mm).aMachineUsageAfterTime(jj-1);
            usage_2 = astMachineUsageTimeInfo(mm).aMachineUsageAfterTime(jj);
            plot([tt_1, tt_2], [usage_1, usage_1]);
            plot([tt_2, tt_2], [usage_1, usage_2]);

        end
    end
    %%%%
        h = plot([tEarliestTimeByHour, tLatestTimeByHour], ...
             [astMachineUsageTimeInfo(mm).iMaxCapacity, astMachineUsageTimeInfo(mm).iMaxCapacity]);
        v = get(h);
        aColor = [1 0 0];
        set(h, 'Color', aColor);
        
    strText = sprintf('Machine Usage for type %d machine', mm);
    title(strText);
end

