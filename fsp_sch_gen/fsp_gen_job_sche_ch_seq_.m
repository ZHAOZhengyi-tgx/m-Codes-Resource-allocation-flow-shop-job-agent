function [stFspSchedule, stJspCfg] = fsp_gen_job_sche_ch_seq_(stGenFspJobList, iJobSeqInJspCfg)
% History
% YYYYMMDD  Notes
% 20080323 Add iReleaseTimeSlotGlobal

iConstDebugLevelStop = 5;
%%%%%%% Read input
iTotalForwardJobs = stGenFspJobList.stAgentBiFSPJobMachConfig.iTotalForwardJobs;
iTotalReverseJobs = stGenFspJobList.stAgentBiFSPJobMachConfig.iTotalReverseJobs;

naMachCapOnePer = stGenFspJobList.stResourceConfig.iaMachCapOnePer;
nTotalMachType = stGenFspJobList.stAgentBiFSPJobMachConfig.iTotalMachType;
astMachineProcTimeOnMachine = stGenFspJobList.astMachineProcTimeOnMachine;


if isfield(stGenFspJobList.stAgentBiFSPJobMachConfig, 'iReleaseTimeSlotGlobal') % 20080323
    tStartTime = stGenFspJobList.stAgentBiFSPJobMachConfig.iReleaseTimeSlotGlobal - 1;
else
    tStartTime = 0;
end
%%% Protatype of Output
%%% Construct Template Structure of Schedule Output

tPrevTotalTimeSlot = 0;
iTotalJob = iTotalReverseJobs + iTotalForwardJobs;

[stJspCfg] = cvt_jsp_cfg_by_gen_bifsp(stGenFspJobList);
[stFspSchedule] = jsp_constr_sche_struct_by_cfg(stJspCfg);

