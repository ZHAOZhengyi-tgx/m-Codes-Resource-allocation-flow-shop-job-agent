function [stFspSchedule, stJspCfg] = fsp_gen_job_schedule_8(stGenFspJobList)
%
% Forward Jobs preceeding reverse jobs
%
iConstDebugLevelStop = 5;
%%%%%%% Read input
iTotalForwardJobs = stGenFspJobList.stAgentBiFSPJobMachConfig.iTotalForwardJobs;
iTotalReverseJobs = stGenFspJobList.stAgentBiFSPJobMachConfig.iTotalReverseJobs;

naMachCapOnePer = stGenFspJobList.stResourceConfig.iaMachCapOnePer;
nTotalMachType = stGenFspJobList.stAgentBiFSPJobMachConfig.iTotalMachType;
astMachineProcTimeOnMachine = stGenFspJobList.astMachineProcTimeOnMachine;


%%% Protatype of Output
%%% Construct Template Structure of Schedule Output
[stJspCfg] = cvt_jsp_cfg_by_gen_bifsp(stGenFspJobList);
[stFspSchedule] = jsp_constr_sche_struct_by_cfg(stJspCfg);
%%%%
if stGenFspJobList.stAgentBiFSPJobMachConfig.iPlotFlag >= 3
    figure_id = 501;
end

