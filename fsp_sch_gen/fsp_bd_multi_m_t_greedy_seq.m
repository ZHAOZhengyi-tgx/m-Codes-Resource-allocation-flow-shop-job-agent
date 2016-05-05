function  [stJspSchedule] = fsp_bd_multi_m_t_greedy_seq(stJobListInfo)
%
% History
% YYYYMMDD Notes
% 20080323  stJobListInfo: from Port-Job-List
% 

stJspScheduleTemplate = stJobListInfo.stJspScheduleTemplate;
jobshop_config = stJobListInfo.jobshop_config;
iJobSeqInJspCfg   = stJobListInfo.aiJobSeqInJspCfg;
jobshop_config.stResourceConfig = stJobListInfo.stResourceConfig;
stJspSchedule = fsp_bd_multi_m_t_greedy_by_seq(stJspScheduleTemplate, jobshop_config, iJobSeqInJspCfg);
