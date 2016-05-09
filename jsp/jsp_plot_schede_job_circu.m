function [iMaxEndTime] = jsp_plot_schede_job_circu(jobshop_solution, figure_id)
% jobshop_solution: a struct with following variables
%    iTotalJob: 
%    stProcessPerJob: 
%    stJobSet: 
% jobshop_solution.stJobSet: an array (length of jobshop_solution.iTotalJob )of struct with following variables
%    iProcessStartTime: an array with length as jobshop_solution.stProcessPerJob
%    iProcessEndTime:   an array with length as jobshop_solution.stProcessPerJob
%    iProcessMachine:   an array with length as jobshop_solution.stProcessPerJob

% 20071106 Add for dumpy process

%

iMaxEndTime = jobshop_solution.iMaxEndTime;
iFlagHoldOnce = 1;
fEpslonTime = 1e-5; % 20071106
nTotalMach = jobshop_solution.iTotalMachine;
nTotalJob = jobshop_solution.iTotalJob;

fMaxRadius = double(iMaxEndTime) * 101/100;
fDeltaAngle_rad = 2 * pi/ nTotalJob;

axis([-fMaxRadius, fMaxRadius,-fMaxRadius, fMaxRadius]);
for ii = 1:1:nTotalJob
    fAngle_rad = (ii - 1)/nTotalJob * 2 * pi;
    for jj = 1:1:double(jobshop_solution.stProcessPerJob(ii))
        fStartTimeJobProc = double(jobshop_solution.stJobSet(ii).iProcessStartTime(jj));
        fEndTimeJobProc = double(jobshop_solution.stJobSet(ii).iProcessEndTime(jj));
        x_p1 = fStartTimeJobProc * cos(fAngle_rad);
        y_p1 = fStartTimeJobProc * sin(fAngle_rad);
        x_p2 = fEndTimeJobProc * cos(fAngle_rad);
        y_p2 = fEndTimeJobProc * sin(fAngle_rad);
        fAngleNextJob_rad = fDeltaAngle_rad * 0.8  + fAngle_rad;
        x_p4 = fStartTimeJobProc * cos(fAngleNextJob_rad);
        y_p4 = fStartTimeJobProc * sin(fAngleNextJob_rad);
        x_p3 = fEndTimeJobProc * cos(fAngleNextJob_rad);
        y_p3 = fEndTimeJobProc * sin(fAngleNextJob_rad);

        if fEndTimeJobProc - fStartTimeJobProc > fEpslonTime % 20071106
%            ii 
            h = plot([x_p1, x_p2], [y_p1, y_p2], [x_p2, x_p3], [y_p2, y_p3], [x_p3, x_p4], [y_p3, y_p4], [x_p4, x_p1], [y_p4, y_p1]);
            v = get(h);

            aColor = [0 0 0];
            rgbStep3 = ceil(nTotalMach /3);
            mm = jobshop_solution.stJobSet(ii).iProcessMachine(jj);
    %        rgbAxis = ceil(jj/rgbStep3);
            rgbAxis = ceil(mm/rgbStep3);
            rgbColorNumber = (rem(mm,rgbStep3)+1)/rgbStep3;
            aColor(rgbAxis) = rgbColorNumber;
            set(h, 'Color', aColor);
            fill([x_p1, x_p2, x_p3, x_p4], [y_p1, y_p2, y_p3, y_p4], aColor)
            if iFlagHoldOnce == 1
                hold on;
                iFlagHoldOnce = 0;
            end
%             if jj <= 1
%                 if abs(x_p2-x_p1) <= 2
%                     strText = sprintf('J%dM%d', ii, mm);
%                     text(x_p1, (y1 + y2)/2, strText);
%                     strText = sprintf('P%d', jj);
%                     text(x_p1, y1, strText);
%                 else
%                     strText = sprintf('J%dM%dP%d', ii, mm, jj);
%                     text(x_p1, (y1 + y2)/2, strText);
%                 end
%             else
%                 if abs(x_p2-x_p1) <= 2
%                     strText = sprintf('P%d', jj);
%                     text((x_p1+x_p2)/2, (y1 + y2)/2, strText);
%                     strText = sprintf('M%d', mm);
%                     text((x_p1+x_p2)/2, y1, strText);
%                 else
%                     strText = sprintf('P%dM%d', jj, mm);
%                     text((x_p1+x_p2)/2, (y1 + y2)/2, strText);
%                 end
%             end
        end        % 20071106
    end
end

aTheta = linspace(0, 2*pi, 100);
aX = fMaxRadius .* cos(aTheta);
aY = fMaxRadius .* sin(aTheta);
plot(aX, aY, '-.');

xlabel('time slot', 'FontSize', 16);
ylabel('Job Id', 'FontSize', 16)
% grid on;
strText = sprintf('Circular Gantt-Chart for Job Shop (job scheduling, Angle- Job, Radius- Time), makespan: %d', jobshop_solution.iMaxEndTime);
title(strText, 'FontSize', 16);