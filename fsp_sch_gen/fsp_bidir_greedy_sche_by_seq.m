function [stSolutionJobSet] = fsp_bidir_greedy_sche_by_seq(jobshop_config, iJobSeqInJspCfg)
%
% A greedy algorithm to solve the job-shop problem with multiple machine
% constraints by predefined sequence.
% 20080323 Add iReleaseTimeSlotGlobal

[stJspSchedule] = jsp_constr_sche_struct_by_cfg(jobshop_config);
stSolutionJobSet = stJspSchedule.stJobSet;

for mm = 1:1:jobshop_config.iTotalMachine 
    for kk = 1:1:jobshop_config.iTotalMachineNum(mm)
        stMachineDoingJobSet(mm).aTimeSetPreviousJobCompleted(kk) = jobshop_config.iReleaseTimeSlotGlobal; % 20080323
        stMachineDoingJobSet(mm).iMachineId(kk) = kk;
        stMachineDoingJobSet(mm).aJob_Id(kk) = 0;
    end
end
%iJobSeqInJspCfg
for ii = 1:1:jobshop_config.iTotalJob
    iJobId = iJobSeqInJspCfg(ii);

    %% look for the earliest available machine
    for mm = 1:1:jobshop_config.iTotalMachine
        tEarliestAvailable(mm) = stMachineDoingJobSet(mm).aTimeSetPreviousJobCompleted(1);
        iMachineIdminTime(mm) = stMachineDoingJobSet(mm).iMachineId(1);
        index_min_MachineId(mm) = 1;
        for jj = 2:1:jobshop_config.iTotalMachineNum(mm)
            if tEarliestAvailable(mm) > stMachineDoingJobSet(mm).aTimeSetPreviousJobCompleted(jj)
                tEarliestAvailable(mm) = stMachineDoingJobSet(mm).aTimeSetPreviousJobCompleted(jj);
                iMachineIdminTime(mm) = stMachineDoingJobSet(mm).iMachineId(jj);
                index_min_MachineId(mm) = jj;
            end
        end
    end
    
    %% assign the MachineId
    for jj = 1:1:jobshop_config.stProcessPerJob(iJobId)
        mm = stSolutionJobSet(iJobId).iProcessMachine(jj);
        stSolutionJobSet(iJobId).iProcessMachineId(jj) = index_min_MachineId(mm);
        tEstimateProcessStart(jj) = tEarliestAvailable(mm);
    end
    
    %% estimate process start time, by latest release time
    for jjProc = 1:1:jobshop_config.stProcessPerJob(iJobId)
        tEstimateJobStartByProc(jjProc) = tEstimateProcessStart(jjProc);
        for jjPrevProc = 1:1:jjProc-1  % there is no inter-process wait
            tEstimateJobStartByProc(jjProc) = tEstimateJobStartByProc(jjProc) ...
               - jobshop_config.jsp_process_time(iJobId).iProcessTime(jjPrevProc);
        end
    end

    stSolutionJobSet(iJobId).iProcessStartTime(1) = max(tEstimateJobStartByProc);
    stSolutionJobSet(iJobId).iProcessEndTime(1) = stSolutionJobSet(iJobId).iProcessStartTime(1) ...
        + jobshop_config.jsp_process_time(iJobId).iProcessTime(1);
    
    for jj = 2:1:jobshop_config.stProcessPerJob(iJobId)
        stSolutionJobSet(iJobId).iProcessStartTime(jj) = stSolutionJobSet(iJobId).iProcessEndTime(jj-1);
        stSolutionJobSet(iJobId).iProcessEndTime(jj) = stSolutionJobSet(iJobId).iProcessStartTime(jj) ...
            + jobshop_config.jsp_process_time(iJobId).iProcessTime(jj);
    end

    %% update the stMachineDoingJobSet
    for jj = 1:1:jobshop_config.stProcessPerJob(iJobId)
        mm = stSolutionJobSet(iJobId).iProcessMachine(jj);
        stMachineDoingJobSet(mm).aTimeSetPreviousJobCompleted(stSolutionJobSet(iJobId).iProcessMachineId(jj)) = ...
            stSolutionJobSet(iJobId).iProcessEndTime(jj);
    
    end
    
    stSolutionJobSet(iJobId).fProcessStartTime = stSolutionJobSet(iJobId).iProcessStartTime;
    stSolutionJobSet(iJobId).fProcessEndTime   = stSolutionJobSet(iJobId).iProcessEndTime;
    
end

%size(stSolutionJobSet)