iCurrentTotalJob = 1;
tPrevTotalTimeSlot = 1;
tTotalTimeSlotVolatile = 0;
while iCurrentTotalJob <= stFspSchedule.iTotalJob
    stJspCfg.iTotalJob = iCurrentTotalJob;
    iCurrentJobId = iCurrentTotalJob;

    %% use jsp_process_time(iCurrentJobId).iProcessTime(mm)
    if iCurrentJobId == 1
        stFspSchedule.stJobSet(iCurrentJobId).iProcessStartTime(1) = 0;
    else
        stFspSchedule.stJobSet(iCurrentJobId).iProcessStartTime(1) = stFspSchedule.stJobSet(iCurrentJobId-1).iProcessStartTime(1);
    end
    stFspSchedule.stJobSet(iCurrentJobId).iProcessEndTime(1) = stFspSchedule.stJobSet(iCurrentJobId).iProcessStartTime(1) ...
        + stJspCfg.jsp_process_time(iCurrentJobId).iProcessTime(1);
    for pp = 2:1:nTotalMachType
        stFspSchedule.stJobSet(iCurrentJobId).iProcessStartTime(pp) = stFspSchedule.stJobSet(iCurrentJobId).iProcessEndTime(pp-1);
        stFspSchedule.stJobSet(iCurrentJobId).iProcessEndTime(pp) = stFspSchedule.stJobSet(iCurrentJobId).iProcessStartTime(pp) ...
            + stJspCfg.jsp_process_time(iCurrentJobId).iProcessTime(pp);
    end
    stFspSchedule.stJobSet(iCurrentJobId).fProcessStartTime = stFspSchedule.stJobSet(iCurrentJobId).iProcessStartTime;
    stFspSchedule.stJobSet(iCurrentJobId).fProcessEndTime = stFspSchedule.stJobSet(iCurrentJobId).iProcessEndTime;

    for pp = 1:1:nTotalMachType
        if stJspCfg.jsp_process_time(iCurrentJobId).iProcessTime(pp) > 0
            stFspSchedule.stJobSet(iCurrentJobId).iProcessMachineId(pp) = rem(iCurrentJobId-1, naMachCapOnePer(pp)) + 1;
        else
            stFspSchedule.stJobSet(iCurrentJobId).iProcessMachineId(pp) = 0;
        end
    end
    
    if iCurrentJobId == 1
        tTotalTimeSlotVolatile = stFspSchedule.stJobSet(iCurrentJobId).iProcessEndTime(nTotalMachType);
    end
    
    iFlagExistNegativeTime = 0;
    tNegMinimumStartTime = 0;
    for jjJob = 1:1:iCurrentTotalJob
        if stFspSchedule.stJobSet(jjJob).iProcessStartTime(1) < 0
            if iFlagExistNegativeTime == 0
                iFlagExistNegativeTime = 1;
            end
            if stFspSchedule.stJobSet(jjJob).iProcessStartTime(1) < tNegMinimumStartTime
                tNegMinimumStartTime = stFspSchedule.stJobSet(jjJob).iProcessStartTime(1);
            end
        end
    end
    if iFlagExistNegativeTime == 1
        tPosShiftTime = - tNegMinimumStartTime;
        for jjJob = 1:1:iCurrentTotalJob
            for jj = 1:1:stFspSchedule.stProcessPerJob(jjJob)
                stFspSchedule.stJobSet(jjJob).iProcessStartTime(jj) = stFspSchedule.stJobSet(jjJob).iProcessStartTime(jj) + tPosShiftTime; 
                stFspSchedule.stJobSet(jjJob).iProcessEndTime(jj) = stFspSchedule.stJobSet(jjJob).iProcessEndTime(jj) + tPosShiftTime;
            end
            stFspSchedule.stJobSet(jjJob).fProcessEndTime = stFspSchedule.stJobSet(jjJob).iProcessEndTime;
            stFspSchedule.stJobSet(jjJob).fProcessStartTime = stFspSchedule.stJobSet(jjJob).iProcessStartTime;
        end
        tTotalTimeSlotVolatile = round(tTotalTimeSlotVolatile + tPosShiftTime);
    end
    
    tTotalTimeSlotVolatile = max([tTotalTimeSlotVolatile, stFspSchedule.stJobSet(iCurrentJobId).iProcessEndTime(nTotalMachType)]);
    
    for kk = 1:1:stJspCfg.iTotalMachine
        for tt = tPrevTotalTimeSlot:1:tTotalTimeSlotVolatile
            aMachineCapacity(kk, tt) = stJspCfg.iTotalMachineNum(kk);
        end
    end
    tPrevTotalTimeSlot = tTotalTimeSlotVolatile;
    stJspCfg.iTotalTimeSlot = tTotalTimeSlotVolatile;
    
    [stMachineConflictInfo, TotalConflictTimePerMachine, astMachineTimeUsage] = ...
        jsp_build_conflit_info_03(stJspCfg, stFspSchedule, aMachineCapacity);

    if sum(TotalConflictTimePerMachine) >= 1 ...
            & stGenFspJobList.stAgentBiFSPJobMachConfig.iPlotFlag >= iConstDebugLevelStop
        if iCurrentJobId >= 3
            stFspSchedule.iMaxEndTime = tTotalTimeSlotVolatile;
            astMachineUsageTimeInfo = jsp_build_machine_usage_con_tm(stFspSchedule);
            figure(figure_id);
            hold off;
            psa_jsp_plot_machusage_info_2(stFspSchedule, astMachineUsageTimeInfo, figure_id, stJspCfg, stGenFspJobList.stResourceConfig);
            input('before shift any key')
        end
        iCurrentJob_nTotalVio_TotalTimeSlot = [iCurrentJobId, TotalConflictTimePerMachine', tTotalTimeSlotVolatile]
    end
    
    while sum(TotalConflictTimePerMachine) >= 1
        
        for pp = 1:1:nTotalMachType
            stFspSchedule.stJobSet(iCurrentJobId).iProcessStartTime(pp) = stFspSchedule.stJobSet(iCurrentJobId).iProcessStartTime(pp) + 1;
            stFspSchedule.stJobSet(iCurrentJobId).iProcessEndTime(pp) = stFspSchedule.stJobSet(iCurrentJobId).iProcessEndTime(pp) + 1;
        end        
         stFspSchedule.stJobSet(iCurrentJobId).fProcessStartTime = stFspSchedule.stJobSet(iCurrentJobId).iProcessStartTime;
         stFspSchedule.stJobSet(iCurrentJobId).fProcessEndTime = stFspSchedule.stJobSet(iCurrentJobId).iProcessEndTime;
        if tTotalTimeSlotVolatile < stFspSchedule.stJobSet(iCurrentJobId).iProcessEndTime(nTotalMachType)
            tTotalTimeSlotVolatile = stFspSchedule.stJobSet(iCurrentJobId).iProcessEndTime(nTotalMachType);
        end
        for kk = 1:1:stJspCfg.iTotalMachine
            for tt = tPrevTotalTimeSlot:1:tTotalTimeSlotVolatile
                aMachineCapacity(kk, tt) = stJspCfg.iTotalMachineNum(kk);
            end
        end
        tPrevTotalTimeSlot = tTotalTimeSlotVolatile;
        stJspCfg.iTotalTimeSlot = tTotalTimeSlotVolatile;
        [stMachineConflictInfo, TotalConflictTimePerMachine, astMachineTimeUsage] = ...
            jsp_build_conflit_info_03(stJspCfg, stFspSchedule, aMachineCapacity);

        if stGenFspJobList.stAgentBiFSPJobMachConfig.iPlotFlag >= iConstDebugLevelStop
            if iCurrentJobId >= 3
                stFspSchedule.iMaxEndTime = tTotalTimeSlotVolatile;
                astMachineUsageTimeInfo = jsp_build_machine_usage_con_tm(stFspSchedule);
                figure(figure_id  +1);
                hold off;
                psa_jsp_plot_machusage_info_2(stFspSchedule, astMachineUsageTimeInfo, figure_id + 1, stJspCfg, stGenFspJobList.stResourceConfig);
                iCurrentJob_nTotalVio_TotalTimeSlot_EndTimeLast = [iCurrentJobId, TotalConflictTimePerMachine', tTotalTimeSlotVolatile, ...
                    stFspSchedule.stJobSet(iCurrentJobId).iProcessEndTime(nTotalMachType)]
                input('any key')
                delete(figure_id + 1)
            end
        end
        
    end
    
    iCurrentTotalJob = iCurrentTotalJob + 1;
end

stFspSchedule.iMaxEndTime = stJspCfg.iTotalTimeSlot;
