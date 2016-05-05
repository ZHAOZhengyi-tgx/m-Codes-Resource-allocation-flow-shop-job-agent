function [x_ip] = psa_jsp_build_xip_from_solution(jobshop_config, lagrangian_info, jobshop_solution)
%
%

total_col = sum(jobshop_config.stProcessPerJob ) * jobshop_config.iTotalTimeSlot;
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
