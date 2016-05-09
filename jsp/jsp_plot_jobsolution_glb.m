function [] = jsp_plot_jobsolution_glb(stGlobalJobInfo, astAgent_Solution, figure_id)
% plot the job scheduling, 
%    (1) group by machine (in Y-axis), 
%    (2) job grouping by colour,
% jobshop_solution: a struct with following variables
%    iTotalJob:  Total number of jobs
%    iTotalMachine:    total number of machine types
%    iTotalMachineNum: total number of machines in each type, an array with length of iTotalMachine
%    stProcessPerJob:  total number of processes per each job
%    stJobSet: 
% jobshop_solution.stJobSet: an array (length of jobshop_solution.iTotalJob )of struct with following variables
%    iProcessStartTime: start time for the process of the job, an array with length as jobshop_solution.stProcessPerJob
%    iProcessEndTime:   end time for the process of the job, an array with length as jobshop_solution.stProcessPerJob
%    iProcessMachine:   MachineType for the process of the job, an array with length as jobshop_solution.stProcessPerJob
%    iProcessMachineId: MachineId for the process of the job, an array with length as jobshop_solution.stProcessPerJob
%    fProcessStartTime: floating point start time for the process of the job, an array with length as jobshop_solution.stProcessPerJob
%    fProcessEndTime:   floating point end time for the process of the job, an array with length as jobshop_solution.stProcessPerJob
%
% History( ToDo for future)
% YYYYMMDD Notes
% 20070725 Consider the case when process time is too small
% 20071025 Consider different start time, pallete design
% 20080327 Differentiate MIP and others
for qq = 1:1: stGlobalJobInfo.iTotalAgent
    astJspSolution(qq) = astAgent_Solution(qq).stSchedule_MinCost;
    tStartTime_datenum(qq) = datenum(stGlobalJobInfo.stAgentJobInfo(qq).atClockAgentJobStart.aClockYearMonthDateHourMinSec); % + epsilon_time;
end
tEarliestStartTime_datenum = min(tStartTime_datenum); % 20071025

if stGlobalJobInfo.iAlgoChoice == 22 || ...
        stGlobalJobInfo.iAlgoChoice == 25  || ...
        stGlobalJobInfo.iAlgoChoice == 17  % % 20080327
    iStartTimeSlot = zeros(1, stGlobalJobInfo.iTotalAgent);
else
    for qq = 1:1: stGlobalJobInfo.iTotalAgent
        fTimeSlot_inMin = astAgent_Solution(qq).stSchedule_MinCost.fTimeUnit_Min;
        iStartTimeSlot(qq) = ceil((tStartTime_datenum(qq) - tEarliestStartTime_datenum) * 24 * 60 /fTimeSlot_inMin);
    end
end

aColor = [0 0 0];
for qq = 1:1:stGlobalJobInfo.iTotalAgent
    rgbStep3 = 3;
    rgbAxis = mod(qq, rgbStep3) + 1;
    rgbColorNumber = rem(qq *  floor(127/stGlobalJobInfo.iTotalAgent), 127) /127;
    aColor(rgbAxis) = rgbColorNumber;
    stAxisPallete(qq).aColor = aColor;
    Axis_color = [qq, stAxisPallete(qq).aColor];
end
if stGlobalJobInfo.iTotalAgent == 4
    stAxisPallete(1).aColor = [1 0 0];
    stAxisPallete(2).aColor = [0 1 0];
    stAxisPallete(3).aColor = [0 0 1];
    stAxisPallete(4).aColor = [0 0 0];
end
% 20071025

for mm = 1:1:stGlobalJobInfo.stResourceConfig.iTotalMachine
    nMaxTotalMachineNum(mm) = max(stGlobalJobInfo.stResourceConfig.stMachineConfig(mm).afMaCapAtTimePoint);
end

figure(figure_id);
%% ToDo
iMaxEndTime = astJspSolution(qq).iMaxEndTime;
iFlagHoldOnce = 1;

for qq = 1:1: stGlobalJobInfo.iTotalAgent  % 20080327
    qTotalProcAtAgent(qq) = sum(astJspSolution(qq).stProcessPerJob);
end
nTotalProcAllAgent = sum(qTotalProcAtAgent);  % 20080327

axis([-1, double(iMaxEndTime) * 6/5, 0, double(astJspSolution(qq).iTotalMachine) *2])
grid on;
for qq = 1:1: stGlobalJobInfo.iTotalAgent
    for ii = 1:1:double(astJspSolution(qq).iTotalJob)
        for jj = 1:1:double(astJspSolution(qq).stProcessPerJob(ii))
            % 20071025
            if stGlobalJobInfo.iAlgoChoice == 22 || ...
                    stGlobalJobInfo.iAlgoChoice == 25 || ...
                    stGlobalJobInfo.iAlgoChoice == 17  % donot add start-time, for IP and LPR already considered start time
                x1 = double(astJspSolution(qq).stJobSet(ii).iProcessStartTime(jj));
                x2 = double(astJspSolution(qq).stJobSet(ii).iProcessEndTime(jj));
            else
                x1 = double(astJspSolution(qq).stJobSet(ii).iProcessStartTime(jj) + iStartTimeSlot(qq));
                x2 = double(astJspSolution(qq).stJobSet(ii).iProcessEndTime(jj) + iStartTimeSlot(qq));
            end % 20071025
            iMachineType = astJspSolution(qq).stJobSet(ii).iProcessMachine(jj);
            iTotalMachineNum = nMaxTotalMachineNum(iMachineType);
            fMachineWidth = 1/(iTotalMachineNum + 1);
            fDeltaWidth = fMachineWidth/(iTotalMachineNum + 1);
            y1 = double(astJspSolution(qq).stJobSet(ii).iProcessMachine(jj) + (astJspSolution(qq).stJobSet(ii).iProcessMachineId(jj) - 1)*fMachineWidth) ...
                + (astJspSolution(qq).stJobSet(ii).iProcessMachineId(jj) - 1)*fDeltaWidth;
            y2 = y1 + fMachineWidth;


            h = plot([x1, x2], [y1, y1], [x1, x2], [y2, y2], [x1, x1], [y1, y2], [x2, x2], [y1, y2]);
            v = get(h);
%             aColor = [0 0 0];
%             rgbStep3 = 3;
%             rgbAxis = mod(qq, rgbStep3) + 1;
%             rgbColorNumber = rem(qq *  floor(127/stGlobalJobInfo.iTotalAgent), 127) /127;
%             aColor(rgbAxis) = rgbColorNumber;
            set(h, 'Color', stAxisPallete(qq).aColor);
            if iFlagHoldOnce == 1
                hold on;
                iFlagHoldOnce = 0;
            end
            % if processing time is too small %20070725
            if nTotalProcAllAgent <= 100  % 20080327
                if abs(x2 - x1) <= 1.5
                    text(x1, y1+ (y2-y1) * 0.5, 'J');
                    strText = sprintf('%d', ii);
                    text(x1, y1 +(y2-y1) * 0.1, strText);
                else
                    strText = sprintf('A%d-J%d', qq, ii);
                    text(x1, (y1 + y2)/2, strText);
                end
            end
        end
    end
end


xlabel('time slot');
ylabel('Integer-MachineType; Fraction-MachineId')
title('Global Machine Dispatching');
hold off;