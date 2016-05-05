function [container_jsp_schedule, jobshop_config] = psa_jsp_gen_job_schedule_28(stQuayCraneJobList)
%    Discharging and then Loading Scheduling Generation
%    Discharging Job: QC -> PM -> YC, Machine-1, Machine-2, Machine-3
%    Loading Job:     YC -> PM -> QC, Machine-3, Machine-2, Machine-1
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
% History
% YYYYMMDD  Notes
% 20080323  iReleaseTimeSlotGlobal

%%%%%%% Read input
TotalContainer_Discharge = stQuayCraneJobList.TotalContainer_Discharge;
MaxVirtualPrimeMover = stQuayCraneJobList.MaxVirtualPrimeMover;
MaxVirtualYardCrane = stQuayCraneJobList.MaxVirtualYardCrane;
stContainerDischargeJobSequence = stQuayCraneJobList.stContainerDischargeJobSequence;
TotalContainer_Load = stQuayCraneJobList.TotalContainer_Load;
stContainerLoadJobSequence = stQuayCraneJobList.stContainerLoadJobSequence;

if isfield(stQuayCraneJobList, 'iReleaseTimeSlotGlobal')
    tStartTime = stQuayCraneJobList.iReleaseTimeSlotGlobal;
else
    tStartTime = 0;
end
%%% Protatype of Output
%%% Protatype of Output
%%% Construct Template Structure of Schedule Output
[container_jsp_schedule, container_jsp_discha_schedule, container_jsp_load_schedule] = fsp_constru_psa_sche_struct(stQuayCraneJobList);
%%%%

tPrevTotalTimeSlot = 0;
iTotalJob = TotalContainer_Load + TotalContainer_Discharge;
container_jsp_schedule.iTotalMachine = 3;
container_jsp_schedule.iTotalMachineNum = [1, MaxVirtualPrimeMover, MaxVirtualYardCrane];
container_jsp_schedule.stProcessPerJob = 3 * ones(1,TotalContainer_Load + TotalContainer_Discharge);

[jobshop_config] = psa_jsp_construct_jsp_config(stQuayCraneJobList);

