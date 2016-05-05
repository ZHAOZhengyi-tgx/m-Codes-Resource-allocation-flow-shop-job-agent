function [iListProperty] = ctnstk_load_property_para(fptr, strConstProperty, iTotalContainer)

lenConstProperty = length(strConstProperty);
iListProperty = [];

iReadCount = 0;
strLine = fgets(fptr);

while iReadCount <= iTotalContainer - 1

   strLine = sprintf('%sMINIMIMLENGTH_TO_BE_COMPATIBLE_WITH_READER', strLine);
   if strLine(1:lenConstProperty) == strConstProperty
       ReadNum = sscanf(strLine((lenConstProperty + 1): end), '%d = %d');
       iListProperty(ReadNum(1)) = ReadNum(2);
       iReadCount = iReadCount + 1;
   elseif feof(fptr)
       error('Not compatible input.');
   end
   strLine = fgets(fptr);

end

