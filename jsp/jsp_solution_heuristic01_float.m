function [jobshop_solution] = jsp_solution_heuristic01_float(jobshop_config)
% [jobshop_solution] = jsp_solution_heuristic02(jobshop_config)
% Classical One-Machine Problem
% a floating process time version of jsp_solution_heuristic01
% INPUT:
% jobshop_config: a struct containing following variables:
%              iTotalJob: Total Number of Jobs
%          iTotalMachine: Total Number of Machines
%         iTotalTimeSlot: Total Time Slot
%            iAlgoOption: Algorithm Option
%              fTimeUnit: Time Unit for each time 1
%        stProcessPerJob: An array with length of iTotalJob, total process for each job
%       jsp_process_time: array of iTotalJob structs, each struct contains two arrays with same length
%                 iProcessTime:  Integer Array 
%                 fProcessTime:  Floating Array
%    jsp_process_machine: array of iTotalJob structs, each struct contains one array
%                 iProcessMachine: integer array
%
% OUTPUT:
% jobshop_solution: a struct with following variables
%    iTotalJob: 
%    stProcessPerJob: 
%    stJobSet: 
% jobshop_solution.stJobSet: an array (length of jobshop_solution.iTotalJob )of struct with following variables
%    iProcessStartTime: an array with length as jobshop_solution.stProcessPerJob
%    iProcessEndTime:   an array with length as jobshop_solution.stProcessPerJob
%    iProcessMachine:   an array with length as jobshop_solution.stProcessPerJob


%% Initialize the SchedulableOperationSet
iCheckSumSchedulableOperation = 0;
for ii = 1:1:jobshop_config.iTotalJob
    stSchedulableOperation(ii).iJobId = ii;
    if jobshop_config.stProcessPerJob(ii) >= 1
        stSchedulableOperation(ii).iProcessToStart = 1;
    end
    stSchedulableOperation(ii).ProcessTime = jobshop_config.jsp_process_time(ii).fProcessTime(1);
    stSchedulableOperation(ii).iProcessMachine = jobshop_config.jsp_process_machine(ii).iProcessMachine(1);
    iCheckSumSchedulableOperation = iCheckSumSchedulableOperation + stSchedulableOperation(ii).iJobId;
end
%% Initialize the Current Time Slot for Job on each machine
for ii = 1:1:jobshop_config.iTotalMachine
    iNextTimeSlotPerMachine(ii) = 0;
end
%% Initialize the jobshop_solution
jobshop_solution.iTotalJob = jobshop_config.iTotalJob;
jobshop_solution.stProcessPerJob = jobshop_config.stProcessPerJob;
jobshop_solution.iTotalMachine = jobshop_config.iTotalMachine;

