function [container_jsp_schedule] = fsp_multi_mach_greedy_seq(stJobListInfo)

stJspScheduleTemplate = stJobListInfo.stJspScheduleTemplate;
jobshop_config = stJobListInfo.jobshop_config;
iJobSeqInJspCfg   = stJobListInfo.aiJobSeqInJspCfg;

[container_jsp_schedule] = fsp_multi_mach_greedy_by_seq(stJspScheduleTemplate, jobshop_config, iJobSeqInJspCfg);
