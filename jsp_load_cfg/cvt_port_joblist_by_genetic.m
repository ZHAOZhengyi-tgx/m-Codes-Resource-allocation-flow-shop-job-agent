function [stQuayCraneJobList, stContainerDischargeJobSequence, stContainerLoadJobSequence] = cvt_port_joblist_by_genetic(stAgentJobList)
% History
% YYYYMMDD  Notes
% 20071115  Port to common.jsp.jsp_def_struct_res_cfg,
% common.jsp.jsp_def_struct_port_job_list


% 20071115 
stResourceConfig = jsp_def_struct_res_cfg();
[stQuayCraneJobList, stContainerDischargeJobSequence, stContainerLoadJobSequence] = jsp_def_struct_port_job_list();

stAgentBiFSPJobMachConfig = stAgentJobList.stAgentBiFSPJobMachConfig;
if stAgentBiFSPJobMachConfig.iTotalMachType == 3 & stAgentBiFSPJobMachConfig.iCriticalMachType == 1 & ...
        stAgentJobList.stResourceConfig.iaMachCapOnePer(1) == 1
    stQuayCraneJobList.strJobListInputFilename  = stAgentJobList.strJobListInputFilename;
    stQuayCraneJobList.iAlgoOption              = stAgentBiFSPJobMachConfig.iOptionPackageIP;
    stQuayCraneJobList.fTimeUnit_Min            = stAgentBiFSPJobMachConfig.fTimeUnit_Min
    stQuayCraneJobList.iOptRule                 = stAgentBiFSPJobMachConfig.iOptRule
    stQuayCraneJobList.TotalContainer_Discharge = stAgentBiFSPJobMachConfig.iTotalForwardJobs;
    stQuayCraneJobList.MaxVirtualPrimeMover     = stAgentJobList.stResourceConfig.iaMachCapOnePer(2);
    stQuayCraneJobList.MaxVirtualYardCrane      = stAgentJobList.stResourceConfig.iaMachCapOnePer(3);
    stQuayCraneJobList.TotalContainer_Load      = stAgentBiFSPJobMachConfig.iTotalReverseJobs;
    stQuayCraneJobList.iPlotFlag                = stAgentBiFSPJobMachConfig.iPlotFlag;

    astMachineProcTimeOnMachine = stAgentJobList.astMachineProcTimeOnMachine;
    for ii = 1:1:stAgentBiFSPJobMachConfig.iTotalForwardJobs
        stContainerDischargeJobSequence(ii).fCycleTimeMachineType1 = astMachineProcTimeOnMachine(1).aForwardTimeMachineCycle(ii); 
        stContainerDischargeJobSequence(ii).Time_PM = astMachineProcTimeOnMachine(2).aForwardTimeMachineCycle(ii);
        stContainerDischargeJobSequence(ii).Time_YC = astMachineProcTimeOnMachine(3).aForwardTimeMachineCycle(ii);
        stContainerDischargeJobSequence(ii).Time_PM_YC = stContainerDischargeJobSequence(ii).Time_PM + stContainerDischargeJobSequence(ii).Time_YC;
        
        stContainerDischargeJobSequence(ii).YC_Id = astMachineProcTimeOnMachine(1).aForwardJobOnMachineId(ii);
        stContainerDischargeJobSequence(ii).PM_Id = astMachineProcTimeOnMachine(2).aForwardJobOnMachineId(ii);
        stContainerDischargeJobSequence(ii).QC_Id = astMachineProcTimeOnMachine(3).aForwardJobOnMachineId(ii);

    end

    for ii = 1:1:stAgentBiFSPJobMachConfig.iTotalReverseJobs
        stContainerLoadJobSequence(ii).fCycleTimeMachineType1 = astMachineProcTimeOnMachine(1).aReverseTimeMachineCycle(ii); 
        stContainerLoadJobSequence(ii).Time_PM = astMachineProcTimeOnMachine(2).aReverseTimeMachineCycle(ii);
        stContainerLoadJobSequence(ii).Time_YC = astMachineProcTimeOnMachine(3).aReverseTimeMachineCycle(ii);
        stContainerLoadJobSequence(ii).Time_PM_YC = stContainerLoadJobSequence(ii).Time_PM + stContainerLoadJobSequence(ii).Time_YC;
        
        stContainerLoadJobSequence(ii).YC_Id = astMachineProcTimeOnMachine(1).aReverseJobOnMachineId(ii);
        stContainerLoadJobSequence(ii).PM_Id = astMachineProcTimeOnMachine(2).aReverseJobOnMachineId(ii);
        stContainerLoadJobSequence(ii).QC_Id = astMachineProcTimeOnMachine(3).aReverseJobOnMachineId(ii);
        
    end
    stQuayCraneJobList.stContainerDischargeJobSequence = stContainerDischargeJobSequence;
    stQuayCraneJobList.stContainerLoadJobSequence = stContainerLoadJobSequence;
    stQuayCraneJobList.stResourceConfig.iTotalMachine = 3;
    stQuayCraneJobList.stResourceConfig.stMachineConfig = stAgentJobList.stResourceConfig.stMachineConfig;
else
    error('cannot map to port job configuration');
end


