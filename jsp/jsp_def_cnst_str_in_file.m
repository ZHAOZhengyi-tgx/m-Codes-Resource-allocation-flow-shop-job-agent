function [stJspConstStringLoadFile] = jsp_def_cnst_str_in_file()
% job shop problem, define constant structure in file
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

%  jsp_def_cnst_str_in_file
% The string for config label in [] is constant:
% The string for entry label or header is constant
% History
% YYYYMMDD  Notes
% 20071211  Add Job SortedIndex
% 20071220  add iSolverPackage
% 20091216  Batch Job Arrival
global DEF_MAX_NUM_MACHINE_TYPE;

jsp_glb_define();

%% OnePeriodMachine Capacity, depends on num. of machine type
stConfigOnePerMachCapLabel.strConstMachineNumOnPer_cfg = '[MACHINE_ONE_PERIOD_CAP_INFO]';
stConfigOnePerMachCapLabel.strConstMachineNumOnPer_hdr = 'TOTAL_MACHINE_PER_TYPE_';

%% Machine Name information
stConfigMachNameLabel.strConstMachineName_cfg = '[MACHINE_NAME_INFO]';
stConfigMachNameLabel.strConstMachineName_hdr = 'NAME_MACHINE_TYPE_';

%% Machine Multi-Period Information
stConfigMachTotalPeriodLabel.strConstMachineInfo_cfg = '[MACHINE_MULTI_PERIOD_INFO]';
stConfigMachTotalPeriodLabel.strConstMachineInfo_hdr = 'NUM_TIME_POINT_SLOT_MACH_TYPE_';

%% Job Shop Schedeling problem configuration
astrJSSProbStructCfg.strConstJSSProbStructCfgLabel = '[JSS_PROBLEM_CONFIG]';
astrJSSProbStructCfg.strConstJSSP_PreemptLabel = 'IS_PREEMPTIVE';
astrJSSProbStructCfg.strConstJSSP_WaitInProcLabel  = 'IS_WAIT_IN_PROCESS';
astrJSSProbStructCfg.strConstJSSP_COSLabel = 'IS_CRITICAL_OPERATION_SEQUENCE';
astrJSSProbStructCfg.strConstJSSP_ObjFuncDefLabel = 'OBJ_OPTION';
astrJSSProbStructCfg.strConstJSSP_MachReleaseLabel = 'IS_MACHINE_RELEASE_IMMEDIATELY_AFTER_PROC';
astrJSSProbStructCfg.strConstJSSP_SemiCOSLabel = 'IS_SEMI_COS';
astrJSSProbStructCfg.strConstJSSP_FlexiCOSLabel = 'IS_FLEXI_COS';

%% Batch Job Arrival config % 20091216
astrDynamicBatchJobArrival.strConstJobArrivalStructMeanTimeCfgLabel = '[BATCH_JOB_ARRIVAL_MEAN_TIME_CONFIG]';
astrDynamicBatchJobArrival.strConstJobArrivalTimeMean = 'JOB_ARRIVAL_MEAN_TIME_BATCH_';

astrDynamicBatchJobArrival.strConstJobArrivalStructStDevTimeCfgLabel = '[BATCH_JOB_ARRIVAL_TIME_STD_CONFIG]';
astrDynamicBatchJobArrival.strConstJobArrivalTimeStDev = 'JOB_ARRIVAL_STD_TIME_BATCH_';

%%% Constant String for Genetic Jobshop 
stJspMasterPropertyLabel.strConstWholeConfigLabel = '[JOB_MACHINE_CONFIG]';
stJspMasterPropertyLabel.strConstAlgoChoice = 'IP_PACKAGE';
stJspMasterPropertyLabel.strConstOptRules = 'OPT_RULE';
stJspMasterPropertyLabel.strConstTimeUnit = 'TIME_UNIT';
stJspMasterPropertyLabel.strConstTotalJob = 'TOTAL_JOB';
stJspMasterPropertyLabel.strConstTotalMachine = 'TOTAL_MACHINE';
stJspMasterPropertyLabel.strConstTotalTimeSlot = 'TOTAL_TIME_SLOT';
stJspMasterPropertyLabel.strConstPlotFlag = 'PLOT_FLAG';
stJspMasterPropertyLabel.strConstTotalBatchPlan = 'TOTAL_BATCH_PLANNING';

%%% Constant string for genetic bidir flowshop
stBiFspStrCfgMstrLabel.strConstWholeConfigLabel = '[AGENT_JOB_LIST_CONFIG]';
stBiFspStrCfgMstrLabel.strConstTotalForwardJob = 'TOTAL_FORWARD_JOBS';
stBiFspStrCfgMstrLabel.strConstTotalReverseJob = 'TOTAL_REVERSE_JOBS';
stBiFspStrCfgMstrLabel.strOptionPackageIP = 'IP_PACKAGE';
stBiFspStrCfgMstrLabel.strConstOptRules = 'OPT_RULE';
stBiFspStrCfgMstrLabel.strConstTotalMachineType = 'TOTAL_MACHINE_TYPE';
stBiFspStrCfgMstrLabel.strConstPlotFlag        = 'PLOT_FLAG';
stBiFspStrCfgMstrLabel.strConstTimeUnit = 'TIME_UNIT_MINUTE';
stBiFspStrCfgMstrLabel.strConstCriticalMachType = 'CRITICAL_MACHINE_TYPE';
%% Config Master Label
stBiFspStrCfgMstrLabel.iTotalVarRead = 8;


