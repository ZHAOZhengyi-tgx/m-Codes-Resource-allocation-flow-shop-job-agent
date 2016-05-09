function psa_jsp_plot_mach_info_dis_tm(jobshop_config, container_sequence_jsp, aMachineCapacity, figure_id)

[stMachineConflictInfo, TotalConflictTimePerMachine, astMachineTimeUsage] = ...
    jsp_build_conflit_info_03(jobshop_config, container_sequence_jsp, aMachineCapacity);    
for kk = 1:1:jobshop_config.iTotalMachine
    for tt = 1:1:jobshop_config.iTotalTimeSlot
        MachineUsage(kk, tt) = astMachineTimeUsage(kk, tt).iTotalJobProcess;
    end
end

tt_index = 1:1:jobshop_config.iTotalTimeSlot;

figure(figure_id);
plot(tt_index, MachineUsage, tt_index, aMachineCapacity, 'o');
title('Machine Usage by Time');
legend('MachineType 1 Usage', 'MachineType 2 Usage', 'MachineType 3 Usage', 'MachineType 1 Capacity', 'MachineType 2 Capacity', 'MachineType 2 Capacity');
