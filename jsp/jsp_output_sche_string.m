function strOutput = jsp_output_sche_string(stJspSchedule)

strOutput = sprintf('Job-Id,  Process [ProcessId, StartTime, EndTime, Duration, MachineType] ...\n');
iTotalJob = stJspSchedule.iTotalJob;
for ii = 1:1:iTotalJob
    strTemp = sprintf('%d, Process', ii);
    strOutput = strcat(strOutput, strTemp);
    iTotalProcessAtJob = stJspSchedule.stProcessPerJob(ii);
    for jj = 1:1:iTotalProcessAtJob
        strTemp = sprintf('[%d, %4.1f, %4.1f, %4.1f, %d] ', ...
                                 jj, ...
                                    stJspSchedule.stJobSet(ii).fProcessStartTime(jj), ...
                                            stJspSchedule.stJobSet(ii).fProcessEndTime(jj), ...
                                                    stJspSchedule.stJobSet(ii).fProcessEndTime(jj) - stJspSchedule.stJobSet(ii).fProcessStartTime(jj), ...
                                                        stJspSchedule.stJobSet(ii).iProcessMachine(jj));
        strOutput = strcat(strOutput, strTemp);
    end
    strOutput = strcat(strOutput, '\n');
end
strOutput = strcat(strOutput, '\n');
