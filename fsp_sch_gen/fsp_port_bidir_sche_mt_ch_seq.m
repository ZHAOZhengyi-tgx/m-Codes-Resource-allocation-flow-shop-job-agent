function [container_jsp_schedule, jobshop_config] = fsp_port_bidir_sche_mt_ch_seq(stJobListInfo, iJobSeqInJspCfg)
% use stJspCfg (jobshop_config)
% stJobListInfo: legacy from Container Job List, 3 machine
% History
% YYYYMMDD  Notes
% 20080323  iReleaseTimeSlotGlobal
stResourceConfig = stJobListInfo.stResourceConfig;

if isfield(stJobListInfo, 'iReleaseTimeSlotGlobal')  % 20080323
    tStartTime = stJobListInfo.iReleaseTimeSlotGlobal;
else
    tStartTime = 0;
end

if isfield(stJobListInfo, 'jobshop_config') % 20091216
    jobshop_config = stJobListInfo.jobshop_config;
else
    [jobshop_config] = psa_jsp_construct_jsp_config(stJobListInfo);
    stJobListInfo.jobshop_config = jobshop_config;
end

iTotalJob = jobshop_config.iTotalJob;

if isfield(stJobListInfo, 'stJspScheduleTemplate') % 20091216
    container_jsp_schedule = stJobListInfo.stJspScheduleTemplate;
else
    container_jsp_schedule = jsp_constr_sche_struct_by_cfg(jobshop_config);
end

