function astQuingTask = jsp_update_quing_task(iJobId, iTaskIdCompleteSchedule, stJspCfg, astQuingTask)

if iTaskIdCompleteSchedule >= stJspCfg.stProcessPerJob(iJobId)
    astQuingTask(iJobId).iJobId = 0;
    astQuingTask(iJobId).iProcessToStart = 0;
    astQuingTask(iJobId).ProcessTime = 0;
    astQuingTask(iJobId).iProcMachType = 0;
else
    iNextTask = iTaskIdCompleteSchedule + 1;
    astQuingTask(iJobId).iProcessToStart = iNextTask;
    astQuingTask(iJobId).ProcessTime = stJspCfg.jsp_process_time(iJobId).fProcessTime(iNextTask);
    astQuingTask(iJobId).iProcMachType = stJspCfg.jsp_process_machine(iJobId).iProcessMachine(iNextTask);
end
