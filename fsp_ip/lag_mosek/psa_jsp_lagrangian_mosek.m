function [jobshop_solution, lagrangian_solution_info, x_relax_sol_ip] = psa_jsp_lagrangian_mosek(jobshop_config, jobshop_formulation, lagrangian_info)

if isfield('iPlotFlag', jobshop_config)
    iPlotFlag = jobshop_config.iPlotFlag;
else
    iPlotFlag = 1;
end
stop_on_iteration = 1;

for kk = 1:1:jobshop_config.iTotalMachine
    for tt = 1:1:jobshop_config.iTotalTimeSlot
        aMachineCapacity(kk, tt) = jobshop_config.iTotalMachineNum(kk);
    end
end

lagrangian_info.LamdaList = zeros(lagrangian_info.iTotalRelexedConstr, 1); %% initialize lagrangian variables
[jsp_sub_prob_formulation] = psa_jsp_construct_sub_problem(jobshop_formulation, lagrangian_info);

alpha_r = lagrangian_info.alpha_r;
iter = 1;
MaxIteration = lagrangian_info.iMaxIter;
%%% Only to get feasible solution in Lagrangian Relaxation Procedure
jobshop_config.iOptRule = lagrangian_info.iHeuristicAchieveFeasibility;

while (iter <= MaxIteration)
    jsp_sub_prob_formulation.mosek_form.c = jobshop_formulation.mosek_form.c  +  ...
        jobshop_formulation.mosek_form.a(lagrangian_info.iRelaxedConstrIndexList, :)' * lagrangian_info.LamdaList;
    jsp_sub_prob_formulation.obj_offset = jobshop_formulation.obj_offset - jobshop_formulation.mosek_form.buc(lagrangian_info.iRelaxedConstrIndexList) * lagrangian_info.LamdaList;

    param.MSK_IPAR_LOG_HEAD = 0;
    param.MSK_IPAR_LOG = 0;
    param.MSK_IPAR_MIO_MAX_NUM_BRANCHES = 2000;
    [r, res] = mosekopt('minimize', jsp_sub_prob_formulation.mosek_form, param);
   
    x_relax_sol_ip = res.sol.int.xx;
    obj_sub_ip = x_relax_sol_ip' * jsp_sub_prob_formulation.mosek_form.c + jsp_sub_prob_formulation.obj_offset;
    if iPlotFlag >= 4
        size(x_relax_sol_ip)
        size(jobshop_formulation.mosek_form.c)
    end
    fLowerBound = x_relax_sol_ip' * jobshop_formulation.mosek_form.c + jobshop_formulation.obj_offset;
    
    %%% Build partial solution structure
    [jobshop_temp_solution] = jsp_build_sulution_from_x(x_relax_sol_ip, jobshop_config, jobshop_formulation);
    jobshop_temp_solution.iTotalMachineNum = jobshop_config.iTotalMachineNum;
    %%% resolve the violations of constraints and build a feasible solution
    
    [container_jsp_patial_heu] = psa_jsp_time_shift_2(jobshop_config, jobshop_temp_solution, aMachineCapacity);
    [x_feasible_ip] = psa_jsp_build_xip_from_solution(jobshop_config, lagrangian_info, container_jsp_patial_heu);
    
    fUpperBound = x_feasible_ip' * jsp_sub_prob_formulation.mosek_form.c + jsp_sub_prob_formulation.obj_offset;
    
    %%%%% Update the best upper bound and lower bound
    if iter == 1
        fLowerBoundList(iter) = fLowerBound;
        fUpperBoundList(iter) = fUpperBound;
        x_optimal_ip = x_feasible_ip;
        jobshop_solution_best_in_iter = container_jsp_patial_heu;
    else
        fLowerBoundList(iter) = max([fLowerBound, fLowerBoundList(iter - 1)]);
        fUpperBoundList(iter) = min([fUpperBound, fUpperBoundList(iter - 1)]);
        if fUpperBoundList(iter) < fUpperBoundList(iter - 1)
            x_optimal_ip = x_feasible_ip;
            if container_jsp_patial_heu.iMaxEndTime < jobshop_solution_best_in_iter.iMaxEndTime
                jobshop_solution_best_in_iter = container_jsp_patial_heu;
            end
        end
    end
    
    if fUpperBoundList(iter) - fLowerBoundList(iter) < lagrangian_info.fDesiredDualityGap
        break;
    end
    
    conflit_constr = jobshop_formulation.mosek_form.a(lagrangian_info.iRelaxedConstrIndexList, :) * x_relax_sol_ip - jobshop_formulation.mosek_form.buc(lagrangian_info.iRelaxedConstrIndexList)';

    sum_sq_conflict = conflit_constr' * conflit_constr;
    s_r_list(iter) = alpha_r * (fUpperBoundList(iter) - fLowerBound)/sum_sq_conflict;
    
    lagrangian_info.LamdaList = lagrangian_info.LamdaList + s_r_list(iter) * conflit_constr;
    for ii = 1:1:size(lagrangian_info.LamdaList)
        if lagrangian_info.LamdaList(ii) < 0
            lagrangian_info.LamdaList(ii) = 0;
        end
    end
    
    %%%%%%%%%%% Debugging Session
    if iPlotFlag >= 1 & stop_on_iteration == 1
        figure(10);
        hold off;
        jsp_plot_jobsolution_2(jobshop_temp_solution, 10);
        title('Temperory Solution');
    %%% Dispathing machine
         container_jsp_patial_heu.iTotalMachineNum = jobshop_config.iTotalMachineNum;
         [jobshop_feasible_solution, stSpecificMachineTimeInfo] = psa_jsp_dispatch_machine_02(container_jsp_patial_heu);
        figure(20);
        hold off;
        psa_jsp_plot_jobsolution(jobshop_feasible_solution, 20);
        title('After resolving machine conflict');
