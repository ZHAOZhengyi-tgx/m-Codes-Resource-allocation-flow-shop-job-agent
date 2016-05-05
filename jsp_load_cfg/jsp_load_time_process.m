function [jsp_process_time] = jsp_load_time_process(jsp_name_label, iTotalJob, jsp_process_whole)


fptr = jsp_name_label.fptr; 

strConstTimeProcessHeader = jsp_name_label.strConstTimeProcessHeader;
lenConstTimeProcessHeader = length(strConstTimeProcessHeader);

iReadCount = 0;
strLine = fgets(fptr);
iTotalProcessAllJob = sum(jsp_process_whole);

while iReadCount <= iTotalProcessAllJob - 1
   strLine = sprintf('%sMINIMIMLENGTH_TO_BE_COMPATIBLE_WITH_READER', strLine);
   if strLine(1:lenConstTimeProcessHeader) == strConstTimeProcessHeader
       iReadData = sscanf(strLine((lenConstTimeProcessHeader + 1): end), '%d_PROCESS_%d = %d');
       jsp_process_time(iReadData(1)).iProcessTime(iReadData(2)) = iReadData(3);
       if iReadData(1) > iTotalJob
           strText = sprintf('check %s', strConstTimeProcessHeader);
           disp(strText);
           error('Exceed total job');
       end
       if iReadData(2) > jsp_process_whole(iReadData(1))
           strText = sprintf('check %s', strConstTimeProcessHeader);
           disp(strText);
           error('Exceed total process');
       end
       iReadCount = iReadCount + 1;
   elseif feof(fptr)
       strText = sprintf('check %s', strConstTimeProcessHeader);
       disp(strText);
       error('Not compatible input. ');
   end
   strLine = fgets(fptr);
end
