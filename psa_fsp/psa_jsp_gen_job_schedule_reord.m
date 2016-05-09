function [container_sequence_jsp, jobshop_config, stDebugOutput] = psa_jsp_gen_job_schedule_reord(stQuayCraneJobList)

[jobshop_config] = psa_jsp_construct_jsp_config(stQuayCraneJobList);

%% Generate a schedule with infinite resources (infinite: large enough for all jobs)
stQuayCraneJobList.MaxVirtualPrimeMover = stQuayCraneJobList.TotalContainer_Load + stQuayCraneJobList.TotalContainer_Discharge;
stQuayCraneJobList.MaxVirtualYardCrane = stQuayCraneJobList.TotalContainer_Load + stQuayCraneJobList.TotalContainer_Discharge;

[stContainerDischargeJobSequence, container_jsp_discha_schedule, stContainerLoadJobSequence, container_jsp_load_schedule, container_sequence_jsp]...
        = psa_jsp_gen_job_schedule_4(stQuayCraneJobList);

if stQuayCraneJobList.iPlotFlag >= 1
    figure_id = 101;
    psa_jsp_plot_jobsolution_2(container_sequence_jsp, figure_id);
    title('Job Schedule for sufficient resources, Y-Group is Job');
end

for ii = 1:1:container_sequence_jsp.iTotalJob
    tJobStartTime(ii) = container_sequence_jsp.stJobSet(ii).iProcessStartTime(1);
end

%% Reorder the job list by starting time of the first process
if stQuayCraneJobList.iOptRule == 11
    [tSortedStartTime, iJobSeqInJspCfg] = sort(tJobStartTime);
elseif stQuayCraneJobList.iOptRule == 13
    % hard coded temperarily
    iJobSeqInJspCfg = 1:100;
    iJobSeqInJspCfg(38:60) = [38, 50, 39, 51, 40, 52, 41, 53, 42, 54, 43, 55, 44, 56, 45, 57, 46, 58, 47, 59, 48, 60, 49];
else
end

%% schedule the reordered job list according to earliest machine
%% availability
stSolutionJobSet = psa_fsp_solve_by_seq(jobshop_config, iJobSeqInJspCfg);

%%% 
container_sequence_jsp.iTotalMachineNum = jobshop_config.iTotalMachineNum;
for ii = 1:1:jobshop_config.iTotalJob
%    container_sequence_jsp.stJobSet(ii) = [];
%    for jj = 1:1:jobshop_config.stProcessPerJob(ii)
        container_sequence_jsp.stJobSet(ii).iProcessStartTime = stSolutionJobSet(ii).iProcessStartTime ;
        container_sequence_jsp.stJobSet(ii).iProcessEndTime   = stSolutionJobSet(ii).iProcessEndTime   ;
        container_sequence_jsp.stJobSet(ii).iProcessMachine   = stSolutionJobSet(ii).iProcessMachine   ;
        container_sequence_jsp.stJobSet(ii).iProcessMachineId = stSolutionJobSet(ii).iProcessMachineId ;
        container_sequence_jsp.stJobSet(ii).fProcessStartTime = stSolutionJobSet(ii).fProcessStartTime ;
        container_sequence_jsp.stJobSet(ii).fProcessEndTime   = stSolutionJobSet(ii).fProcessEndTime   ;
%    end                                 
    if container_sequence_jsp.iMaxEndTime < stSolutionJobSet(ii).fProcessEndTime(jobshop_config.stProcessPerJob(ii))
        container_sequence_jsp.iMaxEndTime = stSolutionJobSet(ii).fProcessEndTime(jobshop_config.stProcessPerJob(ii));
    end
end 

jobshop_config.iTotalTimeSlot = ceil(container_sequence_jsp.iMaxEndTime);

for ii = 1:1:jobshop_config.iTotalJob
    if jobshop_config.iJobType(ii) == 1  %% forward flow shop, Machine-1, Machine-2, Machine-3
        tQcStartTimeList(ii) = container_sequence_jsp.stJobSet(ii).fProcessStartTime(1);
    elseif jobshop_config.iJobType(ii) == 2  %% reverse flow shop: Machine-3, Machine-2, Machine-1
        tQcStartTimeList(ii) = container_sequence_jsp.stJobSet(ii).fProcessStartTime(3);
    else
    end
end

stDebugOutput.tQcStartTimeList = tQcStartTimeList;
stDebugOutput.aiJobSeqInJspCfg     = iJobSeqInJspCfg;