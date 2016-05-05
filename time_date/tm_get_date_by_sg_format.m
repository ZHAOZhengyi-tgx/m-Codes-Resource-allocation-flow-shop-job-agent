function aDateInYear = tm_get_date_by_sg_format(strDateInYear_sg)

atDateInYear = sscanf(strDateInYear_sg, '%d/%d/%d');

tDay = atDateInYear(1);
tMonth = atDateInYear(2);
tYear = atDateInYear(3);

aDateInYear = [tYear, tMonth, tDay];
 
if tMonth < 1 | tMonth > 12
   strText = sprintf('File: tm_get_date_by_sg_format, Error month, check date format');
   error(strText);
end

bIsLeapYear = 0;
if mod(tYear, 4) == 0
   if mod(tYear, 100) ==0
       if mod(tYear, 400) == 0
           bIsLeapYear = 1;
       else
       end
   else
       bIsLeapYear = 1;
   end
end


if tMonth == 1 & (tDay < 1 | tDay > 31 )
   strText = sprintf('File: tm_get_date_by_sg_format, Error day in month 1, check date format');
   error(strText);
elseif tMonth == 2 
   if (tDay < 1 | tDay > 29 ) & bIsLeapYear == 1
       strText = sprintf('File: tm_get_date_by_sg_format, Error day in month 2, check date format');
       error(strText);
   elseif (tDay < 1 | tDay > 28 ) & bIsLeapYear == 0
       strText = sprintf('File: tm_get_date_by_sg_format, Error day in month 2, check date format');
       error(strText);
   else
   end
elseif tMonth == 3 & (tDay < 1 | tDay > 31 )
   strText = sprintf('File: tm_get_date_by_sg_format, Error day in month 3, check date format');
   error(strText);
elseif tMonth == 4 & (tDay < 1 | tDay > 30 )
   strText = sprintf('File: tm_get_date_by_sg_format, Error day in month 4, check date format');
   error(strText);
elseif tMonth == 5 & (tDay < 1 | tDay > 31 )
   strText = sprintf('File: tm_get_date_by_sg_format, Error day in month 5, check date format');
   error(strText);
elseif tMonth == 6 & (tDay < 1 | tDay > 30 )
   strText = sprintf('File: tm_get_date_by_sg_format, Error day in month 6, check date format');
   error(strText);
elseif tMonth == 7 & (tDay < 1 | tDay > 31 )
   strText = sprintf('File: tm_get_date_by_sg_format, Error day in month 7, check date format');
   error(strText);
elseif tMonth == 8 & (tDay < 1 | tDay > 31 )
   strText = sprintf('File: tm_get_date_by_sg_format, Error day in month 8, check date format');
   error(strText);
elseif tMonth == 9 & (tDay < 1 | tDay > 30 )
   strText = sprintf('File: tm_get_date_by_sg_format, Error day in month 9, check date format');
   error(strText);
elseif tMonth == 10 & (tDay < 1 | tDay > 31 )
   strText = sprintf('File: tm_get_date_by_sg_format, Error day in month 10, check date format');
   error(strText);
elseif tMonth == 11 & (tDay < 1 | tDay > 30 )
   strText = sprintf('File: tm_get_date_by_sg_format, Error day in month 11, check date format');
   error(strText);
elseif tMonth == 12 & (tDay < 1 | tDay > 31 )
   strText = sprintf('File: tm_get_date_by_sg_format, Error day in month 12, check date format');
   error(strText);
else
end

