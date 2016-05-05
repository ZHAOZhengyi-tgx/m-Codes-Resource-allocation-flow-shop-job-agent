function psa_fsp_gen_bidding_report(stBerthJobInfo, stAgentJobListBiFsp, stAgent_Solution, stMachineUsageInfoByAgent, strSufix, stBerthSolution)
% prototype
% psa_fsp_gen_bidding_report(stBerthJobInfo, stAgentJobListBiFsp,
% stAgent_Solution, stMachineUsageInfoByAgent, strSufix, stBerthSolution)
% 20070605  improve stoping criterion zzy

iTotalTotalAgent = stBerthJobInfo.iTotalAgent;
iTotalYC = stBerthJobInfo.stResourceConfig.iaMachCapOnePer(3);
iTotalPM = stBerthJobInfo.stResourceConfig.iaMachCapOnePer(2);

iLenNameNoExt = strfind(stBerthJobInfo.strInputFilename, '.') - 1;
strFileName = sprintf('%s_BerthReport_%s.txt', ...
           stBerthJobInfo.strInputFilename(1:iLenNameNoExt), ...
           strSufix);
fptr = fopen(strFileName, 'w');

fprintf(fptr, '%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%  \n');
fprintf(fptr, '%% Project: Solution for Port Container Discharging & Loading Scheduling Problem    \n');
fprintf(fptr, '%%\n');
fprintf(fptr, '%% This is a computer generated file \n');
fprintf(fptr, '%%\n');
fprintf(fptr, '\n\n');

fprintf(fptr, '%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%  \n');
fprintf(fptr, 'Input filename: %s\n\n', stBerthJobInfo.strInputFilename);
fprintf(fptr, '\n\n');

fprintf(fptr, 'JobNum,     PriceMakespan         DelayPenalty   CancelPenalty\n');
for qq = 1:1:stBerthJobInfo.iTotalAgent
    fprintf(fptr, '%d,  \t%4.1f,   \t%4.1f   TBA\n', qq, stBerthJobInfo.stAgentJobInfo(qq).fPriceAgentDollarPerFrame, stBerthJobInfo.stAgentJobInfo(qq).fLatePenalty_DollarPerFrame);
end
fprintf(fptr, '\n\n');

fprintf(fptr, 'Total Resource:  PM - %d, YC - %d\n\n', iTotalPM, iTotalYC);

fprintf(fptr, '%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%  \n');
fprintf(fptr, 'Output Bidding\n\n');
for qq = 1:1:iTotalTotalAgent
    fprintf(fptr, 'Job List Execution Period for TotalAgent -- %d: \n', qq);
    fprintf(fptr, 'Job start: %s\n', stMachineUsageInfoByAgent.stMachineBiddingInfo(qq).stBiddingPeriod.strJobStartTime);
    fprintf(fptr, 'Job Complete: %s\n', stMachineUsageInfoByAgent.stMachineBiddingInfo(qq).stBiddingPeriod.strJobCompleteTime);
    fprintf(fptr, 'Bidding for TotalAgent--%d: \n', qq);
    fprintf(fptr, 'NumPeriod       \tStartTime    \tEndTime     \tBidNumPM     \tBidNumYC\n');
    
    if stBerthJobInfo.iObjFunction == 5
        for tt = 1:1:stMachineUsageInfoByAgent.stMachineBiddingInfo(qq).stBiddingPeriod.iTotalTimePeriod
                fprintf(fptr, '%d,    \t%s,      \t%s,      \t%d,   \t%d\n', ...
                    tt, ...
                    datestr(stMachineUsageInfoByAgent.stMachineBiddingInfo(qq).stBiddingPeriod.tPeriodStartTime(tt), 13), ...
                    datestr(stMachineUsageInfoByAgent.stMachineBiddingInfo(qq).stBiddingPeriod.tPeriodEndTime(tt), 13), ...
                    max([stMachineUsageInfoByAgent.stMachineBiddingInfo(qq).astMachineBidding(2).aMachineUsageAtPeriod(tt) - stAgentJobListBiFsp(qq).MaxVirtualPrimeMover, 0]), ...
                    max([stMachineUsageInfoByAgent.stMachineBiddingInfo(qq).astMachineBidding(3).aMachineUsageAtPeriod(tt) - stAgentJobListBiFsp(qq).MaxVirtualYardCrane, 0])  );
        end
    else
        for tt = 1:1:stMachineUsageInfoByAgent.stMachineBiddingInfo(qq).stBiddingPeriod.iTotalTimePeriod
                fprintf(fptr, '%d,    \t%s,      \t%s,      \t%d,   \t%d\n', ...
                    tt, ...
                    datestr(stMachineUsageInfoByAgent.stMachineBiddingInfo(qq).stBiddingPeriod.tPeriodStartTime(tt), 13), ...
                    datestr(stMachineUsageInfoByAgent.stMachineBiddingInfo(qq).stBiddingPeriod.tPeriodEndTime(tt), 13), ...
                    stMachineUsageInfoByAgent.stMachineBiddingInfo(qq).astMachineBidding(2).aMachineUsageAtPeriod(tt), ...
                    stMachineUsageInfoByAgent.stMachineBiddingInfo(qq).astMachineBidding(3).aMachineUsageAtPeriod(tt)  );
        end
    end
    fprintf(fptr, '%%-------------------------------------------------------------------------%%  \n');
end
fprintf(fptr, '\n\n');

