function [astMachineUsageTimeInfo] = jsp_build_machine_usage_con_tm(jsp_solution)
% jsp_build_machine_usage_con_tm(jsp_solution)
%
%
% History
% YYYYMMDD Notes
% 20071109 Add global parameter definition
% 20080122 Debug for special case
iPlotFlag = 0;
global epsilon; % 20071109
%if ~exist('epsilon') % 20080122
    jsp_glb_define(); 
%end

for mm = 1:1:jsp_solution.iTotalMachine
    astMachineUsageTimeInfo(mm).iTotalProcess = 0;
end

for ii = 1:1:jsp_solution.iTotalJob
    for jj = 1:1:jsp_solution.stProcessPerJob(ii)
        mm = jsp_solution.stJobSet(ii).iProcessMachine(jj);
        astMachineUsageTimeInfo(mm).iTotalProcess = astMachineUsageTimeInfo(mm).iTotalProcess + 1;
        astMachineUsageTimeInfo(mm).aTimeArray(2 * astMachineUsageTimeInfo(mm).iTotalProcess - 1) = jsp_solution.stJobSet(ii).fProcessStartTime(jj)+epsilon;
        astMachineUsageTimeInfo(mm).aTimeArray(2 * astMachineUsageTimeInfo(mm).iTotalProcess) = jsp_solution.stJobSet(ii).fProcessEndTime(jj)-epsilon;
        astMachineUsageTimeInfo(mm).aDeltaStartEnd(2 * astMachineUsageTimeInfo(mm).iTotalProcess - 1) = 1;
        astMachineUsageTimeInfo(mm).aDeltaStartEnd(2 * astMachineUsageTimeInfo(mm).iTotalProcess) = -1;
        astMachineUsageTimeInfo(mm).aJobArray(2 * astMachineUsageTimeInfo(mm).iTotalProcess - 1) = ii;
        astMachineUsageTimeInfo(mm).aJobArray(2 * astMachineUsageTimeInfo(mm).iTotalProcess) = ii;
        astMachineUsageTimeInfo(mm).aProcessArray(2 * astMachineUsageTimeInfo(mm).iTotalProcess - 1) = jj;
        astMachineUsageTimeInfo(mm).aProcessArray(2 * astMachineUsageTimeInfo(mm).iTotalProcess) = jj;
    end
end

for mm = 1:1:jsp_solution.iTotalMachine
    [aSortedTime, aSortedIndex] = sort(astMachineUsageTimeInfo(mm).aTimeArray);
    astMachineUsageTimeInfo(mm).aSortedTime = aSortedTime;
    astMachineUsageTimeInfo(mm).aSortedDelta = astMachineUsageTimeInfo(mm).aDeltaStartEnd(aSortedIndex);
    astMachineUsageTimeInfo(mm).aSortedJob = astMachineUsageTimeInfo(mm).aJobArray(aSortedIndex);
    astMachineUsageTimeInfo(mm).aSortedProcess = astMachineUsageTimeInfo(mm).aProcessArray(aSortedIndex);
end

for mm = 1:1:jsp_solution.iTotalMachine
    sumMachineUsage = 0;
    for jj = 1:1:astMachineUsageTimeInfo(mm).iTotalProcess * 2
        sumMachineUsage = sumMachineUsage + astMachineUsageTimeInfo(mm).aSortedDelta(jj);
        astMachineUsageTimeInfo(mm).aMachineUsageAfterTime(jj) = sumMachineUsage;
        if jj == 1
            astMachineUsageTimeInfo(mm).aMachineUsageBeforeTime(jj) = 0;
        else
            astMachineUsageTimeInfo(mm).aMachineUsageBeforeTime(jj) = astMachineUsageTimeInfo(mm).aMachineUsageAfterTime(jj-1);
        end
    end
end

for mm = 1:1:jsp_solution.iTotalMachine
    astMachineUsageTimeInfo(mm).iMaxUsage = max(astMachineUsageTimeInfo(mm).aMachineUsageAfterTime);
end

if iPlotFlag >=3
    figure;    
    for mm = 1:1:jsp_solution.iTotalMachine
        subplot(jsp_solution.iTotalMachine, 1, mm);
        hold off;
        if astMachineUsageTimeInfo(mm).iTotalProcess > 0
            axis([-1, jsp_solution.iMaxEndTime+1, -1, astMachineUsageTimeInfo(mm).iMaxUsage+1]);
            for jj = 1:1:astMachineUsageTimeInfo(mm).iTotalProcess * 2
                if jj == 1
                    hold on;
                    tt_1 = astMachineUsageTimeInfo(mm).aSortedTime(jj);
                    usage_1 = 0;
                    usage_2 = astMachineUsageTimeInfo(mm).aMachineUsageAfterTime(jj);
                    plot([tt_1, tt_1], [usage_1, usage_2]);

                else
                    tt_1 = astMachineUsageTimeInfo(mm).aSortedTime(jj-1);
                    tt_2 = astMachineUsageTimeInfo(mm).aSortedTime(jj);
                    usage_1 = astMachineUsageTimeInfo(mm).aMachineUsageAfterTime(jj-1);
                    usage_2 = astMachineUsageTimeInfo(mm).aMachineUsageAfterTime(jj);
                    plot([tt_1, tt_2], [usage_1, usage_1]);
                    plot([tt_2, tt_2], [usage_1, usage_2]);

                end
            end
        end
    end
end