while  iCheckSumSchedulableOperation > 0
    for ii = 1:1:jobshop_config.iTotalMachine
        stMachineUsageSO(ii).iTotalJob = 0;
        stMachineUsageSO(ii).iJobSet = [];
    end
    for ii = 1:1:jobshop_config.iTotalJob
        if stSchedulableOperation(ii).iJobId >= 1 %% Only insert the reasonable job
            stMachineUsageSO(stSchedulableOperation(ii).iProcessMachine).iTotalJob = stMachineUsageSO(stSchedulableOperation(ii).iProcessMachine).iTotalJob + 1;
            stMachineUsageSO(stSchedulableOperation(ii).iProcessMachine).iJobSet = [stMachineUsageSO(stSchedulableOperation(ii).iProcessMachine).iJobSet, stSchedulableOperation(ii).iJobId];
        end
    end
    
    %%% for all the machines
    for ii = 1:1:jobshop_config.iTotalMachine
        if stMachineUsageSO(ii).iTotalJob == 1
            %%% Only one job bidding for the machine, 
            %%%     assign the machine to that job directly, 
            iJobToStart = stMachineUsageSO(ii).iJobSet(1);
            iProcessToStart = stSchedulableOperation(iJobToStart).iProcessToStart;
            if iProcessToStart >= 2
                jobshop_solution.stJobSet(iJobToStart).iProcessStartTime(iProcessToStart) = max(jobshop_solution.stJobSet(iJobToStart).iProcessEndTime(iProcessToStart-1), iNextTimeSlotPerMachine(ii));
            else
                jobshop_solution.stJobSet(iJobToStart).iProcessStartTime(iProcessToStart) = iNextTimeSlotPerMachine(ii);
            end
            jobshop_solution.stJobSet(iJobToStart).iProcessEndTime(iProcessToStart) = jobshop_solution.stJobSet(iJobToStart).iProcessStartTime(iProcessToStart) + ...
                    jobshop_config.jsp_process_time(iJobToStart).fProcessTime(iProcessToStart);
            jobshop_solution.stJobSet(iJobToStart).iProcessMachine(iProcessToStart) = ii;
            %%%     update the iNextTimeSlotPerMachine
            iNextTimeSlotPerMachine(ii) = jobshop_solution.stJobSet(iJobToStart).iProcessStartTime(iProcessToStart) + stSchedulableOperation(iJobToStart).ProcessTime;
            %%%     update the Schedulable Operation Set: stSchedulableOperation
            if(iProcessToStart < jobshop_config.stProcessPerJob(iJobToStart))
                stSchedulableOperation(iJobToStart).iJobId = iJobToStart;
                stSchedulableOperation(iJobToStart).iProcessToStart = iProcessToStart + 1;
                stSchedulableOperation(iJobToStart).ProcessTime = jobshop_config.jsp_process_time(iJobToStart).fProcessTime(iProcessToStart + 1);
                stSchedulableOperation(iJobToStart).iProcessMachine = jobshop_config.jsp_process_machine(iJobToStart).iProcessMachine(iProcessToStart + 1);
            else
                stSchedulableOperation(iJobToStart).iJobId = 0;  %% This job has completed all its processes
                stSchedulableOperation(iJobToStart).iProcessToStart = 0;
                stSchedulableOperation(iJobToStart).ProcessTime = 0;
                stSchedulableOperation(iJobToStart).iProcessMachine = 0;
            end 
        elseif stMachineUsageSO(ii).iTotalJob >= 2
            %%% more than one job bidding for the machine
            %%%          find the job with the minimum process time
            iJobIdWithMinimumProcessTime = stMachineUsageSO(ii).iJobSet(1);
            MinimumProcessTime = stSchedulableOperation(iJobIdWithMinimumProcessTime).ProcessTime;
            for jj = 2:1:stMachineUsageSO(ii).iTotalJob
                if MinimumProcessTime > stSchedulableOperation(stMachineUsageSO(ii).iJobSet(jj)).ProcessTime
                    iJobIdWithMinimumProcessTime = stMachineUsageSO(ii).iJobSet(jj);
                    MinimumProcessTime = stSchedulableOperation(iJobIdWithMinimumProcessTime).ProcessTime;
                end
            end
            %%%          
            %%%     assign the machine to the job with minimum process time, 
            iProcessToStart = stSchedulableOperation(iJobIdWithMinimumProcessTime).iProcessToStart;
            if iProcessToStart >= 2
                jobshop_solution.stJobSet(iJobIdWithMinimumProcessTime).iProcessStartTime(iProcessToStart) = max(jobshop_solution.stJobSet(iJobIdWithMinimumProcessTime).iProcessEndTime(iProcessToStart-1), iNextTimeSlotPerMachine(ii));
            else
                jobshop_solution.stJobSet(iJobIdWithMinimumProcessTime).iProcessStartTime(iProcessToStart) = iNextTimeSlotPerMachine(ii);
            end
            jobshop_solution.stJobSet(iJobIdWithMinimumProcessTime).iProcessEndTime(iProcessToStart) = jobshop_solution.stJobSet(iJobIdWithMinimumProcessTime).iProcessStartTime(iProcessToStart) + ...
                jobshop_config.jsp_process_time(iJobIdWithMinimumProcessTime).fProcessTime(iProcessToStart);
            jobshop_solution.stJobSet(iJobIdWithMinimumProcessTime).iProcessMachine(iProcessToStart) = ii;
            %%%     update the iNextTimeSlotPerMachine
            iNextTimeSlotPerMachine(ii) = jobshop_solution.stJobSet(iJobIdWithMinimumProcessTime).iProcessEndTime(iProcessToStart);
            %%%     update the Schedulable Operation Set: stSchedulableOperation
            if(iProcessToStart < jobshop_config.stProcessPerJob(iJobIdWithMinimumProcessTime))
                stSchedulableOperation(iJobIdWithMinimumProcessTime).iJobId = iJobIdWithMinimumProcessTime;
                stSchedulableOperation(iJobIdWithMinimumProcessTime).iProcessToStart = iProcessToStart + 1;
                stSchedulableOperation(iJobIdWithMinimumProcessTime).ProcessTime = jobshop_config.jsp_process_time(iJobIdWithMinimumProcessTime).fProcessTime(iProcessToStart + 1);
                stSchedulableOperation(iJobIdWithMinimumProcessTime).iProcessMachine = jobshop_config.jsp_process_machine(iJobIdWithMinimumProcessTime).iProcessMachine(iProcessToStart + 1);
            else
                stSchedulableOperation(iJobIdWithMinimumProcessTime).iJobId = 0;  %% This job has completed all its processes
                stSchedulableOperation(iJobIdWithMinimumProcessTime).iProcessToStart = 0;
                stSchedulableOperation(iJobIdWithMinimumProcessTime).ProcessTime = 0;
                stSchedulableOperation(iJobIdWithMinimumProcessTime).iProcessMachine = 0;
            end 

        else
            %%% zero job bidding the machine
            %strText = sprintf('No job is going to use machine %d', ii);
            %disp(strText);
        end
    end
    
    iCheckSumSchedulableOperation = 0;
    for ii = 1:1:jobshop_config.iTotalJob
        iCheckSumSchedulableOperation = iCheckSumSchedulableOperation + stSchedulableOperation(ii).iJobId;
    end

end

for ii = 1:1:jobshop_solution.iTotalJob
    jobshop_solution.stJobSet(ii).fProcessStartTime = jobshop_solution.stJobSet(ii).iProcessStartTime;
    jobshop_solution.stJobSet(ii).iProcessStartTime = ceil(jobshop_solution.stJobSet(ii).fProcessStartTime);
    
    jobshop_solution.stJobSet(ii).fProcessEndTime = jobshop_solution.stJobSet(ii).iProcessEndTime;
    jobshop_solution.stJobSet(ii).iProcessEndTime = ceil(jobshop_solution.stJobSet(ii).fProcessEndTime);
end

fMaxEndTime = jobshop_solution.stJobSet(1).fProcessEndTime(jobshop_solution(1).stProcessPerJob(1));
for ii = 2:1:jobshop_solution.iTotalJob
    if fMaxEndTime < jobshop_solution.stJobSet(ii).fProcessEndTime(jobshop_solution.stProcessPerJob(ii))
        fMaxEndTime = jobshop_solution.stJobSet(ii).fProcessEndTime(jobshop_solution.stProcessPerJob(ii));
    end
end
jobshop_solution.MaxEndTime = fMaxEndTime;
jobshop_solution.iMaxEndTime = ceil(fMaxEndTime);