iCurrentJobIndex = 1;
tPrevTotalTimeSlot = 1;
jobshop_config.iTotalTimeSlot = 0;
jobshop_config.iTotalJob = 1;
container_jsp_schedule.iTotalJob = 1;
while iCurrentJobIndex <= iTotalJob
    iCurrentJobId = iJobSeqInJspCfg(iCurrentJobIndex);
    if iCurrentJobIndex >= 2
        iPreviouJobId = iJobSeqInJspCfg(iCurrentJobIndex - 1);
    end
    jobshop_config.iTotalJob = max([iCurrentJobId, jobshop_config.iTotalJob]);
    container_jsp_schedule.iTotalJob = jobshop_config.iTotalJob;

    %% schedule the current job according to previous job's start time
    if jobshop_config.iJobType(iCurrentJobId) == 1  % iCurrentJobId <= TotalContainer_Discharge, current job is a forward job
        if iCurrentJobIndex == 1
            container_jsp_schedule.stJobSet(iCurrentJobId).iProcessStartTime(1) = tStartTime;
        else
            if jobshop_config.iJobType(iPreviouJobId) == 1   % iPreviouJobId <= TotalContainer_Discharge, previous job is a forward job
                container_jsp_schedule.stJobSet(iCurrentJobId).iProcessStartTime(1) = ...
                    container_jsp_schedule.stJobSet(iPreviouJobId).iProcessStartTime(1) + ...
                    jobshop_config.jsp_process_time(iPreviouJobId).iProcessTime(1);
            else
                container_jsp_schedule.stJobSet(iCurrentJobId).iProcessStartTime(1) = ...
                    container_jsp_schedule.stJobSet(iPreviouJobId).iProcessStartTime(3) + ...
                    jobshop_config.jsp_process_time(iPreviouJobId).iProcessTime(3);
            end
        end
        container_jsp_schedule.stJobSet(iCurrentJobId).iProcessEndTime(1) = ...
            container_jsp_schedule.stJobSet(iCurrentJobId).iProcessStartTime(1) + jobshop_config.jsp_process_time(iCurrentJobId).iProcessTime(1);
        container_jsp_schedule.stJobSet(iCurrentJobId).iProcessStartTime(2) = ...
            container_jsp_schedule.stJobSet(iCurrentJobId).iProcessEndTime(1);
        container_jsp_schedule.stJobSet(iCurrentJobId).iProcessEndTime(2) = ...
            container_jsp_schedule.stJobSet(iCurrentJobId).iProcessStartTime(2) + jobshop_config.jsp_process_time(iCurrentJobId).iProcessTime(2);
        container_jsp_schedule.stJobSet(iCurrentJobId).iProcessStartTime(3) = ...
            container_jsp_schedule.stJobSet(iCurrentJobId).iProcessEndTime(2);
        container_jsp_schedule.stJobSet(iCurrentJobId).iProcessEndTime(3) = ...
            container_jsp_schedule.stJobSet(iCurrentJobId).iProcessStartTime(3) + jobshop_config.jsp_process_time(iCurrentJobId).iProcessTime(3);
        container_jsp_schedule.stJobSet(iCurrentJobId).fProcessStartTime = container_jsp_schedule.stJobSet(iCurrentJobId).iProcessStartTime;
        container_jsp_schedule.stJobSet(iCurrentJobId).fProcessEndTime = container_jsp_schedule.stJobSet(iCurrentJobId).iProcessEndTime;

        container_jsp_schedule.stJobSet(iCurrentJobId).iProcessMachineId(1) = 1;
        container_jsp_schedule.stJobSet(iCurrentJobId).iProcessMachineId(2) = 0; % rem(iCurrentJobIndex - 1, MaxVirtualPrimeMover) + 1;
        container_jsp_schedule.stJobSet(iCurrentJobId).iProcessMachineId(3) = 0; % rem(iCurrentJobIndex - 1, MaxVirtualYardCrane) + 1;

    else  % current job is a reverse job
        if iCurrentJobIndex == 1  % it doesnot has any previous job
            container_jsp_schedule.stJobSet(iCurrentJobId).iProcessStartTime(3) = tStartTime;
        else
            if jobshop_config.iJobType(iPreviouJobId) == 1   % previous job is a forward job
                container_jsp_schedule.stJobSet(iCurrentJobId).iProcessStartTime(3) = ...
                    container_jsp_schedule.stJobSet(iPreviouJobId).iProcessStartTime(1) +  ...
                    jobshop_config.jsp_process_time(iPreviouJobId).iProcessTime(1);
            else
                container_jsp_schedule.stJobSet(iCurrentJobId).iProcessStartTime(3) = ...
                    container_jsp_schedule.stJobSet(iPreviouJobId).iProcessStartTime(3) +  ...
                    jobshop_config.jsp_process_time(iPreviouJobId).iProcessTime(3);
            end
        end
        container_jsp_schedule.stJobSet(iCurrentJobId).iProcessEndTime(3) = ...
            container_jsp_schedule.stJobSet(iCurrentJobId).iProcessStartTime(3) + jobshop_config.jsp_process_time(iCurrentJobId).iProcessTime(3);
        container_jsp_schedule.stJobSet(iCurrentJobId).iProcessStartTime(1) = ...
            container_jsp_schedule.stJobSet(iCurrentJobId).iProcessStartTime(3) - ...
            jobshop_config.jsp_process_time(iCurrentJobId).iProcessTime(2) - jobshop_config.jsp_process_time(iCurrentJobId).iProcessTime(1);
        container_jsp_schedule.stJobSet(iCurrentJobId).iProcessEndTime(1) = ...
            container_jsp_schedule.stJobSet(iCurrentJobId).iProcessStartTime(1) + jobshop_config.jsp_process_time(iCurrentJobId).iProcessTime(1);
        container_jsp_schedule.stJobSet(iCurrentJobId).iProcessStartTime(2) = container_jsp_schedule.stJobSet(iCurrentJobId).iProcessEndTime(1);
        container_jsp_schedule.stJobSet(iCurrentJobId).iProcessEndTime(2) = ...
            container_jsp_schedule.stJobSet(iCurrentJobId).iProcessStartTime(2) + jobshop_config.jsp_process_time(iCurrentJobId).iProcessTime(2);
        container_jsp_schedule.stJobSet(iCurrentJobId).fProcessStartTime = container_jsp_schedule.stJobSet(iCurrentJobId).iProcessStartTime;
        container_jsp_schedule.stJobSet(iCurrentJobId).fProcessEndTime = container_jsp_schedule.stJobSet(iCurrentJobId).iProcessEndTime;
        
        container_jsp_schedule.stJobSet(iCurrentJobId).iProcessMachineId(1) = 0; % rem(iCurrentJobIndex -1, MaxVirtualYardCrane) + 1;
        container_jsp_schedule.stJobSet(iCurrentJobId).iProcessMachineId(2) = 0; % rem(iCurrentJobIndex -1, MaxVirtualPrimeMover) + 1;
        container_jsp_schedule.stJobSet(iCurrentJobId).iProcessMachineId(3) = 1;
        
    end
    
    iFlagExistNegativeTime = 0;
    tNegMinimumStartTime = 0;
%    for jjJob = 1:1:jobshop_config.iTotalJob
        jjJob = iCurrentJobId;
        if container_jsp_schedule.stJobSet(jjJob).iProcessStartTime(1) < 0
            if iFlagExistNegativeTime == 0
                iFlagExistNegativeTime = 1;
            end
            if container_jsp_schedule.stJobSet(jjJob).iProcessStartTime(1) < tNegMinimumStartTime
                tNegMinimumStartTime = container_jsp_schedule.stJobSet(jjJob).iProcessStartTime(1);
            end
        end
