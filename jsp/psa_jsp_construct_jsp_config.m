function [jobshop_config] = psa_jsp_construct_jsp_config(stQuayCraneJobList)
%
% naming convention of jobshop_config, inherit from reading Erhan's paper
% History
% YYYYMMDD Notes
% 20070629  reorganize output,
% 20070701  modification to relax the critical operational sequencing
% 20070801  add stResourceConfig into output struct
% 20080211  add stGASetting into jobshop_config
% 20080322  Add iReleaseTimeSlotGlobal

jobshop_config = jsp_def_struct_cfg();
                    

TotalContainer_Discharge = stQuayCraneJobList.TotalContainer_Discharge;
MaxVirtualPrimeMover = stQuayCraneJobList.MaxVirtualPrimeMover;
MaxVirtualYardCrane = stQuayCraneJobList.MaxVirtualYardCrane;
stContainerDischargeJobSequence = stQuayCraneJobList.stContainerDischargeJobSequence;
TotalContainer_Load = stQuayCraneJobList.TotalContainer_Load;
stContainerLoadJobSequence = stQuayCraneJobList.stContainerLoadJobSequence;

jTotalJob = TotalContainer_Discharge + TotalContainer_Load;
for jj = 1:1:jTotalJob
    jsp_process_machine(jj) = struct('iProcessMachine', []);
end

%%%%%%%%%% Construct jobshop_config
jobshop_config.iTotalMachine = 3;
jobshop_config.iTotalJob = TotalContainer_Discharge + TotalContainer_Load;
jobshop_config.stProcessPerJob = 3 * ones(1,TotalContainer_Load + TotalContainer_Discharge);
for ii = 1:1:jobshop_config.iTotalJob
    if ii <= TotalContainer_Discharge
        jobshop_config.iJobType(ii) = 1; % For discharge job, process 1 uses machine type 1, process 3 uses machine type 3, job dependence on machine 1
        jobshop_config.jsp_process_time(ii).iProcessTime(1) = stContainerDischargeJobSequence(ii).fCycleTimeMachineType1;
        jobshop_config.jsp_process_time(ii).iProcessTime(2) = stContainerDischargeJobSequence(ii).Time_PM;
        jobshop_config.jsp_process_time(ii).iProcessTime(3) = stContainerDischargeJobSequence(ii).Time_YC;
    else
        jobshop_config.iJobType(ii) = 2; % For load job, process 1 uses machine type 3, process 3 uses machine type 1, job dependence on machine 1
        jobshop_config.jsp_process_time(ii).iProcessTime(1) = stContainerLoadJobSequence(ii - TotalContainer_Discharge).Time_YC;
        jobshop_config.jsp_process_time(ii).iProcessTime(2) = stContainerLoadJobSequence(ii - TotalContainer_Discharge).Time_PM;
        jobshop_config.jsp_process_time(ii).iProcessTime(3) = stContainerLoadJobSequence(ii - TotalContainer_Discharge).fCycleTimeMachineType1;
    end
    
    if jobshop_config.iJobType(ii) == 1
        jobshop_config.jsp_process_machine(ii).iProcessMachine(1) = 1;
        jobshop_config.jsp_process_machine(ii).iProcessMachine(2) = 2;
        jobshop_config.jsp_process_machine(ii).iProcessMachine(3) = 3;
    else
        jobshop_config.jsp_process_machine(ii).iProcessMachine(1) = 3;
        jobshop_config.jsp_process_machine(ii).iProcessMachine(2) = 2;
        jobshop_config.jsp_process_machine(ii).iProcessMachine(3) = 1;
    end
    jobshop_config.aJobWeight(ii) = 1;
end

jobshop_config.iReleaseTimeSlotGlobal = stQuayCraneJobList.iReleaseTimeSlotGlobal; % 20080322  Add 

%%% Machine Configuration depends on whether it is time variant
if isfield(stQuayCraneJobList, 'stResourceConfig')
    stResourceConfig = stQuayCraneJobList.stResourceConfig;
    nTotalPrimeMoverCommonPoolAllPeriod = max(stResourceConfig.stMachineConfig(2).afMaCapAtTimePoint);
    nTotalYardCraneCommonPoolAllPeriod = max(stResourceConfig.stMachineConfig(3).afMaCapAtTimePoint);
    jobshop_config.stResourceConfig = stQuayCraneJobList.stResourceConfig; %20070801
    
else
    nTotalPrimeMoverCommonPoolAllPeriod = stQuayCraneJobList.MaxVirtualPrimeMover;
    nTotalYardCraneCommonPoolAllPeriod = stQuayCraneJobList.MaxVirtualYardCrane;
end

if isfield(stQuayCraneJobList, 'aiJobSeqInJspCfg')
    jobshop_config.aiJobSeqInJspCfg = stQuayCraneJobList.aiJobSeqInJspCfg;
else
    jobshop_config.aiJobSeqInJspCfg = 1:jobshop_config.iTotalJob;
end

jobshop_config.iTotalMachineNum = [1, nTotalPrimeMoverCommonPoolAllPeriod, nTotalYardCraneCommonPoolAllPeriod];

% 20070701 
jobshop_config.stJssProbStructConfig = stQuayCraneJobList.stJssProbStructConfig;
%% it calls the fastest scheduler to generate the temperary solution, it is
%% partial solution without dispatching information, only use the
%% iTotalTimeSlot
% calling time for GenSch2: 10disc+10load jobs: 0.1 seconds
%                           50disc+50load jobs: 8 seconds
%[container_jsp_patial_heu, jobshop_config_temp] = psa_jsp_gen_job_schedule_8(stQuayCraneJobList);
% calling time for GenSch3: 50disc+50load: 0.18 seconds
[stContainerDischargeJobSequence, container_jsp_discha_schedule, stContainerLoadJobSequence, container_jsp_load_schedule, container_sequence_jsp]...
            = psa_jsp_gen_job_schedule_4(stQuayCraneJobList);
        
jobshop_config.iTotalTimeSlot = container_sequence_jsp.iMaxEndTime;
jobshop_config.strJobListInputFilename = stQuayCraneJobList.strJobListInputFilename;

%% to minimize the make span

%% assigning job due time to each each job
for ii = 1:1:jobshop_config.iTotalJob
    jobshop_config.aJobDueTime(ii) = jobshop_config.iTotalTimeSlot;
end

jobshop_config.iPlotFlag  = stQuayCraneJobList.iPlotFlag;
jobshop_config.fTimeUnit_Min = stQuayCraneJobList.fTimeUnit_Min; % 20070629
jobshop_config.iOptRule = stQuayCraneJobList.iOptRule;           % 20070701
jobshop_config.stGASetting = stQuayCraneJobList.stGASetting;
