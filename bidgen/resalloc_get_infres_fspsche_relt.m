function stInputResAlloc = resalloc_get_infres_fspsche_relt(stResAllocGenJspAgent)
% 20080301 inherit iCriticalMachType 
% 20080323 Add iReleaseTimeSlotGlobal
global epsilon_time;

stSystemMasterConfig = stResAllocGenJspAgent.stSystemMasterConfig;
iPlotFlag = stSystemMasterConfig.iPlotFlag;

for aa = 1:1:stSystemMasterConfig.iTotalAgent
    astAgentJobListBiFspCfg(aa) = fsp_load_joblist_parameter(stResAllocGenJspAgent.strFileAgentJobList(aa).strFilename);

    astAgentJobListBiFspCfg(aa).stResourceConfig.iCriticalMachType = stResAllocGenJspAgent.stSystemMasterConfig.iCriticalMachType; %20080301
    
    atStartTime_datenum(aa) = datenum(stResAllocGenJspAgent.stAgentJobInfo(aa).atClockAgentJobStart.aClockYearMonthDateHourMinSec); % + epsilon_time;

end

[tEarliestStartTime_datenum, idxAgentEarlistStart ] = min(atStartTime_datenum);

for aa = 1:1:stSystemMasterConfig.iTotalAgent
    if aa ~= idxAgentEarlistStart
        tStartTimeRelativeGlobal = atStartTime_datenum(aa) - tEarliestStartTime_datenum;
        if tStartTimeRelativeGlobal <= epsilon_time
           aiStartTimeSlotPerAgent(aa) = 0;
        else
           aiStartTimeSlotPerAgent(aa) = round(tStartTimeRelativeGlobal * 24 * 60/astAgentJobListBiFspCfg(aa).stAgentBiFSPJobMachConfig.fTimeUnit_Min);
        end
    else
        aiStartTimeSlotPerAgent(aa) = 0;
    end
    aiStartResourceFramePerAgent(aa) = ...
        floor( ...
        aiStartTimeSlotPerAgent(aa) * astAgentJobListBiFspCfg(aa).stAgentBiFSPJobMachConfig.fTimeUnit_Min ...
        /60 /stSystemMasterConfig.fTimeFrameUnitInHour...
        );
    astAgentJobListBiFspCfg(aa).stAgentBiFSPJobMachConfig.iReleaseTimeSlotGlobal = aiStartTimeSlotPerAgent(aa);

end % 20080322

for aa = 1:1:stSystemMasterConfig.iTotalAgent
    astAgentJobListJspCfg(aa) = cvt_jsp_cfg_by_gen_bifsp(astAgentJobListBiFspCfg(aa));
%     [stJspScheduleTemplate] = jsp_constr_sche_struct_by_cfg(astAgentJobListJspCfg(aa));
%     astAgentJobListJspCfg(aa).stJspScheduleTemplate = stJspScheduleTemplate;
end % 20080322


nTotalMachType = stResAllocGenJspAgent.stSystemMasterConfig.iTotalMachType;

for aa = 1:1:stSystemMasterConfig.iTotalAgent
    %% construct BiFspConfig with Infinite Resource
    nTotalJobs = astAgentJobListBiFspCfg(aa).stAgentBiFSPJobMachConfig.iTotalForwardJobs + ...
        astAgentJobListBiFspCfg(aa).stAgentBiFSPJobMachConfig.iTotalReverseJobs;
    stJspCfgInfRes = astAgentJobListJspCfg(aa);
%    stJspCfgInfRes.iReleaseTimeSlotGlobal
    for mm = 1:1:nTotalMachType
        if mm == stSystemMasterConfig.iCriticalMachType
            stJspCfgInfRes.stResourceConfig.iaMachCapOnePer(mm) = 1;
            stJspCfgInfRes.stResourceConfig.stMachineConfig(mm).afMaCapAtTimePoint = 1;
        else
            stJspCfgInfRes.stResourceConfig.iaMachCapOnePer(mm) = nTotalJobs;
            stJspCfgInfRes.stResourceConfig.stMachineConfig(mm).afMaCapAtTimePoint = nTotalJobs;
        end
    end
    iJobSeqInJspCfg = stJspCfgInfRes.aiJobSeqInJspCfg;
    [stFspSchedule] = jsp_constr_sche_struct_by_cfg(stJspCfgInfRes);
    
    [stFspSchedule] = fsp_bd_multi_m_t_greedy_by_seq(stFspSchedule, stJspCfgInfRes, iJobSeqInJspCfg);
