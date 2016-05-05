function [container_jsp_schedule, jobshop_config] = psa_jsp_gen_job_schedule_8(stQuayCraneJobList)
%    Discharging and then Loading Scheduling Generation
%    Discharging Job: QC -> PM -> YC
%    Loading Job:     YC -> PM -> QC
%    so, total machine type is 3 {QC, PM, YC}
%    total number of QC(Quay Crane) is 1
%    total number of YC(Yard Crane) is MaxVirtualYardCrane
%    total number of PM is MaxVirtualPrimeMover
%    total number of jobs: = total number of containers (TotalContainer_Discharge + TotalContainer_Load)
%  Job can be done on specific PM or YC selected by the user, or automatically selected by the  solver
%
% input structure:
%    stContainerDischargeJobSequence, stContainerLoadJobSequence: an array of structure containing following
%    fields
%        fCycleTimeMachineType1      : Operation Time taken for QC
%        Time_PM      : Operation Time taken for Prime Mover
%        Time_YC      : Operation Time taken for YC
%        Time_PM_YC   : Operation Time taken for both PM and YC

%%%%%%% Read input
TotalContainer_Discharge = stQuayCraneJobList.TotalContainer_Discharge;
MaxVirtualPrimeMover = stQuayCraneJobList.MaxVirtualPrimeMover
MaxVirtualYardCrane = stQuayCraneJobList.MaxVirtualYardCrane
stContainerDischargeJobSequence = stQuayCraneJobList.stContainerDischargeJobSequence;
TotalContainer_Load = stQuayCraneJobList.TotalContainer_Load;
stContainerLoadJobSequence = stQuayCraneJobList.stContainerLoadJobSequence;

%%% Protatype of Output
%%% Construct Template Structure of Schedule Output
[container_jsp_schedule, container_jsp_discha_schedule, container_jsp_load_schedule] = fsp_constru_psa_sche_struct(stQuayCraneJobList);
%%%%

% jobshop_config.iTotalMachine = container_jsp_schedule.iTotalMachine;
% jobshop_config.iTotalMachineNum = container_jsp_schedule.iTotalMachineNum
% jobshop_config.stProcessPerJob = container_jsp_schedule.stProcessPerJob;
% jobshop_config.fTimeUnit_Min   = container_jsp_schedule.fTimeUnit_Min; 
% 
% for ii = 1:1:container_jsp_schedule.iTotalJob
%     if ii <= TotalContainer_Discharge
%         container_jsp_schedule.stJobSet(ii).iProcessMachine(1) = 1;
%         container_jsp_schedule.stJobSet(ii).iProcessMachine(2) = 2;
%         container_jsp_schedule.stJobSet(ii).iProcessMachine(3) = 3;
%         jobshop_config.jsp_process_machine(ii).iProcessMachine = container_jsp_schedule.stJobSet(ii).iProcessMachine;
%         jobshop_config.jsp_process_time(ii).iProcessTime(1) = stContainerDischargeJobSequence(ii).fCycleTimeMachineType1;
%         jobshop_config.jsp_process_time(ii).iProcessTime(2) = stContainerDischargeJobSequence(ii).Time_PM;
%         jobshop_config.jsp_process_time(ii).iProcessTime(3) = stContainerDischargeJobSequence(ii).Time_YC;
%         jobshop_config.aJobDueTime(ii) = 0;
%         jobshop_config.aJobWeight(ii) = 1;
%         jobshop_config.iJobType(ii) = 1; % For discharge job, process 1 uses machine type 1, process 3 uses machine type 3, job dependence on machine 1
% 
%     else
%         container_jsp_schedule.stJobSet(ii).iProcessMachine(1) = 3;
%         container_jsp_schedule.stJobSet(ii).iProcessMachine(2) = 2;
%         container_jsp_schedule.stJobSet(ii).iProcessMachine(3) = 1;
%         jobshop_config.jsp_process_machine(ii).iProcessMachine = container_jsp_schedule.stJobSet(ii ).iProcessMachine;
%         jobshop_config.jsp_process_time(ii).iProcessTime(1) = stContainerLoadJobSequence(ii- TotalContainer_Discharge).Time_YC;
%         jobshop_config.jsp_process_time(ii).iProcessTime(2) = stContainerLoadJobSequence(ii- TotalContainer_Discharge).Time_PM;
%         jobshop_config.jsp_process_time(ii).iProcessTime(3) = stContainerLoadJobSequence(ii- TotalContainer_Discharge).fCycleTimeMachineType1;
%         jobshop_config.aJobDueTime(ii) = 0;
%         jobshop_config.aJobWeight(ii) = 1;
%         jobshop_config.iJobType(ii) = 2; % For load job, process 1 uses machine type 3, process 3 uses machine type 1, job dependence on machine 1
% 
%     end
% end

[jobshop_config] = psa_jsp_construct_jsp_config(stQuayCraneJobList);

