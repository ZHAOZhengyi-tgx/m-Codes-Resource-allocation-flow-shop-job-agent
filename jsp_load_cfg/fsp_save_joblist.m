function [strFileName] = fsp_save_joblist(stBiFlowShopJobListInfo, strFilenamePrefix)
%% History
%% YYYYMMDD Notes

if nargin <= 1
    strFileFullName = stBiFlowShopJobListInfo.strJobListInputFilename;
    [s,strSystem] = system('ver');
    if s == 0 %% it is a dos-windows system
        iPathStringList = strfind(strFileFullName, '\');
    else %% it is a UNIX or Linux system
        iPathStringList = strfind(strFileFullName, '/');
    end

    strFilenamePrefix = strFileFullName(1:iPathStringList(end))
end

stAgentBiFSPJobMachConfig = stBiFlowShopJobListInfo.stAgentBiFSPJobMachConfig;
stResourceConfig = stBiFlowShopJobListInfo.stResourceConfig;
iTotalMachType = stAgentBiFSPJobMachConfig.iTotalMachType;
nTotalJobs = stAgentBiFSPJobMachConfig.iTotalForwardJobs + stAgentBiFSPJobMachConfig.iTotalReverseJobs;

strTextMachCycleTime = [];
for mm = 1:1:iTotalMachType
    for ii = 1:1: nTotalJobs
        if ii <= stAgentBiFSPJobMachConfig.iTotalForwardJobs
            tMachineTime(ii, mm) = stBiFlowShopJobListInfo.astMachineProcTimeOnMachine(mm).aForwardTimeMachineCycle(ii);
        else
            tMachineTime(ii, mm) = stBiFlowShopJobListInfo.astMachineProcTimeOnMachine(mm).aReverseTimeMachineCycle(ii - stAgentBiFSPJobMachConfig.iTotalForwardJobs);
        end
    end
    fVarTime(mm) = round(var(tMachineTime(:, mm)));
    fMeanTime(mm) = round(mean(tMachineTime(:, mm)));
    strTextMachCycleTime = sprintf('%sMach-%d_Time(Mean-%d,Var-%d)', strTextMachCycleTime, mm, fMeanTime(mm), fVarTime(mm));
end

strTextMachCap = 'Cap';
for mm = 1:1:iTotalMachType;
    if stResourceConfig.stMachineConfig(mm).iNumPointTimeCap <= 1
        strTextMachCap = sprintf('%s-%d', strTextMachCap, stResourceConfig.iaMachCapOnePer(mm));
    else
        nMacCapType_m = round(max(stResourceConfig.stMachineConfig(mm).afMaCapAtTimePoint));
        strTextMachCap = sprintf('%s-%d', strTextMachCap, nMacCapType_m);
    end
end
% strFileName = sprintf('%s_BiDirFSP_MultiMach_For%dRev%d_OptRule%d_%s_%s.ini', ...
%            strFilenamePrefix, ...
%            stAgentBiFSPJobMachConfig.iTotalForwardJobs, ...
%            stAgentBiFSPJobMachConfig.iTotalReverseJobs, ...
%            stAgentBiFSPJobMachConfig.iOptRule,...
%            strTextMachCap, ...
%            strTextMachCycleTime)
strFileName = sprintf('%s_BiDirFSP_MultiMach_For%dRev%d_OptRule%d_%s.ini', ...
           strFilenamePrefix, ...
           stAgentBiFSPJobMachConfig.iTotalForwardJobs, ...
           stAgentBiFSPJobMachConfig.iTotalReverseJobs, ...
           stAgentBiFSPJobMachConfig.iOptRule,...
           strTextMachCap);

fptr = fopen(strFileName, 'w');

fprintf(fptr, '%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%  \n');
fprintf(fptr, '%% Project:  IMSS- Integrated Manufacturing & Service Systems    \n');
fprintf(fptr, '%%\n');
fprintf(fptr, '%%\n');
fprintf(fptr, '%% Module: Solution for Genetic Multi-Machine BiDirectional FlowShop Scheduling Problem \n');
fprintf(fptr, '%% Template for Problem Input\n');
fprintf(fptr, '%% OUTPUT from the solver: schedule for each job''s process, dispatching for each machine\n');
fprintf(fptr, '%% During this whole document, %% is for line commenting, which means any line starting with a %% will not be taken into parsing.\n');
fprintf(fptr, '%%\n');
fprintf(fptr, '%% all right reserved 2006 - 2008\n');
fprintf(fptr, '%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%\n');
fprintf(fptr, '%%\n');
fprintf(fptr, '%% Author: \n');
fprintf(fptr, '%%             Zhengyi John, ZHAO(zyzhao@smu.edu.sg) \n');
fprintf(fptr, '%% Supervisor: \n');
fprintf(fptr, '%%             Lau Hoong Chuin (hclau@smu.edu.sg)\n');
fprintf(fptr, '%%             Shuzhi, Sam, GE (elegesz@nus.edu.sg) \n');
fprintf(fptr, '%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%\n');
fprintf(fptr, '\n\n');

stConstStringConfigLabels = stBiFlowShopJobListInfo.stConstStringConfigLabels;
fprintf(fptr, '%s\n', stConstStringConfigLabels.stBiFspStrCfgMstrLabel.strConstWholeConfigLabel);
fprintf(fptr, '%s = %d\n',  stConstStringConfigLabels.stBiFspStrCfgMstrLabel.strConstTotalForwardJob, stAgentBiFSPJobMachConfig.iTotalForwardJobs);
fprintf(fptr, '%s = %d\n',  stConstStringConfigLabels.stBiFspStrCfgMstrLabel.strConstTotalReverseJob, stAgentBiFSPJobMachConfig.iTotalReverseJobs);
fprintf(fptr, '%s = %d\n',  stConstStringConfigLabels.stBiFspStrCfgMstrLabel.strOptionPackageIP,    stAgentBiFSPJobMachConfig.iOptionPackageIP);
fprintf(fptr, '%s = %d\n',  stConstStringConfigLabels.stBiFspStrCfgMstrLabel.strConstTotalMachineType, stAgentBiFSPJobMachConfig.iTotalMachType);
fprintf(fptr, '%s = %d\n',  stConstStringConfigLabels.stBiFspStrCfgMstrLabel.strConstCriticalMachType, stAgentBiFSPJobMachConfig.iCriticalMachType);
fprintf(fptr, '%s = %d\n',  stConstStringConfigLabels.stBiFspStrCfgMstrLabel.strConstTimeUnit,     stAgentBiFSPJobMachConfig.fTimeUnit_Min);
fprintf(fptr, '%s = %d\n',  stConstStringConfigLabels.stBiFspStrCfgMstrLabel.strConstOptRules,      stAgentBiFSPJobMachConfig.iOptRule);
% fprintf(fptr, '%% OPT_RULE = 0: heuristic No.0, Forward Only, PM has constraint, YC always available\n');
% fprintf(fptr, '%% OPT_RULE = 1: heuristic No.1, Discharge Only, PM and YC has virtual capacities\n');
% fprintf(fptr, '%% OPT_RULE = 2: heuristic No.2, Discharge first then load, PM and YC has same virtual capacities in both discharge and load\n');
% fprintf(fptr, '%% OPT_RULE = 3: heuristic No.3, first schedule for infinite PM and YC, then shift. Always choose latest start job to shift, no matter the violations, in the confliction set.\n');
% fprintf(fptr, '%% OPT_RULE = 4: heuristic No.4, first schedule for infinite PM and YC, then shift. According to violation number K, choose K-th latest start jobs, in the confliction set.\n');
% fprintf(fptr, '%% OPT_RULE = 5: heuristic No.5, first schedule for infinite PM and YC, then shift. Exclude the first job in violation set. According to violation number K, choose K-th smallest shift, in the confliction set\n');
% fprintf(fptr, '%% OPT_RULE = 6: Apply Heuristic 8 first, then apply MIP Solver, currently MOSEK\n');
% fprintf(fptr, '%% OPT_RULE = 7: heuristic No.7, schedule one job after another, first schedule for infinite PM and YC, then shift the last job for feasibility of machine capacity.\n');
% fprintf(fptr, '%% OPT_RULE = 8: heuristic No.8, Add Pure load job from No.7, considering necessary shift to avoid the negative starting time.\n');
% fprintf(fptr, '%% OPT_RULE = 9: heuristic No.9, Lagrangian Relaxation with MIP Solver currently MOSEK.\n');
% fprintf(fptr, '%% OPT_RULE = 10: heuristic No.10, first schedule for infinite PM and YC, then shift, According to violation number K, choose K-th latest job in the job list and in the confliction set \n');
% fprintf(fptr, '%% OPT_RULE = 12: heuristic No.12, relax machine after machine, do the following {first schedule for infinite machine resource, then apply heu 10}, choose the best makespan from above solutions \n');
% fprintf(fptr, '%% OPT_RULE = 17: heuristic,No.17  MIP formulation and output CPLEX format only, not solve\n');
% fprintf(fptr, '%% OPT_RULE = 20: heuristic No.20, \n');
% fprintf(fptr, '%% OPT_RULE = 26: heuristic No.26, MIP solver, Continuous time and time variant machine capacity, apply heuristic 28 first. \n');
% fprintf(fptr, '%% OPT_RULE = 28: heuristic No.28, Continuous time and time variant machine capacity, apply heuristic 8. \n');
fprintf(fptr, '\n\n');
fprintf(fptr, '%s = %d\n',  stConstStringConfigLabels.stBiFspStrCfgMstrLabel.strConstPlotFlag, stAgentBiFSPJobMachConfig.iPlotFlag);
fprintf(fptr, '\n\n');

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Need to merge later, 
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%%%%%%%%%%%%%%%% JSS problem struct 20070724
fprintf(fptr, '[JSS_PROBLEM_CONFIG]\n');
fprintf(fptr, 'IS_PREEMPTIVE = %d\n', stBiFlowShopJobListInfo.stJssProbStructConfig.isPreemptiveProcess);
fprintf(fptr, 'IS_WAIT_IN_PROCESS = %d\n', stBiFlowShopJobListInfo.stJssProbStructConfig.isWaitInProcess);
fprintf(fptr, 'IS_CRITICAL_OPERATION_SEQUENCE = %d\n', stBiFlowShopJobListInfo.stJssProbStructConfig.isCriticalOperateSeq);
fprintf(fptr, 'IS_MACHINE_RELEASE_IMMEDIATELY_AFTER_PROC = %d\n', stBiFlowShopJobListInfo.stJssProbStructConfig.isMachineReleaseImmediate);
fprintf(fptr, 'IS_SEMI_COS = %d\n', stBiFlowShopJobListInfo.stJssProbStructConfig.isSemiCOS);
fprintf(fptr, 'IS_FLEXI_COS = %d\n', stBiFlowShopJobListInfo.stJssProbStructConfig.isFlexiCOS);
fprintf(fptr, 'OBJ_OPTION = %d\n', stBiFlowShopJobListInfo.stJssProbStructConfig.iFlagObjFuncDefine);
fprintf(fptr, '\n\n');

%% Job Sequencing, 20071211
aiJobSeqInJspCfg = stBiFlowShopJobListInfo.aiJobSeqInJspCfg;
fprintf(fptr, '%s\n', stConstStringConfigLabels.stJobSequencingStrCfgLabel.strConstJobSeqConfig);
for ii = 1:1:nTotalJobs
    fprintf(fptr, '%s%d = %d\n', stConstStringConfigLabels.stJobSequencingStrCfgLabel.strConstJobSeqHeader, ii, aiJobSeqInJspCfg(ii));
end
fprintf(fptr, '\n\n');

stGASetting = stBiFlowShopJobListInfo.stGASetting;
fprintf(fptr, '%s\n', stConstStringConfigLabels.stConstStringGASetting.strConstGASettingCfgLabel);
fprintf(fptr, '%s = %d\n', stConstStringConfigLabels.stConstStringGASetting.strConstFlagSeqByGA,        stGASetting.isSequecingByGA);
fprintf(fptr, '%s = %d\n', stConstStringConfigLabels.stConstStringGASetting.strConstFlagLoadRandStateGA, stGASetting.iFlagInitRandGeneratorSeed);
fprintf(fptr, '%s = %d\n', stConstStringConfigLabels.stConstStringGASetting.strConstGenePopSize,         stGASetting.iPopSize);
fprintf(fptr, '%s = %f\n', stConstStringConfigLabels.stConstStringGASetting.strConstGeneXoverRate,       stGASetting.fXoverRate);
fprintf(fptr, '%s = %f\n', stConstStringConfigLabels.stConstStringGASetting.strConstGeneMutateRate,      stGASetting.fMutateRate);
fprintf(fptr, '%s = %d\n', stConstStringConfigLabels.stConstStringGASetting.strConstGeneMaxGeneration,   stGASetting.iTotalGen);
fprintf(fptr, '%s = %f\n', stConstStringConfigLabels.stConstStringGASetting.strConstEpsStdByAveStopGA,   stGASetting.fEpsStdByAveMakespan);
fprintf(fptr, '\n\n');

%%%%%%%%%%%%%%%% Machine Capacity: one-period format
fprintf(fptr, '[MACHINE_ONE_PERIOD_CAP_INFO]\n');
for mm = 1:1:iTotalMachType
    fprintf(fptr, 'TOTAL_MACHINE_PER_TYPE_%d = %d\n', ...
        mm, stResourceConfig.iaMachCapOnePer(mm));
end
fprintf(fptr, '\n\n');

%%%%%%%%%%%%%%%% Machine Name Information
fprintf(fptr, '[MACHINE_NAME_INFO]\n');
for mm = 1:1:iTotalMachType
    fprintf(fptr, 'NAME_MACHINE_TYPE_%d = %s\n', ...
        mm, stResourceConfig.stMachineConfig(mm).strName);
end
fprintf(fptr, '\n\n');

%%%%%%%%%%%%%%% Multi-period machine capacity information
fprintf(fptr, '[MACHINE_MULTI_PERIOD_INFO]\n');
for mm = 1:1:iTotalMachType
    fprintf(fptr, 'NUM_TIME_POINT_SLOT_MACH_TYPE_%d = %d\n', ...
        mm, stResourceConfig.stMachineConfig(mm).iNumPointTimeCap);
end
fprintf(fptr, '\n\n');

for mm = 1:1:iTotalMachType
    if stResourceConfig.stMachineConfig(mm).iNumPointTimeCap >= 2
        fprintf(fptr, '[TIME_POINT_MACH_CAPACITY_TYPE_%d]\n', mm);
        for ff = 1:1:stResourceConfig.stMachineConfig(mm).iNumPointTimeCap
            fprintf(fptr, 'TIME_POINT_MACH_TYPE_%d_CAP_%d = %d\n', ...
                mm, ff, stResourceConfig.stMachineConfig(mm).afTimePointAtCap(ff));
        end
        fprintf(fptr, '\n');

        fprintf(fptr, '[MACH_CAPACITY_TIME_TYPE_%d]\n', mm);
        for ff = 1:1:stResourceConfig.stMachineConfig(mm).iNumPointTimeCap
            fprintf(fptr, 'MACH_TYPE_%d_CAP_TIME_POINT_%d = %d\n', ...
                mm, ff, stResourceConfig.stMachineConfig(mm).afMaCapAtTimePoint(ff));
        end
        fprintf(fptr, '\n\n');
    end
end

%%%%%%%%%%%%%%%% Forward Job Machine Time
for mm = 1:1:iTotalMachType
    fprintf(fptr, '[FORWARD_MACH_TIME_TYPE_%d]\n', mm);
    for ii = 1:1:stAgentBiFSPJobMachConfig.iTotalForwardJobs
        fprintf(fptr, 'MACH_TYPE_%d_TIME_FORWARD_%d = %d\n', ...
            mm, ii, stBiFlowShopJobListInfo.astMachineProcTimeOnMachine(mm).aForwardTimeMachineCycle(ii));
    end
    fprintf(fptr, '\n\n');
end

for mm = 1:1:iTotalMachType
    fprintf(fptr, '[REVERSE_MACH_TIME_TYPE_%d]\n', mm);
    for ii = 1:1:stAgentBiFSPJobMachConfig.iTotalReverseJobs
        fprintf(fptr, 'MACH_TYPE_%d_TIME_REVERSE_%d = %d\n', ...
            mm, ii, stBiFlowShopJobListInfo.astMachineProcTimeOnMachine(mm).aReverseTimeMachineCycle(ii));
    end
    fprintf(fptr, '\n\n');
end

fprintf(fptr, '%%%%%%%%%%%%%%%%%%%%%%%%%%%% \n');
fprintf(fptr, '%% MachineId includes MACH_TYPE_1_ID, MACH_TYPE_2_ID, MACH_TYPE_3_ID, ... \n');
fprintf(fptr, '%%          Valid MachineId: should be >0 [1, ..., MachineCapacity] \n');
fprintf(fptr, '%%          Flexible MachineId: 0, can be assigned by the scheduler, otherwise dedicated machine case (manully assignment) \n');
fprintf(fptr, '%%%%%%%%%%%%%%%%%%%%%%%%%%%% \n');

for mm = 1:1:iTotalMachType
    fprintf(fptr, '\n[FORWARD_MACH_ID_TYPE_%d]\n', mm);
    for ii = 1:1:stAgentBiFSPJobMachConfig.iTotalForwardJobs
         fprintf(fptr, 'MACH_TYPE_%d_ID_FORWARD_JOB_%d = %d\n', ...
             mm, ii, stBiFlowShopJobListInfo.astMachineProcTimeOnMachine(mm).aForwardJobOnMachineId(ii));
    end
    fprintf(fptr, '\n\n');
end

for mm = 1:1:iTotalMachType
    fprintf(fptr, '\n[REVERSE_MACH_ID_TYPE_%d]\n', mm);
    for ii = 1:1:stAgentBiFSPJobMachConfig.iTotalReverseJobs
         fprintf(fptr, 'MACH_TYPE_%d_ID_REVERSE_JOB_%d = %d\n', ...
             mm, ii, stBiFlowShopJobListInfo.astMachineProcTimeOnMachine(mm).aReverseJobOnMachineId(ii));
    end
    fprintf(fptr, '\n\n');
end

fprintf(fptr, '%%%%%%%%%%%%%%%%%%%%%%%%%%%% \n');
fprintf(fptr, '%% Release Time for a Machine is the minimum time required for a machine to be ready for next job\n');
fprintf(fptr, '%%%%%%%%%%%%%%%%%%%%%%%%%%%% \n');

for mm = 1:1:iTotalMachType
    fprintf(fptr, '\n[FORWARD_MACH_RELEASE_TIME_TYPE_%d]\n', mm);
    for ii = 1:1:stAgentBiFSPJobMachConfig.iTotalForwardJobs
         fprintf(fptr, 'MACH_TYPE_%d_RELEASE_TIME_AFTER_FORWARD_%d = %d\n', ...
             mm, ii, stBiFlowShopJobListInfo.astMachineProcTimeOnMachine(mm).aForwardRelTimeMachineCycle(ii));
    end
    fprintf(fptr, '\n\n');
end

for mm = 1:1:iTotalMachType
    fprintf(fptr, '\n[REVERSE_MACH_RELEASE_TIME_TYPE_%d]\n', mm);
    for ii = 1:1:stAgentBiFSPJobMachConfig.iTotalReverseJobs
         fprintf(fptr, 'MACH_TYPE_%d_RELEASE_TIME_AFTER_REVERSE_%d = %d\n', ...
             mm, ii, stBiFlowShopJobListInfo.astMachineProcTimeOnMachine(mm).aReverseRelTimeMachineCycle(ii));
    end
    fprintf(fptr, '\n\n');
end

fclose(fptr);
