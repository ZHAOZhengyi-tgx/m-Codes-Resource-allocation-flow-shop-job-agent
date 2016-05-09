function jsp_out_schedule_xls(stAgentJobListBiFsp, stJspSchedule, stSchedulePerformance)
% History
% YYYYMMDD  Notes
% 20080415  use system('dir') but not mtlb_system_version to judge DOS or
% UNIX system
iFlagDos =  system('dir');

stMachUtilizationInfo = stSchedulePerformance.stMachUtilizationInfo;

stRefXlsOutput = stAgentJobListBiFsp.stRefXlsOutput;
%%% Convert file name to be compatible with UNIX
%[iFlagDos, astrVer] = mtlb_system_version(); % 20070729

if iFlagDos == 0 %% it is a dos-windows system
%     disp('it is a dos-windows system');
    iPathStringList = strfind(stAgentJobListBiFsp.strJobListInputFilename, '\');
    strPathname = stAgentJobListBiFsp.strJobListInputFilename(1:iPathStringList(end));

else %% it is a UNIX or Linux system
    error('Only Windows system support XLS COM function');
end

%% get the starting location
strXlsOutFullFilename = strcat(strPathname, stRefXlsOutput.strFilenameRelativePath);
strSheetname = stRefXlsOutput.strSheetname;

strStartCell = sprintf('%s%d', stRefXlsOutput.strColStart, stRefXlsOutput.iRowStart);
%% build output cell matrix
nMaxNumProc = max(stJspSchedule.stProcessPerJob);
%% stRefXlsOutput.iFlagXlsTableFormat
% 1: general multi-machine job shop, [Start, End, MachineType, MachineId]
% 2: standard multi-machine flow-shop, [Start, End, MachineId]
for jj = 1:1:stJspSchedule.iTotalJob
    for ii = 1:1:stJspSchedule.stProcessPerJob(jj)
        if stRefXlsOutput.iFlagXlsTableFormat == 1
            strText = sprintf('[%d, %d, %d, %d]', ...
                stJspSchedule.stJobSet(jj).iProcessStartTime(ii), ...
                stJspSchedule.stJobSet(jj).iProcessEndTime(ii), ...
                stJspSchedule.stJobSet(jj).iProcessMachine(ii), ...
                stJspSchedule.stJobSet(jj).iProcessMachineId(ii));
        elseif stRefXlsOutput.iFlagXlsTableFormat == 2
            strText = sprintf('[%d, %d, %d]', ...
                stJspSchedule.stJobSet(jj).iProcessStartTime(ii), ...
                stJspSchedule.stJobSet(jj).iProcessEndTime(ii), ...
                stJspSchedule.stJobSet(jj).iProcessMachineId(ii));
        end
        cellScheduleXls(jj+1, ii+1) = {strText};
    end
end
for jj = 1:1:stJspSchedule.iTotalJob
    strText = sprintf('Job - %d', jj);
    cellScheduleXls(jj+1, 1) = {strText};
end
nMaxNumTasksPerJob = max(stJspSchedule.stProcessPerJob);
if stRefXlsOutput.iFlagXlsTableFormat == 1
    strText = sprintf('[t^s, t^e, m_type, m_id]');
elseif stRefXlsOutput.iFlagXlsTableFormat == 2
    strText = sprintf('[t^s, t^e, m_id]');
end
    cellScheduleXls(1, 1) = {strText};
for ii = 1:1:nMaxNumTasksPerJob
    strText = sprintf('Proc-%d ', ii);
    cellScheduleXls(1, ii+1) = {strText};
end

[iFlagSuccess, strMessage] = xlswrite(strXlsOutFullFilename, cellScheduleXls, strSheetname, strStartCell);
%% 

%% output makespan
strStartCell = sprintf('%s%d', stRefXlsOutput.strColStart, stRefXlsOutput.iRowStart - 2);
cellMakespanString(1, 1) = {'Makespan'};
cellMakespanString(2, 1) = {stJspSchedule.iMaxEndTime};
cellMakespanString(1, 2) = {'TotalWait'};
cellMakespanString(2, 2) = {stSchedulePerformance.nTotalWaitCount};
cellMakespanString(1, 3) = {'MaxWaitTime'};
cellMakespanString(2, 3) = {stSchedulePerformance.fMaxWaitTime};
cellMakespanString(1, 4) = {'MeanWaitTime'};
cellMakespanString(2, 4) = {stSchedulePerformance.fMeanWaitTime};
cellMakespanString(1, 5) = {'MaxUtiliz AllMach Percent'};
cellMakespanString(2, 5) = {stMachUtilizationInfo.fMaxUtilizAllMachPercent};
cellMakespanString(1, 6) = {'Mean Utiliz AllMach Percent'};
cellMakespanString(2, 6) = {stMachUtilizationInfo.fMeanUtilizAllMachPercent};
cellMakespanString(1, 7) = {'Mean CompleteTime'};
cellMakespanString(2, 7) = {stSchedulePerformance.fAveCompleteTime};

%%
[iFlagSuccess, strMessage] = xlswrite(strXlsOutFullFilename, cellMakespanString, strSheetname, strStartCell);

%% output machine utilization
cellMachUtilizeXls(1, 1) = {'Machine Type Name'};
cellMachUtilizeXls(2, 1) = {'Max Utilization (per cent)'};
cellMachUtilizeXls(3, 1) = {'Mean Utilization (per cent)'};
cellMachUtilizeXls(4, 1) = {'Sum Release Time (slot)'};
cellMachUtilizeXls(5, 1) = {'Mean Release Time (slot)'};

strStartCell = sprintf('%s%d', stRefXlsOutput.strColStart, stRefXlsOutput.iRowStart - 8);
for mm = 1:1:stJspSchedule.iTotalMachine
    strText = sprintf('%s', stJspSchedule.stResourceConfig.stMachineConfig(mm).strName);
    cellMachUtilizeXls(1, mm+1) = {strText};
    cellMachUtilizeXls(2, mm+1) = {stMachUtilizationInfo.afMaxPercentUtili(mm)};
    cellMachUtilizeXls(3, mm+1) = {stMachUtilizationInfo.afMeanPercentUtili(mm)};
    cellMachUtilizeXls(4, mm+1) = {stSchedulePerformance.afSumReleaseTimePerMachType(mm)};
    cellMachUtilizeXls(5, mm+1) = {stSchedulePerformance.afMeanRelaseTimePerMach(mm)};
    
end
cellMachUtilizeXls(1, mm + 3) = {'Total'};
cellMachUtilizeXls(2, mm + 3) = {stMachUtilizationInfo.fMaxUtilizAllMachPercent};
cellMachUtilizeXls(3, mm + 3) = {stMachUtilizationInfo.fMeanUtilizAllMachPercent};
cellMachUtilizeXls(4, mm + 3) = {stSchedulePerformance.fSumReleaseTimeAllMach};
cellMachUtilizeXls(5, mm + 3) = {stSchedulePerformance.fMeanReleaseTimeAllMach};

[iFlagSuccess, strMessage] = xlswrite(strXlsOutFullFilename, cellMachUtilizeXls, strSheetname, strStartCell);

%% output task priority
if isfield(stRefXlsOutput, 'strSheetnamePriority')
    strSheetname = stRefXlsOutput.strSheetnamePriority;
else
    strSheetname = 'Task Priority';
end

%% Start priority
astPriorityAtJobSet = stSchedulePerformance.astPriorityAtJobSet;
strStartCell = sprintf('%s%d', stRefXlsOutput.strColStart, stRefXlsOutput.iRowStart);
%% build output cell matrix
nMaxNumProc = max(stJspSchedule.stProcessPerJob);
%% stRefXlsOutput.iFlagXlsTableFormat
% 1: general multi-machine job shop, [Start, End, MachineType, MachineId]
% 2: standard multi-machine flow-shop, [Start, End, MachineId]
for jj = 1:1:stJspSchedule.iTotalJob
    for ii = 1:1:stJspSchedule.stProcessPerJob(jj)
        cellScheduleXls(jj+1, ii+1) = {astPriorityAtJobSet(jj).aiStartPriorityAtProc(ii) };
    end
end
for jj = 1:1:stJspSchedule.iTotalJob
    strText = sprintf('Job - %d', jj);
    cellScheduleXls(jj+1, 1) = {strText};
end
nMaxNumTasksPerJob = max(stJspSchedule.stProcessPerJob);
strText = sprintf('Task Start Priority (low value high priority)');
cellScheduleXls(1, 1) = {strText};
for ii = 1:1:nMaxNumTasksPerJob
    strText = sprintf('Proc-%d ', ii);
    cellScheduleXls(1, ii+1) = {strText};
end

[iFlagSuccess, strMessage] = xlswrite(strXlsOutFullFilename, cellScheduleXls, strSheetname, strStartCell);

%% End priority
astPriorityAtJobSet = stSchedulePerformance.astPriorityAtJobSet;
strStartCell = sprintf('%s%d', stRefXlsOutput.strColStart, stRefXlsOutput.iRowStart + stJspSchedule.iTotalJob + 10);
%% build output cell matrix
nMaxNumProc = max(stJspSchedule.stProcessPerJob);
%% stRefXlsOutput.iFlagXlsTableFormat
% 1: general multi-machine job shop, [Start, End, MachineType, MachineId]
% 2: standard multi-machine flow-shop, [Start, End, MachineId]
for jj = 1:1:stJspSchedule.iTotalJob
    for ii = 1:1:stJspSchedule.stProcessPerJob(jj)
        cellScheduleXls(jj+1, ii+1) = {astPriorityAtJobSet(jj).aiEndPriorityAtProc(ii) };
    end
end
for jj = 1:1:stJspSchedule.iTotalJob
    strText = sprintf('Job - %d', jj);
    cellScheduleXls(jj+1, 1) = {strText};
end
nMaxNumTasksPerJob = max(stJspSchedule.stProcessPerJob);
strText = sprintf('Task End Priority (low value high priority)');
cellScheduleXls(1, 1) = {strText};
for ii = 1:1:nMaxNumTasksPerJob
    strText = sprintf('Proc-%d ', ii);
    cellScheduleXls(1, ii+1) = {strText};
end

[iFlagSuccess, strMessage] = xlswrite(strXlsOutFullFilename, cellScheduleXls, strSheetname, strStartCell);
