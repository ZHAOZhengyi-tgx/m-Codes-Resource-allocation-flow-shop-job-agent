function [tDateVec] = cfg_get_datenum_by_str(strDate, strTime)
%
% strDate: DD/MM/YYYY
% strTime: Hour:Minute


tDateVec = datevec(strDate, 'dd/mm/yyyy');
%
% Logic to judge whether the month date is correct, leap year's rule
%
%

[aHourMin, iReadLen] = sscanf(strTime, '%d:%d');
if iReadLen ~= 2
    error('Time format must be: Hour:Minute');
end
% Logic to judge time is valid, Hour: [0:24], Minute: [0:59]
% 
tDateVec(4) = aHourMin(1);
tDateVec(5) = aHourMin(2);

