function [stJspCfg] = cvt_jsp_cfg_by_gen_bifsp(stAgentJobListBiFsp)
% convert to job-shop-problem from genetic bi-directional flow-shop-problem
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
%
% naming convention of jobshop_config, inherit from reading Erhan's paper
% History
% YYYYMMDD Notes
% 20070629  reorganize output,
% 20070701  modification to relax the critical operational sequencing
% 20070801  add stResourceConfig into output struct
% 20071109  add GA Setting
% 20071109  add fProcessMachine
% 20071212  aiJobSeqInJspCfg
% 20080323  iReleaseTimeSlotGlobal
stJspCfg = jsp_def_struct_cfg();

stAgentBiFSPJobMachConfig = stAgentJobListBiFsp.stAgentBiFSPJobMachConfig;

nTotalForwardJobs = stAgentBiFSPJobMachConfig.iTotalForwardJobs;
nTotalReverseJobs = stAgentBiFSPJobMachConfig.iTotalReverseJobs;

nTotalJobs = nTotalForwardJobs + nTotalReverseJobs;
for jj = 1:1:nTotalJobs
    jsp_process_machine(jj) = struct('iProcessMachine', []); 
end

%%%%%%%%%% Construct stJspCfg
stJspCfg.iTotalMachine = stAgentBiFSPJobMachConfig.iTotalMachType;
stJspCfg.iTotalJob = nTotalJobs;
stJspCfg.stProcessPerJob = stJspCfg.iTotalMachine * ones(1,nTotalJobs);
for ii = 1:1:stJspCfg.iTotalJob
    if ii <= nTotalForwardJobs
        stJspCfg.iJobType(ii) = 1; % For forward job, 
        for mm = 1:1:stJspCfg.iTotalMachine
            stJspCfg.jsp_process_time(ii).iProcessTime(mm) = stAgentJobListBiFsp.astMachineProcTimeOnMachine(mm).aForwardTimeMachineCycle(ii);
        end
        stJspCfg.jsp_process_time(ii).fProcessTime = stJspCfg.jsp_process_time(ii).iProcessTime;  % 20071109
    else
        stJspCfg.iJobType(ii) = 2; % For forward job, 
        for mm = 1:1:stJspCfg.iTotalMachine
            stJspCfg.jsp_process_time(ii).iProcessTime(mm) = stAgentJobListBiFsp.astMachineProcTimeOnMachine(stJspCfg.iTotalMachine + 1 - mm).aReverseTimeMachineCycle(ii - nTotalForwardJobs);
        end
        stJspCfg.jsp_process_time(ii).fProcessTime = stJspCfg.jsp_process_time(ii).iProcessTime;   % 20071109
    end
    
    if stJspCfg.iJobType(ii) == 1
        for mm = 1:1:stJspCfg.iTotalMachine
            stJspCfg.jsp_process_machine(ii).iProcessMachine(mm) = mm;
        end
    else
        for mm = 1:1:stJspCfg.iTotalMachine
            stJspCfg.jsp_process_machine(ii).iProcessMachine(mm) = stJspCfg.iTotalMachine + 1 - mm;
        end
    end
    stJspCfg.aJobWeight(ii) = 1;
end

%%% Machine Configuration depends on whether it is time variant
if isfield(stAgentJobListBiFsp, 'stResourceConfig')
    stResourceConfig = stAgentJobListBiFsp.stResourceConfig;
    for mm = 1:1:stJspCfg.iTotalMachine
        nTotalMachOnePeriod(mm) = max(stResourceConfig.stMachineConfig(mm).afMaCapAtTimePoint);
        stJspCfg.iTotalMachineNum(mm) = max([stResourceConfig.iaMachCapOnePer(mm), nTotalMachOnePeriod(mm)]);
    end
    stJspCfg.stResourceConfig = stResourceConfig; %20070801
end

if isfield(stAgentJobListBiFsp, 'aiJobSeqInJspCfg')
    stJspCfg.aiJobSeqInJspCfg = stAgentJobListBiFsp.aiJobSeqInJspCfg;
else
    stJspCfg.aiJobSeqInJspCfg = 1:nTotalJobs;
end

stJspCfg.iReleaseTimeSlotGlobal = stAgentBiFSPJobMachConfig.iReleaseTimeSlotGlobal; % 20080323

% 20070701 
stJspCfg.stJssProbStructConfig = stAgentJobListBiFsp.stJssProbStructConfig;
%% it calls the fastest scheduler to generate the temperary solution, it is
%% partial solution without dispatching information, only use the
%% iTotalTimeSlot
[stJspSchedule] = jsp_constr_sche_struct_by_cfg(stJspCfg);
[stJspSchedule] = fsp_bd_multi_m_t_greedy_by_seq(stJspSchedule, stJspCfg, [1:nTotalJobs]);

stJspCfg.iTotalTimeSlot = stJspSchedule.iMaxEndTime;
stJspCfg.strJobListInputFilename = stAgentJobListBiFsp.strJobListInputFilename;

%% to minimize the make span

%% assigning job due time to each each job
% for ii = 1:1:stJspCfg.iTotalJob
%     stJspCfg.aJobDueTime(ii) = stJspCfg.iTotalTimeSlot;
% end

stJspCfg.iPlotFlag  = stAgentJobListBiFsp.stAgentBiFSPJobMachConfig.iPlotFlag;
stJspCfg.fTimeUnit_Min = stAgentJobListBiFsp.stAgentBiFSPJobMachConfig.fTimeUnit_Min; % 20070629
stJspCfg.iOptRule = stAgentJobListBiFsp.stAgentBiFSPJobMachConfig.iOptRule;           % 20070701

stJspCfg.stGASetting = stAgentJobListBiFsp.stGASetting; %20071109