iCurrentJobIndex = 1;
tPrevTotalTimeSlot = 1;
stJspCfg.iTotalTimeSlot = 0;
stJspCfg.iTotalJob = 1;
while iCurrentJobIndex <= iTotalJob
    iCurrentJobId = iJobSeqInJspCfg(iCurrentJobIndex);
    if iCurrentJobIndex >= 2
        iPreviouJobId = iJobSeqInJspCfg(iCurrentJobIndex - 1);
    end
    stJspCfg.iTotalJob = max([iCurrentJobId, stJspCfg.iTotalJob]);
    stFspSchedule.iTotalJob = stJspCfg.iTotalJob;

    if iCurrentJobIndex == 1
        stFspSchedule.stJobSet(iCurrentJobId).iProcessStartTime(1) = tStartTime;
    else
        if stJspCfg.stJssProbStructConfig.isCriticalOperateSeq == 1
            if stJspCfg.iJobType(iPreviouJobId) == 1 & stJspCfg.iJobType(iCurrentJobId) == 1 % iPreviouJobId <= iTotalForwardJobs, previous job is a forward job
                stFspSchedule.stJobSet(iCurrentJobId).iProcessStartTime(1) = stFspSchedule.stJobSet(iPreviouJobId).iProcessStartTime(1);
            elseif stJspCfg.iJobType(iPreviouJobId) == 2 & stJspCfg.iJobType(iCurrentJobId) == 1
                stFspSchedule.stJobSet(iCurrentJobId).iProcessStartTime(1) = stFspSchedule.stJobSet(iPreviouJobId).iProcessStartTime(nTotalMachType);
            elseif stJspCfg.iJobType(iPreviouJobId) == 2 & stJspCfg.iJobType(iCurrentJobId) == 2
                stFspSchedule.stJobSet(iCurrentJobId).iProcessStartTime(nTotalMachType) = stFspSchedule.stJobSet(iPreviouJobId).iProcessStartTime(nTotalMachType);
                stFspSchedule.stJobSet(iCurrentJobId).iProcessStartTime(1) = stFspSchedule.stJobSet(iCurrentJobId).iProcessStartTime(nTotalMachType) ...
                    - sum(stJspCfg.jsp_process_time(iCurrentJobId).iProcessTime(1:nTotalMachType - 1));
            else %  stJspCfg.iJobType(iPreviouJobId) == 1 & stJspCfg.iJobType(iCurrentJobId) == 2
                stFspSchedule.stJobSet(iCurrentJobId).iProcessStartTime(nTotalMachType) = stFspSchedule.stJobSet(iPreviouJobId).iProcessStartTime(1);
                stFspSchedule.stJobSet(iCurrentJobId).iProcessStartTime(1) = stFspSchedule.stJobSet(iCurrentJobId).iProcessStartTime(nTotalMachType) ...
                    - sum(stJspCfg.jsp_process_time(iCurrentJobId).iProcessTime(1:nTotalMachType - 1));
            end
        else
            stFspSchedule.stJobSet(iCurrentJobId).iProcessStartTime(1) = stFspSchedule.stJobSet(iPreviouJobId).iProcessStartTime(1);
        end
    end
    stFspSchedule.stJobSet(iCurrentJobId).iProcessEndTime(1) = stFspSchedule.stJobSet(iCurrentJobId).iProcessStartTime(1) ...
        + stJspCfg.jsp_process_time(iCurrentJobId).iProcessTime(1); % astMachineProcTimeOnMachine(1).aForwardTimeMachineCycle(iCurrentJobId);
    for pp = 2:1:nTotalMachType
        stFspSchedule.stJobSet(iCurrentJobId).iProcessStartTime(pp) = stFspSchedule.stJobSet(iCurrentJobId).iProcessEndTime(pp-1);
        stFspSchedule.stJobSet(iCurrentJobId).iProcessEndTime(pp) = stFspSchedule.stJobSet(iCurrentJobId).iProcessStartTime(pp) ...
           + stJspCfg.jsp_process_time(iCurrentJobId).iProcessTime(pp);  % + astMachineProcTimeOnMachine(pp).aForwardTimeMachineCycle(iCurrentJobId);
    end
    stFspSchedule.stJobSet(iCurrentJobId).fProcessStartTime = stFspSchedule.stJobSet(iCurrentJobId).iProcessStartTime;
    stFspSchedule.stJobSet(iCurrentJobId).fProcessEndTime = stFspSchedule.stJobSet(iCurrentJobId).iProcessEndTime;

    for pp = 1:1:nTotalMachType
        if stJspCfg.jsp_process_time(iCurrentJobId).iProcessTime(pp) > 0
            stFspSchedule.stJobSet(iCurrentJobId).iProcessMachineId(pp) = rem(iCurrentJobIndex-1, naMachCapOnePer(pp)) + 1;
        else
            stFspSchedule.stJobSet(iCurrentJobId).iProcessMachineId(pp) = 0;
        end
    end
    
    %% schedule the current job according to previous job's start time
