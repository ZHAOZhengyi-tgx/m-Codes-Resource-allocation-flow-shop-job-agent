function [fsp_bidir_schedule_partial] = fsp_bd_multi_m_t_greedy_by_seq(stJspScheduleTemplate, jobshop_config, iJobSeqInJspCfg)
% flow-shop-problem build multi-machine time-slot, a greedy algorithm by
% sequencing
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
% [fsp_bidir_schedule_partial] = fsp_bd_multi_m_t_greedy_by_seq(stJspScheduleTemplate, jobshop_config, iJobSeqInJspCfg)
% bi-directional flow shop problem, with multi-machine capacity, multi-period, greedy algorithm, with known sequencing
%
%
% History
% YYYYMMDD  Notes
% 20071127  Debugging for negative time
% 20080323 Add iReleaseTimeSlotGlobal

stSolutionJobSet = stJspScheduleTemplate.stJobSet;

%%%%%%% Read input and create short-cut reference variables
astMachineConfig = jobshop_config.stResourceConfig.stMachineConfig;
for mm = 1:1:jobshop_config.iTotalMachine
	astMachineTimeCapInfo(mm).MaxVirtualMach = max(astMachineConfig(mm).afMaCapAtTimePoint);
	astMachineTimeCapInfo(mm).iStartingNumMach = astMachineConfig(mm).afMaCapAtTimePoint(1);
	astMachineTimeCapInfo(mm).iLenPointsMachCap = astMachineConfig(mm).iNumPointTimeCap;
end

%%% Calculate total machine time
afTotalMachineTime = zeros(jobshop_config.iTotalMachine, 1);
for jj = 1:1:jobshop_config.iTotalJob
    if jobshop_config.iJobType(jj) == 1  %% forward flow shop, Proc-1 one Mach-1, Proc-2 one Mach-2, Proc-3 one Mach-3
        for mm = 1:1:jobshop_config.iTotalMachine 
            afTotalMachineTime(mm) = afTotalMachineTime(mm) + jobshop_config.jsp_process_time(jj).iProcessTime(mm);
        end
        
    elseif jobshop_config.iJobType(jj) == 2  %% reverse flow shop, Proc-1 one Mach-3, Proc-2 one Mach-2, Proc-3 one Mach-1
        for mm = 1:1:jobshop_config.iTotalMachine 
            afTotalMachineTime(mm) = afTotalMachineTime(mm) + jobshop_config.jsp_process_time(jj).iProcessTime(jobshop_config.iTotalMachine + 1 - mm);
        end
    
    else
        disp('warning: iJobType not defined')
    end
end

%%%%%% Initialize a Machine Common Pool, where all machines are available at very beginning
for mm = 1:1:jobshop_config.iTotalMachine 
    for kk = 1:1:astMachineTimeCapInfo(mm).MaxVirtualMach  %% jobshop_config.iTotalMachineNum(mm)
        stMachineDoingJobSet(mm).aTimeSetPreviousJobCompleted(kk) = ...
            jobshop_config.iReleaseTimeSlotGlobal - afTotalMachineTime(mm); % 20080323
        stMachineDoingJobSet(mm).iMachineId(kk) = kk;
        stMachineDoingJobSet(mm).aJob_Id(kk) = 0;
    end
end

tEstimateMaCapFromPrevJob = 0;  %% the time point to estimate machine capacity
for ii = 1:1:jobshop_config.iTotalJob
    iJobId = iJobSeqInJspCfg(ii);

   timeTotalProcInJob = 0;
   for jjProc = 1:1:jobshop_config.stProcessPerJob(iJobId)
       timeTotalProcInJob = timeTotalProcInJob + jobshop_config.jsp_process_time(iJobId).iProcessTime(jjProc);
   end
   
   for mm = 1:1:jobshop_config.iTotalMachine
       [nMaxMachRealTimeMultiPeriod, iIndex] = ...
           calc_lut_min_between(astMachineConfig(mm).afMaCapAtTimePoint, astMachineConfig(mm).afTimePointAtCap, ...
           tEstimateMaCapFromPrevJob, tEstimateMaCapFromPrevJob + timeTotalProcInJob);
       anMaxMachRealTimeMultiPeriod(mm) = nMaxMachRealTimeMultiPeriod;
   end
    
    %% look for the earliest available machine
    for mm = 1:1:jobshop_config.iTotalMachine
        timeEarliestByMach(mm) = stMachineDoingJobSet(mm).aTimeSetPreviousJobCompleted(1);
        iMachineIdminTime(mm) = stMachineDoingJobSet(mm).iMachineId(1);
        index_min_MachineId(mm) = 1;
        for jj = 2:1:anMaxMachRealTimeMultiPeriod(mm)
            if timeEarliestByMach(mm) > stMachineDoingJobSet(mm).aTimeSetPreviousJobCompleted(jj)
                timeEarliestByMach(mm) = stMachineDoingJobSet(mm).aTimeSetPreviousJobCompleted(jj);
                iMachineIdminTime(mm) = stMachineDoingJobSet(mm).iMachineId(jj);
                index_min_MachineId(mm) = jj;
            end
        end
    end
    
    %% assign the MachineId
    for jj = 1:1:jobshop_config.stProcessPerJob(iJobId)
