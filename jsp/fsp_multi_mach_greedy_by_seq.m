function [fsp_bidir_schedule_partial] = fsp_multi_mach_greedy_by_seq(fsp_bidir_schedule_partial, jobshop_config, iJobSeqInJspCfg)
% flow-shop-problem multiple machine greedy algorithm by sequencing
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
% [fsp_bidir_schedule_partial] = fsp_multi_mach_greedy_by_seq(fsp_bidir_schedule_partial, jobshop_config, iJobSeqInJspCfg)
% flow shop problem, with multi-machine capacity, greedy algorithm, with known sequencing
%
%

%  jobshop_config.iTotalJob
%  jobshop_config.stProcessPerJob
stSolutionJobSet = fsp_bidir_greedy_sche_by_seq(jobshop_config, iJobSeqInJspCfg);
fsp_bidir_schedule_partial.stJobSet = stSolutionJobSet;
fsp_bidir_schedule_partial.iTotalMachineNum = jobshop_config.iTotalMachineNum;
iMaxEndTime = 0;
for ii = 1:1:jobshop_config.iTotalJob
%      stSolutionJobSet(ii).fProcessEndTime
    if iMaxEndTime < stSolutionJobSet(ii).fProcessEndTime(jobshop_config.stProcessPerJob(ii))
        iMaxEndTime = stSolutionJobSet(ii).fProcessEndTime(jobshop_config.stProcessPerJob(ii));
    end
end
fsp_bidir_schedule_partial.iMaxEndTime = iMaxEndTime;
