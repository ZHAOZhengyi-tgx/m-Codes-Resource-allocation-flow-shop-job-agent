function [x_ip] = jsp_build_xip_from_solution(jobshop_config, stFormulationInfo, jobshop_solution)
%
%
lagrangian_info = stFormulationInfo.lagrangian_info;

total_col = length(stFormulationInfo.jobshop_formulation.mosek_form.blx);
x_ip = zeros(total_col, 1);

curr_row = 0;
iTotalTimeSlot = jobshop_config.iTotalTimeSlot;
for ii = 1:1:jobshop_config.iTotalJob
    iJobId = lagrangian_info.job_var_info(ii).iJobId;
    iJobStartVariable = lagrangian_info.job_var_info(ii).iVarIndexList(1);
    for jj = 1:1:jobshop_config.stProcessPerJob(ii)
        iProcessStartVariable = iJobStartVariable + (jj -1) * iTotalTimeSlot;
        iProcessEndVariable = iJobStartVariable + jj * iTotalTimeSlot - 1;
        for tt = iProcessStartVariable + jobshop_solution.stJobSet(ii).iProcessStartTime(jj): 1:iProcessEndVariable
            x_ip(tt) = 1;
        end
    end
end

iTotalNumOperation =  sum(jobshop_config.stProcessPerJob );
if total_col > iTotalNumOperation * iTotalTimeSlot
    % there is makespan dummy variables
    idxBaseVarDummyOperation = iTotalNumOperation * iTotalTimeSlot;                   %% 20070724
    for tt = idxBaseVarDummyOperation + 1 + jobshop_solution.iMaxEndTime: 1: total_col
        x_ip(tt) = 1;
    end
end
