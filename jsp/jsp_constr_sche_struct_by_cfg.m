function [stJspSchedule] = jsp_constr_sche_struct_by_cfg(stJspCfg)
% job-shop-problem to construct schedule structure by configuration
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
% History
% YYYYMMDD  Notes
% 20071023  created from template of port discharge-load case,
%

%%% Prototype of Output
stJspSchedule.iTotalJob = [];
stJspSchedule.iTotalMachine = [];
stJspSchedule.iTotalMachineNum = [];
stJspSchedule.stProcessPerJob = [];
stJspSchedule.stJobSet = ...
  struct('fProcessStartTime', [], 'fProcessEndTime', [], 'iProcessStartTime', [], 'iProcessEndTime', [], 'iProcessMachine', [], 'iProcessMachineId', []);
stJspSchedule.iMaxEndTime = [];
stJspSchedule.stResourceConfig = [];
stJspSchedule.fTimeUnit_Min    = [];


%%%%
if isfield(stJspCfg, 'stResourceConfig')
    stResourceConfig = stJspCfg.stResourceConfig;
    for mm = 1:1:stJspCfg.iTotalMachine
        nTotalMachOnePeriod(mm) = max(stResourceConfig.stMachineConfig(mm).afMaCapAtTimePoint);
        stJspSchedule.iTotalMachineNum(mm) = max([stResourceConfig.iaMachCapOnePer(mm), nTotalMachOnePeriod(mm)]);
    end
    stJspSchedule.stResourceConfig = stResourceConfig; %20070801
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%% jsp format
stJspSchedule.iTotalJob = stJspCfg.iTotalJob;
stJspSchedule.iTotalMachine = stJspCfg.iTotalMachine;
stJspSchedule.stProcessPerJob = stJspCfg.stProcessPerJob;
stJspSchedule.fTimeUnit_Min    = stJspCfg.fTimeUnit_Min;

for ii = 1:1:stJspSchedule.iTotalJob
    for jj = 1:1:stJspCfg.stProcessPerJob(ii)
        stJspSchedule.stJobSet(ii).iProcessMachine(jj) = stJspCfg.jsp_process_machine(ii).iProcessMachine(jj);
    end
    
    stJspSchedule.stJobSet(ii).iProcessStartTime  = zeros(stJspSchedule.stProcessPerJob(ii), 1);
    stJspSchedule.stJobSet(ii).iProcessEndTime    = zeros(stJspSchedule.stProcessPerJob(ii), 1);
    stJspSchedule.stJobSet(ii).fProcessStartTime  = zeros(stJspSchedule.stProcessPerJob(ii), 1);
    stJspSchedule.stJobSet(ii).fProcessEndTime    = zeros(stJspSchedule.stProcessPerJob(ii), 1);
    
end
