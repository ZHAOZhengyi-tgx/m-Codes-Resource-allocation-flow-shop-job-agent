function [stAgentJobList] = cvt_joblist_by_port(stQuayCraneJobList)
%
% 20071115  Move to common.jsp.fsp_def_struct_bidir_cfg
% 20071023  stGASetting, stJssProbStructConfig
% 20080323  aiJobSeqInJspCfg, iReleaseTimeSlotGlobal

stAgentBiFSPJobMachConfig.iTotalForwardJobs = stQuayCraneJobList.TotalContainer_Discharge;
stAgentBiFSPJobMachConfig.iTotalReverseJobs = stQuayCraneJobList.TotalContainer_Load;
stAgentBiFSPJobMachConfig.iOptionPackageIP  = stQuayCraneJobList.iAlgoOption;
stAgentBiFSPJobMachConfig.iOptRule          = stQuayCraneJobList.iOptRule;
stAgentBiFSPJobMachConfig.iTotalMachType    = 3;
stAgentBiFSPJobMachConfig.iPlotFlag         = stQuayCraneJobList.iPlotFlag;
stAgentBiFSPJobMachConfig.fTimeUnit_Min     = stQuayCraneJobList.fTimeUnit_Min;
stAgentBiFSPJobMachConfig.iCriticalMachType = 1;
stAgentBiFSPJobMachConfig.iReleaseTimeSlotGlobal = stQuayCraneJobList.iReleaseTimeSlotGlobal; % 20080323

stAgentJobList.stAgentBiFSPJobMachConfig = stAgentBiFSPJobMachConfig;

stResourceConfig.iTotalMachine = 3;
stResourceConfig.iaMachCapOnePer = [1, stQuayCraneJobList.MaxVirtualPrimeMover, stQuayCraneJobList.MaxVirtualYardCrane];
stResourceConfig.stMachineConfig = stQuayCraneJobList.stResourceConfig.stMachineConfig;
stAgentJobList.stResourceConfig = stResourceConfig;

stAgentJobList.strJobListInputFilename = stQuayCraneJobList.strJobListInputFilename;

stContainerDischargeJobSequence = stQuayCraneJobList.stContainerDischargeJobSequence;
for ii = 1:1:stAgentBiFSPJobMachConfig.iTotalForwardJobs
    astMachineProcTimeOnMachine(1).aForwardTimeMachineCycle(ii) = stContainerDischargeJobSequence(ii).fCycleTimeMachineType1; 
    astMachineProcTimeOnMachine(2).aForwardTimeMachineCycle(ii) = stContainerDischargeJobSequence(ii).Time_PM;
    astMachineProcTimeOnMachine(3).aForwardTimeMachineCycle(ii) = stContainerDischargeJobSequence(ii).Time_YC;

    astMachineProcTimeOnMachine(1).aForwardJobOnMachineId(ii) = stContainerDischargeJobSequence(ii).YC_Id;
    astMachineProcTimeOnMachine(2).aForwardJobOnMachineId(ii) = stContainerDischargeJobSequence(ii).PM_Id;
    astMachineProcTimeOnMachine(3).aForwardJobOnMachineId(ii) = stContainerDischargeJobSequence(ii).QC_Id;

    astMachineProcTimeOnMachine(1).aForwardRelTimeMachineCycle(ii) = 0;
    astMachineProcTimeOnMachine(2).aForwardRelTimeMachineCycle(ii) = 0;
    astMachineProcTimeOnMachine(3).aForwardRelTimeMachineCycle(ii) = 0;
end

stContainerLoadJobSequence = stQuayCraneJobList.stContainerLoadJobSequence;
for ii = 1:1:stAgentBiFSPJobMachConfig.iTotalReverseJobs
    astMachineProcTimeOnMachine(1).aReverseTimeMachineCycle(ii) = stContainerLoadJobSequence(ii).fCycleTimeMachineType1; 
    astMachineProcTimeOnMachine(2).aReverseTimeMachineCycle(ii) = stContainerLoadJobSequence(ii).Time_PM;
    astMachineProcTimeOnMachine(3).aReverseTimeMachineCycle(ii) = stContainerLoadJobSequence(ii).Time_YC;

    astMachineProcTimeOnMachine(1).aReverseJobOnMachineId(ii) = stContainerLoadJobSequence(ii).YC_Id;
    astMachineProcTimeOnMachine(2).aReverseJobOnMachineId(ii) = stContainerLoadJobSequence(ii).PM_Id;
    astMachineProcTimeOnMachine(3).aReverseJobOnMachineId(ii) = stContainerLoadJobSequence(ii).QC_Id;

    astMachineProcTimeOnMachine(1).aReverseRelTimeMachineCycle(ii) = 0;
    astMachineProcTimeOnMachine(2).aReverseRelTimeMachineCycle(ii) = 0;
    astMachineProcTimeOnMachine(3).aReverseRelTimeMachineCycle(ii) = 0;
end
stAgentJobList.astMachineProcTimeOnMachine = astMachineProcTimeOnMachine;

%% version compatible % 20071023
if ~isfield(stQuayCraneJobList, 'stJssProbStructConfig')
    stJssProbStructConfig = jsp_def_struct_prob_cfg();
    stAgentJobList.stJssProbStructConfig = stJssProbStructConfig;
else               
    stAgentJobList.stJssProbStructConfig = stQuayCraneJobList.stJssProbStructConfig;
end

%% version compatible
if ~isfield(stQuayCraneJobList, 'stGASetting')
    stGASetting = ga_struct_def(); % 20071023
    stAgentJobList.stGASetting = stGASetting;
else
    stAgentJobList.stGASetting = stQuayCraneJobList.stGASetting;
end

if ~isfield(stQuayCraneJobList, 'aiJobSeqInJspCfg')
    aiJobSeqInJspCfg = 1:(stAgentBiFSPJobMachConfig.iTotalForwardJobs + stAgentBiFSPJobMachConfig.iTotalReverseJobs); % 20071023
    stAgentJobList.aiJobSeqInJspCfg = aiJobSeqInJspCfg;
else
    stAgentJobList.aiJobSeqInJspCfg = stQuayCraneJobList.aiJobSeqInJspCfg;
end
