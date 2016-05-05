
stClockT0 = clock
tic

dblTimeNow = now

strTimeNow = datestr(now)

stClockT1 = clock

stElapsTimeT0_T1 = etime(stClockT1, stClockT0)
toc

strTimeNow = datestr(now)

fTimeNow = datenum(strTimeNow)

strTimeNow = datestr(fTimeNow)

strArray = java_array('java.lang.String', 1)

strArray = java.lang.String(strTimeNow)
 
cellTime = cell(strArray)

strTimeConvertBack = char(cellTime)
