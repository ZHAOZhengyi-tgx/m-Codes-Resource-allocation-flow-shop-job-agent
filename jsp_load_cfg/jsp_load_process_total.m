function [jsp_process_whole, strLine] = jsp_load_process_total(jsp_name_label, iTotalJob)


fptr = jsp_name_label.fptr; 

strConstProcessTotal = jsp_name_label.strConstProcessTotal;
lenConstProcessTotal = length(strConstProcessTotal);

iReadCount = 0;
strLine = fgets(fptr);
strLine = sprintf('%sMINIMIMLENGTH_TO_BE_COMPATIBLE_WITH_READER', strLine);

while iReadCount <= iTotalJob - 1
   if strLine(1:lenConstProcessTotal) == strConstProcessTotal
       iReadData = sscanf(strLine((lenConstProcessTotal + 1): end), '%d = %d');
       jsp_process_whole(iReadData(1)) = iReadData(2);
       if iReadData(1) > iTotalJob
           strText = sprintf('check %s', strConstProcessTotal);
           disp(strText);
           error('Exceed total job');
       end
       iReadCount = iReadCount + 1;
   elseif feof(fptr)
       strText = sprintf('check %s', strConstProcessTotal);
       disp(strText);
       error('Not compatible input. ');
   end
   strLine = fgets(fptr);
   strLine = sprintf('%sMINIMIMLENGTH_TO_BE_COMPATIBLE_WITH_READER', strLine);
end