%     [stFspSchedule, stJspCfg] = fsp_gen_job_sche_ch_seq_(stGeneticCfgBiFspInfRes(aa), iJobSeqInJspCfg);
    astFspScheduleInfRes(aa) = stFspSchedule;

    [stBuildMachConfigOutput] = jsp_bld_machfig_by_sch(stSystemMasterConfig, stFspSchedule);
    astMachUsageInfRes(aa) = stBuildMachConfigOutput;
%%    astMachUsageInfRes(aa).stResourceConfig.iCriticalMachType = stJspCfgInfRes.stResourceConfig.iCriticalMachType;
%input('any key')

    if iPlotFlag >= 0
        jsp_plot_jobsolution_2(astFspScheduleInfRes(aa), 10 * aa + 2);
    end
end

%% get total work hour per machine
for qq = 1:1:stSystemMasterConfig.iTotalAgent
    afTotalWorkHourPerMachine = zeros(1, nTotalMachType);
    for mm = 1:1:nTotalMachType
        afTotalWorkHourPerMachine(mm) = sum(astAgentJobListBiFspCfg(qq).astMachineProcTimeOnMachine(mm).aForwardTimeMachineCycle) + ...
            sum(astAgentJobListBiFspCfg(qq).astMachineProcTimeOnMachine(mm).aReverseTimeMachineCycle);
    end
    astAgentMachineHourInfo(qq).afTotalWorkHourPerMachine = afTotalWorkHourPerMachine;

    if astAgentJobListJspCfg(qq).stJssProbStructConfig.isCriticalOperateSeq == 0  %%% agent dependent
        if astAgentJobListJspCfg(qq).stGASetting.isSequecingByGA == 0
            afProcessTime = zeros(astAgentJobListJspCfg(qq).iTotalJob, 1);
            for ii = 1:1:astAgentJobListJspCfg(qq).iTotalJob
                afProcessTime(ii) = sum(astAgentJobListJspCfg(qq).jsp_process_time(ii).iProcessTime);
            end
            % iJobSeqInJspCfg is simply by processing time
            [afSortedProcessTime, iJobSeqInJspCfg] = sort(afProcessTime);
            astAgentJobListJspCfg(qq).aiJobSeqInJspCfg = iJobSeqInJspCfg;
        else
            jobshop_config_qq = astAgentJobListJspCfg(qq);
            for mm = 1:1:nTotalMachType
                jobshop_config_qq.iTotalMachineNum(mm) = round(stResAllocGenJspAgent.stResourceConfig.iaMachCapOnePer(mm) ...
                    / stSystemMasterConfig.iTotalAgent);
            end
            jobshop_config_qq.stGASetting = astAgentJobListJspCfg(qq).stGASetting;
            stSchedulePartial = jsp_constr_sche_struct_by_cfg(astAgentJobListJspCfg(qq));
            [iJobSeqInJspCfg, stDebugOutput] = ga_fsp_bd_greedy(stSchedulePartial, jobshop_config_qq); % , stGASetting); % 20080211
            astAgentJobListJspCfg(qq).aiJobSeqInJspCfg = iJobSeqInJspCfg;
            if stSystemMasterConfig.iPlotFlag >= 2
                iJobSeqInJspCfg
                stDebugOutput.aStdMakespanGen
                stDebugOutput.aAveMakespanGen
            end
        end
    end

end

stInputResAlloc.stResAllocGenJspAgent = stResAllocGenJspAgent;
stInputResAlloc.astAgentJobListBiFspCfg = astAgentJobListBiFspCfg;
stInputResAlloc.astAgentJobListJspCfg = astAgentJobListJspCfg;
stInputResAlloc.astFspScheduleInfRes = astFspScheduleInfRes;
stInputResAlloc.astMachUsageInfRes = astMachUsageInfRes;
stInputResAlloc.astAgentMachineHourInfo = astAgentMachineHourInfo;