%     if stJspCfg.iJobType(iCurrentJobId) == 1  % iCurrentJobId <= iTotalForwardJobs, current job is a forward job
%         if iCurrentJobIndex == 1
%             stFspSchedule.stJobSet(iCurrentJobId).iProcessStartTime(1) = tStartTime;
%         else
%             if stJspCfg.iJobType(iPreviouJobId) == 1   % iPreviouJobId <= iTotalForwardJobs, previous job is a forward job
%                 stFspSchedule.stJobSet(iCurrentJobId).iProcessStartTime(1) = stFspSchedule.stJobSet(iPreviouJobId).iProcessStartTime(1);
%             else
%                 stFspSchedule.stJobSet(iCurrentJobId).iProcessStartTime(1) = stFspSchedule.stJobSet(iPreviouJobId).iProcessStartTime(nTotalMachType);
%             end
%         end
%         stFspSchedule.stJobSet(iCurrentJobId).iProcessEndTime(1) = stFspSchedule.stJobSet(iCurrentJobId).iProcessStartTime(1) + astMachineProcTimeOnMachine(1).aForwardTimeMachineCycle(iCurrentJobId);
%         for pp = 2:1:nTotalMachType
%             stFspSchedule.stJobSet(iCurrentJobId).iProcessStartTime(pp) = stFspSchedule.stJobSet(iCurrentJobId).iProcessEndTime(pp-1);
%             stFspSchedule.stJobSet(iCurrentJobId).iProcessEndTime(pp) = stFspSchedule.stJobSet(iCurrentJobId).iProcessStartTime(pp) + astMachineProcTimeOnMachine(pp).aForwardTimeMachineCycle(iCurrentJobId);
%         end
%         stFspSchedule.stJobSet(iCurrentJobId).fProcessStartTime = stFspSchedule.stJobSet(iCurrentJobId).iProcessStartTime;
%         stFspSchedule.stJobSet(iCurrentJobId).fProcessEndTime = stFspSchedule.stJobSet(iCurrentJobId).iProcessEndTime;
%         
%         for pp = 1:1:nTotalMachType
%             if astMachineProcTimeOnMachine(pp).aForwardTimeMachineCycle(iCurrentJobId) > 0
%                 stFspSchedule.stJobSet(iCurrentJobId).iProcessMachineId(pp) = rem(iCurrentJobIndex-1, naMachCapOnePer(pp)) + 1;
%             else
%                 stFspSchedule.stJobSet(iCurrentJobId).iProcessMachineId(pp) = 0;
%             end
%         end
%         
%     else  % current job is a reverse job
%         if iCurrentJobIndex == 1  % it doesnot has any previous job
%             stFspSchedule.stJobSet(iCurrentJobId).iProcessStartTime(nTotalMachType) = tStartTime;
%         else
%             if stJspCfg.iJobType(iPreviouJobId) == 1   % previous job is a forward job
%                 stFspSchedule.stJobSet(iCurrentJobId).iProcessStartTime(nTotalMachType) = stFspSchedule.stJobSet(iPreviouJobId).iProcessStartTime(1);
%             else
%                 stFspSchedule.stJobSet(iCurrentJobId).iProcessStartTime(nTotalMachType) = stFspSchedule.stJobSet(iPreviouJobId).iProcessStartTime(nTotalMachType);
%             end
%         end
%         stFspSchedule.stJobSet(iCurrentJobId).iProcessEndTime(nTotalMachType) = ...
%             stFspSchedule.stJobSet(iCurrentJobId).iProcessStartTime(nTotalMachType) + astMachineProcTimeOnMachine(1).aReverseTimeMachineCycle(iCurrentJobId - iTotalForwardJobs); 
% 
%         for pp = nTotalMachType-1 : (-1) : 1
%             stFspSchedule.stJobSet(iCurrentJobId).iProcessEndTime(pp) = stFspSchedule.stJobSet(iCurrentJobId).iProcessStartTime(pp + 1);
%             stFspSchedule.stJobSet(iCurrentJobId).iProcessStartTime(pp) = stFspSchedule.stJobSet(iCurrentJobId).iProcessEndTime(pp) ...
%                 - astMachineProcTimeOnMachine(nTotalMachType + 1 - pp).aReverseTimeMachineCycle(iCurrentJobId- iTotalForwardJobs);
%         end
%         stFspSchedule.stJobSet(iCurrentJobId).fProcessStartTime = stFspSchedule.stJobSet(iCurrentJobId).iProcessStartTime;
%         stFspSchedule.stJobSet(iCurrentJobId).fProcessEndTime = stFspSchedule.stJobSet(iCurrentJobId).iProcessEndTime;
%         
%         for pp = 1:1:nTotalMachType
%             if astMachineProcTimeOnMachine(pp).aReverseTimeMachineCycle(iCurrentJobId- iTotalForwardJobs) > 0
%                 stFspSchedule.stJobSet(iCurrentJobId).iProcessMachineId(pp) = rem(iCurrentJobIndex-1, naMachCapOnePer(nTotalMachType + 1 - pp)) + 1;
%             else
%                 stFspSchedule.stJobSet(iCurrentJobId).iProcessMachineId(pp) = 0;
%             end
%         end
%         
%     end
    
    iFlagExistNegativeTime = 0;
    tNegMinimumStartTime = 0;
    if stFspSchedule.stJobSet(iCurrentJobId).iProcessStartTime(1) < 0
        if iFlagExistNegativeTime == 0
            iFlagExistNegativeTime = 1;
        end
        if stFspSchedule.stJobSet(iCurrentJobId).iProcessStartTime(1) < tNegMinimumStartTime
            tNegMinimumStartTime = stFspSchedule.stJobSet(iCurrentJobId).iProcessStartTime(1);
        end
    end
    if iFlagExistNegativeTime == 1
        tPosShiftTime = - tNegMinimumStartTime;
        jsp_save_schedule = stFspSchedule;
        for ii = 1:1:stJspCfg.iTotalJob % iCurrentJobId
            jjJob = iJobSeqInJspCfg(ii);
            for jj = 1:1:stFspSchedule.stProcessPerJob(jjJob)
                stFspSchedule.stJobSet(jjJob).iProcessStartTime(jj) = stFspSchedule.stJobSet(jjJob).iProcessStartTime(jj) + tPosShiftTime; 
                stFspSchedule.stJobSet(jjJob).iProcessEndTime(jj) = stFspSchedule.stJobSet(jjJob).iProcessEndTime(jj) + tPosShiftTime;
            end
            stFspSchedule.stJobSet(jjJob).fProcessEndTime = stFspSchedule.stJobSet(jjJob).iProcessEndTime;
            stFspSchedule.stJobSet(jjJob).fProcessStartTime = stFspSchedule.stJobSet(jjJob).iProcessStartTime;
        end
        stJspCfg.iTotalTimeSlot = round(stJspCfg.iTotalTimeSlot + tPosShiftTime);
        
        stFspSchedule.iTotalJob = stJspCfg.iTotalJob - 1;
        [TotalConflictTimePerMachine, astMachineUsageTimeInfo] = ...
            jsp_calc_cnflt_disce_tm01(stFspSchedule, stGenFspJobList.stResourceConfig, ...
            stJspCfg.iTotalTimeSlot);
        if sum(TotalConflictTimePerMachine) >= 1
            %%% restore previous schedule
            stFspSchedule = jsp_save_schedule;
            %%% reschedule for the last job
                stFspSchedule.stJobSet(iCurrentJobId).iProcessStartTime(1) = 0;
                stFspSchedule.stJobSet(iCurrentJobId).iProcessEndTime(1) = ...
                    stFspSchedule.stJobSet(iCurrentJobId).iProcessStartTime(1) + stJspCfg.jsp_process_time(iCurrentJobId).iProcessTime(1);
                for pp = 2:1:nTotalMachType
                    stFspSchedule.stJobSet(iCurrentJobId).iProcessStartTime(pp) = stFspSchedule.stJobSet(iCurrentJobId).iProcessEndTime(pp-1);
                    stFspSchedule.stJobSet(iCurrentJobId).iProcessEndTime(pp) = stFspSchedule.stJobSet(iCurrentJobId).iProcessStartTime(pp) + ...
                        stJspCfg.jsp_process_time(iCurrentJobId).iProcessTime(pp);
                end

            stFspSchedule.stJobSet(iCurrentJobId).fProcessStartTime = stFspSchedule.stJobSet(iCurrentJobId).iProcessStartTime;
            stFspSchedule.stJobSet(iCurrentJobId).fProcessEndTime = stFspSchedule.stJobSet(iCurrentJobId).iProcessEndTime;

            for pp = 1:1:nTotalMachType
                if astMachineProcTimeOnMachine(pp).aReverseTimeMachineCycle(iCurrentJobId- iTotalForwardJobs) > 0
                    stFspSchedule.stJobSet(iCurrentJobId).iProcessMachineId(pp) = rem(iCurrentJobIndex-1, naMachCapOnePer(nTotalMachType + 1 - pp)) + 1;
                else
                    stFspSchedule.stJobSet(iCurrentJobId).iProcessMachineId(pp) = 0;
                end
            end
            stJspCfg.iTotalTimeSlot = max([tPrevTotalTimeSlot, stFspSchedule.stJobSet(iCurrentJobId).iProcessEndTime(nTotalMachType)]);
        else
            stFspSchedule.iTotalJob = stJspCfg.iTotalJob;
        end
    end
    
    stJspCfg.iTotalTimeSlot = max([stJspCfg.iTotalTimeSlot, stFspSchedule.stJobSet(iCurrentJobId).iProcessEndTime(nTotalMachType)]);
    
    tPrevTotalTimeSlot = stJspCfg.iTotalTimeSlot;
    stFspSchedule.iMaxEndTime = stJspCfg.iTotalTimeSlot;
    
