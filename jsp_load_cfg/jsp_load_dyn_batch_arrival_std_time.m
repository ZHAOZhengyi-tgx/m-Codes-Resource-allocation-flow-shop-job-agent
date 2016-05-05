function [stJobArrivalStDevTimePerBatch, strLine] = jsp_load_dyn_batch_arrival_std_time(astrDynamicBatchJobArrival, nTotalBatch)


fptr = astrDynamicBatchJobArrival.fptr; 

strConstJobArrivalTimeStDev = astrDynamicBatchJobArrival.strConstJobArrivalTimeStDev;
lenConstJobArrivalTimeStDev = length(strConstJobArrivalTimeStDev);

iReadCount = 0;
strLine = fgets(fptr);
strLine = sprintf('%sMINIMIMLENGTH_TO_BE_COMPATIBLE_WITH_READER', strLine);

while iReadCount <= nTotalBatch - 1
   if strLine(1:lenConstJobArrivalTimeStDev) == strConstJobArrivalTimeStDev
%       strLine((lenConstJobArrivalTimeStDev + 1): end)
       iReadData = sscanf(strLine((lenConstJobArrivalTimeStDev + 1): end), '%d = %f');
       stJobArrivalStDevTimePerBatch(iReadData(1)) = iReadData(2);
       if iReadData(1) > nTotalBatch
           strText = sprintf('check %s', strConstJobArrivalTimeStDev);
           disp(strText);
           error('Exceed total job');
       end
       iReadCount = iReadCount + 1;
   elseif feof(fptr)
       strText = sprintf('check %s', strConstJobArrivalTimeStDev);
       disp(strText);
       error('Not compatible input. ');
   end
   strLine = fgets(fptr);
   strLine = sprintf('%sMINIMIMLENGTH_TO_BE_COMPATIBLE_WITH_READER', strLine);
end
