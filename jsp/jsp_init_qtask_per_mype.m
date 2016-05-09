function astQuingTaskMachType = jsp_init_qtask_per_mype(stJspCfg, astQuingTask)

for mm = 1:1:stJspCfg.iTotalMachine
    for ii = 1:1:stJspCfg.iTotalMachineNum(mm)
        astQuingTaskMachType(mm).iTotalTask = 0;
        astQuingTaskMachType(mm).iJobSet = [];
    end
end
for ii = 1:1:stJspCfg.iTotalJob
    if astQuingTask(ii).iJobId >= 1 %% Only insert the reasonable job
        mType = astQuingTask(ii).iProcMachType;
        nTotalTaskInQue = astQuingTaskMachType(mType).iTotalTask + 1;
        astQuingTaskMachType(mType).iTotalTask = nTotalTaskInQue;
        astQuingTaskMachType(mType).iJobSet(nTotalTaskInQue) = astQuingTask(ii).iJobId;
    end
end


