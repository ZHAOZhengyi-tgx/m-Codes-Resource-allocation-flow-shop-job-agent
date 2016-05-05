function [stOutput] = psa_fsp_get_maxusage_gensch0(stBerthJobInfo)
%%%%%%%%%%%%  Get the maximum number of searching range of [PM, YC] by GenSch0
% 20080211 version compatible with  ga_fsp_bd_greedy
% 20080322  Add syncronization of multiple agents 
global epsilon_time;

for ii = 1:1:stBerthJobInfo.iTotalAgent  % 20080322
    [stJobListInfoAgent_ii, stContainerDischargeJobSequence, stContainerLoadJobSequence] = jsp_load_port_bifsp_list(stBerthJobInfo.strFileAgentJobList(ii).strFilename);
    stJobListInfoAgent(ii) = stJobListInfoAgent_ii;
    atStartTime_datenum(ii) = datenum(stBerthJobInfo.stAgentJobInfo(ii).atClockAgentJobStart.aClockYearMonthDateHourMinSec); % + epsilon_time;
end
[tEarliestStartTime_datenum, idxAgentEarlistStart ] = min(atStartTime_datenum);

for ii = 1:1:stBerthJobInfo.iTotalAgent
    if ii ~= idxAgentEarlistStart
        tStartTimeRelativeGlobal = atStartTime_datenum(ii) - tEarliestStartTime_datenum;
        if tStartTimeRelativeGlobal <= epsilon_time
           aiStartTimeSlotPerAgent(ii) = 0;
        else
           aiStartTimeSlotPerAgent(ii) = round(tStartTimeRelativeGlobal * 24 * 60/stJobListInfoAgent(ii).fTimeUnit_Min);
        end
    else
        aiStartTimeSlotPerAgent(ii) = 0;
    end
    aiStartResourceFramePerAgent(ii) = ...
        floor( ...
        aiStartTimeSlotPerAgent(ii) * stJobListInfoAgent(ii).fTimeUnit_Min ...
        /60 /stBerthJobInfo.fTimeFrameUnitInHour...
        );
    stJobListInfoAgent(ii).iReleaseTimeSlotGlobal = aiStartTimeSlotPerAgent(ii);

    [fsp_bidir_schedule_partial] = fsp_constru_psa_sche_struct(stJobListInfoAgent(ii));
    stJobListInfoAgent(ii).stJspScheduleTemplate = fsp_bidir_schedule_partial;
end % 20080322

for qq = 1:1:stBerthJobInfo.iTotalAgent
    tPrimeMoverTotalTime = 0;
    tYardCraneTotalTime = 0;
    for jj = 1:1:stJobListInfoAgent(qq).TotalContainer_Discharge
        tPrimeMoverTotalTime = tPrimeMoverTotalTime + stJobListInfoAgent(qq).stContainerDischargeJobSequence(jj).Time_PM;
        tYardCraneTotalTime  = tYardCraneTotalTime  + stJobListInfoAgent(qq).stContainerDischargeJobSequence(jj).Time_YC;
    end
    for jj = 1:1:stJobListInfoAgent(qq).TotalContainer_Load
        tPrimeMoverTotalTime = tPrimeMoverTotalTime + stJobListInfoAgent(qq).stContainerLoadJobSequence(jj).Time_PM;
        tYardCraneTotalTime  = tYardCraneTotalTime  + stJobListInfoAgent(qq).stContainerLoadJobSequence(jj).Time_YC;
    end
    
    if tPrimeMoverTotalTime <= 0 | tYardCraneTotalTime <= 0
        error('Total Time cannot be <= 0');
    else
        stJobListInfoAgent(qq).fTotalTimeRatioPM_OverYC = tPrimeMoverTotalTime/tYardCraneTotalTime;
        stJobListInfoAgent(qq).tPrimeMoverTotalTime     = tPrimeMoverTotalTime;
        stJobListInfoAgent(qq).tYardCraneTotalTime      = tYardCraneTotalTime;
        astAgentMachineHourInfo(qq).afTotalWorkHourPerMachine(1) = ...
            stJobListInfoAgent(qq).TotalContainer_Discharge + ...
            stJobListInfoAgent(qq).TotalContainer_Load;
        astAgentMachineHourInfo(qq).afTotalWorkHourPerMachine(2) = tPrimeMoverTotalTime;
        astAgentMachineHourInfo(qq).afTotalWorkHourPerMachine(3) = tYardCraneTotalTime;
    end
    
    %%% Add sorted index by total process time of each time
    [jobshop_config] = psa_jsp_construct_jsp_config(stJobListInfoAgent(qq));
    stJobListInfoAgent(qq).jobshop_config = jobshop_config;
