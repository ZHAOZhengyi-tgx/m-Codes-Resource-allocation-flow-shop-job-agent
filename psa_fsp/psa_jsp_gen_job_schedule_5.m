function [container_jsp_discha_schedule, container_jsp_load_schedule, container_jsp_schedule, jobshop_config] = psa_jsp_gen_job_schedule_5(stQuayCraneJobList)
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
%    
% output structure
%    stContainerDischargeJobSequence, stContainerLoadJobSequence: an array of structure containing following as well as the above two fields
%        StartTime    : starting time of i^th job
%        CompleteTime : completion time of i^th job
%        iPM_Id       : iPM_Id, the actual specific PrimeMover in use
%        iYC_Id       : the actual specific YardCrane in use

%%%%%%% Read input
TotalContainer_Discharge = stQuayCraneJobList.TotalContainer_Discharge;
MaxVirtualPrimeMover = stQuayCraneJobList.MaxVirtualPrimeMover;
MaxVirtualYardCrane = stQuayCraneJobList.MaxVirtualYardCrane;
stContainerDischargeJobSequence = stQuayCraneJobList.stContainerDischargeJobSequence;
TotalContainer_Load = stQuayCraneJobList.TotalContainer_Load;
stContainerLoadJobSequence = stQuayCraneJobList.stContainerLoadJobSequence;

%%% Protatype of Output
%%% Protatype of Output
%%% Construct Template Structure of Schedule Output
[container_jsp_schedule, container_jsp_discha_schedule, container_jsp_load_schedule] = fsp_constru_psa_sche_struct(stQuayCraneJobList);

%%%%%%% Generate Discharging Schedule only according to the QC job precedence constraint 
iMaxEndTime = 0;

container_jsp_discha_schedule.iTotalJob = TotalContainer_Discharge;
container_jsp_discha_schedule.iTotalMachine = 3;
container_jsp_discha_schedule.iTotalMachineNum = [1, MaxVirtualPrimeMover, MaxVirtualYardCrane];
container_jsp_discha_schedule.stProcessPerJob = 3 * ones(1,TotalContainer_Discharge);
for ii = 1:1:TotalContainer_Discharge
    if ii == 1
        container_jsp_discha_schedule.stJobSet(ii).iProcessStartTime(1) = 0;
    else
        container_jsp_discha_schedule.stJobSet(ii).iProcessStartTime(1) = container_jsp_discha_schedule.stJobSet(ii-1).iProcessStartTime(1) + stContainerDischargeJobSequence(ii-1).fCycleTimeMachineType1;
    end
    container_jsp_discha_schedule.stJobSet(ii).iProcessEndTime(1) = container_jsp_discha_schedule.stJobSet(ii).iProcessStartTime(1) + stContainerDischargeJobSequence(ii).fCycleTimeMachineType1;
    container_jsp_discha_schedule.stJobSet(ii).iProcessStartTime(2) = container_jsp_discha_schedule.stJobSet(ii).iProcessEndTime(1);
    container_jsp_discha_schedule.stJobSet(ii).iProcessEndTime(2) = container_jsp_discha_schedule.stJobSet(ii).iProcessStartTime(2) + stContainerDischargeJobSequence(ii).Time_PM;
    container_jsp_discha_schedule.stJobSet(ii).iProcessStartTime(3) = container_jsp_discha_schedule.stJobSet(ii).iProcessEndTime(2);
    container_jsp_discha_schedule.stJobSet(ii).iProcessEndTime(3) = container_jsp_discha_schedule.stJobSet(ii).iProcessStartTime(3) + stContainerDischargeJobSequence(ii).Time_YC;
    container_jsp_discha_schedule.stJobSet(ii).iProcessMachine(1) = 1;
    container_jsp_discha_schedule.stJobSet(ii).iProcessMachine(2) = 2;
    container_jsp_discha_schedule.stJobSet(ii).iProcessMachine(3) = 3;
    container_jsp_discha_schedule.stJobSet(ii).iProcessMachineId(1) = 1;
    container_jsp_discha_schedule.stJobSet(ii).iProcessMachineId(2) = rem(ii-1, MaxVirtualPrimeMover) + 1;
    container_jsp_discha_schedule.stJobSet(ii).iProcessMachineId(3) = rem(ii-1, MaxVirtualYardCrane) + 1;
    
    container_jsp_discha_schedule.stJobSet(ii).fProcessStartTime = container_jsp_discha_schedule.stJobSet(ii).iProcessStartTime;
    container_jsp_discha_schedule.stJobSet(ii).fProcessEndTime = container_jsp_discha_schedule.stJobSet(ii).iProcessEndTime;
    if iMaxEndTime < container_jsp_discha_schedule.stJobSet(ii).iProcessEndTime(3)
        iMaxEndTime = container_jsp_discha_schedule.stJobSet(ii).iProcessEndTime(3);
    end
end
container_jsp_discha_schedule.iMaxEndTime = iMaxEndTime;