%    iCurrentJobIndex
%    iCurrentJobId
%    tJobStartTime = stFspSchedule.stJobSet(iCurrentJobId).iProcessStartTime(1)
%    tJobEndTime = stFspSchedule.stJobSet(iCurrentJobId).iProcessEndTime(3)
   
    [TotalConflictTimePerMachine, astMachineUsageTimeInfo] = ...
        jsp_calc_cnflt_disce_tm02(stFspSchedule, stGenFspJobList.stResourceConfig, ...
            stFspSchedule.stJobSet(iCurrentJobId).iProcessStartTime(1), ...
            stFspSchedule.stJobSet(iCurrentJobId).iProcessEndTime(nTotalMachType));
    
    if stGenFspJobList.stAgentBiFSPJobMachConfig.iPlotFlag >= iConstDebugLevelStop
        if iCurrentJobId >= 1
        TotalConflictTimePerMachine
        iCurrentJobId
        figure_id = 1;
        Machine2ConfigArray = stGenFspJobList.stResourceConfig.stMachineConfig(2).afMaCapAtTimePoint
        Machine3ConfigArray = stGenFspJobList.stResourceConfig.stMachineConfig(3).afMaCapAtTimePoint
        
        astMachineUsageTimeInfo = jsp_build_machine_usage_con_tm(stFspSchedule)
