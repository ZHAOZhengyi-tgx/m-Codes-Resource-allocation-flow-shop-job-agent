function [strListProperty] = ctnstk_load_property_para_str(fptr, strConstProperty, iTotalContainer)

lenConstProperty = length(strConstProperty);
strListProperty = [];

iReadCount = 0;
strLine = fgets(fptr);

while iReadCount <= iTotalContainer - 1

   strLine = sprintf('%sMINIMIMLENGTH_TO_BE_COMPATIBLE_WITH_READER', strLine);
   if strLine(1:lenConstProperty) == strConstProperty
       ReadCell = sscanf(strLine((lenConstProperty + 1): end), '%d = %s');
       strListProperty(ReadCell(1)).id = ReadCell(1);
       strListProperty(ReadCell(1)).strText = char(ReadCell(2:end)');
%       strListProperty(ReadCell(1)).strText = sprintf('%s', ReadCell(2:end));
 %      [ReadId, strText] = sscanf(strLine((lenConstProperty + 1): end), '%d = %s')
 %      strListProperty(ReadId).id = ReadId;
 %      strListProperty(ReadId).strText = strText;
       iReadCount = iReadCount + 1;
   elseif feof(fptr)
       error('Not compatible input.');
   end
   strLine = fgets(fptr);

end