iCurrentTotalJob = 1;
tPrevTotalTimeSlot = 1;
jobshop_config.iTotalTimeSlot = 0;
while iCurrentTotalJob <= container_jsp_schedule.iTotalJob
    jobshop_config.iTotalJob = iCurrentTotalJob;
    ii = iCurrentTotalJob;

    if iCurrentTotalJob <= TotalContainer_Discharge
        if iCurrentTotalJob == 1
            container_jsp_schedule.stJobSet(ii).iProcessStartTime(1) = 0;
        else
            container_jsp_schedule.stJobSet(ii).iProcessStartTime(1) = container_jsp_schedule.stJobSet(ii-1).iProcessStartTime(1) + stContainerDischargeJobSequence(ii-1).fCycleTimeMachineType1;
        end
        container_jsp_schedule.stJobSet(ii).iProcessEndTime(1) = container_jsp_schedule.stJobSet(ii).iProcessStartTime(1) + stContainerDischargeJobSequence(ii).fCycleTimeMachineType1;
        container_jsp_schedule.stJobSet(ii).iProcessStartTime(2) = container_jsp_schedule.stJobSet(ii).iProcessEndTime(1);
        container_jsp_schedule.stJobSet(ii).iProcessEndTime(2) = container_jsp_schedule.stJobSet(ii).iProcessStartTime(2) + stContainerDischargeJobSequence(ii).Time_PM;
        container_jsp_schedule.stJobSet(ii).iProcessStartTime(3) = container_jsp_schedule.stJobSet(ii).iProcessEndTime(2);
        container_jsp_schedule.stJobSet(ii).iProcessEndTime(3) = container_jsp_schedule.stJobSet(ii).iProcessStartTime(3) + stContainerDischargeJobSequence(ii).Time_YC;
        container_jsp_schedule.stJobSet(ii).fProcessStartTime = container_jsp_schedule.stJobSet(ii).iProcessStartTime;
        container_jsp_schedule.stJobSet(ii).fProcessEndTime = container_jsp_schedule.stJobSet(ii).iProcessEndTime;

        container_jsp_schedule.stJobSet(ii).iProcessMachineId(1) = 1;
        container_jsp_schedule.stJobSet(ii).iProcessMachineId(2) = rem(ii-1, MaxVirtualPrimeMover) + 1;
        container_jsp_schedule.stJobSet(ii).iProcessMachineId(3) = rem(ii-1, MaxVirtualYardCrane) + 1;

    else
        if iCurrentTotalJob == (TotalContainer_Discharge +1)
            if TotalContainer_Discharge >= 1
                container_jsp_schedule.stJobSet(ii).iProcessStartTime(3) = container_jsp_schedule.stJobSet(TotalContainer_Discharge).iProcessEndTime(1);
            else
                container_jsp_schedule.stJobSet(ii).iProcessStartTime(3) = 0;
            end
        else
            container_jsp_schedule.stJobSet(ii).iProcessStartTime(3) = container_jsp_schedule.stJobSet(ii-1).iProcessStartTime(3) + stContainerLoadJobSequence(ii- TotalContainer_Discharge -1).fCycleTimeMachineType1;
        end
        container_jsp_schedule.stJobSet(ii).iProcessEndTime(3) = ...
            container_jsp_schedule.stJobSet(ii).iProcessStartTime(3) + stContainerLoadJobSequence(ii- TotalContainer_Discharge).fCycleTimeMachineType1;
        container_jsp_schedule.stJobSet(ii).iProcessStartTime(1) = ...
            container_jsp_schedule.stJobSet(ii).iProcessStartTime(3) -  stContainerLoadJobSequence(ii- TotalContainer_Discharge).Time_PM_YC;
        container_jsp_schedule.stJobSet(ii).iProcessEndTime(1) = ...
            container_jsp_schedule.stJobSet(ii).iProcessStartTime(1) + stContainerLoadJobSequence(ii- TotalContainer_Discharge).Time_YC;
        container_jsp_schedule.stJobSet(ii).iProcessStartTime(2) = container_jsp_schedule.stJobSet(ii).iProcessEndTime(1);
        container_jsp_schedule.stJobSet(ii).iProcessEndTime(2) = ...
            container_jsp_schedule.stJobSet(ii).iProcessStartTime(2) + stContainerLoadJobSequence(ii- TotalContainer_Discharge).Time_PM;
        container_jsp_schedule.stJobSet(ii).fProcessStartTime = container_jsp_schedule.stJobSet(ii).iProcessStartTime;
        container_jsp_schedule.stJobSet(ii).fProcessEndTime = container_jsp_schedule.stJobSet(ii).iProcessEndTime;
        
        container_jsp_schedule.stJobSet(ii).iProcessMachineId(1) = rem(ii-1, MaxVirtualYardCrane) + 1;
        container_jsp_schedule.stJobSet(ii).iProcessMachineId(2) = rem(ii-1, MaxVirtualPrimeMover) + 1;
        container_jsp_schedule.stJobSet(ii).iProcessMachineId(3) = 1;
        
    end
    
    iFlagExistNegativeTime = 0;
    tNegMinimumStartTime = 0;
    for jjJob = 1:1:iCurrentTotalJob
        if container_jsp_schedule.stJobSet(jjJob).iProcessStartTime(1) < 0
            if iFlagExistNegativeTime == 0
                iFlagExistNegativeTime = 1;
            end
            if container_jsp_schedule.stJobSet(jjJob).iProcessStartTime(1) < tNegMinimumStartTime
                tNegMinimumStartTime = container_jsp_schedule.stJobSet(jjJob).iProcessStartTime(1);
            end
        end
    end
    if iFlagExistNegativeTime == 1
        tPosShiftTime = - tNegMinimumStartTime;
        for jjJob = 1:1:iCurrentTotalJob
            for jj = 1:1:container_jsp_schedule.stProcessPerJob(jjJob)
                container_jsp_schedule.stJobSet(jjJob).iProcessStartTime(jj) = container_jsp_schedule.stJobSet(jjJob).iProcessStartTime(jj) + tPosShiftTime; 
                container_jsp_schedule.stJobSet(jjJob).iProcessEndTime(jj) = container_jsp_schedule.stJobSet(jjJob).iProcessEndTime(jj) + tPosShiftTime;
            end
            container_jsp_schedule.stJobSet(jjJob).fProcessEndTime = container_jsp_schedule.stJobSet(jjJob).iProcessEndTime;
            container_jsp_schedule.stJobSet(jjJob).fProcessStartTime = container_jsp_schedule.stJobSet(jjJob).iProcessStartTime;
        end
        jobshop_config.iTotalTimeSlot = ceil(jobshop_config.iTotalTimeSlot + tPosShiftTime);
    end
    
    jobshop_config.iTotalTimeSlot = max([jobshop_config.iTotalTimeSlot, container_jsp_schedule.stJobSet(iCurrentTotalJob).iProcessEndTime(3)]);
    
    for kk = 1:1:jobshop_config.iTotalMachine
        for tt = tPrevTotalTimeSlot:1:jobshop_config.iTotalTimeSlot
            aMachineCapacity(kk, tt) = jobshop_config.iTotalMachineNum(kk);
        end
    end
    tPrevTotalTimeSlot = jobshop_config.iTotalTimeSlot;
    
    [stMachineConflictInfo, TotalConflictTimePerMachine, astMachineTimeUsage] = ...
        jsp_build_conflit_info_03(jobshop_config, container_jsp_schedule, aMachineCapacity);
    while sum(TotalConflictTimePerMachine) >= 1
        container_jsp_schedule.stJobSet(ii).iProcessStartTime(1) = container_jsp_schedule.stJobSet(ii).iProcessStartTime(1) + 1;
        container_jsp_schedule.stJobSet(ii).iProcessEndTime(1) = container_jsp_schedule.stJobSet(ii).iProcessEndTime(1) + 1;
        container_jsp_schedule.stJobSet(ii).iProcessStartTime(2) = container_jsp_schedule.stJobSet(ii).iProcessStartTime(2) + 1;
        container_jsp_schedule.stJobSet(ii).iProcessEndTime(2) = container_jsp_schedule.stJobSet(ii).iProcessEndTime(2) + 1;
        container_jsp_schedule.stJobSet(ii).iProcessStartTime(3) = container_jsp_schedule.stJobSet(ii).iProcessStartTime(3) + 1;
        container_jsp_schedule.stJobSet(ii).iProcessEndTime(3) = container_jsp_schedule.stJobSet(ii).iProcessEndTime(3) + 1;
        container_jsp_schedule.stJobSet(ii).fProcessStartTime = container_jsp_schedule.stJobSet(ii).iProcessStartTime;
        container_jsp_schedule.stJobSet(ii).fProcessEndTime = container_jsp_schedule.stJobSet(ii).iProcessEndTime;
        jobshop_config.iTotalTimeSlot = jobshop_config.iTotalTimeSlot + 1;
        for kk = 1:1:jobshop_config.iTotalMachine
            for tt = tPrevTotalTimeSlot:1:jobshop_config.iTotalTimeSlot
                aMachineCapacity(kk, tt) = jobshop_config.iTotalMachineNum(kk);
            end
        end
        tPrevTotalTimeSlot = jobshop_config.iTotalTimeSlot;
        [stMachineConflictInfo, TotalConflictTimePerMachine, astMachineTimeUsage] = ...
            jsp_build_conflit_info_03(jobshop_config, container_jsp_schedule, aMachineCapacity);
    end
    
    iCurrentTotalJob = iCurrentTotalJob + 1;
end

container_jsp_schedule.iMaxEndTime = jobshop_config.iTotalTimeSlot;

