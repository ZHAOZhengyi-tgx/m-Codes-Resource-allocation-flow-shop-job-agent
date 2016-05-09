function [iMaxEndTime] = jsp_plot_jobsolution_2(jobshop_solution, figure_id)
% jobshop_solution: a struct with following variables
%    iTotalJob: 
%    stProcessPerJob: 
%    stJobSet: 
% jobshop_solution.stJobSet: an array (length of jobshop_solution.iTotalJob )of struct with following variables
%    iProcessStartTime: an array with length as jobshop_solution.stProcessPerJob
%    iProcessEndTime:   an array with length as jobshop_solution.stProcessPerJob
%    iProcessMachine:   an array with length as jobshop_solution.stProcessPerJob

% 20071106 Add for dumpy process
% 20080428 Add for filling
%
MAX_NUM_PROC_DRAW_TEXT = 100;

nTotalProc = sum(jobshop_solution.stProcessPerJob);
if nTotalProc >= MAX_NUM_PROC_DRAW_TEXT
    iFlagDrawText = 0;
else
    iFlagDrawText = 1;
end

figure(figure_id);
iMaxEndTime = jobshop_solution.iMaxEndTime;
iFlagHoldOnce = 1;
fEpslonTime = 1e-5; % 20071106
nTotalMach = jobshop_solution.iTotalMachine;

axis([-1, double(iMaxEndTime) * 6/5, 0, double(jobshop_solution.iTotalMachine) *6/5])
for ii = 1:1:double(jobshop_solution.iTotalJob)
    for jj = 1:1:double(jobshop_solution.stProcessPerJob(ii))
        x1 = double(jobshop_solution.stJobSet(ii).iProcessStartTime(jj));
        x2 = double(jobshop_solution.stJobSet(ii).iProcessEndTime(jj));
        y1 = ii;
        fWidthY = 0.8;
        y2 = y1 + fWidthY;

        if x2 - x1 > fEpslonTime % 20071106
            h = plot([x1, x2], [y1, y1], [x1, x2], [y2, y2], [x1, x1], [y1, y2], [x2, x2], [y1, y2]);
            v = get(h);

            aColor = [0 0 0];
            rgbStep3 = ceil(nTotalMach /3);
            mm = jobshop_solution.stJobSet(ii).iProcessMachine(jj);
    %        rgbAxis = ceil(jj/rgbStep3);
            rgbAxis = ceil(mm/rgbStep3);
            rgbColorNumber = (rem(mm,rgbStep3)+1)/rgbStep3;
            aColor(rgbAxis) = rgbColorNumber;
            set(h, 'Color', aColor);
            if iFlagHoldOnce == 1
                hold on;
                iFlagHoldOnce = 0;
            end
            
            if iFlagDrawText == 0
                fill([x1, x2, x2, x1], [y1, y1, y2, y2], aColor);
            elseif iFlagDrawText == 1
                if jj <= 1
                    if abs(x2-x1) <= 2
                        strText = sprintf('J%dM%d', ii, mm);
                        text(x1, (y1 + y2)/2, strText);
                        strText = sprintf('P%d', jj);
                        text(x1, y1, strText);
                    else
                        strText = sprintf('J%dM%dP%d', ii, mm, jj);
                        text(x1, (y1 + y2)/2, strText);
                    end
                else
                    if abs(x2-x1) <= 2
                        strText = sprintf('P%d', jj);
                        text((x1+x2)/2, (y1 + y2)/2, strText);
                        strText = sprintf('M%d', mm);
                        text((x1+x2)/2, y1, strText);
                    else
                        strText = sprintf('P%dM%d', jj, mm);
                        text((x1+x2)/2, (y1 + y2)/2, strText);
                    end
                end
            end
        end        % 20071106
    end
end
xlabel('time slot');
ylabel('Job Id')
grid on;
strText = sprintf('Solution Scheduling for the Job Shop(grouping by job), Makespan: %d', jobshop_solution.iMaxEndTime);
title(strText);