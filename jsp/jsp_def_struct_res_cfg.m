function [stResourceConfig, stMachineConfig] = jsp_def_struct_res_cfg()
% job shop problem, define struct of resource configuration
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
% 20071115  Created, add iaMachCapOnePer
% 20080211  iCriticalMachType

global DEF_MAX_NUM_MACHINE_TYPE;

stMachineConfig = struct('strName', [], ...
    'iNumPointTimeCap', [], ...
    'afTimePointAtCap', [], ...
    'afMaCapAtTimePoint', []);
    
stResourceConfig = struct('iTotalMachine', DEF_MAX_NUM_MACHINE_TYPE, ...
    'iaMachCapOnePer', ones(DEF_MAX_NUM_MACHINE_TYPE, 1), ...
    'stMachineConfig', stMachineConfig, ...
    'iCriticalMachType', 1, ...
    'fTimeUnitInHour', 1); % 20080211