%% variable length string struct, define with a default length
%%%%%
for mm = 1:1:DEF_MAX_NUM_MACHINE_TYPE
    %% Machine Capacity Lookup Table
    astMachineProcLabel(mm).strConstMachLUTTimePt_cfg = sprintf('[TIME_POINT_MACH_CAPACITY_TYPE_%d]', mm);
    astMachineProcLabel(mm).strConstMachLUTTimePt_hdr = sprintf('TIME_POINT_MACH_TYPE_%d_CAP_', mm);
    astMachineProcLabel(mm).strConstMachLUTCapPt_cfg = sprintf('[MACH_CAPACITY_TIME_TYPE_%d]', mm);
    astMachineProcLabel(mm).strConstMachLUTCapPt_hdr = sprintf('MACH_TYPE_%d_CAP_TIME_POINT_', mm);
    %% process time
    astMachineProcLabel(mm).strConstForwardJobMachTime_cfg = sprintf('[FORWARD_MACH_TIME_TYPE_%d]', mm);
    astMachineProcLabel(mm).strConstForwardJobMachTime_hdr = sprintf('MACH_TYPE_%d_TIME_FORWARD_', mm);
    astMachineProcLabel(mm).strConstReverseJobMachTime_cfg = sprintf('[REVERSE_MACH_TIME_TYPE_%d]', mm);
    astMachineProcLabel(mm).strConstReverseJobMachTime_hdr = sprintf('MACH_TYPE_%d_TIME_REVERSE_', mm);
    %% release time after process
    astMachineProcLabel(mm).strConstForwardJobMachRelTime_cfg = sprintf('[FORWARD_MACH_RELEASE_TIME_TYPE_%d]', mm);
    astMachineProcLabel(mm).strConstForwardJobMachRelTime_hdr = sprintf('MACH_TYPE_%d_RELEASE_TIME_AFTER_FORWARD_', mm);
    astMachineProcLabel(mm).strConstReverseJobMachRelTime_cfg = sprintf('[REVERSE_MACH_RELEASE_TIME_TYPE_%d]', mm);
    astMachineProcLabel(mm).strConstReverseJobMachRelTime_hdr = sprintf('MACH_TYPE_%d_RELEASE_TIME_AFTER_REVERSE_', mm);
    
    %% Mahine Id for manual dispatching
    astMachineProcLabel(mm).strConstForwardJobMachId_cfg = sprintf('[FORWARD_MACH_ID_TYPE_%d]', mm);
    astMachineProcLabel(mm).strConstForwardJobMachId_hdr = sprintf('MACH_TYPE_%d_ID_FORWARD_JOB_', mm);
    astMachineProcLabel(mm).strConstReverseJobMachId_cfg = sprintf('[REVERSE_MACH_ID_TYPE_%d]', mm);
    astMachineProcLabel(mm).strConstReverseJobMachId_hdr = sprintf('MACH_TYPE_%d_ID_REVERSE_JOB_', mm);
end

stResAllocStrCfgMstrLabel.strSystemResourceConfig = '[SYSTEM_RESOURCE_CONFIG]';
stResAllocStrCfgMstrLabel.strConstTotalNumAgent = 'TOTAL_AGENT';
stResAllocStrCfgMstrLabel.strConstTotalMachineType = 'TOTAL_MACHINE_TYPE';
stResAllocStrCfgMstrLabel.strConstTimeFrameUnit_hour = 'TIME_FRAME_UNIT_HOUR';
stResAllocStrCfgMstrLabel.strConstObjFunction   = 'OBJ_FUNCTION';
stResAllocStrCfgMstrLabel.strConstAlgoChoice    = 'ALGO_CHOICE';
stResAllocStrCfgMstrLabel.strConstPlotFlag      = 'PLOT_FLAG';
stResAllocStrCfgMstrLabel.strConstCriticalMachType = 'CRITICAL_MACHINE_TYPE';
stResAllocStrCfgMstrLabel.strConstMaxPlanningFrame = 'MAX_FRAMES_FOR_PLANNING';
stResAllocStrCfgMstrLabel.strConstOptionPackageIP = 'IP_PACKAGE'; % 20071220 add iSolverPackage
stResAllocStrCfgMstrLabel.iTotalParameterWhole = 9;


% 20071211
stJobSequencingStrCfgLabel.strConstJobSeqConfig = '[JOB_SEQUENCE]';
stJobSequencingStrCfgLabel.strConstJobSeqHeader = 'JOB_ID_INDEX_';

%% build output structure
stJspConstStringLoadFile.stConfigOnePerMachCapLabel      = stConfigOnePerMachCapLabel; 
stJspConstStringLoadFile.stConfigMachNameLabel           = stConfigMachNameLabel;
stJspConstStringLoadFile.stConfigMachTotalPeriodLabel    = stConfigMachTotalPeriodLabel;
stJspConstStringLoadFile.astrJSSProbStructCfg            = astrJSSProbStructCfg;
stJspConstStringLoadFile.stJspMasterPropertyLabel        = stJspMasterPropertyLabel;
stJspConstStringLoadFile.stBiFspStrCfgMstrLabel          = stBiFspStrCfgMstrLabel;
stJspConstStringLoadFile.astMachineProcLabel             = astMachineProcLabel;
stJspConstStringLoadFile.stResAllocStrCfgMstrLabel       = stResAllocStrCfgMstrLabel;
stJspConstStringLoadFile.stJobSequencingStrCfgLabel      = stJobSequencingStrCfgLabel;
stJspConstStringLoadFile.astrDynamicBatchJobArrival      = astrDynamicBatchJobArrival; % 20091216