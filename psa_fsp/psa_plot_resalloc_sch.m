function [stFigureIndivAgent] = psa_plot_resalloc_sch(stAgent_Solution)
% psa plot resource allocation and schedule
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
% YYYYMMDD  Notes
% 20070725  Add stFigureIndivAgent for return

iTotalAgent = length(stAgent_Solution);
nFigureStepSize = ceil(power(10, log10(iTotalAgent))); % 20070725 
%% temperorily hard-coded only for debugging, to be moved out-side
iFigureIdBase = 100;
% 20070725 

for ii = 1:1:iTotalAgent

    container_sequence_jsp = stAgent_Solution(ii).stCostAtAgent.stSolutionMinCost.stSchedule;
    figure_id = iFigureIdBase + ii* nFigureStepSize + 1;
    psa_jsp_plot_jobsolution(container_sequence_jsp, figure_id);
    title('Job Sequence Generation, Y-Group is Machine');
    stFigureIndivAgent.aiFigureIdGroupByMachine(ii) = figure_id;   % 20070725
    
    figure_id = iFigureIdBase + ii* nFigureStepSize + 2;
    psa_jsp_plot_jobsolution_2(container_sequence_jsp, figure_id);
    title('Solution Scheduling for the Job Shop, Y-Group is Job');
    stFigureIndivAgent.aiFigureIdGroupByJob(ii) = figure_id;       % 20070725

end