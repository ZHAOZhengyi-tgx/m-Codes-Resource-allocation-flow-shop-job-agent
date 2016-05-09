function [iMaxEndTime] = jsp_plot_schedu_mach_circu(jobshop_solution, figure_id)
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


figure(figure_id);
iMaxEndTime = jobshop_solution.iMaxEndTime;
iFlagHoldOnce = 1;
fEpslonTime = 1e-5; % 20071106
nTotalMachine = jobshop_solution.iTotalMachine;

fMaxRadius = double(iMaxEndTime) * 101/100;
fDeltaAngle_rad = 2 * pi/ nTotalMachine;
axis([-fMaxRadius, fMaxRadius,-fMaxRadius, fMaxRadius]);

for mm = 1:1:nTotalMachine
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
    %% plot the frame
    plot([0, fMaxRadius * cos((mm - 1) * fDeltaAngle_rad)], [0, fMaxRadius * sin((mm - 1) * fDeltaAngle_rad)])
    if iFlagHoldOnce == 1
        hold on;
        iFlagHoldOnce = 0;
    end
end

%grid on;
for ii = 1:1:double(jobshop_solution.iTotalJob)
    for jj = 1:1:double(jobshop_solution.stProcessPerJob(ii))
        fProcStartTime = double(jobshop_solution.stJobSet(ii).iProcessStartTime(jj));
        fProcEndTime = double(jobshop_solution.stJobSet(ii).iProcessEndTime(jj));
        x1 = fProcStartTime;
        x2 = fProcEndTime;
        
        iMachineType = jobshop_solution.stJobSet(ii).iProcessMachine(jj);
        iTotalMachineNum = nMaxTotalMachineNum(iMachineType);
        fMachineWidth = 1/(iTotalMachineNum + 1);
        fDeltaWidth = fMachineWidth/(iTotalMachineNum + 1);
        y1 = double(jobshop_solution.stJobSet(ii).iProcessMachine(jj) + (jobshop_solution.stJobSet(ii).iProcessMachineId(jj) - 1)*fMachineWidth) ...
            + (jobshop_solution.stJobSet(ii).iProcessMachineId(jj) - 1)*fDeltaWidth;
        y2 = y1 + fMachineWidth;
        
        fAngleMachType_1 = y1 / nTotalMachine * 2 * pi;
        fAngleMachType_2 = y2 / nTotalMachine * 2 * pi;
        
        x_p1 = fProcStartTime * cos(fAngleMachType_1);
        y_p1 = fProcStartTime * sin(fAngleMachType_1);
        x_p2 = fProcEndTime * cos(fAngleMachType_1);
        y_p2 = fProcEndTime * sin(fAngleMachType_1);
        x_p3 = fProcEndTime * cos(fAngleMachType_2);
        y_p3 = fProcEndTime * sin(fAngleMachType_2);
        x_p4 = fProcStartTime * cos(fAngleMachType_2);
        y_p4 = fProcStartTime * sin(fAngleMachType_2);
        
        if fProcEndTime - fProcStartTime > fEpslonTime % 20071106
            h = plot([x_p1, x_p2], [y_p1, y_p2], [x_p2, x_p3], [y_p2, y_p3], [x_p3, x_p4], [y_p3, y_p4], [x_p4, x_p1], [y_p4, y_p1]);
            v = get(h);
            aColor = [0 0 0];
            rgbStep3 = ceil(jobshop_solution.iTotalJob /3);
            rgbAxis = ceil(ii/rgbStep3);
            rgbColorNumber = (rem(ii,rgbStep3)+1)/rgbStep3;
            aColor(rgbAxis) = rgbColorNumber;
            set(h, 'Color', aColor);
            fill([x_p1, x_p2, x_p3, x_p4], [y_p1, y_p2, y_p3, y_p4], aColor)
            % if processing time is too small %20070725
%             if abs(x2 - x1) <= 1.5
%                 strText = sprintf('J%d', ii);
%                 text(x1, y1+ (y2-y1) * 0.5, strText);
%                 strText = sprintf('P%d', jj);
%                 text(x1, y1 +(y2-y1) * 0.1, strText);
%             else
%                 strText = sprintf('J%dP%d', ii, jj);
%                 text(x1, (y1 + y2)/2, strText);
%             end
        end  % 20071106
    end
end
aTheta = linspace(0, 2*pi, 100);
aX = fMaxRadius .* cos(aTheta);
aY = fMaxRadius .* sin(aTheta);
plot(aX, aY, '-.');

xlabel('Radius is time slot', 'FontSize', 16);
ylabel('Angular section: machine type; fraction: machine-Id', 'FontSize', 16);
strText = sprintf('Circular Gantt-Chart for Job Shop (machine scheduling), makespan: %d', jobshop_solution.iMaxEndTime);
title(strText, 'FontSize', 18);
hold off;