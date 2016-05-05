function [jsp_weight_whole] = jsp_load_job_weight_total(jsp_name_label, iTotalJob)


fptr = jsp_name_label.fptr; 

strConstJobWeightHeader = jsp_name_label.strConstJobWeightHeader;
lenConstJobWeightHeader = length(strConstJobWeightHeader);

iReadCount = 0;
strLine = fgets(fptr);

while iReadCount <= iTotalJob - 1
   strLine = sprintf('%sMINIMIMLENGTH_TO_BE_COMPATIBLE_WITH_READER', strLine);
   if strLine(1:lenConstJobWeightHeader) == strConstJobWeightHeader
       iReadData = sscanf(strLine((lenConstJobWeightHeader + 1): end), '%d = %f');
       jsp_weight_whole(iReadData(1)) = iReadData(2);
       if iReadData(1) > iTotalJob
           strText = sprintf('check %s', strConstJobWeightHeader);
           disp(strText);
           error('Exceed total job');
       end
       iReadCount = iReadCount + 1;
   elseif feof(fptr)
       strText = sprintf('check %s', strConstJobWeightHeader);
       disp(strText);
       error('Not compatible input. ');
   end
   strLine = fgets(fptr);
end