%    end
    if iFlagExistNegativeTime == 1
        tPosShiftTime = - tNegMinimumStartTime;
        container_save_schedule = container_jsp_schedule;
        for ii = 1:1:jobshop_config.iTotalJob % iCurrentJobId
            jjJob = iJobSeqInJspCfg(ii);
            for jj = 1:1:container_jsp_schedule.stProcessPerJob(jjJob)
                container_jsp_schedule.stJobSet(jjJob).iProcessStartTime(jj) = container_jsp_schedule.stJobSet(jjJob).iProcessStartTime(jj) + tPosShiftTime; 
                container_jsp_schedule.stJobSet(jjJob).iProcessEndTime(jj) = container_jsp_schedule.stJobSet(jjJob).iProcessEndTime(jj) + tPosShiftTime;
            end
            container_jsp_schedule.stJobSet(jjJob).fProcessEndTime = container_jsp_schedule.stJobSet(jjJob).iProcessEndTime;
            container_jsp_schedule.stJobSet(jjJob).fProcessStartTime = container_jsp_schedule.stJobSet(jjJob).iProcessStartTime;
        end
        jobshop_config.iTotalTimeSlot = ceil(jobshop_config.iTotalTimeSlot + tPosShiftTime);
        
        container_jsp_schedule.iTotalJob = jobshop_config.iTotalJob - 1;
        [TotalConflictTimePerMachine, astMachineUsageTimeInfo] = ...
            jsp_calc_cnflt_disce_tm01(container_jsp_schedule, stResourceConfig, ...
            jobshop_config.iTotalTimeSlot);
        if sum(TotalConflictTimePerMachine) >= 1
            %%% restore previous schedule
            container_jsp_schedule = container_save_schedule;
            %%% reschedule for the last job
            container_jsp_schedule.stJobSet(iCurrentJobId).iProcessStartTime(1) = 0;
            container_jsp_schedule.stJobSet(iCurrentJobId).iProcessEndTime(1) = ...
                container_jsp_schedule.stJobSet(iCurrentJobId).iProcessStartTime(1) + jobshop_config.jsp_process_time(iCurrentJobId).iProcessTime(1);
            container_jsp_schedule.stJobSet(iCurrentJobId).iProcessStartTime(2) = container_jsp_schedule.stJobSet(iCurrentJobId).iProcessEndTime(1);
            container_jsp_schedule.stJobSet(iCurrentJobId).iProcessEndTime(2) = ...
                container_jsp_schedule.stJobSet(iCurrentJobId).iProcessStartTime(2) + jobshop_config.jsp_process_time(iCurrentJobId).iProcessTime(2);
            container_jsp_schedule.stJobSet(iCurrentJobId).iProcessStartTime(3) =  container_jsp_schedule.stJobSet(iCurrentJobId).iProcessEndTime(2);
            container_jsp_schedule.stJobSet(iCurrentJobId).iProcessEndTime(3) = ...
                container_jsp_schedule.stJobSet(iCurrentJobId).iProcessStartTime(3) + jobshop_config.jsp_process_time(iCurrentJobId).iProcessTime(3);
            container_jsp_schedule.stJobSet(iCurrentJobId).fProcessStartTime = container_jsp_schedule.stJobSet(iCurrentJobId).iProcessStartTime;
            container_jsp_schedule.stJobSet(iCurrentJobId).fProcessEndTime = container_jsp_schedule.stJobSet(iCurrentJobId).iProcessEndTime;

            container_jsp_schedule.stJobSet(iCurrentJobId).iProcessMachineId(1) = 0; % rem(iCurrentJobIndex -1, MaxVirtualYardCrane) + 1;
            container_jsp_schedule.stJobSet(iCurrentJobId).iProcessMachineId(2) = 0; % rem(iCurrentJobIndex -1, MaxVirtualPrimeMover) + 1;
            container_jsp_schedule.stJobSet(iCurrentJobId).iProcessMachineId(3) = 1;
            jobshop_config.iTotalTimeSlot = max([tPrevTotalTimeSlot, container_jsp_schedule.stJobSet(iCurrentJobId).iProcessEndTime(3)]);
        else
            container_jsp_schedule.iTotalJob = jobshop_config.iTotalJob;
        end
    end
    
    jobshop_config.iTotalTimeSlot = max([jobshop_config.iTotalTimeSlot, container_jsp_schedule.stJobSet(iCurrentJobId).iProcessEndTime(3)]);
    
    tPrevTotalTimeSlot = jobshop_config.iTotalTimeSlot;
    container_jsp_schedule.iMaxEndTime = jobshop_config.iTotalTimeSlot;
    
