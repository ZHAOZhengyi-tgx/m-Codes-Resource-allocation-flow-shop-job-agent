function [strFileName] = resalloc_save_config(stResAllocGenJspAgent, strFilenamePrefix)
%% History
%% YYYYMMDD Notes
% 20080301 Add stBidGenSubProbSearch
% 20071220 add iSolverPackage 
if nargin <= 1
    strFileFullName = stResAllocGenJspAgent.strInputFilename;
    [s,strSystem] = system('ver');
    if s == 0 %% it is a dos-windows system
        iPathStringList = strfind(strFileFullName, '\');
    else %% it is a UNIX or Linux system
        iPathStringList = strfind(strFileFullName, '/');
    end

    strFilenamePrefix = strFileFullName(1:iPathStringList(end))
end

stSystemMasterConfig = stResAllocGenJspAgent.stSystemMasterConfig;
stResourceConfig = stResAllocGenJspAgent.stResourceConfig;
iTotalMachType = stSystemMasterConfig.iTotalMachType;
nTotalAgent = stSystemMasterConfig.iTotalAgent;
nTotalFramePlanning = stSystemMasterConfig.iMaxFramesForPlanning;

strFileName = sprintf('%sResAlloc_Agent%d_Res%d_Algo%d.ini', ...
           strFilenamePrefix, ...
           nTotalAgent, ...
           iTotalMachType, ...
           stSystemMasterConfig.iAlgoChoice);
       
fptr = fopen(strFileName, 'w');

fprintf(fptr, '%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%  \n');
fprintf(fptr, '%% Project:  IMSS- Integrated Manufacturing & Service Systems    \n');
fprintf(fptr, '%%\n');
fprintf(fptr, '%%\n');
fprintf(fptr, '%% Module: Solution for Resource Allocation among Scheduling Agents \n');
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
fprintf(fptr, '%%             Shuzhi, Sam, GE (samge@nus.edu.sg) \n');
fprintf(fptr, '%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%\n');
fprintf(fptr, '\n\n');

fprintf(fptr, '[SYSTEM_RESOURCE_CONFIG]\n');
fprintf(fptr, 'TOTAL_AGENT = %d\n',          stSystemMasterConfig.iTotalAgent);
fprintf(fptr, 'TOTAL_MACHINE_TYPE = %d\n',   stSystemMasterConfig.iTotalMachType);
fprintf(fptr, 'TIME_FRAME_UNIT_HOUR = %d\n', stSystemMasterConfig.fTimeFrameUnitInHour);
fprintf(fptr, 'OBJ_FUNCTION = %d\n',         stSystemMasterConfig.iObjFunction);
fprintf(fptr, 'ALGO_CHOICE = %d\n',          stSystemMasterConfig.iAlgoChoice);
fprintf(fptr, 'PLOT_FLAG = %d\n',            stSystemMasterConfig.iPlotFlag);
fprintf(fptr, 'CRITICAL_MACHINE_TYPE = %d\n',   stSystemMasterConfig.iCriticalMachType);
fprintf(fptr, 'MAX_FRAMES_FOR_PLANNING = %d\n', stSystemMasterConfig.iMaxFramesForPlanning);
fprintf(fptr, 'IP_PACKAGE = %d\n', stSystemMasterConfig.iSolverPackage);
fprintf(fptr, '\n\n');
% 'iSolverPackage', 1); % 20071130, % 20071220 add iSolverPackage 

%%%%%%%%%%%%%%%% JSS problem struct 20070724
fprintf(fptr, '[JSS_PROBLEM_CONFIG]\n');
fprintf(fptr, 'IS_PREEMPTIVE = %d\n', stResAllocGenJspAgent.stJssProbStructConfig.isPreemptiveProcess);
fprintf(fptr, 'IS_WAIT_IN_PROCESS = %d\n', stResAllocGenJspAgent.stJssProbStructConfig.isWaitInProcess);
fprintf(fptr, 'IS_CRITICAL_OPERATION_SEQUENCE = %d\n', stResAllocGenJspAgent.stJssProbStructConfig.isCriticalOperateSeq);
fprintf(fptr, 'IS_MACHINE_RELEASE_IMMEDIATELY_AFTER_PROC = %d\n', stResAllocGenJspAgent.stJssProbStructConfig.isMachineReleaseImmediate);
fprintf(fptr, 'IS_SEMI_COS = %d\n', stResAllocGenJspAgent.stJssProbStructConfig.isSemiCOS);
fprintf(fptr, 'IS_FLEXI_COS = %d\n', stResAllocGenJspAgent.stJssProbStructConfig.isFlexiCOS);
fprintf(fptr, 'OBJ_OPTION = %d\n', stResAllocGenJspAgent.stJssProbStructConfig.iFlagObjFuncDefine);
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

