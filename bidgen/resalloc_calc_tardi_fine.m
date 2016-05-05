function [fTardinessFine_dollar, tAgentTardiness_hour] = resalloc_calc_tardi_fine(stSystemMasterConfig, stAgentJobInfo, tAgentJobDuration_hour)

tAgentRequiredDuration_sec = etime(stAgentJobInfo.atClockAgentJobDue.aClockYearMonthDateHourMinSec, ...
                                stAgentJobInfo.atClockAgentJobStart.aClockYearMonthDateHourMinSec);

tAgentTardiness_hour = tAgentJobDuration_hour - tAgentRequiredDuration_sec/3600;
if tAgentTardiness_hour < 0
    tAgentTardiness_hour = 0;
end

fTardinessFine_dollar = stAgentJobInfo.fLatePenalty_DollarPerFrame/stSystemMasterConfig.fTimeFrameUnitInHour * tAgentTardiness_hour;