function stInputResAlloc = resalloc_get_inf_res_sche_fsp(stResAllocGenJspAgent)
% resource allocation to get schedule of flow-shop with infinite resoure
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%  
%
%The MIT License (MIT)
%
%Copyright (c) 2016 ZHAOZhengyi-tgx
%
%Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the "Software"), to deal in the Software without restriction, including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions:
%
%The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.
%
%THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%
% Module: Solution for Resource Allocation among Scheduling Agents 
% Template for Problem Input
% OUTPUT from the solver: schedule for each job's process, dispatching for each machine
% During this whole document, % is for line commenting, which means any line starting with a % will not be taken into parsing.
%
% all right reserved (c)2016
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% all right reserved, @2016, Sg.LongRenE@gmail.com
% 20080301 inherit iCriticalMachType 
% 20080422 debug
stSystemMasterConfig = stResAllocGenJspAgent.stSystemMasterConfig;
iPlotFlag = stSystemMasterConfig.iPlotFlag;

for aa = 1:1:stSystemMasterConfig.iTotalAgent
    disp(['Agent-# ', num2str(aa)]);
    astAgentJobListBiFspCfg(aa) = fsp_load_joblist_parameter(stResAllocGenJspAgent.strFileAgentJobList(aa).strFilename);

    astAgentJobListBiFspCfg(aa).stResourceConfig.iCriticalMachType = stResAllocGenJspAgent.stSystemMasterConfig.iCriticalMachType; %20080301
    
    astAgentJobListJspCfg(aa) = cvt_jsp_cfg_by_gen_bifsp(astAgentJobListBiFspCfg(aa));
end

nTotalMachType = stResAllocGenJspAgent.stSystemMasterConfig.iTotalMachType;

for aa = 1:1:stResAllocGenJspAgent.stSystemMasterConfig.iTotalAgent
    %% construct BiFspConfig with Infinite Resource
    nTotalJobs = astAgentJobListBiFspCfg(aa).stAgentBiFSPJobMachConfig.iTotalForwardJobs + astAgentJobListBiFspCfg(aa).stAgentBiFSPJobMachConfig.iTotalReverseJobs;
    stJspCfgInfRes = astAgentJobListJspCfg(aa);
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

    if iPlotFlag >= 5
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
            astAgentJobListBiFspCfg(qq).aiJobSeqInJspCfg = iJobSeqInJspCfg; % 20080422
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
            astAgentJobListBiFspCfg(qq).aiJobSeqInJspCfg = iJobSeqInJspCfg;  % 20080422
            if stSystemMasterConfig.iPlotFlag >= 1
                disp(['aiJobSeqInJspCfg: ', num2str(iJobSeqInJspCfg)]);
                disp(['aStdMakespanGen:  ', num2str(stDebugOutput.aStdMakespanGen)]);
                disp(['aAveMakespanGen: ', num2str(stDebugOutput.aAveMakespanGen)]);
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
