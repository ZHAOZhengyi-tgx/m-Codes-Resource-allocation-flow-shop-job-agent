function [stJspSchedule, stDebugOutput, astRelTimeMachType] = psa_jsp_dispatch_machine_round_robin(stJspScheduleBeforeDispatch)
%
%
%
iPlotFlag = 0;
% Modification:
% 20070310, ZhengYI, Add consideration for multiple period machine capacity. stJspScheduleBeforeDispatch.stResourceConfig
% 20080113  Add astRelTimeMachType or later compatibility
% 20080520  for more flexible job shop 
% 20091216 dispatching machine with round-robin mechanism, ,
astRelTimeMachType = jsp_def_st_res_reltim_sche(stJspScheduleBeforeDispatch); % 20080113

for mm = 1:1:stJspScheduleBeforeDispatch.iTotalMachine
    if isfield(stJspScheduleBeforeDispatch, 'stResourceConfig')
        nMaxTotalMachineNum(mm) = max(stJspScheduleBeforeDispatch.stResourceConfig.stMachineConfig(mm).afMaCapAtTimePoint);
    else
        nMaxTotalMachineNum(mm) = stJspScheduleBeforeDispatch.iTotalMachineNum(mm);
    end
    for ii = 1:1:nMaxTotalMachineNum(mm)
        for tt = 1:1:stJspScheduleBeforeDispatch.iMaxEndTime
            stSpecificMachineTimeInfo(mm).stMachineIdTime(ii).TimeJob(tt) = 0;
        end
    end
end

jMaxProcess = 0;
for ii = 1:1:stJspScheduleBeforeDispatch.iTotalJob
    aJobIdAndProcessStartTimePerMachine(1, ii) = ii;
    for jj = 1:1:stJspScheduleBeforeDispatch.stProcessPerJob(ii)
        iMachineType = stJspScheduleBeforeDispatch.stJobSet(ii).iProcessMachine(jj);
        aJobIdAndProcessStartTimePerMachine(1+iMachineType, ii) = stJspScheduleBeforeDispatch.stJobSet(ii).iProcessStartTime(jj);
        aProcessIdForMachineJob(iMachineType, ii) = jj;
        if jMaxProcess < jj
            jMaxProcess = jj;
        end
    end
end

for mm = 1:1:stJspScheduleBeforeDispatch.iTotalMachine
    [tSortStartTime, iSortJobid] = sort(aJobIdAndProcessStartTimePerMachine(mm+1, :));
    aSortedJobIdForProcessStartTimePerMachine(mm, :) = iSortJobid;
    aSortedProcessIdForStartTime(mm, :) = aProcessIdForMachineJob(mm, iSortJobid);
end

%for ii = 1:1:stJspScheduleBeforeDispatch.iTotalJob
%    for jj = 1:1:stJspScheduleBeforeDispatch.stProcessPerJob(ii)
%        iSortedJobId = aSortedJobIdForProcessStartTimePerMachine(jj, ii);
%        iMachaneType = stJspScheduleBeforeDispatch.stJobSet(ii).iProcessMachine(jj);
for mm = 1:1:stJspScheduleBeforeDispatch.iTotalMachine
    kk = 0; %% dispatching machine with round-robin mechanism, 20091216, 

    for ii = 1:1:stJspScheduleBeforeDispatch.iTotalJob
        iMachaneType = mm;
        iSortedJobId = aSortedJobIdForProcessStartTimePerMachine(mm, ii);
        jj = aSortedProcessIdForStartTime(mm, ii);
        if jj ~= 0 %% for more flexible job shop % 20080520
            tSlotStart = stJspScheduleBeforeDispatch.stJobSet(iSortedJobId).iProcessStartTime(jj) + 1;
            tSlotEnd = stJspScheduleBeforeDispatch.stJobSet(iSortedJobId).fProcessEndTime(jj); 
            iSlotEnd = round(tSlotEnd); % 20080113

            %% kk = 0; move to outside for round-robin mechanism, 20091216
            nTrialTimesForMachineItem = 0; % round-robin mechanism, 20091216
            iFlagFindMachine = 0;
            while (nTrialTimesForMachineItem < nMaxTotalMachineNum(iMachaneType) & iFlagFindMachine == 0) % round-robin mechanism, 20091216
                kk = kk + 1; kk = mod(kk, nMaxTotalMachineNum(iMachaneType)) + 1; % round-robin mechanism, 20091216
                if stSpecificMachineTimeInfo(iMachaneType).stMachineIdTime(kk).TimeJob(tSlotStart) == 0
                    iFlagFindMachine = 1;
                    for tt = tSlotStart+1:1:iSlotEnd  % 20080113
                        if stSpecificMachineTimeInfo(iMachaneType).stMachineIdTime(kk).TimeJob(tt) ~= 0
                            iFlagFindMachine = 0;
                        end
                    end
                end
                nTrialTimesForMachineItem = nTrialTimesForMachineItem + 1; % round-robin mechanism, 20091216
            end
            if iFlagFindMachine == 0
                strText = sprintf('Error dispatch machine %d for job: %d, process %d', iMachaneType, iSortedJobId, jj);
                disp(strText);
                continue;
    %            error('Error dispatch machine')
            else
                kMachineId = kk;
            end
            
            for tt = tSlotStart:1:iSlotEnd % 20080113
                stSpecificMachineTimeInfo(iMachaneType).stMachineIdTime(kMachineId).TimeJob(tt) = iSortedJobId;   %% Job 
            end
            aVerifyProcessMachinePerJob(jj, iSortedJobId) = kMachineId;
            if iPlotFlag >= 4
                [iSortedJobId, jj, kMachineId]
            end
            stJspScheduleBeforeDispatch.stJobSet(iSortedJobId).iProcessMachineId(jj) = kMachineId;

            % 20080113
            astRelTimeMachType(mm).tRelTimeAtOneMach(kMachineId) = tSlotEnd;
        end
    end
end

stJspSchedule = stJspScheduleBeforeDispatch;
stDebugOutput.stSpecificMachineTimeInfo = stSpecificMachineTimeInfo;
stDebugOutput.aJobIdAndProcessStartTimePerMachine = aJobIdAndProcessStartTimePerMachine;
stDebugOutput.aSortedJobIdForProcessStartTimePerMachine = aSortedJobIdForProcessStartTimePerMachine;
stDebugOutput.aSortedProcessIdForStartTime = aSortedProcessIdForStartTime;
