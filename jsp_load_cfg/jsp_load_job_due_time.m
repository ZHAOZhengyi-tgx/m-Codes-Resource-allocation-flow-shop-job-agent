function [jsp_due_time] = jsp_load_job_due_time(jsp_name_label, iTotalJob)

fptr = jsp_name_label.fptr; 

strConstJobDueTimeHeader = jsp_name_label.strConstJobDueTimeHeader;
lenConstJobDueTimeHeader = length(strConstJobDueTimeHeader);

iReadCount = 0;
strLine = fgets(fptr);

while iReadCount <= iTotalJob - 1
   strLine = sprintf('%sMINIMIMLENGTH_TO_BE_COMPATIBLE_WITH_READER', strLine);
   if strLine(1:lenConstJobDueTimeHeader) == strConstJobDueTimeHeader
       iReadData = sscanf(strLine((lenConstJobDueTimeHeader + 1): end), '%d = %d');
       jsp_due_time(iReadData(1)) = iReadData(2);
       if iReadData(1) > iTotalJob
           strText = sprintf('check %s', strConstJobDueTimeHeader);
           disp(strText);
           error('Exceed total job');
       end
       iReadCount = iReadCount + 1;
   elseif feof(fptr)
       strText = sprintf('check %s', strConstJobDueTimeHeader);
       disp(strText);
       error('Not compatible input. ');
   end
   strLine = fgets(fptr);
end