iCurrentTotalJob = 1;
tPrevTotalTimeSlot = 1;
jobshop_config.iTotalTimeSlot = 0;
while iCurrentTotalJob <= iTotalJob
    jobshop_config.iTotalJob = iCurrentTotalJob;
    container_jsp_schedule.iTotalJob = iCurrentTotalJob;
    ii = iCurrentTotalJob;

    if iCurrentTotalJob <= TotalContainer_Discharge
        if iCurrentTotalJob == 1
            container_jsp_schedule.stJobSet(ii).iProcessStartTime(1) = tStartTime;
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
                container_jsp_schedule.stJobSet(ii).iProcessStartTime(3) = tStartTime;
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
        container_save_schedule = container_jsp_schedule;
        for jjJob = 1:1:iCurrentTotalJob
            for jj = 1:1:container_jsp_schedule.stProcessPerJob(jjJob)
                container_jsp_schedule.stJobSet(jjJob).iProcessStartTime(jj) = container_jsp_schedule.stJobSet(jjJob).iProcessStartTime(jj) + tPosShiftTime; 
                container_jsp_schedule.stJobSet(jjJob).iProcessEndTime(jj) = container_jsp_schedule.stJobSet(jjJob).iProcessEndTime(jj) + tPosShiftTime;
            end
            container_jsp_schedule.stJobSet(jjJob).fProcessEndTime = container_jsp_schedule.stJobSet(jjJob).iProcessEndTime;
            container_jsp_schedule.stJobSet(jjJob).fProcessStartTime = container_jsp_schedule.stJobSet(jjJob).iProcessStartTime;
        end
        jobshop_config.iTotalTimeSlot = ceil(jobshop_config.iTotalTimeSlot + tPosShiftTime);
        
        container_jsp_schedule.iTotalJob = iCurrentTotalJob - 1;
        [TotalConflictTimePerMachine, astMachineUsageTimeInfo] = ...
            jsp_calc_cnflt_disce_tm01(container_jsp_schedule, stQuayCraneJobList.stResourceConfig, ...
            jobshop_config.iTotalTimeSlot);
        if sum(TotalConflictTimePerMachine) >= 1
            %%% restore previous schedule
            container_jsp_schedule = container_save_schedule;
            %%% reschedule for the last job
            container_jsp_schedule.stJobSet(iCurrentTotalJob).iProcessStartTime(1) = 0;
            container_jsp_schedule.stJobSet(iCurrentTotalJob).iProcessEndTime(1) = ...
                container_jsp_schedule.stJobSet(iCurrentTotalJob).iProcessStartTime(1) + stContainerLoadJobSequence(iCurrentTotalJob- TotalContainer_Discharge).Time_YC;
            container_jsp_schedule.stJobSet(iCurrentTotalJob).iProcessStartTime(2) = container_jsp_schedule.stJobSet(iCurrentTotalJob).iProcessEndTime(1);
            container_jsp_schedule.stJobSet(iCurrentTotalJob).iProcessEndTime(2) = ...
                container_jsp_schedule.stJobSet(iCurrentTotalJob).iProcessStartTime(2) + stContainerLoadJobSequence(iCurrentTotalJob- TotalContainer_Discharge).Time_PM;
            container_jsp_schedule.stJobSet(iCurrentTotalJob).iProcessStartTime(3) =  container_jsp_schedule.stJobSet(iCurrentTotalJob).iProcessEndTime(2);
            container_jsp_schedule.stJobSet(iCurrentTotalJob).iProcessEndTime(3) = ...
                container_jsp_schedule.stJobSet(iCurrentTotalJob).iProcessStartTime(3) + stContainerLoadJobSequence(iCurrentTotalJob- TotalContainer_Discharge).fCycleTimeMachineType1;
            container_jsp_schedule.stJobSet(iCurrentTotalJob).fProcessStartTime = container_jsp_schedule.stJobSet(iCurrentTotalJob).iProcessStartTime;
            container_jsp_schedule.stJobSet(iCurrentTotalJob).fProcessEndTime = container_jsp_schedule.stJobSet(iCurrentTotalJob).iProcessEndTime;

            container_jsp_schedule.stJobSet(iCurrentTotalJob).iProcessMachineId(1) = rem(iCurrentTotalJob-1, MaxVirtualYardCrane) + 1;
            container_jsp_schedule.stJobSet(iCurrentTotalJob).iProcessMachineId(2) = rem(iCurrentTotalJob-1, MaxVirtualPrimeMover) + 1;
            container_jsp_schedule.stJobSet(iCurrentTotalJob).iProcessMachineId(3) = 1;
            jobshop_config.iTotalTimeSlot = max([tPrevTotalTimeSlot, container_jsp_schedule.stJobSet(iCurrentTotalJob).iProcessEndTime(3)]);
        else
            container_jsp_schedule.iTotalJob = iCurrentTotalJob;
        end
    end
    
    jobshop_config.iTotalTimeSlot = max([jobshop_config.iTotalTimeSlot, container_jsp_schedule.stJobSet(iCurrentTotalJob).iProcessEndTime(3)]);
    container_jsp_schedule.iMaxEndTime = jobshop_config.iTotalTimeSlot;
    tPrevTotalTimeSlot = jobshop_config.iTotalTimeSlot;
    