%        figure(figure_id);
%        hold off;
        
        psa_jsp_plot_machusage_info_2(stFspSchedule, astMachineUsageTimeInfo, figure_id, stJspCfg, stGenFspJobList.stResourceConfig);

        input('any key to continue');
        close(figure_id);
        end
    end
    
    while sum(TotalConflictTimePerMachine) >= 1
        
        for pp = 1:1:nTotalMachType
            stFspSchedule.stJobSet(iCurrentJobId).iProcessStartTime(pp) = stFspSchedule.stJobSet(iCurrentJobId).iProcessStartTime(pp) + 1;
            stFspSchedule.stJobSet(iCurrentJobId).iProcessEndTime(pp) = stFspSchedule.stJobSet(iCurrentJobId).iProcessEndTime(pp) + 1;
        end        
        stFspSchedule.stJobSet(iCurrentJobId).fProcessStartTime = stFspSchedule.stJobSet(iCurrentJobId).iProcessStartTime;
        stFspSchedule.stJobSet(iCurrentJobId).fProcessEndTime = stFspSchedule.stJobSet(iCurrentJobId).iProcessEndTime;

        % Wrong implementation
        %        stJspCfg.iTotalTimeSlot = stJspCfg.iTotalTimeSlot + 1;
        % correct 
        stJspCfg.iTotalTimeSlot = max([stJspCfg.iTotalTimeSlot, stFspSchedule.stJobSet(iCurrentJobId).iProcessEndTime(nTotalMachType)]);
        stFspSchedule.iMaxEndTime = stJspCfg.iTotalTimeSlot;
        tPrevTotalTimeSlot = stJspCfg.iTotalTimeSlot;
        [TotalConflictTimePerMachine, astMachineUsageTimeInfo] = ...
            jsp_calc_cnflt_disce_tm02(stFspSchedule, stGenFspJobList.stResourceConfig, ...
            stFspSchedule.stJobSet(iCurrentJobId).iProcessStartTime(1), ...
            stFspSchedule.stJobSet(iCurrentJobId).iProcessEndTime(nTotalMachType));

        if stGenFspJobList.stAgentBiFSPJobMachConfig.iPlotFlag >= iConstDebugLevelStop
            if iCurrentJobId >= 1
                astMachineUsageTimeInfo = jsp_build_machine_usage_con_tm(stFspSchedule);
%                figure(figure_id  +1);
%                hold off;
                psa_jsp_plot_machusage_info_2(stFspSchedule, astMachineUsageTimeInfo, figure_id+1, stJspCfg, stGenFspJobList.stResourceConfig);

                input('any key to continue');
                close(figure_id + 1);
            end
        end
        
    end
    iCurrentJobIndex = iCurrentJobIndex + 1;
end

stFspSchedule.iMaxEndTime = stJspCfg.iTotalTimeSlot;

