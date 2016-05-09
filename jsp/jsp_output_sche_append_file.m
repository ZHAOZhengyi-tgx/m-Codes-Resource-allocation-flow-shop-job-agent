function jsp_output_sche_append_file(fptr, stJspSchedule)

fprintf(fptr, 'Job-Id,  Process [ProcessId, StartTime, EndTime, Duration, MachineType] ...\n');
iTotalJob = stJspSchedule.iTotalJob;
for ii = 1:1:iTotalJob
    fprintf(fptr, '%d, Process', ii);
    iTotalProcessAtJob = stJspSchedule.stProcessPerJob(ii);
    for jj = 1:1:iTotalProcessAtJob
        fprintf(fptr, '[%d, %4.1f, %4.1f, %4.1f, %d] ', ...
                                 jj, ...
                                    stJspSchedule.stJobSet(ii).fProcessStartTime(jj), ...
                                            stJspSchedule.stJobSet(ii).fProcessEndTime(jj), ...
                                                    stJspSchedule.stJobSet(ii).fProcessEndTime(jj) - stJspSchedule.stJobSet(ii).fProcessStartTime(jj), ...
                                                        stJspSchedule.stJobSet(ii).iProcessMachine(jj));
        
    end
    fprintf(fptr, '\n');
end
fprintf(fptr, '\n');