%         iJobId, jj
%         size_stSolutionJobSet = size(stSolutionJobSet)
%         size_ProcMach = size(stSolutionJobSet(iJobId).iProcessMachine)
        mMachineType = stSolutionJobSet(iJobId).iProcessMachine(jj);
        stSolutionJobSet(iJobId).iProcessMachineId(jj) = index_min_MachineId(mMachineType);
        tEstimateProcessStart(jj) = timeEarliestByMach(mMachineType);
    end
    
    %% Estimate job start time by process
    for jjProc = 1:1:jobshop_config.stProcessPerJob(iJobId)
        tEstimateJobStartByProc(jjProc) = tEstimateProcessStart(jjProc);
        for jjPrevProc = 1:1:jjProc-1
            tEstimateJobStartByProc(jjProc) = tEstimateJobStartByProc(jjProc) ...
               - jobshop_config.jsp_process_time(iJobId).iProcessTime(jjPrevProc);
        end
    end

    stSolutionJobSet(iJobId).iProcessStartTime(1) = max(tEstimateJobStartByProc);
    stSolutionJobSet(iJobId).iProcessEndTime(1) = stSolutionJobSet(iJobId).iProcessStartTime(1) ...
        + jobshop_config.jsp_process_time(iJobId).iProcessTime(1);
    
    tEstimateMaCapFromPrevJob = stSolutionJobSet(iJobId).iProcessStartTime(1);
    
    for jj = 2:1:jobshop_config.stProcessPerJob(iJobId)
        stSolutionJobSet(iJobId).iProcessStartTime(jj) = stSolutionJobSet(iJobId).iProcessEndTime(jj-1);
        stSolutionJobSet(iJobId).iProcessEndTime(jj) = stSolutionJobSet(iJobId).iProcessStartTime(jj) ...
            + jobshop_config.jsp_process_time(iJobId).iProcessTime(jj);
    end

    %% update the stMachineDoingJobSet
    for jj = 1:1:jobshop_config.stProcessPerJob(iJobId)
        mMachineType = stSolutionJobSet(iJobId).iProcessMachine(jj);
        stMachineDoingJobSet(mMachineType).aTimeSetPreviousJobCompleted(stSolutionJobSet(iJobId).iProcessMachineId(jj)) = ...
            stSolutionJobSet(iJobId).iProcessEndTime(jj);
    
    end
end
%jobshop_config
%% detection of negative time % 20071127
for jj = 1:1:jobshop_config.iTotalJob
    if jj == 1
        tEarlistStartTime = stSolutionJobSet(jj).iProcessStartTime(1);
    else
        if tEarlistStartTime > stSolutionJobSet(jj).iProcessStartTime(1)
            tEarlistStartTime = stSolutionJobSet(jj).iProcessStartTime(1);
        end
    end
end
if tEarlistStartTime < jobshop_config.iReleaseTimeSlotGlobal
    %% shift all previous job's time 
    tTimeShift = abs(tEarlistStartTime - jobshop_config.iReleaseTimeSlotGlobal);
%     tEarlistStartTime
    for jj = 1:1:jobshop_config.iTotalJob
%         iJobId = iJobSeqInJspCfg(jj);
%         for ii = 1:1:jobshop_config.stProcessPerJob(jj) % vector add is
%         faster
            stSolutionJobSet(jj).iProcessStartTime = stSolutionJobSet(jj).iProcessStartTime + tTimeShift;
            stSolutionJobSet(jj).iProcessEndTime = stSolutionJobSet(jj).iProcessEndTime + tTimeShift;
%         end
    end
end  % 20071127

for ii = 1:1:jobshop_config.iTotalJob
    stSolutionJobSet(ii).fProcessStartTime = stSolutionJobSet(ii).iProcessStartTime;
    stSolutionJobSet(ii).fProcessEndTime   = stSolutionJobSet(ii).iProcessEndTime;
end

fsp_bidir_schedule_partial = stJspScheduleTemplate; 
fsp_bidir_schedule_partial.stJobSet = stSolutionJobSet;
iMaxEndTime = 0;
for ii = 1:1:jobshop_config.iTotalJob
    if iMaxEndTime < stSolutionJobSet(ii).fProcessEndTime(jobshop_config.stProcessPerJob(ii))
        iMaxEndTime = stSolutionJobSet(ii).fProcessEndTime(jobshop_config.stProcessPerJob(ii));
    end
end
fsp_bidir_schedule_partial.iMaxEndTime = iMaxEndTime;
