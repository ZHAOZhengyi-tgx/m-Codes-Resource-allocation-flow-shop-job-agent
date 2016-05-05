function [container_jsp_solution] = ...
    psa_jsp_time_shift_2(jobshop_config, container_temp_jsp, aMachineCapacity)
% To resolve the machine confliction by time shifting
%

iPlotFlag = jobshop_config.iPlotFlag;
% build output
container_jsp_solution.iTotalJob = container_temp_jsp.iTotalJob;
container_jsp_solution.iTotalMachine = container_temp_jsp.iTotalMachine;
container_jsp_solution.iTotalMachineNum = container_temp_jsp.iTotalMachineNum;
container_jsp_solution.stProcessPerJob = container_temp_jsp.stProcessPerJob;
if jobshop_config.iTotalTimeSlot < container_temp_jsp.iMaxEndTime
    jobshop_config.iTotalTimeSlot = container_temp_jsp.iMaxEndTime;
end

iCurrTimeSlot = 1;
while iCurrTimeSlot <= container_temp_jsp.iMaxEndTime

    iSizeMachineCap = size(aMachineCapacity, 2);
    if iSizeMachineCap < container_temp_jsp.iMaxEndTime
        for kk = 1:1:container_temp_jsp.iTotalMachine
            for tt = iSizeMachineCap+1:1:container_temp_jsp.iMaxEndTime*2
                aMachineCapacity(kk, tt) = container_temp_jsp.iTotalMachineNum(kk);
            end
        end
    end

    [stMachineConflictInfo, TotalConflictTimePerMachine, astMachineTimeUsage, iFirstMachineInConflict] = ...
        jsp_build_conflit_info_04(jobshop_config, container_temp_jsp, aMachineCapacity, iCurrTimeSlot);

    if jobshop_config.iOptRule == 4
        [container_temp_jsp, aMachineCapacity, jobshop_config] = ...
            psa_jsp_shift_solve_one_t...
            (jobshop_config, container_temp_jsp, aMachineCapacity, stMachineConflictInfo, TotalConflictTimePerMachine, astMachineTimeUsage, iFirstMachineInConflict, iCurrTimeSlot);
    elseif jobshop_config.iOptRule == 5
        [container_temp_jsp, aMachineCapacity, jobshop_config] = ...
            psa_jsp_shift_solve_one_t_2...
            (jobshop_config, container_temp_jsp, aMachineCapacity, stMachineConflictInfo, TotalConflictTimePerMachine, astMachineTimeUsage, iFirstMachineInConflict, iCurrTimeSlot);
    elseif jobshop_config.iOptRule == 10
         [container_temp_jsp, aMachineCapacity, jobshop_config] = ...
            psa_jsp_shift_solve_one_t_10...
            (jobshop_config, container_temp_jsp, aMachineCapacity, stMachineConflictInfo, TotalConflictTimePerMachine, astMachineTimeUsage, iFirstMachineInConflict, iCurrTimeSlot);
    else
    end

    if iPlotFlag >= 3
        figure_id = 2;
        psa_jsp_plot_jobsolution_2(container_temp_jsp, figure_id);
        title('Solution Scheduling for the Job Shop, Y-Group is Job');
        
        [stTotalMachineConflictInfo, TotalConflictTotalTimePerMachine, astMachineTotalTimeUsage] = ...
            jsp_build_conflit_info_03(jobshop_config, container_temp_jsp, aMachineCapacity);    
        for kk = 1:1:jobshop_config.iTotalMachine
            for tt = 1:1:jobshop_config.iTotalTimeSlot
                MachineUsage(kk, tt) = astMachineTotalTimeUsage(kk, tt).iTotalJobProcess;
            end
        end
        tt_index = 1:1:jobshop_config.iTotalTimeSlot;
        figure(figure_id + 1);
        plot(tt_index, MachineUsage, tt_index, aMachineCapacity, 'o');
        title('Machine Usage by Time');
        legend('Mach-1', 'Mach-2', 'Mach-3', 'CapMach-1', 'CapMach-2', 'CapMach-3');
        iCurrTimeSlot
        if iCurrTimeSlot >= 17
            figure(figure_id);
