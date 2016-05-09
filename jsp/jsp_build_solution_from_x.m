function [stJspSchedule] = jsp_build_solution_from_x(x_ip, stJspCfg, jobshop_formulation)
%
%
% History
% YYYYMMDD Notes
% 20070629 Add iTotalMachineNum into solution, zzy
% 20080428 call jsp_bld_solution_by_x_02 for merging
%     

[stJspSchedule] = jsp_bld_solution_by_x_02(x_ip, stJspCfg);

stJspSchedule.ObjTardiness = jobshop_formulation.obj_offset + jobshop_formulation.mosek_form.c' * x_ip;
