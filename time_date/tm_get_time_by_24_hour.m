function aTime24HourFormat = tm_get_time_by_24_hour(strTime24HourFormat)

aTimeInDay = sscanf(strTime24HourFormat, '%d:%d');

iHour = aTimeInDay(1);
iMin = aTimeInDay(2);

aTime24HourFormat = [iHour, iMin, 0];

if iHour <0 | iHour>= 24
   strText = sprintf('File: tm_get_time_by_24_hour, Error hour, check time format');
   error(strText);
end

if iMin <0 | iMin >= 60
   strText = sprintf('File: tm_get_time_by_24_hour, Error minutes, check time format');
   error(strText);
end