end % 20080322


for ii = 1:1:stBerthJobInfo.iTotalAgent
%    ii
    stJobListInfoAgent_ii = stJobListInfoAgent(ii);

    stJobListInfoAgent_ii.MaxVirtualPrimeMover = stJobListInfoAgent_ii.TotalContainer_Load + stJobListInfoAgent_ii.TotalContainer_Discharge;
    stJobListInfoAgent_ii.MaxVirtualYardCrane = stJobListInfoAgent_ii.TotalContainer_Load + stJobListInfoAgent_ii.TotalContainer_Discharge;
%    [stContainerDischargeJobSequence, container_jsp_discha_schedule, stContainerLoadJobSequence, ...
%             container_jsp_load_schedule, container_sequence_jsp_ii]...
%        = psa_jsp_gen_job_schedule_4(stJobListInfoAgent_ii);
%    [container_sequence_jsp_ii, jobshop_config] = psa_jsp_gen_job_schedule_8(stJobListInfoAgent_ii);
%    psa_jsp_plot_jobsolution(container_sequence_jsp_ii, ii+300);


    stJobListInfoAgent_ii.jobshop_config.iTotalMachineNum = ...
        ones(1, stJobListInfoAgent_ii.jobshop_config.iTotalMachine) * stJobListInfoAgent_ii.jobshop_config.iTotalJob
    %  -> [stJspScheduleTemplate, jobshop_config]
    [container_sequence_jsp_ii] = fsp_multi_mach_greedy_seq(stJobListInfoAgent_ii);
    
    [stBuildMachConfigOutput] = psa_fsp_bld_machfig_by_sch(stBerthJobInfo.fTimeFrameUnitInHour, stJobListInfoAgent_ii.stResourceConfig, container_sequence_jsp_ii);

    iMaxPrimeMoverUsageByGenSch0(ii) = stBuildMachConfigOutput.iMaxPrimeMoverUsageBySchOut;
    iMaxYardCraneUsageByGenSch0(ii)  = stBuildMachConfigOutput.iMaxYardCraneUsageBySchOut;
    stResourceConfigGenSch0(ii)      = stBuildMachConfigOutput.stResourceConfigSchOut;
    astMachineUsageInfoPerAgent(ii)     = stBuildMachConfigOutput.astMachineUsageInfoPerAgent;
    container_sequence_jsp_ii.stResourceConfig      = stResourceConfigGenSch0(ii).stResourceConfig;

    % consider dispatching
%    [container_jsp_solution_ii, stDebugOutput] = psa_jsp_dispatch_machine_02(container_sequence_jsp_ii);
%    stSchedule0_InfResourceModel(ii)             = container_jsp_solution_ii;
    % donot consider dispatching
    stSchedule0_InfResourceModel(ii)             = container_sequence_jsp_ii;
    clear stJobListInfoAgent_ii container_jsp_solution_ii container_sequence_jsp_ii stBuildMachConfigOutput;
    
    %% protection against 0, => zero searching range
    for mm = 1:1:stResourceConfigGenSch0(ii).stResourceConfig.iTotalMachine
        for tt = 1:1:stResourceConfigGenSch0(ii).stResourceConfig.stMachineConfig(mm).iNumPointTimeCap
            if stResourceConfigGenSch0(ii).stResourceConfig.stMachineConfig(mm).afTimePointAtCap(tt) >= aiStartTimeSlotPerAgent(ii) ... 
                  & stResourceConfigGenSch0(ii).stResourceConfig.stMachineConfig(mm).afMaCapAtTimePoint(tt) == 0
                stResourceConfigGenSch0(ii).stResourceConfig.stMachineConfig(mm).afMaCapAtTimePoint(tt) = 1;
            end
        end
    end
