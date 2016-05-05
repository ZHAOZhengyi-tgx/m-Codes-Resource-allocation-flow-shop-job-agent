function [jsp_sub_prob_formulation] = psa_jsp_construct_sub_problem(jobshop_formulation, lagrangian_info)
%
%jobshop_formulation = 
%    mosek_form: [1x1 struct]
%    obj_offset: 
%jobshop_formulation.mosek_form
%       a: 
%     blc: 
%     buc: 
%       c: 
%     blx: 
%     bux: 
%    ints: 
%lagrangian_info = 
%               job_var_info: 
%            job_constr_info: 
%    iRelaxedConstrIndexList: 
%        iTotalRelexedConstr: 
%                 lamda_init: 
%lagrangian_info.job_var_info
%1x3 struct array with fields:
%    iJobId
%    iVarIndexList
%    iTotalVar
%
%lagrangian_info.job_constr_info
%1x3 struct array with fields:
%    iJobId
%    iTotalConstr
%    iConstrIndexList

jsp_sub_prob_formulation.mosek_form.a = jobshop_formulation.mosek_form.a(1:jobshop_formulation.mosek_form.index_start_machine_constr-1, :);
jsp_sub_prob_formulation.mosek_form.blc = jobshop_formulation.mosek_form.blc(1:jobshop_formulation.mosek_form.index_start_machine_constr-1);
jsp_sub_prob_formulation.mosek_form.buc = jobshop_formulation.mosek_form.buc(1:jobshop_formulation.mosek_form.index_start_machine_constr-1);
jsp_sub_prob_formulation.mosek_form.blx = jobshop_formulation.mosek_form.blx;
jsp_sub_prob_formulation.mosek_form.bux = jobshop_formulation.mosek_form.bux;
jsp_sub_prob_formulation.mosek_form.ints.sub = 1:length(jsp_sub_prob_formulation.mosek_form.bux);



