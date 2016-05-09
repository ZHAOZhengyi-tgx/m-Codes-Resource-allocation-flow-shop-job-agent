function [stMachUtilizationInfo] = jsp_get_machine_utilization(stJspSchedule, astMachineUsageTimeInfo)
%
% iMaxUtilization
% iMeanUtilization
% fMaxPerCentUtili
% fMeanPerCentUtili

for mm = 1:1:stJspSchedule.iTotalMachine
    if astMachineUsageTimeInfo(mm).iTotalProcess <= 0
        astUtilizeAtMach(mm).iMaxUtilization   = 0;
        astUtilizeAtMach(mm).fMeanUtilization  = 0;
        astUtilizeAtMach(mm).fMaxPerCentUtili  = 0;
        astUtilizeAtMach(mm).fMeanPerCentUtili = 0;
    else
        astUtilizeAtMach(mm).iMaxUtilization   = astMachineUsageTimeInfo(mm).iMaxUsage;
        astUtilizeAtMach(mm).fMaxPerCentUtili  = astMachineUsageTimeInfo(mm).iMaxUsage/stJspSchedule.iTotalMachineNum(mm);
        fUsageTimeSum = 0;
        idxEndPoint = astMachineUsageTimeInfo(mm).iTotalProcess * 2;
        for jj = 1:1:idxEndPoint
            if jj == 1
                tt_1 = astMachineUsageTimeInfo(mm).aSortedTime(jj);
                usage_1 = 0;
                usage_2 = astMachineUsageTimeInfo(mm).aMachineUsageAfterTime(jj);
%                plot([tt_1, tt_1], [usage_1, usage_2]);

            else
                tt_1 = astMachineUsageTimeInfo(mm).aSortedTime(jj-1);
                tt_2 = astMachineUsageTimeInfo(mm).aSortedTime(jj);
                usage_1 = astMachineUsageTimeInfo(mm).aMachineUsageAfterTime(jj-1);
                usage_2 = astMachineUsageTimeInfo(mm).aMachineUsageAfterTime(jj);
                fUsageTimeSum = fUsageTimeSum + usage_1 * (tt_2 - tt_1);
%                 plot([tt_1, tt_2], [usage_1, usage_1]);
%                 plot([tt_2, tt_2], [usage_1, usage_2]);
            end
        end
        fPlanningTimeDuration = astMachineUsageTimeInfo(mm).aSortedTime(idxEndPoint) - astMachineUsageTimeInfo(mm).aSortedTime(1);
        astUtilizeAtMach(mm).fMeanUtilization  = fUsageTimeSum /fPlanningTimeDuration;
        astUtilizeAtMach(mm).fMeanPerCentUtili = astUtilizeAtMach(mm).fMeanUtilization/stJspSchedule.iTotalMachineNum(mm);
        
    end
    aiMaxUtilize(mm) = astUtilizeAtMach(mm).iMaxUtilization;
    afMeanUtilize(mm) = astUtilizeAtMach(mm).fMeanUtilization;
    afMaxPercentUtili(mm) = astUtilizeAtMach(mm).fMaxPerCentUtili;
    afMeanPercentUtili(mm)= astUtilizeAtMach(mm).fMeanPerCentUtili;
    
end
% Overall Mean Utilization in percent
stMachUtilizationInfo.fMeanUtilizAllMachPercent = sum(afMeanUtilize) / sum(stJspSchedule.iTotalMachineNum);
stMachUtilizationInfo.fMaxUtilizAllMachPercent = max(afMaxPercentUtili);

stMachUtilizationInfo.aiMaxUtilize       = aiMaxUtilize;
stMachUtilizationInfo.afMeanUtilize      = afMeanUtilize;
stMachUtilizationInfo.afMaxPercentUtili  = afMaxPercentUtili;
stMachUtilizationInfo.afMeanPercentUtili = afMeanPercentUtili;
stMachUtilizationInfo.astUtilizeAtMach = astUtilizeAtMach;