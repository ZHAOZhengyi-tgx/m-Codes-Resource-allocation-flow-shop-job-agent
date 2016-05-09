function [iMaxEndTime] = psa_jsp_plot_jobsolution_2(jobshop_solution, figure_id)
% plot the job scheduling, 
%    (1) job grouping by Y-axis,
%    (2) process grouping by colour, 
%    (3) Yard Cranes Operation is integrated in PrimeMover
% jobshop_solution: a struct with following variables
%    iTotalJob:  Total number of jobs
%    iTotalMachine:    total number of machine types
%    iTotalMachineNum: total number of machines in each type, an array with length of iTotalMachine
%    stProcessPerJob:  total number of processes per each job
%    iMaxEndTime:      Final completion time for all processes of all jobs
%    stJobSet: 
% jobshop_solution.stJobSet: an array (length of jobshop_solution.iTotalJob )of struct with following variables
%    iProcessStartTime: start time for the process of the job, an array with length as jobshop_solution.stProcessPerJob
%    iProcessEndTime:   end time for the process of the job, an array with length as jobshop_solution.stProcessPerJob
%    iProcessMachine:   MachineType for the process of the job, an array with length as jobshop_solution.stProcessPerJob
%    iProcessMachineId: MachineId for the process of the job, an array with length as jobshop_solution.stProcessPerJob
%    fProcessStartTime: floating point start time for the process of the job, an array with length as jobshop_solution.stProcessPerJob
%    fProcessEndTime:   floating point end time for the process of the job, an array with length as jobshop_solution.stProcessPerJob
%

figure(figure_id);
iMaxEndTime = jobshop_solution.iMaxEndTime;
iFlagHoldOnce = 1;

axis([-1, double(iMaxEndTime) * 6/5, 0, double(jobshop_solution.iTotalJob) *2])
for ii = 1:1:double(jobshop_solution.iTotalJob)
    for jj = 1:1:double(jobshop_solution.stProcessPerJob(ii))
        x1 = double(jobshop_solution.stJobSet(ii).iProcessStartTime(jj));
        x2 = double(jobshop_solution.stJobSet(ii).iProcessEndTime(jj));
        fWidthY = 0.8;
        y1 = ii;
        y2 = y1 + fWidthY;
      
        h = plot([x1, x2], [y1, y1], [x1, x2], [y2, y2], [x1, x1], [y1, y2], [x2, x2], [y1, y2]);
        v = get(h);
        aColor = [0 0 0];
        rgbStep3 = ceil(max(jobshop_solution.stProcessPerJob(ii)) /3);
        mm = jobshop_solution.stJobSet(ii).iProcessMachine(jj);
%        rgbAxis = ceil(jj/rgbStep3);
        rgbAxis = ceil(mm/rgbStep3);
        rgbColorNumber = (rem(ii,rgbStep3)+1)/rgbStep3;
        aColor(rgbAxis) = rgbColorNumber;
        set(h, 'Color', aColor);
        if iFlagHoldOnce == 1
            hold on;
            grid on;
            iFlagHoldOnce = 0;
        end
        
        if jobshop_solution.stJobSet(ii).iProcessMachine(jj) == 2
            strText = sprintf('PM-%d', jobshop_solution.stJobSet(ii).iProcessMachineId(jj));
            text(x1, (y1 + y2)/2, strText);
        elseif jobshop_solution.stJobSet(ii).iProcessMachine(jj) == 3
            strText = sprintf('Y%d', jobshop_solution.stJobSet(ii).iProcessMachineId(jj));
            text(x1, (y1 + y2)/2, strText);
        end
    end
end
xlabel('time slot (Colour Group is process)');
ylabel('Job Id')
title('Solution Scheduling for the Job Shop, Y-Group is Job');
hold off;