function [jsp_process_time] = jsp_load_time_process_float(jsp_name_label, iTotalJob, jsp_process_whole)


fptr = jsp_name_label.fptr; 

strConstTimeProcessHeader = jsp_name_label.strConstTimeProcessHeader;
lenConstTimeProcessHeader = length(strConstTimeProcessHeader);

iReadCount = 0;
strLine = fgets(fptr);
iTotalProcessAllJob = sum(jsp_process_whole);

while iReadCount <= iTotalProcessAllJob - 1
   strLine = sprintf('%sMINIMIMLENGTH_TO_BE_COMPATIBLE_WITH_READER', strLine);
   if strLine(1:lenConstTimeProcessHeader) == strConstTimeProcessHeader
       fReadData = sscanf(strLine((lenConstTimeProcessHeader + 1): end), '%d_PROCESS_%d = %f');
       jsp_process_time(fReadData(1)).iProcessTime(fReadData(2)) = round(fReadData(3));
       jsp_process_time(fReadData(1)).fProcessTime(fReadData(2)) = fReadData(3);
       if fReadData(1) > iTotalJob
           strText = sprintf('check %s', strConstTimeProcessHeader);
           disp(strText);
           error('Exceed total job');
       end
       if fReadData(2) > jsp_process_whole(fReadData(1))
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
