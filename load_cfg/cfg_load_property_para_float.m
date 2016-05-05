function [fListProperty] = cfg_load_property_para_float(fptr, strConstProperty, iTotalItems)

lenConstProperty = length(strConstProperty);
fListProperty = [];

iReadCount = 0;
strLine = fgets(fptr);

while iReadCount <= iTotalItems - 1

   strLine = sprintf('%sMINIMIMLENGTH_TO_BE_COMPATIBLE_WITH_READER', strLine);
   if strLine(1:lenConstProperty) == strConstProperty
       [fReadArray, iReadNum] = sscanf(strLine((lenConstProperty + 1): end), '%d = %f');
       fListProperty(fReadArray(1)) = fReadArray(2);
       iReadCount = iReadCount + 1;
   elseif feof(fptr)
       error('Not compatible input.');
   end
   strLine = fgets(fptr);

end
