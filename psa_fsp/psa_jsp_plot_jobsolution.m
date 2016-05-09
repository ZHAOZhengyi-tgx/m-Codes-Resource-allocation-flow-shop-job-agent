function [iMaxEndTime] = psa_jsp_plot_jobsolution(jobshop_solution, figure_id)
% plot the job scheduling, 
%    (1) group by machine (in Y-axis), 
%    (2) job grouping by colour,
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
% History
% YYYYMMDD Notes
% 20070725 Consider the case when process time is too small
% 20071106 Add for dumpy process

for mm = 1:1:jobshop_solution.iTotalMachine
    if isfield(jobshop_solution, 'stResourceConfig')
         nMaxFromConfig = max(jobshop_solution.stResourceConfig.stMachineConfig(mm).afMaCapAtTimePoint);
         if nMaxFromConfig > jobshop_solution.iTotalMachineNum(mm)
             nMaxTotalMachineNum(mm) = nMaxFromConfig;
         else
             nMaxTotalMachineNum(mm) = jobshop_solution.iTotalMachineNum(mm);
         end
    else
        nMaxTotalMachineNum(mm) = jobshop_solution.iTotalMachineNum(mm);
    end
end

figure(figure_id);
iMaxEndTime = jobshop_solution.iMaxEndTime;
iFlagHoldOnce = 1;
fEpslonTime = 1e-5; % 20071106

axis([-1, double(iMaxEndTime) * 6/5, 0, double(jobshop_solution.iTotalMachine) + 1])
grid on;
for ii = 1:1:double(jobshop_solution.iTotalJob)
    for jj = 1:1:double(jobshop_solution.stProcessPerJob(ii))
        x1 = double(jobshop_solution.stJobSet(ii).iProcessStartTime(jj));
        x2 = double(jobshop_solution.stJobSet(ii).iProcessEndTime(jj));
        iMachineType = jobshop_solution.stJobSet(ii).iProcessMachine(jj);
        iTotalMachineNum = nMaxTotalMachineNum(iMachineType);
        fMachineWidth = 1/(iTotalMachineNum + 1);
        fDeltaWidth = fMachineWidth/(iTotalMachineNum + 1);
        y1 = double(jobshop_solution.stJobSet(ii).iProcessMachine(jj) + (jobshop_solution.stJobSet(ii).iProcessMachineId(jj) - 1)*fMachineWidth) ...
            + (jobshop_solution.stJobSet(ii).iProcessMachineId(jj) - 1)*fDeltaWidth;
        y2 = y1 + fMachineWidth;
        
      
        if x2 - x1 > fEpslonTime % 20071106
            h = plot([x1, x2], [y1, y1], [x1, x2], [y2, y2], [x1, x1], [y1, y2], [x2, x2], [y1, y2]);
            v = get(h);
            aColor = [0 0 0];
            rgbStep3 = ceil(jobshop_solution.iTotalJob /3);
            rgbAxis = ceil(ii/rgbStep3);
            rgbColorNumber = (rem(ii,rgbStep3)+1)/rgbStep3;
            aColor(rgbAxis) = rgbColorNumber;
            set(h, 'Color', aColor);
            if iFlagHoldOnce == 1
                hold on;
                iFlagHoldOnce = 0;
            end
            % if processing time is too small %20070725
            if abs(x2 - x1) <= 1.5
                strText = sprintf('J%d', ii);
                text(x1, y1+ (y2-y1) * 0.5, strText);
                strText = sprintf('P%d', jj);
                text(x1, y1 +(y2-y1) * 0.1, strText);
            else
                strText = sprintf('J%dP%d', ii, jj);
                text(x1, (y1 + y2)/2, strText);
            end
        end  % 20071106
    end
end
plot([iMaxEndTime, iMaxEndTime], [0, jobshop_solution.iTotalMachine + 1], '-.')
xlabel('time slot', 'FontSize', 16);
ylabel('Integer: Machine Type; Fraction: Machine-Id', 'FontSize', 16);
strText = sprintf('Machine schedule Gantt chart for job/flow shop,  Makespan: %d', jobshop_solution.iMaxEndTime);
title(strText, 'FontSize', 18);
hold off;