%        stop_on_iteration = input('1--- continuous with stop, else continue no stop.');
    end
    iter_upp_low_makespan = [iter, fUpperBoundList(iter), fLowerBoundList(iter), jobshop_solution_best_in_iter.iMaxEndTime]
    iter = iter + 1;
end
jobshop_solution = jobshop_solution_best_in_iter;

lagrangian_solution_info.fUpperBoundList = fUpperBoundList;
lagrangian_solution_info.fLowerBoundList = fLowerBoundList;
lagrangian_solution_info.s_r_list = s_r_list;
lagrangian_solution_info.LamdaList = lagrangian_info.LamdaList;
currRowBase = 0;
for mm = 1:1:jobshop_config.iTotalMachine
    lagrangian_solution_info.fTimeSlotPricePerMachine(mm).PriceList = lagrangian_solution_info.LamdaList(currRowBase + 1: currRowBase + jobshop_config.iTotalTimeSlot);
    currRowBase = currRowBase + jobshop_config.iTotalTimeSlot;
end

%%% Actual Maximum Iteration
if iPlotFlag >= 1
    if iter < MaxIteration
        MaxIteration = iter-1;
    end
    figure(101)
    iter_list = 1:MaxIteration;
    size(iter_list), size(lagrangian_solution_info.fUpperBoundList), size(lagrangian_solution_info.fLowerBoundList)
    plot(iter_list, lagrangian_solution_info.fUpperBoundList(iter_list),  iter_list, lagrangian_solution_info.fLowerBoundList(iter_list), '+');
    title('Lagrangian Relaxation Solving Process');
    xlabel('iteration');
    legend('Obj in Primal Form', 'Obj in Dual Form');

    figure(102)
    plot(iter_list, lagrangian_solution_info.s_r_list(iter_list));
    title('slack factor in Lagrangian Relaxation Solving Process')
    
    figure(103)
    hold on;
    time_list = 1:1:jobshop_config.iTotalTimeSlot;
    for mm = 1:1:jobshop_config.iTotalMachine
        subplot(jobshop_config.iTotalMachine, 1, mm);
        plot(time_list, lagrangian_solution_info.fTimeSlotPricePerMachine(mm).PriceList);
        strText = sprintf('Time Slot Price at Machine %d', mm);
        title(strText);
    end
end