fprintf(fptr, '%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%  \n');
fprintf(fptr, 'Solution Performance Report\n');
fprintf(fptr, 'Agentid, GCR(GrossCraneRate), SolutionTime, Makespan, CostMakespanTardiness,  TotalCost\n');
fprintf(fptr, '         , mph(move per hour),  second,       hour,     dollars,                dollars\n');
for qq = 1:1:iTotalTotalAgent
    fprintf(fptr, '%d,     %4.2f,          %4.2f,           %4.2f,             %4.2f,          %4.2f\n', ...
                 qq, stAgent_Solution(qq).stPerformReport.tMinCostGrossCraneRate, ...
                     stAgent_Solution(qq).stPerformReport.tSolutionTime_sec, ...
                     stAgent_Solution(qq).stPerformReport.tMinCostMakeSpan_hour, ...
                     stAgent_Solution(qq).stPerformReport.fCostMakespanTardiness, ...
                     stAgent_Solution(qq).stPerformReport.fMinCost);
end

if strSufix(1:3) == 'Fin'
    if ( stBerthJobInfo.iAlgoChoice == 4 |stBerthJobInfo.iAlgoChoice == 5 | stBerthJobInfo.iAlgoChoice == 7 | stBerthJobInfo.iAlgoChoice == 18 | ...
            stBerthJobInfo.iAlgoChoice == 19 | stBerthJobInfo.iAlgoChoice == 20 | stBerthJobInfo.iAlgoChoice == 21) ...
        fprintf(fptr, '%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% Heuristic Solution %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%  \n');
        fprintf(fptr, 'total iteration: %d\n', length(stBerthSolution.stSolutionInfo.s_r));
        fprintf(fptr, 'initialization time: %4.2f\n', stBerthSolution.tSolutionTimeInitialization_sec);
        fprintf(fptr, 'solution time: %4.2f\n',  stBerthSolution.tSolutionTime_sec);

        if stBerthSolution.stSolutionInfo.iFlagSolution == 0
            fprintf(fptr, 'IT IS A manually adjusted feasible solution\n');
        elseif stBerthSolution.stSolutionInfo.iFlagSolution == 1
            fprintf(fptr, 'IT IS A best in history feasible solution\n');
        elseif stBerthSolution.stSolutionInfo.iFlagSolution == 2
            fprintf(fptr, 'IT IS A Equilibrium Solution\n');
        else
            fprintf(fptr, 'IT IS A infeasible solution\n');
        end
    %%% report whether it is a feasible solution
        fprintf(fptr, 'Total Cases of Feasible Solution During Auction Iteration: %d\n', stBerthSolution.stSolutionInfo.nTotalFeasibleSolution);
        fprintf(fptr, 'Total Cost (Makespan & Tardiness) for all TotalAgents: %f\n', stBerthSolution.stSolutionInfo.fTotalCostMakespanTardiness);
        fprintf(fptr, 'Feasibility of final solution: \n');
        if stBerthSolution.stConstraintVialationInfo.nTotalCaseViolation == 0
            fprintf(fptr, 'Feasibility: no confliction, all resolved.\n');
        else
            fprintf(fptr, 'Not Feasible Solution: no. confliction -- %d\n', stBerthSolution.stConstraintVialationInfo.nTotalCaseViolation);
            astCaseViolation = stBerthSolution.stConstraintVialationInfo.astCaseViolation;
            fprintf(fptr, '[ConflictionTimeFrame, ConflictResourceMachineId, TotalViolationDemandMinusSupply]\n');
            for ii = 1:1:stBerthSolution.stConstraintVialationInfo.nTotalCaseViolation

                fprintf(fptr, '[%d, %d, %d]\n', astCaseViolation(ii).iTimeFrameWithViolation, ...
                    astCaseViolation(ii).iMachineResourceViolation, ...
                    astCaseViolation(ii).nTotalViolation);
            end
        end
        fprintf(fptr, '\n\n');
    elseif  stBerthJobInfo.iAlgoChoice == 17 | stBerthJobInfo.iAlgoChoice == 22 | stBerthJobInfo.iAlgoChoice == 25
        fprintf(fptr, '%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%  Solver Solution %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%  \n');
        fprintf(fptr, 'initialization time: %4.2f\n', stBerthSolution.tSolutionTimeInitialization_sec);
        fprintf(fptr, 'solution time: %4.2f\n',  stBerthSolution.tSolutionTime_sec);
        fprintf(fptr, 'Total Cost (Makespan & Tardiness) for all TotalAgents: %f\n', stBerthSolution.stSolutionInfo.fTotalCostMakespanTardiness);
        fprintf(fptr, 'Best Objetive Value Returned by Solver: %f\n', stBerthSolution.stSolutionInfo.fObjValue);
    end
end

fprintf(fptr, '%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%  \n');
fprintf(fptr, 'Output Schedule\n\n');

for qq = 1:1:iTotalTotalAgent
    stJspSchedule = stAgent_Solution(qq).stSchedule_MinCost;
    fprintf(fptr, 'Schedule TotalAgent-%d\n', qq);
    
    jsp_output_sche_append_file(fptr, stJspSchedule);
%     strOutput = jsp_output_sche_string(stJspSchedule);
%     fprintf(fptr, '%s', strOutput);

    stJspSchedule = [];
    fprintf(fptr, '\n');
end

% fprintf(fptr, 'Resource Price: \n');
% iTotalTimeFramePerDay = ceil(24 / stBerthJobInfo.fTimeFrameUnitInHour);
% fprintf(fptr, 'TimePeriodNum,     PrimeMover(PM)         YardCrane(YC)\n');
% for tt = 1:1:iTotalTimeFramePerDay
%    fprintf(fptr, '%d,  \t%4.1f,   \t%4.1f\n', tt, stBerthJobInfo.astResourceInitPrice(2).afMachinePriceListPerFrame(tt), stBerthJobInfo.astResourceInitPrice(3).afMachinePriceListPerFrame(tt));
% end

fclose(fptr);