%            axis([iCurrTimeSlot-20 iCurrTimeSlot+20  26])
            input('AnyKey to Continue');
        end
    elseif iPlotFlag >= 2
        iCurrTimeSlot
    end
    
    iCurrTimeSlot = iCurrTimeSlot + 1;
end

[stTotalMachineConflictInfo, TotalConflictTotalTimePerMachine, astMachineTotalTimeUsage] = ...
            jsp_build_conflit_info_03(jobshop_config, container_temp_jsp, aMachineCapacity);    

iEarliestTimeSlot = container_temp_jsp.iMaxEndTime;
if max(TotalConflictTotalTimePerMachine) > 0
    for mm = 1:1:container_temp_jsp.iTotalMachine
        if TotalConflictTotalTimePerMachine(mm) >0
            if iEarliestTimeSlot > stTotalMachineConflictInfo(mm).aConflictTime(1)
                iEarliestTimeSlot = stTotalMachineConflictInfo(mm).aConflictTime(1);
            end
        end
    end
end
    
iCurrTimeSlot = iEarliestTimeSlot;
while iCurrTimeSlot < container_temp_jsp.iMaxEndTime
    
    [stMachineConflictInfo, TotalConflictTimePerMachine, astMachineTimeUsage, iFirstMachineInConflict] = ...
        jsp_build_conflit_info_04(jobshop_config, container_temp_jsp, aMachineCapacity, iCurrTimeSlot);
    
    if jobshop_config.iOptRule == 4
        [container_temp_jsp, aMachineCapacity, jobshop_config] = ...
            psa_jsp_shift_solve_one_t...
            (jobshop_config, container_temp_jsp, aMachineCapacity, stMachineConflictInfo, TotalConflictTimePerMachine, astMachineTimeUsage, iFirstMachineInConflict, iCurrTimeSlot);
    else
        [container_temp_jsp, aMachineCapacity, jobshop_config] = ...
            psa_jsp_shift_solve_one_t_2...
            (jobshop_config, container_temp_jsp, aMachineCapacity, stMachineConflictInfo, TotalConflictTimePerMachine, astMachineTimeUsage, iFirstMachineInConflict, iCurrTimeSlot);
    end

    iCurrTimeSlot = iCurrTimeSlot + 1;
end

container_jsp_solution.iMaxEndTime = container_temp_jsp.iMaxEndTime;
container_jsp_solution.stJobSet = container_temp_jsp.stJobSet;

%%%%%%%%%%%%%% shift for starting from 0
tMinStartTime = container_jsp_solution.stJobSet(1).iProcessStartTime(1);
for ii = 2:1:container_jsp_solution.iTotalJob
    if container_jsp_solution.stJobSet(ii).iProcessStartTime(1) < tMinStartTime
        tMinStartTime = container_jsp_solution.stJobSet(ii).iProcessStartTime(1);
    end
end
if tMinStartTime > 0
    for ii = 1:1:container_jsp_solution.iTotalJob
        for jj = 1:1:container_jsp_solution.stProcessPerJob(ii)
            container_jsp_solution.stJobSet(ii).iProcessStartTime(jj) = container_jsp_solution.stJobSet(ii).iProcessStartTime(jj) - tMinStartTime; 
            container_jsp_solution.stJobSet(ii).iProcessEndTime(jj) = container_jsp_solution.stJobSet(ii).iProcessEndTime(jj) - tMinStartTime;
        end
        container_jsp_solution.stJobSet(ii).fProcessEndTime = container_jsp_solution.stJobSet(ii).iProcessEndTime;
        container_jsp_solution.stJobSet(ii).fProcessStartTime = container_jsp_solution.stJobSet(ii).iProcessStartTime;
    end
    container_jsp_solution.iMaxEndTime = ceil(container_jsp_solution.iMaxEndTime - tMinStartTime);
end

container_jsp_solution.fTimeUnit_Min = container_temp_jsp.fTimeUnit_Min;
container_jsp_solution.stResourceConfig = container_temp_jsp.stResourceConfig;