%    iCurrentJobIndex
%    iCurrentJobId
%    tJobStartTime = container_jsp_schedule.stJobSet(iCurrentJobId).iProcessStartTime(1)
%    tJobEndTime = container_jsp_schedule.stJobSet(iCurrentJobId).iProcessEndTime(3)
   
    [TotalConflictTimePerMachine, astMachineUsageTimeInfo] = ...
        jsp_calc_cnflt_disce_tm02(container_jsp_schedule, stResourceConfig, ...
            container_jsp_schedule.stJobSet(iCurrentJobId).iProcessStartTime(1), ...
            container_jsp_schedule.stJobSet(iCurrentJobId).iProcessEndTime(3));
    
    if stJobListInfo.iPlotFlag >= 3
        if iCurrentJobId >= 3
        TotalConflictTimePerMachine
        iCurrentJobId
        figure_id = 1;
        Machine2ConfigArray = stResourceConfig.stMachineConfig(2).afMaCapAtTimePoint
        Machine3ConfigArray = stResourceConfig.stMachineConfig(3).afMaCapAtTimePoint
        
        astMachineUsageTimeInfo = jsp_build_machine_usage_con_tm(container_jsp_schedule)
%        figure(figure_id);
%        hold off;
        
        psa_jsp_plot_machusage_info_2(container_jsp_schedule, astMachineUsageTimeInfo, figure_id, jobshop_config, stResourceConfig);

        input('any key to continue');
        close(figure_id);
        end
    end
    
    while sum(TotalConflictTimePerMachine) >= 1
        
        container_jsp_schedule.stJobSet(iCurrentJobId).iProcessStartTime(1) = container_jsp_schedule.stJobSet(iCurrentJobId).iProcessStartTime(1) + 1;
        container_jsp_schedule.stJobSet(iCurrentJobId).iProcessEndTime(1) = container_jsp_schedule.stJobSet(iCurrentJobId).iProcessEndTime(1) + 1;
        container_jsp_schedule.stJobSet(iCurrentJobId).iProcessStartTime(2) = container_jsp_schedule.stJobSet(iCurrentJobId).iProcessStartTime(2) + 1;
        container_jsp_schedule.stJobSet(iCurrentJobId).iProcessEndTime(2) = container_jsp_schedule.stJobSet(iCurrentJobId).iProcessEndTime(2) + 1;
        container_jsp_schedule.stJobSet(iCurrentJobId).iProcessStartTime(3) = container_jsp_schedule.stJobSet(iCurrentJobId).iProcessStartTime(3) + 1;
        container_jsp_schedule.stJobSet(iCurrentJobId).iProcessEndTime(3) = container_jsp_schedule.stJobSet(iCurrentJobId).iProcessEndTime(3) + 1;
        container_jsp_schedule.stJobSet(iCurrentJobId).fProcessStartTime = container_jsp_schedule.stJobSet(iCurrentJobId).iProcessStartTime;
        container_jsp_schedule.stJobSet(iCurrentJobId).fProcessEndTime = container_jsp_schedule.stJobSet(iCurrentJobId).iProcessEndTime;

        % Wrong implementation
        %        jobshop_config.iTotalTimeSlot = jobshop_config.iTotalTimeSlot + 1;
        % correct 
        jobshop_config.iTotalTimeSlot = max([jobshop_config.iTotalTimeSlot, container_jsp_schedule.stJobSet(iCurrentJobId).iProcessEndTime(3)]);
        container_jsp_schedule.iMaxEndTime = jobshop_config.iTotalTimeSlot;
        tPrevTotalTimeSlot = jobshop_config.iTotalTimeSlot;
        [TotalConflictTimePerMachine, astMachineUsageTimeInfo] = ...
            jsp_calc_cnflt_disce_tm02(container_jsp_schedule, stResourceConfig, ...
            container_jsp_schedule.stJobSet(iCurrentJobId).iProcessStartTime(1), ...
            container_jsp_schedule.stJobSet(iCurrentJobId).iProcessEndTime(3));

        if stJobListInfo.iPlotFlag >= 3
            if iCurrentJobId >= 3
                astMachineUsageTimeInfo = jsp_build_machine_usage_con_tm(container_jsp_schedule);
%                figure(figure_id  +1);
%                hold off;
                psa_jsp_plot_machusage_info_2(container_jsp_schedule, astMachineUsageTimeInfo, figure_id+1, jobshop_config, stResourceConfig);

                input('any key to continue');
                close(figure_id + 1);
            end
        end
        
    end
    iCurrentJobIndex = iCurrentJobIndex + 1;
end

container_jsp_schedule.iMaxEndTime = jobshop_config.iTotalTimeSlot;

