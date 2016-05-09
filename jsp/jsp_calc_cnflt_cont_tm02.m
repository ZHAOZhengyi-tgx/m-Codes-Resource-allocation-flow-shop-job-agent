function [TotalConflictTimePerMachine, astMachineUsageTimeInfo] = jsp_calc_cnflt_cont_tm02(container_sequence_jsp, stResourceConfig)


[astMachineUsageTimeInfo] = jsp_build_machine_usage_con_tm(container_sequence_jsp);

iCurrentTotalJob = container_sequence_jsp.iTotalJob;
nTotalProcess = container_sequence_jsp.stProcessPerJob(iCurrentTotalJob);

