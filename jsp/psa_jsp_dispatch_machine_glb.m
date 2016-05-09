function [astJspSolution, stDebugOutput] = psa_jsp_dispatch_machine_glb(stGlobalJobInfo, astJspSolution)
%
%
%
% Modification:
% History, ToDo
% YYYYMMDD  Notes
% 20070310, ZhengYI, Add consideration for multiple period machine capacity. container_jsp_partial_solution.stResourceConfig
% 20072025, consider different starting time for all agents

iPlotFlag = stGlobalJobInfo.iPlotFlag;
for qq = 1:1:stGlobalJobInfo.iTotalAgent
    container_jsp_partial_solution(qq) = astJspSolution(qq).stSchedule_MinCost;
    
    tStartTime_datenum(qq) = datenum(stGlobalJobInfo.stAgentJobInfo(qq).atClockAgentJobStart.aClockYearMonthDateHourMinSec);
    tCompleteTime_datenum(qq) = tStartTime_datenum(qq) + container_jsp_partial_solution(qq).iMaxEndTime * container_jsp_partial_solution(qq).fTimeUnit_Min/60/24;
end
tEarliestStartTime = min(tStartTime_datenum); % 20072025
tLatestCompleteTime = max(tCompleteTime_datenum); % 20072025

iTotalTimeSlot = ceil((tLatestCompleteTime - tEarliestStartTime) * 24 * 60 / container_jsp_partial_solution(1).fTimeUnit_Min);
% 20072025
for qq = 1:1: stGlobalJobInfo.iTotalAgent
    fTimeSlot_inMin = container_jsp_partial_solution(qq).fTimeUnit_Min;
    iStartTimeSlot_Agent(qq) = floor((tStartTime_datenum(qq) - tEarliestStartTime) * 24 * 60 /fTimeSlot_inMin);
end % 20072025

%% initialize all machine to be free at beginning
for mm = 1:1:stGlobalJobInfo.stResourceConfig.iTotalMachine
    nMaxTotalMachineNum(mm) = max(stGlobalJobInfo.stResourceConfig.stMachineConfig(mm).afMaCapAtTimePoint);
    
    for ii = 1:1:nMaxTotalMachineNum(mm)
        for tt = 1:1:iTotalTimeSlot
            stSpecificMachineTimeInfo(mm).stMachineIdTime(ii).TimeJob(tt) = 0;
        end
    end
end

jMaxProcess = 0;
nJobCount = 0;
for qq = 1:1:stGlobalJobInfo.iTotalAgent
    for ii = 1:1:container_jsp_partial_solution(qq).iTotalJob
        nJobCount = nJobCount + 1;
        aAgJobIdProcStartTimeByMach(1, nJobCount) = qq;
        aAgJobIdProcStartTimeByMach(2, nJobCount) = ii;
        for jj = 1:1:container_jsp_partial_solution(qq).stProcessPerJob(ii)
            iMachineType = container_jsp_partial_solution(qq).stJobSet(ii).iProcessMachine(jj);
            %% need to consider different starting time for all agents,
            % 20072025
            if stGlobalJobInfo.iAlgoChoice == 22 | stGlobalJobInfo.iAlgoChoice == 25 % donot add start-time, for IP and LPR already considered start time
                aAgJobIdProcStartTimeByMach(2+iMachineType, nJobCount) = container_jsp_partial_solution(qq).stJobSet(ii).iProcessStartTime(jj);
            else
                aAgJobIdProcStartTimeByMach(2+iMachineType, nJobCount) = container_jsp_partial_solution(qq).stJobSet(ii).iProcessStartTime(jj) + iStartTimeSlot_Agent(qq);
            end  %% % 20072025

            aProcessIdForMachineJob(iMachineType, nJobCount) = jj;
            if jMaxProcess < jj
                jMaxProcess = jj;
            end
        end
    end
end

for mm = 1:1:stGlobalJobInfo.stResourceConfig.iTotalMachine
    [tSortStartTime, iSortJobid] = sort(aAgJobIdProcStartTimeByMach(mm+2, :));
    aSortedJobIdProcStartTime(mm, :) = aAgJobIdProcStartTimeByMach(2,iSortJobid);
    aSortedAgentIdProcStartTime(mm, :) = aAgJobIdProcStartTimeByMach(1,iSortJobid);
    aSortedProcessIdForStartTime(mm, :) = aProcessIdForMachineJob(mm, iSortJobid);
end

if iPlotFlag >= 3
    nMaxTotalMachineNum
    stSpecificMachineTimeInfo
