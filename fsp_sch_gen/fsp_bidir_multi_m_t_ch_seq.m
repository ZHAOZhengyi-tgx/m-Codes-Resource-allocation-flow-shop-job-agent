function [fsp_bidir_schedule_partial, jobshop_config] = fsp_bidir_multi_m_t_ch_seq(stJobListInfo)

iJobSeqInJspCfg = stJobListInfo.aiJobSeqInJspCfg;
[fsp_bidir_schedule_partial, jobshop_config] = fsp_port_bidir_sche_mt_ch_seq(stJobListInfo, iJobSeqInJspCfg);


