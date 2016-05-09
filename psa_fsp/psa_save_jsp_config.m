function [strFileName] = psa_save_jsp_config(stJobShopSchedulingJobListInfo, strFilenamePrefix)
%% History
%% YYYYMMDD Notes
%% 20070724 Add JSS Problem Structure Configuration

if nargin <= 1
    strFileFullName = stJobShopSchedulingJobListInfo.strJobListInputFilename;
    [s,strSystem] = system('ver');
    if s == 0 %% it is a dos-windows system
        iPathStringList = strfind(strFileFullName, '\');
    else %% it is a UNIX or Linux system
        iPathStringList = strfind(strFileFullName, '/');
    end

    strFilenamePrefix = strFileFullName(1:iPathStringList(end))
end

for ii = 1:1:stJobShopSchedulingJobListInfo.TotalContainer_Discharge + stJobShopSchedulingJobListInfo.TotalContainer_Load
   if ii <= stJobShopSchedulingJobListInfo.TotalContainer_Discharge
       tPM_Time(ii) = stJobShopSchedulingJobListInfo.stContainerDischargeJobSequence(ii).Time_PM;
   else
       tPM_Time(ii) = stJobShopSchedulingJobListInfo.stContainerLoadJobSequence(ii - stJobShopSchedulingJobListInfo.TotalContainer_Discharge).Time_PM;
   end
end
iVarPmTime = round(var(tPM_Time));
iMeanPmTime = round(mean(tPM_Time));

for ii = 1:1:stJobShopSchedulingJobListInfo.TotalContainer_Discharge + stJobShopSchedulingJobListInfo.TotalContainer_Load
   if ii <= stJobShopSchedulingJobListInfo.TotalContainer_Discharge
       tYC_Time(ii) = stJobShopSchedulingJobListInfo.stContainerDischargeJobSequence(ii).Time_YC;
   else
       tYC_Time(ii) = stJobShopSchedulingJobListInfo.stContainerLoadJobSequence(ii - stJobShopSchedulingJobListInfo.TotalContainer_Discharge).Time_YC;
   end
end
iVarYcTime = round(var(tYC_Time));
iMeanYcTime = round(mean(tYC_Time));

if iVarYcTime == 0
    strFileName = sprintf('%sDisc%dLoad%d_OptRule%d_PM%d_YC%d_PMTime_Mean%d_Var%d', ...
               strFilenamePrefix, ...
               stJobShopSchedulingJobListInfo.TotalContainer_Discharge, ...
               stJobShopSchedulingJobListInfo.TotalContainer_Load, ...
               stJobShopSchedulingJobListInfo.iOptRule,...
               stJobShopSchedulingJobListInfo.MaxVirtualPrimeMover, ...
               stJobShopSchedulingJobListInfo.MaxVirtualYardCrane, ...
               iMeanPmTime, ...
               iVarPmTime);
else
    strFileName = sprintf('%sDisc%dLoad%d_OptRule%d_PM%d_YC%d_PMTime_Mean%d_Var%d_YCTime_Mean%d_Var%d', ...
               strFilenamePrefix, ...
               stJobShopSchedulingJobListInfo.TotalContainer_Discharge, ...
               stJobShopSchedulingJobListInfo.TotalContainer_Load, ...
               stJobShopSchedulingJobListInfo.iOptRule,...
               stJobShopSchedulingJobListInfo.MaxVirtualPrimeMover, ...
               stJobShopSchedulingJobListInfo.MaxVirtualYardCrane, ...
               iMeanPmTime, ...
               iVarPmTime, ...
               iMeanYcTime, ...
               iVarYcTime);
end

if stJobShopSchedulingJobListInfo.stJssProbStructConfig.isCriticalOperateSeq == 0
    strFileName = sprintf('%s_NoCOS', strFileName);
end
if stJobShopSchedulingJobListInfo.stGASetting.isSequecingByGA == 1
    strFileName = sprintf('%s_GA', strFileName);
end
strFileName = sprintf('%s.ini', strFileName);

fptr = fopen(strFileName, 'w');

fprintf(fptr, '%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%  \n');
fprintf(fptr, '%% Project: Solution for JobShop (FlowShop) Scheduling Problem    \n');
fprintf(fptr, '%%\n');
fprintf(fptr, '%%\n');
fprintf(fptr, '%% OUTPUT from the solver \n');
fprintf(fptr, '%% During this whole document, %% is for line commenting, which means any line starting with a %% will not be taken into parsing.\n');
fprintf(fptr, '%%\n');
fprintf(fptr, '%% all right reserved 2007\n');
fprintf(fptr, '%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%\n');
fprintf(fptr, '%%\n');
fprintf(fptr, '%% Author: \n');
fprintf(fptr, '%%             Zhao ZhengYi (zyzhao@smu.edu.sg) \n');
fprintf(fptr, '%% Supervisor: \n');
fprintf(fptr, '%%             Lau Hoong Chuin (hclau@smu.edu.sg)\n');
fprintf(fptr, '%%             Shuzhi, Sam, GE (elegesz@nus.edu.sg) \n');
fprintf(fptr, '%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%\n');
fprintf(fptr, '\n\n');

fprintf(fptr, '[PORT_JOB_CONFIG]\n');
fprintf(fptr, 'TOTAL_DISCHARGE_CONTAINER = %d\n',       stJobShopSchedulingJobListInfo.TotalContainer_Discharge);
fprintf(fptr, 'TOTAL_LOAD_CONTAINER = %d\n',       stJobShopSchedulingJobListInfo.TotalContainer_Load);
fprintf(fptr, 'IP_PACKAGE = %d\n',      stJobShopSchedulingJobListInfo.iAlgoOption);
fprintf(fptr, 'TOTAL_PM_PER_QC = %d\n', stJobShopSchedulingJobListInfo.MaxVirtualPrimeMover);
fprintf(fptr, 'TOTAL_YC_PER_QC = %d\n', stJobShopSchedulingJobListInfo.MaxVirtualYardCrane);
fprintf(fptr, 'TIME_UNIT_MINUTE = %d\n',       stJobShopSchedulingJobListInfo.fTimeUnit_Min);
fprintf(fptr, 'OPT_RULE = %d\n',        stJobShopSchedulingJobListInfo.iOptRule);
fprintf(fptr, '%% OPT_RULE = 0: heuristic No.0, Discharge Only, PM has constraint, YC always available\n');
fprintf(fptr, '%% OPT_RULE = 1: heuristic No.1, Discharge Only, PM and YC has virtual capacities\n');
fprintf(fptr, '%% OPT_RULE = 2: heuristic No.2, Discharge first then load, PM and YC has same virtual capacities in both discharge and load\n');
fprintf(fptr, '%% OPT_RULE = 3: heuristic No.3, first schedule for infinite PM and YC, then shift. Always choose latest start job to shift, no matter the violations, in the confliction set.\n');
fprintf(fptr, '%% OPT_RULE = 4: heuristic No.4, first schedule for infinite PM and YC, then shift. According to violation number K, choose K-th latest start jobs, in the confliction set.\n');
fprintf(fptr, '%% OPT_RULE = 5: heuristic No.5, first schedule for infinite PM and YC, then shift. Exclude the first job in violation set. According to violation number K, choose K-th smallest shift, in the confliction set\n');
fprintf(fptr, '%% OPT_RULE = 6: Apply Heuristic 8 first, then apply MIP Solver, currently MOSEK\n');
fprintf(fptr, '%% OPT_RULE = 7: heuristic No.7, schedule one job after another, first schedule for infinite PM and YC, then shift the last job for feasibility of machine capacity.\n');
fprintf(fptr, '%% OPT_RULE = 8: heuristic No.8, Add Pure load job from No.7, considering necessary shift to avoid the negative starting time.\n');
fprintf(fptr, '%% OPT_RULE = 9: heuristic No.9, Lagrangian Relaxation with MIP Solver currently MOSEK.\n');
fprintf(fptr, '%% OPT_RULE = 10: heuristic No.10, first schedule for infinite PM and YC, then shift, According to violation number K, choose K-th latest job in the job list and in the confliction set \n');
fprintf(fptr, '%% OPT_RULE = 12: heuristic No.12, relax machine after machine, do the following {first schedule for infinite machine resource, then apply heu 10}, choose the best makespan from above solutions \n');
fprintf(fptr, '%% OPT_RULE = 17: heuristic,No.17  MIP formulation and output CPLEX format only, not solve\n');
fprintf(fptr, '%% OPT_RULE = 20: heuristic No.20, \n');
fprintf(fptr, '%% OPT_RULE = 26: heuristic No.26, MIP solver, Continuous time and time variant machine capacity, apply heuristic 28 first. \n');
fprintf(fptr, '%% OPT_RULE = 28: heuristic No.28, Continuous time and time variant machine capacity, apply heuristic 8. \n');
% fprintf(fptr, '%% OPT_RULE = 770: (0x100 + 0x200 + 0x002) no COS constraint problems, greedy algorithm, constant machine capacity. \n');
% fprintf(fptr, '%% OPT_RULE = 786: (0x100 + 0x200 + 0x012) no COS constraint problems, greedy algorithm, time variant machine capacity. \n');
% fprintf(fptr, '%% OPT_RULE = 774: (0x100 + 0x200 + 0x006) MIP and solution by MOSEK for no COS constraint problems, time variant machine capacity. \n');
% fprintf(fptr, '%% OPT_RULE = 785: (0x100 + 0x200 + 0x011) MIP  formulation solution by MOSEK for no COS constraint problems, time variant machine capacity. \n');
% fprintf(fptr, '%% constraints, X = 0 or 1\n');
% fprintf(fptr, '%%          XXXX,XXXX,XXXX,XXXX\n');
% fprintf(fptr, '%%                 ||       110 --> MIP, and solution by MOSEK, 0x6\n');
% fprintf(fptr, '%%                 ||      1001 --> Lagrangian Relaxation,      0x9\n');
% fprintf(fptr, '%%                 ||    1,0001 --> MIP formulation only, 0x11 \n');
% fprintf(fptr, '%%                  --------------> 00: strict COS, 01: semi-strict COS,\n');
% fprintf(fptr, '%%                  10:Userdefine, 11: no COS at all\n');
fprintf(fptr, '\n\n');
fprintf(fptr, 'PLOT_FLAG = %d\n',        stJobShopSchedulingJobListInfo.iPlotFlag);
fprintf(fptr, '\n\n');

%%%%%%%%%%%%%%%% JSS problem struct 20070724
fprintf(fptr, '[JSS_PROBLEM_CONFIG]\n');
fprintf(fptr, 'IS_PREEMPTIVE = %d\n', stJobShopSchedulingJobListInfo.stJssProbStructConfig.isPreemptiveProcess);
fprintf(fptr, 'IS_WAIT_IN_PROCESS = %d\n', stJobShopSchedulingJobListInfo.stJssProbStructConfig.isWaitInProcess);
fprintf(fptr, 'IS_CRITICAL_OPERATION_SEQUENCE = %d\n', stJobShopSchedulingJobListInfo.stJssProbStructConfig.isCriticalOperateSeq);
fprintf(fptr, '\n\n');

%%%%%%%%%%%%%%%% JSS problem struct 20070724
fprintf(fptr, '[GA_SETTING]\n');
fprintf(fptr, 'IS_SEQUENCING_BY_GA = %d\n', stJobShopSchedulingJobListInfo.stGASetting.isSequecingByGA);
fprintf(fptr, 'IS_GA_LOAD_RANDOM_STATE = %d\n', stJobShopSchedulingJobListInfo.stGASetting.iFlagInitRandGeneratorSeed);
fprintf(fptr, 'GA_POP_SIZE = %d\n', stJobShopSchedulingJobListInfo.stGASetting.iPopSize);
fprintf(fptr, 'GA_CROSSOVER_RATE = %f\n', stJobShopSchedulingJobListInfo.stGASetting.fXoverRate);
fprintf(fptr, 'GA_MUTATE_RATE = %f\n', stJobShopSchedulingJobListInfo.stGASetting.fMutateRate);
fprintf(fptr, 'GA_TOTAL_GEN = %d\n', stJobShopSchedulingJobListInfo.stGASetting.iTotalGen);
fprintf(fptr, 'GA_EPSILON_STD_BY_AVE_STOPPING_MAKESPAN = %f\n', stJobShopSchedulingJobListInfo.stGASetting.fEpsStdByAveMakespan);
fprintf(fptr, '\n\n');

%%%%%%%%%%%%%%%% Diacharge Time
fprintf(fptr, '[DISCHARGE_QC_TIME]\n');
for ii = 1:1:stJobShopSchedulingJobListInfo.TotalContainer_Discharge
    fprintf(fptr, 'QC_TIME_DISCHARGE_%d = %d\n', ii, stJobShopSchedulingJobListInfo.stContainerDischargeJobSequence(ii).fCycleTimeMachineType1);
end
fprintf(fptr, '\n\n');

fprintf(fptr, '[DISCHARGE_PM_TIME]\n');
for ii = 1:1:stJobShopSchedulingJobListInfo.TotalContainer_Discharge
    fprintf(fptr, 'PM_TIME_DISCHARGE_%d = %d\n', ii, stJobShopSchedulingJobListInfo.stContainerDischargeJobSequence(ii).Time_PM);
end
fprintf(fptr, '\n\n');

fprintf(fptr, '[DISCHARGE_YC_TIME]\n');
for ii = 1:1:stJobShopSchedulingJobListInfo.TotalContainer_Discharge
    fprintf(fptr, 'YC_TIME_DISCHARGE_%d = %d\n', ii, stJobShopSchedulingJobListInfo.stContainerDischargeJobSequence(ii).Time_YC);
end
fprintf(fptr, '\n\n');

fprintf(fptr, '%%%%%%%%%%%%%%%%%%%%%%%%%%%% \n');
fprintf(fptr, '%% MachineId includes YC_ID, PM_ID, QC_ID, \n');
fprintf(fptr, '%%          Valid MachineId: should be >0 [1, ..., MachineCapacity] \n');
fprintf(fptr, '%%          Flexible MachineId: 0, can be assigned by the scheduler \n');
fprintf(fptr, '%%%%%%%%%%%%%%%%%%%%%%%%%%%% \n');
fprintf(fptr, '\n[DISCHARGE_YC_ID]\n');
for ii = 1:1:stJobShopSchedulingJobListInfo.TotalContainer_Discharge
     fprintf(fptr, 'YC_ID_JOB_%d = %d\n', ii, stJobShopSchedulingJobListInfo.stContainerDischargeJobSequence(ii).YC_Id);
end
fprintf(fptr, '\n\n');

fprintf(fptr, '[DISCHARGE_PM_ID]\n');
for ii = 1:1:stJobShopSchedulingJobListInfo.TotalContainer_Discharge
    fprintf(fptr, 'PM_ID_JOB_%d = %d\n', ii, stJobShopSchedulingJobListInfo.stContainerDischargeJobSequence(ii).PM_Id);
end
fprintf(fptr, '\n\n');

fprintf(fptr, '[DISCHARGE_QC_ID]\n');
for ii = 1:1:stJobShopSchedulingJobListInfo.TotalContainer_Discharge
    fprintf(fptr, 'QC_ID_JOB_%d = %d\n', ii, stJobShopSchedulingJobListInfo.stContainerDischargeJobSequence(ii).QC_Id);
end
fprintf(fptr, '\n\n');

%%%%%%%%%%%%%%
%%%%%%%%%%%%%%  Load Time
%%%%%%%%%%%%%%
fprintf(fptr, '[LOAD_QC_TIME]\n');
for ii = 1:1:stJobShopSchedulingJobListInfo.TotalContainer_Load
    fprintf(fptr, 'QC_TIME_LOAD_%d = %d\n', ii, stJobShopSchedulingJobListInfo.stContainerLoadJobSequence(ii).fCycleTimeMachineType1);
end
fprintf(fptr, '\n\n');

fprintf(fptr, '[LOAD_PM_TIME]\n');
for ii = 1:1:stJobShopSchedulingJobListInfo.TotalContainer_Load
    fprintf(fptr, 'PM_TIME_LOAD_%d = %d\n', ii, stJobShopSchedulingJobListInfo.stContainerLoadJobSequence(ii).Time_PM);
end
fprintf(fptr, '\n\n');

fprintf(fptr, '[LOAD_YC_TIME]\n');
for ii = 1:1:stJobShopSchedulingJobListInfo.TotalContainer_Load
    fprintf(fptr, 'YC_TIME_LOAD_%d = %d\n', ii, stJobShopSchedulingJobListInfo.stContainerLoadJobSequence(ii).Time_YC);
end
fprintf(fptr, '\n\n');

fprintf(fptr, '[LOAD_YC_ID]\n');
for ii = 1:1:stJobShopSchedulingJobListInfo.TotalContainer_Load
    fprintf(fptr, 'YC_ID_JOB_%d = %d\n', ii, stJobShopSchedulingJobListInfo.stContainerLoadJobSequence(ii).YC_Id);
end
fprintf(fptr, '\n\n');

fprintf(fptr, '[LOAD_PM_ID]\n');
for ii = 1:1:stJobShopSchedulingJobListInfo.TotalContainer_Load
    fprintf(fptr, 'PM_ID_JOB_%d = %d\n', ii, stJobShopSchedulingJobListInfo.stContainerLoadJobSequence(ii).PM_Id);
end
fprintf(fptr, '\n\n');

fprintf(fptr, '[LOAD_QC_ID]\n');
for ii = 1:1:stJobShopSchedulingJobListInfo.TotalContainer_Load
    fprintf(fptr, 'QC_ID_JOB_%d = %d\n', ii, stJobShopSchedulingJobListInfo.stContainerLoadJobSequence(ii).QC_Id);
end
fprintf(fptr, '\n\n');

fclose(fptr);