end

for mm = 1:1:stGlobalJobInfo.stResourceConfig.iTotalMachine
    for ii = 1:1:nJobCount
        iMachaneType = mm;
        iSortedJobId = aSortedJobIdProcStartTime(iMachaneType, ii);
        jj = aSortedProcessIdForStartTime(iMachaneType, ii);
        iAgentId = aSortedAgentIdProcStartTime(iMachaneType, ii);
        % 20072025
        if stGlobalJobInfo.iAlgoChoice == 22 | stGlobalJobInfo.iAlgoChoice == 25 ...
                | stGlobalJobInfo.iAlgoChoice == 17  % donot add start-time, for IP and LPR already considered start time
            tSlotStart = ...
                round(container_jsp_partial_solution(iAgentId).stJobSet(iSortedJobId).iProcessStartTime(jj)+1);
            tSlotEnd = ...
                round(container_jsp_partial_solution(iAgentId).stJobSet(iSortedJobId).iProcessEndTime(jj));
        else
            tSlotStart = ...
                round(container_jsp_partial_solution(iAgentId).stJobSet(iSortedJobId).iProcessStartTime(jj) +1 ...
                + iStartTimeSlot_Agent(iAgentId));
            tSlotEnd = ...
                round(container_jsp_partial_solution(iAgentId).stJobSet(iSortedJobId).iProcessEndTime(jj) ...
                + iStartTimeSlot_Agent(iAgentId));
        end
        % 20072025
        kk = 0;
        iFlagFindMachine = 0;
        while (kk < nMaxTotalMachineNum(iMachaneType) & iFlagFindMachine == 0)
            kk = kk + 1;
%             tSlotStart
            if stSpecificMachineTimeInfo(iMachaneType).stMachineIdTime(kk).TimeJob(tSlotStart) == 0
                iFlagFindMachine = 1;
                for tt = tSlotStart+1:1:tSlotEnd
                	if stSpecificMachineTimeInfo(iMachaneType).stMachineIdTime(kk).TimeJob(tt) ~= 0
                	    iFlagFindMachine = 0;
                	end
                end
            end
        end
        if iFlagFindMachine == 0
            strText = sprintf('Error dispatch machine %d for agent: %d, job: %d, process %d', iMachaneType, iAgentId, iSortedJobId, jj);
            for kk = 1:1: nMaxTotalMachineNum(iMachaneType)
                kk_TimeStart_TimeEnd_UtilityTimeStartToEnd = [kk, tSlotStart, tSlotEnd, ...
                    stSpecificMachineTimeInfo(iMachaneType).stMachineIdTime(kk).TimeJob(tSlotStart:tSlotEnd)]
            end
            disp(strText);
%            input('any key')
%            continue;
%            error('Error dispatch machine')
        else
            kMachineId = kk;
        end
        for tt = tSlotStart:1:tSlotEnd
            stSpecificMachineTimeInfo(iMachaneType).stMachineIdTime(kMachineId).TimeJob(tt) = iSortedJobId;   %% Job 
        end
        aVerifyProcessMachinePerJob(jj, iSortedJobId) = kMachineId;
        if iPlotFlag >= 4
            [iSortedJobId, jj, kMachineId]
        end
        if mm == 1 & nMaxTotalMachineNum(mm) == stGlobalJobInfo.iTotalAgent %% it is a critical machine type, total machine number == total agent number
            container_jsp_partial_solution(iAgentId).stJobSet(iSortedJobId).iProcessMachineId(jj) = iAgentId;
        else
            container_jsp_partial_solution(iAgentId).stJobSet(iSortedJobId).iProcessMachineId(jj) = kMachineId;
        end
    end

end

for qq = 1:1:stGlobalJobInfo.iTotalAgent
    astJspSolution(qq).stSchedule_MinCost = container_jsp_partial_solution(qq);
    for mm = 1:1:stGlobalJobInfo.stResourceConfig.iTotalMachine
        astJspSolution(qq).stSchedule_MinCost.iTotalMachineNum(mm) = nMaxTotalMachineNum(mm);
    end
end

stDebugOutput.stSpecificMachineTimeInfo = stSpecificMachineTimeInfo;
stDebugOutput.aAgJobIdProcStartTimeByMach = aAgJobIdProcStartTimeByMach;
stDebugOutput.aSortedJobIdProcStartTime = aSortedJobIdProcStartTime;
stDebugOutput.aSortedProcessIdForStartTime = aSortedProcessIdForStartTime;
