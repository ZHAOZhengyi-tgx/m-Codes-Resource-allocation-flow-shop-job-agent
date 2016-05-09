function [fTardinessFine_Sgd, tAgentTardiness_hour] = fsp_resalloc_tardi_fine(stBerthJobInfo, stAgentJobInfo, tAgentJobDuration_hour)

tAgentRequiredDuration_sec = etime(stAgentJobInfo.atClockAgentJobDue.aClockYearMonthDateHourMinSec, ...
                                stAgentJobInfo.atClockAgentJobStart.aClockYearMonthDateHourMinSec);

tAgentTardiness_hour = tAgentJobDuration_hour - tAgentRequiredDuration_sec/3600;
if tAgentTardiness_hour < 0
    tAgentTardiness_hour = 0;
end

fTardinessFine_Sgd = stAgentJobInfo.fLatePenalty_SgdPerFrame/stBerthJobInfo.fTimeFrameUnitInHour * tAgentTardiness_hour;