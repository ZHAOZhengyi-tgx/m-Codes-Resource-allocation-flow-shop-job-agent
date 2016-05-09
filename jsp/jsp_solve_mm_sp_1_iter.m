function [astQuingTaskByJob, astRelTimeMachType, astQuingTaskMachType, stJobSet] = jsp_solve_mm_sp_1_iter(stJspCfg, mm, astQuingTaskByJob, astRelTimeMachType, astQuingTaskMachType, stJobSet)
%
fPlanningTimeWindow = stJspCfg.iTotalTimeSlot;

if stJspCfg.iPlotFlag >=  2
    stQuingTaskMachType = astQuingTaskMachType(mm);
    astQuingTaskByJob
end
astQuingTaskBak = astQuingTaskByJob; % 20080109

if stJspCfg.iOptRule == 1 % jsp_calc_imm_model
    [stJobSet, astQuingTaskByJob, stRelTimeMachType] = ...
        jsp_calc_imm_model(stJspCfg, mm, fPlanningTimeWindow, stJobSet,  ...
        astQuingTaskMachType(mm), astRelTimeMachType(mm), astQuingTaskByJob);
elseif stJspCfg.iOptRule == 2
    [stJobSet, astQuingTaskByJob, stRelTimeMachType] = ...
        jsp_calc_match_min_sum_mkspn(stJspCfg, mm, fPlanningTimeWindow, stJobSet,  ...
        astQuingTaskMachType(mm), astRelTimeMachType(mm), astQuingTaskByJob);

else
    error('wrong iOptRule')
end

astRelTimeMachType(mm) = stRelTimeMachType;

if stJspCfg.iPlotFlag >= 2
    tRelTimeAtOneMach_ = stRelTimeMachType.tRelTimeAtOneMach
    mTypeDisp_sizeQuingTask = [mm, length(astQuingTaskMachType)]
end

%%% update astQuingTaskMachType for this machine
astQuingTaskMachType(mm).iTotalTask = 0;
astQuingTaskMachType(mm).iJobSet = [];

nQuingJobsFromTaskst = 0;
for ii = 1:1:stJspCfg.iTotalJob
    if astQuingTaskByJob(ii).iJobId >= 1 %% Only insert the reasonable job
        nQuingJobsFromTaskst = nQuingJobsFromTaskst + 1;
        mType = astQuingTaskByJob(ii).iProcMachType;
%                    
        if mType == mm ...  %% for the machine type just scheduled
                || mType ~= astQuingTaskBak(ii).iProcMachType %% if this job's prev-task has been done, queing task updated
            nTotalTaskInQue = astQuingTaskMachType(mType).iTotalTask + 1;
            astQuingTaskMachType(mType).iTotalTask = nTotalTaskInQue;
            astQuingTaskMachType(mType).iJobSet(nTotalTaskInQue) = astQuingTaskByJob(ii).iJobId;
        end
    end
end

if stJspCfg.iPlotFlag >= 2
    nQuingJobsFromMach = 0;
    for kk = 1:1:stJspCfg.iTotalMachine
        nQuingJobsFromMach = nQuingJobsFromMach + astQuingTaskMachType(kk).iTotalTask;
        anTotalTaskPerMachine(kk) = astQuingTaskMachType(kk).iTotalTask;
    end
    numJobsQuInTaskSet_numJobsQuInMachSet_TotalTaskPerMach = [nQuingJobsFromMach, anTotalTaskPerMachine]
end
if stJspCfg.iPlotFlag >= 4
    input('any key')
end
