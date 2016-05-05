function [stJspSchedule, stDebugOutput, astRelTimeMachType] = psa_jsp_dispatch_machine_02(stJspScheduleBeforeDispatch)
% Port of Singapore Authorith dispatch machine
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%  
%
%The MIT License (MIT)
%
%Copyright (c) 2016 ZHAOZhengyi-tgx
%
%Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the "Software"), to deal in the Software without restriction, including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions:
%
%The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.
%
%THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%
% Module: Solution for Resource Allocation among Scheduling Agents 
% Template for Problem Input
% OUTPUT from the solver: schedule for each job's process, dispatching for each machine
% During this whole document, % is for line commenting, which means any line starting with a % will not be taken into parsing.
%
% all right reserved (c)2016
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% all right reserved, @2016, Sg.LongRenE@gmail.com
%
%
%
iPlotFlag = 0;
% Modification:
% 20070310, ZhengYI, Add consideration for multiple period machine capacity. stJspScheduleBeforeDispatch.stResourceConfig
% 20080113  Add astRelTimeMachType or later compatibility
% 20080520  for more flexible job shop 
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
    for ii = 1:1:stJspScheduleBeforeDispatch.iTotalJob
        iMachaneType = mm;
        iSortedJobId = aSortedJobIdForProcessStartTimePerMachine(mm, ii);
        jj = aSortedProcessIdForStartTime(mm, ii);
        if jj ~= 0 %% for more flexible job shop % 20080520
            tSlotStart = stJspScheduleBeforeDispatch.stJobSet(iSortedJobId).iProcessStartTime(jj) + 1;
            tSlotEnd = stJspScheduleBeforeDispatch.stJobSet(iSortedJobId).fProcessEndTime(jj); 
            iSlotEnd = round(tSlotEnd); % 20080113
            kk = 0;
            iFlagFindMachine = 0;
            while (kk < nMaxTotalMachineNum(iMachaneType) && iFlagFindMachine == 0)
                kk = kk + 1;
                if stSpecificMachineTimeInfo(iMachaneType).stMachineIdTime(kk).TimeJob(tSlotStart) == 0
                    iFlagFindMachine = 1;
                    for tt = tSlotStart+1:1:iSlotEnd  % 20080113
                        if stSpecificMachineTimeInfo(iMachaneType).stMachineIdTime(kk).TimeJob(tt) ~= 0
                            iFlagFindMachine = 0;
                        end
                    end
                end
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
                disp(['[iSortedJobId, jj, kMachineId]: ', num2str([iSortedJobId, jj, kMachineId])]);
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