fprintf(fptr, '[AGENT_JOB_LIST]\n');
for aa = 1:1:nTotalAgent
    aiPathChar = strfind(stResAllocGenJspAgent.strFileAgentJobList(aa).strFilename, '\');
    iFileNameStart = aiPathChar(end)+1;
    fprintf(fptr, 'JOB_LIST_FILE_AGENT_%d = ..\\%s\n', aa, stResAllocGenJspAgent.strFileAgentJobList(aa).strFilename(iFileNameStart:end));
end
fprintf(fptr, '\n\n');

fprintf(fptr, '[PRICE_ADJUSTMENT_IN_AUCTION]\n');
fprintf(fptr, 'PA_STRATEGY = %d\n',     stResAllocGenJspAgent.stPriceAjustment.iFlagStrategy);
fprintf(fptr, 'ALPHA_STEP_SIZE = %f\n', stResAllocGenJspAgent.stPriceAjustment.fAlpha);
fprintf(fptr, '\n\n');

stAuctionStrategy = stResAllocGenJspAgent.stAuctionStrategy;
fprintf(fptr, '[AUCTION_STRATEGY]\n');
fprintf(fptr, 'FLAG_MAKESPAN_FUNCTION = %d\n',             stAuctionStrategy.iFlagMakeSpanFunction);
fprintf(fptr, 'FLAG_SYNCHRONOUS_BIDDING_ADJUSTING = %d\n', stAuctionStrategy.iSynchUpdatingBid);
fprintf(fptr, 'FLAG_WINNER_DETERMINATION = %d\n',          stAuctionStrategy.iHasWinnerDetermination);
fprintf(fptr, 'MIN_NUM_ITERATION = %d\n',                  stAuctionStrategy.iMinIteration);
fprintf(fptr, 'MAX_NUM_ITERATION = %d\n',                  stAuctionStrategy.iMaxIteration);
fprintf(fptr, 'DELTA_OBJECTIVE_VALUE = %f\n',              stAuctionStrategy.fDeltaObj);
fprintf(fptr, 'DELTA_PRICE = %f\n',                        stAuctionStrategy.fDeltaPrice);
fprintf(fptr, 'MIN_NUM_FEASIBLE_SOLUTION = %d\n',          stAuctionStrategy.iMinNumFeasibleSolution);
fprintf(fptr, 'CONVERGING_RULE = %d\n',                    stAuctionStrategy.iConvergingRule);
fprintf(fptr, 'NUM_ITER_DEOSCILATING = %d\n',              stAuctionStrategy.iNumIterDeOscilating);
fprintf(fptr, '\n\n');

stBidGenSubProbSearch = stResAllocGenJspAgent.stBidGenSubProbSearch;  % 20080301
fprintf(fptr, '[BIDGEN_SUBSEARCH_SETTING]\n');
fprintf(fptr, 'BIDGEN_SUBSEARCH_ALGO = %d\n',           stBidGenSubProbSearch.iFlag_BidGenAlgo);
fprintf(fptr, 'BIDGEN_FLAG_SORTING_PRICE = %d\n',       stBidGenSubProbSearch.iFlagSortingPrice);
fprintf(fptr, 'BIDGEN_MAX_ITER_SUB_SEARCH = %d\n',      stBidGenSubProbSearch.iMaxIter_LocalSearchBidGen);
fprintf(fptr, 'BIDGEN_OPTION_STRICT_SEARCH = %d\n',     stBidGenSubProbSearch.iFlagRunStrictSrch);
fprintf(fptr, '\n\n');

fprintf(fptr, '[AGENT_PRICE_PER_FRAME]\n');
for aa = 1:1:nTotalAgent
    fprintf(fptr, 'PRICE_AGENT_%d = %f\n', aa, stResAllocGenJspAgent.stAgentJobInfo(aa).fPriceQuayCraneDollarPerFrame);
end
fprintf(fptr, '\n\n');

fprintf(fptr, '[AGENT_JOB_START_DATE]\n');
for aa = 1:1:nTotalAgent
    strDateJobStart = datestr(stResAllocGenJspAgent.stAgentJobInfo(aa).atClockAgentJobStart.aClockYearMonthDateHourMinSec, 'dd/mm/yyyy');
    fprintf(fptr, 'START_DATE_AGENT_%d = %s\n', aa, strDateJobStart);
end
fprintf(fptr, '\n\n');

fprintf(fptr, '[AGENT_JOB_DUE_DATE]]\n');
for aa = 1:1:nTotalAgent
    strDateJobDue = datestr(stResAllocGenJspAgent.stAgentJobInfo(aa).atClockAgentJobDue.aClockYearMonthDateHourMinSec, 'dd/mm/yyyy');
    fprintf(fptr, 'DUE_DATE_AGENT_%d = %s\n', aa, strDateJobDue);
end
fprintf(fptr, '\n\n');

fprintf(fptr, '[AGENT_JOB_START_TIME]\n');
for aa = 1:1:nTotalAgent
    strTimeJobStart = datestr(stResAllocGenJspAgent.stAgentJobInfo(aa).atClockAgentJobStart.aClockYearMonthDateHourMinSec, 'HH:MM');
    fprintf(fptr, 'START_TIME_AGENT_%d = %s\n', aa, strTimeJobStart);
end
fprintf(fptr, '\n\n');

fprintf(fptr, '[AGENT_JOB_DUE_TIME]\n');
for aa = 1:1:nTotalAgent
    strTimeJobDue = datestr(stResAllocGenJspAgent.stAgentJobInfo(aa).atClockAgentJobDue.aClockYearMonthDateHourMinSec, 'HH:MM');
    fprintf(fptr, 'DUE_TIME_AGENT_%d = %s\n', aa, strTimeJobDue);
end
fprintf(fptr, '\n\n');

fprintf(fptr, '[AGENT_JOB_LATE_PENALTY_SGD_PER_FRAME]\n');
for aa = 1:1:nTotalAgent
    fprintf(fptr, 'LATE_PENALTY_AGENT_%d = %f\n', aa,  stResAllocGenJspAgent.stAgentJobInfo(aa).fLatePenalty_DollarPerFrame);
end
fprintf(fptr, '\n\n');

for mm = 1:1:iTotalMachType
    fprintf(fptr, '[MACHINE_TYPE_%d_PRICE_PER_TIME_FRAME_IN_PLANNING]\n', mm);
    for tt = 1:1:nTotalFramePlanning
        fprintf(fptr, 'MACHINE_TYPE_%d_PRICE_T_FRAME_%d = %f\n', mm, tt, stResAllocGenJspAgent.astResourceInitPrice(mm).afMachinePriceListPerFrame(tt));
    end
    fprintf(fptr, '\n\n');
end

fclose(fptr);