end

if stBerthJobInfo.iPlotFlag >= 4
    for ii = 1:1:stBerthJobInfo.iTotalAgent
        % dispatch first
%         [container_jsp_solution_ii, stDebugOutput] = psa_jsp_dispatch_machine_02(stSchedule0_InfResourceModel(ii));
%         stSchedule0_InfResourceModel(ii)             = container_jsp_solution_ii;
        
        psa_jsp_plot_jobsolution(stSchedule0_InfResourceModel(ii), ii+200);
        psa_jsp_plot_jobsolution_2(stSchedule0_InfResourceModel(ii), ii+210);
    end
    stSchedule0_InfResourceModel(3).iTotalMachineNum
    stSchedule0_InfResourceModel(4).iTotalMachineNum
end


for qq = 1:1:stBerthJobInfo.iTotalAgent

    if stBerthJobInfo.stJssProbStructConfig.isCriticalOperateSeq == 0
        if stBerthJobInfo.iFlagScheByGA == 0
            afProcessTime = zeros(jobshop_config.iTotalJob, 1);
            for ii = 1:1:jobshop_config.iTotalJob
                afProcessTime(ii) = sum(jobshop_config.jsp_process_time(ii).iProcessTime);
            end
            % iJobSeqInJspCfg is simply by processing time
            [afSortedProcessTime, iJobSeqInJspCfg] = sort(afProcessTime);
            stJobListInfoAgent(qq).aiJobSeqInJspCfg = iJobSeqInJspCfg;
        else
            stJobListInfoAgent(qq).jobshop_config.iTotalMachineNum(2) = ...
                round(stBerthJobInfo.iTotalPrimeMover / stBerthJobInfo.iTotalAgent);
            stJobListInfoAgent(qq).jobshop_config.iTotalMachineNum(3) = ...
                round(stBerthJobInfo.iTotalYardCrane / stBerthJobInfo.iTotalAgent);
            stJobListInfoAgent(qq).jobshop_config.stGASetting = stJobListInfoAgent(qq).stGASetting;
            [iJobSeqInJspCfg, stDebugOutput] = ...
                ga_fsp_bd_greedy(stJobListInfoAgent(qq).stJspScheduleTemplate, ...
                                    stJobListInfoAgent(qq).jobshop_config); % , stGASetting); % 20080211
            stJobListInfoAgent(qq).aiJobSeqInJspCfg = iJobSeqInJspCfg;
            if stBerthJobInfo.iPlotFlag >= 2
                iJobSeqInJspCfg
                stDebugOutput.aStdMakespanGen
                stDebugOutput.aAveMakespanGen
            end
        end
    end

end

stOutput.iMaxPrimeMoverUsageByGenSch0 = iMaxPrimeMoverUsageByGenSch0;
stOutput.iMaxYardCraneUsageByGenSch0  = iMaxYardCraneUsageByGenSch0;
stOutput.stJobListInfoAgent = stJobListInfoAgent;
stOutput.stResourceConfigGenSch0 = stResourceConfigGenSch0;
stOutput.astMachineUsageInfoPerAgent = astMachineUsageInfoPerAgent;
stOutput.stSchedule0_InfResourceModel = stSchedule0_InfResourceModel;
stOutput.astAgentMachineHourInfo = astAgentMachineHourInfo;