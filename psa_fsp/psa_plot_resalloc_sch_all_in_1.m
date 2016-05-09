function psa_plot_resalloc_sch_all_in_1(stQC_Solution, stIdFigure)
% Port-of-Singapore-Authority plot resource allocation & schedules all in 1
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

iTotalQC = length(stQC_Solution);
nCol_subplot = ceil(sqrt(iTotalQC));
nRow_subplot = round(iTotalQC/nCol_subplot);
if nCol_subplot * nRow_subplot < iTotalQC
    nRow_subplot = nRow_subplot + 1;
end

for ii = 1:1:iTotalQC

    container_sequence_jsp = stQC_Solution(ii).stSchedule_MinCost;
    figure_id = stIdFigure.iAllScheGroupByMachine;
    figure(figure_id);
    if iTotalQC == 4
        subplot(2,2,ii);
    else
        subplot(nRow_subplot, nCol_subplot, ii);
    end
    psa_jsp_plot_jobsolution(container_sequence_jsp, figure_id);
    strText = sprintf('Agent - %d', ii);
    title(strText);
%    title('Job Sequence Generation, Y-Group is Machine');
    
    figure_id = stIdFigure.iAllScheGroupByJob;
    figure(figure_id);
    if iTotalQC == 4
        subplot(2,2,ii);
    else
        subplot(nRow_subplot, nCol_subplot, ii);
    end
    psa_jsp_plot_jobsolution_2(container_sequence_jsp, figure_id);
    strText = sprintf('Agent - %d', ii);
    title(strText);
%    title('Solution Scheduling for the Job Shop, Y-Group is Job');

end