function [jobshop_solution] = jsp_mosek(jobshop_formulation, jobshop_config)


param.MSK_IPAR_MIO_MAX_NUM_BRANCHES = 2000;
[r, res] = mosekopt('minimize', jobshop_formulation.mosek_form, param);

x_ip = res.sol.int.xx;

%[jobshop_solution] = jsp_build_solution_from_x(x_ip, jobshop_config, jobshop_formulation);
[jobshop_solution] = jsp_bld_solution_by_x_02(x_ip, jobshop_config);