%%%%%% Loading case
container_jsp_load_schedule.iTotalJob = TotalContainer_Load;
container_jsp_load_schedule.iTotalMachine = 3;
container_jsp_load_schedule.iTotalMachineNum = [1, MaxVirtualPrimeMover, MaxVirtualYardCrane];
container_jsp_load_schedule.stProcessPerJob = 3 * ones(1,TotalContainer_Load);
for ii = 1:1:TotalContainer_Load
    if ii == 1
        if TotalContainer_Discharge > 0
            container_jsp_load_schedule.stJobSet(ii).iProcessStartTime(3) = container_jsp_discha_schedule.stJobSet(TotalContainer_Discharge).iProcessEndTime(1);
        else
            container_jsp_load_schedule.stJobSet(ii).iProcessStartTime(3) = 0;
        end        
    else
        container_jsp_load_schedule.stJobSet(ii).iProcessStartTime(3) = container_jsp_load_schedule.stJobSet(ii-1).iProcessStartTime(3) + stContainerLoadJobSequence(ii-1).fCycleTimeMachineType1;
    end
    container_jsp_load_schedule.stJobSet(ii).iProcessEndTime(3) = ...
        container_jsp_load_schedule.stJobSet(ii).iProcessStartTime(3) + stContainerLoadJobSequence(ii).fCycleTimeMachineType1;
    container_jsp_load_schedule.stJobSet(ii).iProcessStartTime(1) = ...
        container_jsp_load_schedule.stJobSet(ii).iProcessStartTime(3) -  stContainerLoadJobSequence(ii).Time_PM_YC;
    container_jsp_load_schedule.stJobSet(ii).iProcessEndTime(1) = ...
        container_jsp_load_schedule.stJobSet(ii).iProcessStartTime(1) + stContainerLoadJobSequence(ii).Time_YC;
    container_jsp_load_schedule.stJobSet(ii).iProcessStartTime(2) = container_jsp_load_schedule.stJobSet(ii).iProcessEndTime(1);
    container_jsp_load_schedule.stJobSet(ii).iProcessEndTime(2) = ...
        container_jsp_load_schedule.stJobSet(ii).iProcessStartTime(2) + stContainerLoadJobSequence(ii).Time_PM;
    container_jsp_load_schedule.stJobSet(ii).iProcessMachine(1) = 3;
    container_jsp_load_schedule.stJobSet(ii).iProcessMachine(2) = 2;
    container_jsp_load_schedule.stJobSet(ii).iProcessMachine(3) = 1;
    container_jsp_load_schedule.stJobSet(ii).iProcessMachineId(1) = rem(ii-1, MaxVirtualYardCrane) + 1;
    container_jsp_load_schedule.stJobSet(ii).iProcessMachineId(2) = rem(ii-1, MaxVirtualPrimeMover) + 1;
    container_jsp_load_schedule.stJobSet(ii).iProcessMachineId(3) = 1;
    
    container_jsp_load_schedule.stJobSet(ii).fProcessStartTime = container_jsp_load_schedule.stJobSet(ii).iProcessStartTime;
    container_jsp_load_schedule.stJobSet(ii).fProcessEndTime = container_jsp_load_schedule.stJobSet(ii).iProcessEndTime;

    if iMaxEndTime < container_jsp_load_schedule.stJobSet(ii).iProcessEndTime(3)
        iMaxEndTime = container_jsp_load_schedule.stJobSet(ii).iProcessEndTime(3);
    end

end
container_jsp_load_schedule.iMaxEndTime = iMaxEndTime;

container_jsp_schedule.iTotalJob = TotalContainer_Load + TotalContainer_Discharge;
container_jsp_schedule.iTotalMachine = 3;
container_jsp_schedule.iTotalMachineNum = [1, MaxVirtualPrimeMover, MaxVirtualYardCrane];
container_jsp_schedule.stProcessPerJob = 3 * ones(1,TotalContainer_Load + TotalContainer_Discharge);
for ii = 1:1:container_jsp_schedule.iTotalJob
    if ii <= TotalContainer_Discharge
        container_jsp_schedule.stJobSet(ii) = container_jsp_discha_schedule.stJobSet(ii);
    else
        container_jsp_schedule.stJobSet(ii) = container_jsp_load_schedule.stJobSet(ii - TotalContainer_Discharge);
    end
end
container_jsp_schedule.iMaxEndTime = iMaxEndTime;

%%%%%%%%%%%%%% shift for negative starting time
iFlagExistNegativeTime = 0;
tNegMinimumStartTime = 0;
for jjJob = 1:1:container_jsp_schedule.iTotalJob
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
    for jjJob = 1:1:container_jsp_schedule.iTotalJob
        for jj = 1:1:container_jsp_schedule.stProcessPerJob(jjJob)
            container_jsp_schedule.stJobSet(jjJob).iProcessStartTime(jj) = container_jsp_schedule.stJobSet(jjJob).iProcessStartTime(jj) + tPosShiftTime; 
            container_jsp_schedule.stJobSet(jjJob).iProcessEndTime(jj) = container_jsp_schedule.stJobSet(jjJob).iProcessEndTime(jj) + tPosShiftTime;
        end
        container_jsp_schedule.stJobSet(jjJob).fProcessEndTime = container_jsp_schedule.stJobSet(jjJob).iProcessEndTime;
        container_jsp_schedule.stJobSet(jjJob).fProcessStartTime = container_jsp_schedule.stJobSet(jjJob).iProcessStartTime;
    end
    container_jsp_schedule.iMaxEndTime = ceil(container_jsp_schedule.iMaxEndTime + tPosShiftTime);
end

%%%%% This section could be moved out of this routine, just for version
%%%%% compatible
[jobshop_config] = psa_jsp_construct_jsp_config(stQuayCraneJobList);
jobshop_config.iTotalTimeSlot = iMaxEndTime;

