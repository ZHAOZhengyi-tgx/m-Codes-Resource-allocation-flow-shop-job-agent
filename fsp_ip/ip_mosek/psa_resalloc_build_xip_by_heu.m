function [x_ip] = psa_resalloc_build_xip_by_heu(jobshop_config, stBerthJobInfo, lagrangian_info, jobshop_solution)
%
%

fFactorFramePerSlot = jobshop_config.fTimeUnit_Min/60/stBerthJobInfo.fTimeFrameUnitInHour;
iTotalTimeFrame = floor(jobshop_config.iTotalTimeSlot * fFactorFramePerSlot) + 1;
%% Allocation of memory
total_col = sum(jobshop_config.stProcessPerJob ) * jobshop_config.iTotalTimeSlot + jobshop_config.iTotalMachine * iTotalTimeFrame;
col_base_machine_time = sum(jobshop_config.stProcessPerJob ) * jobshop_config.iTotalTimeSlot;

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

for kk = 1:1:jobshop_config.iTotalMachine
    for tt = 1:1:jobshop_config.iTotalTimeSlot
        aMachineCapacity(kk, tt) = jobshop_config.iTotalMachineNum(kk);
        
    end
end
[stMachineConflictInfo, TotalConflictTimePerMachine, astMachineTimeUsage] = ...
    jsp_build_conflit_info_03(jobshop_config, jobshop_solution, aMachineCapacity);
for kk = 1:1:jobshop_config.iTotalMachine
    for tt = 1:1:jobshop_config.iTotalTimeSlot
        idx_col_var_machine_time_cap = col_base_machine_time + (kk -1)* iTotalTimeFrame + floor(tt*fFactorFramePerSlot) + 1;
        if tt == 1
            x_ip(idx_col_var_machine_time_cap) = astMachineTimeUsage(kk, tt).iTotalJobProcess;
        else
            x_ip(idx_col_var_machine_time_cap) = max([x_ip(idx_col_var_machine_time_cap), astMachineTimeUsage(kk, tt).iTotalJobProcess]);
        end
    end
end