%    if iFlagExistNegativeTime == 0
        [TotalConflictTimePerMachine, astMachineUsageTimeInfo] = ...
            jsp_calc_cnflt_disce_tm02(container_jsp_schedule, stQuayCraneJobList.stResourceConfig, ...
                container_jsp_schedule.stJobSet(ii).iProcessStartTime(1), ...
                container_jsp_schedule.stJobSet(ii).iProcessEndTime(3));
    
    if stQuayCraneJobList.iPlotFlag >= 3
        if ii >= 3
        TotalConflictTimePerMachine
        ii
        figure_id = 1;
        Machine2ConfigArray = stQuayCraneJobList.stResourceConfig.stMachineConfig(2).afMaCapAtTimePoint
        Machine3ConfigArray = stQuayCraneJobList.stResourceConfig.stMachineConfig(3).afMaCapAtTimePoint
        container_jsp_schedule.iMaxEndTime = jobshop_config.iTotalTimeSlot
        astMachineUsageTimeInfo = jsp_build_machine_usage_con_tm(container_jsp_schedule)
%        figure(figure_id);
%        hold off;
        
        psa_jsp_plot_machusage_info_2(container_jsp_schedule, astMachineUsageTimeInfo, figure_id, jobshop_config, stQuayCraneJobList.stResourceConfig);

        input('any key to continue');
        close(figure_id);
        end
    end
    
    while sum(TotalConflictTimePerMachine) >= 1
        
        container_jsp_schedule.stJobSet(ii).iProcessStartTime(1) = container_jsp_schedule.stJobSet(ii).iProcessStartTime(1) + 1;
        container_jsp_schedule.stJobSet(ii).iProcessEndTime(1) = container_jsp_schedule.stJobSet(ii).iProcessEndTime(1) + 1;
        container_jsp_schedule.stJobSet(ii).iProcessStartTime(2) = container_jsp_schedule.stJobSet(ii).iProcessStartTime(2) + 1;
        container_jsp_schedule.stJobSet(ii).iProcessEndTime(2) = container_jsp_schedule.stJobSet(ii).iProcessEndTime(2) + 1;
        container_jsp_schedule.stJobSet(ii).iProcessStartTime(3) = container_jsp_schedule.stJobSet(ii).iProcessStartTime(3) + 1;
        container_jsp_schedule.stJobSet(ii).iProcessEndTime(3) = container_jsp_schedule.stJobSet(ii).iProcessEndTime(3) + 1;
        container_jsp_schedule.stJobSet(ii).fProcessStartTime = container_jsp_schedule.stJobSet(ii).iProcessStartTime;
        container_jsp_schedule.stJobSet(ii).fProcessEndTime = container_jsp_schedule.stJobSet(ii).iProcessEndTime;

        % Wrong implementation
        %        jobshop_config.iTotalTimeSlot = jobshop_config.iTotalTimeSlot + 1;
        % correct 
        jobshop_config.iTotalTimeSlot = max([jobshop_config.iTotalTimeSlot, container_jsp_schedule.stJobSet(iCurrentTotalJob).iProcessEndTime(3)]);
        container_jsp_schedule.iMaxEndTime = jobshop_config.iTotalTimeSlot;
        tPrevTotalTimeSlot = jobshop_config.iTotalTimeSlot;
        [TotalConflictTimePerMachine, astMachineUsageTimeInfo] = ...
            jsp_calc_cnflt_disce_tm02(container_jsp_schedule, stQuayCraneJobList.stResourceConfig, ...
            container_jsp_schedule.stJobSet(ii).iProcessStartTime(1), ...
            container_jsp_schedule.stJobSet(ii).iProcessEndTime(3));

        if stQuayCraneJobList.iPlotFlag >= 3
            if ii >= 3
                astMachineUsageTimeInfo = jsp_build_machine_usage_con_tm(container_jsp_schedule);
%                figure(figure_id  +1);
%                hold off;
                psa_jsp_plot_machusage_info_2(container_jsp_schedule, astMachineUsageTimeInfo, figure_id+1, jobshop_config, stQuayCraneJobList.stResourceConfig);

                input('any key to continue');
                close(figure_id + 1);
            end
        end
        
    end
    iCurrentTotalJob = iCurrentTotalJob + 1;
end

container_jsp_schedule.iMaxEndTime = jobshop_config.iTotalTimeSlot;

