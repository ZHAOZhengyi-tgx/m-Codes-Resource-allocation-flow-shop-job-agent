function [container_jsp_solution] = ...
    psa_jsp_time_shift(jobshop_config, container_temp_jsp, aMachineCapacity)
% To resolve the machine confliction by time shifting
%

iPlotFlag = jobshop_config.iPlotFlag;
% build output
container_jsp_solution.iTotalJob = container_temp_jsp.iTotalJob;
container_jsp_solution.iTotalMachine = container_temp_jsp.iTotalMachine;
container_jsp_solution.iTotalMachineNum = container_temp_jsp.iTotalMachineNum;
container_jsp_solution.stProcessPerJob = container_temp_jsp.stProcessPerJob;

iCurrTimeSlot = 1;

while iCurrTimeSlot <= container_temp_jsp.iMaxEndTime
    if iPlotFlag >= 1
        iLatestStartJobId = iCurrTimeSlot;
    end
    
    [stMachineConflictInfo, TotalConflictTimePerMachine, astMachineTimeUsage, iFirstMachineInConflict] = ...
        jsp_build_conflit_info_04(jobshop_config, container_temp_jsp, aMachineCapacity, iCurrTimeSlot);
    while sum(TotalConflictTimePerMachine) >= 1
        for ii = 1:1:stMachineConflictInfo(iFirstMachineInConflict).TimeConflitInfo.iTotalNumProcessInConflit
            iJobId = stMachineConflictInfo(iFirstMachineInConflict).TimeConflitInfo.aConflitJobId(ii);
            iProcessId = stMachineConflictInfo(iFirstMachineInConflict).TimeConflitInfo.aConflitProcessId(ii);
            if ii == 1
                iLatestStartJobId = iJobId;
                iLatestStartProcessId = iProcessId;
                tLatestStartTime = container_temp_jsp.stJobSet(iJobId).iProcessStartTime(1);
            else
                if tLatestStartTime <= container_temp_jsp.stJobSet(iJobId).iProcessStartTime(1)
                    iLatestStartJobId = iJobId;
                    iLatestStartProcessId = iProcessId;
                    tLatestStartTime = container_temp_jsp.stJobSet(iJobId).iProcessStartTime(1);
                end
            end
        end
        if iPlotFlag >= 1
            iLatestStartJobId
        end
%        tShiftTime = iCurrTimeSlot - tLatestStartTime;
        tShiftTime = iCurrTimeSlot - container_temp_jsp.stJobSet(iLatestStartJobId).iProcessStartTime(iLatestStartProcessId);
        for ii = iLatestStartJobId:1:container_jsp_solution.iTotalJob
            for jj = 1:1:container_temp_jsp.stProcessPerJob(ii)
                container_temp_jsp.stJobSet(ii).iProcessStartTime(jj) = container_temp_jsp.stJobSet(ii).iProcessStartTime(jj) + tShiftTime;
                container_temp_jsp.stJobSet(ii).iProcessEndTime(jj) = container_temp_jsp.stJobSet(ii).iProcessEndTime(jj) + tShiftTime;
                container_temp_jsp.stJobSet(ii).fProcessStartTime(jj) = container_temp_jsp.stJobSet(ii).iProcessStartTime(jj);
                container_temp_jsp.stJobSet(ii).fProcessEndTime(jj) = container_temp_jsp.stJobSet(ii).iProcessEndTime(jj);
                
            end
        end
        for ii = 1:1:container_temp_jsp.iTotalJob
            if container_temp_jsp.iMaxEndTime <= container_temp_jsp.stJobSet(ii).iProcessEndTime(container_temp_jsp.stProcessPerJob(ii))
                container_temp_jsp.iMaxEndTime = container_temp_jsp.stJobSet(ii).iProcessEndTime(container_temp_jsp.stProcessPerJob(ii));
            end
        end
        
        for mm = 1:1:container_temp_jsp.iTotalMachine
            aMachineCapacity(mm, jobshop_config.iTotalTimeSlot:container_temp_jsp.iMaxEndTime) = ...
                ones(1, container_temp_jsp.iMaxEndTime - jobshop_config.iTotalTimeSlot + 1) * container_temp_jsp.iTotalMachineNum(mm);
        end
        jobshop_config.iTotalTimeSlot = container_temp_jsp.iMaxEndTime;
        
        [stMachineConflictInfo, TotalConflictTimePerMachine, astMachineTimeUsage, iFirstMachineInConflict] = ...
            jsp_build_conflit_info_04(jobshop_config, container_temp_jsp, aMachineCapacity, iCurrTimeSlot);
        
    end
    container_temp_jsp.iMaxEndTime = container_temp_jsp.stJobSet(container_jsp_solution.iTotalJob).iProcessEndTime(container_temp_jsp.stProcessPerJob(container_jsp_solution.iTotalJob));
   
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
        figure(figure_id+1);
        plot(tt_index, MachineUsage, tt_index, aMachineCapacity, 'o');
        title('Machine Usage by Time');
        legend('Mach-1', 'Mach-2', 'Mach-3', 'CapMach-1', 'CapMach-2', 'CapMach-3');
        if iCurrTimeSlot >= 5
            figure(figure_id);
%            axis([(iCurrTimeSlot-20), (iCurrTimeSlot+20),  (iLatestStartJobId-10), (iLatestStartJobId+10)])
            input('AnyKey to Continue');
        end
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
while iCurrTimeSlot <= container_temp_jsp.iMaxEndTime
    
    [stMachineConflictInfo, TotalConflictTimePerMachine, astMachineTimeUsage, iFirstMachineInConflict] = ...
        jsp_build_conflit_info_04(jobshop_config, container_temp_jsp, aMachineCapacity, iCurrTimeSlot);
    while sum(TotalConflictTimePerMachine) >= 1
        for ii = 1:1:stMachineConflictInfo(iFirstMachineInConflict).TimeConflitInfo.iTotalNumProcessInConflit
            iJobId = stMachineConflictInfo(iFirstMachineInConflict).TimeConflitInfo.aConflitJobId(ii);
            iProcessId = stMachineConflictInfo(iFirstMachineInConflict).TimeConflitInfo.aConflitProcessId(ii);
            if ii == 1
                iLatestStartJobId = iJobId;
                iLatestStartProcessId = iProcessId;
                tLatestStartTime = container_temp_jsp.stJobSet(iJobId).iProcessStartTime(1);
            else
                if tLatestStartTime <= container_temp_jsp.stJobSet(iJobId).iProcessStartTime(1)
                    iLatestStartJobId = iJobId;
                    iLatestStartProcessId = iProcessId;
                    tLatestStartTime = container_temp_jsp.stJobSet(iJobId).iProcessStartTime(1);
                end
            end
        end
        if iPlotFlag >= 1
            iLatestStartJobId
        end
%        tShiftTime = iCurrTimeSlot - tLatestStartTime;
        tShiftTime = iCurrTimeSlot - container_temp_jsp.stJobSet(iLatestStartJobId).iProcessStartTime(iLatestStartProcessId);
        for ii = iLatestStartJobId:1:container_jsp_solution.iTotalJob
            for jj = 1:1:container_temp_jsp.stProcessPerJob(ii)
                container_temp_jsp.stJobSet(ii).iProcessStartTime(jj) = container_temp_jsp.stJobSet(ii).iProcessStartTime(jj) + tShiftTime;
                container_temp_jsp.stJobSet(ii).iProcessEndTime(jj) = container_temp_jsp.stJobSet(ii).iProcessEndTime(jj) + tShiftTime;
                container_temp_jsp.stJobSet(ii).fProcessStartTime(jj) = container_temp_jsp.stJobSet(ii).iProcessStartTime(jj);
                container_temp_jsp.stJobSet(ii).fProcessEndTime(jj) = container_temp_jsp.stJobSet(ii).iProcessEndTime(jj);
                
            end
        end
        for ii = 1:1:container_temp_jsp.iTotalJob
            if container_temp_jsp.iMaxEndTime <= container_temp_jsp.stJobSet(ii).iProcessEndTime(container_temp_jsp.stProcessPerJob(ii))
                container_temp_jsp.iMaxEndTime = container_temp_jsp.stJobSet(ii).iProcessEndTime(container_temp_jsp.stProcessPerJob(ii));
            end
        end
        for mm = 1:1:container_temp_jsp.iTotalMachine
            aMachineCapacity(mm, jobshop_config.iTotalTimeSlot:container_temp_jsp.iMaxEndTime) = ...
                ones(1, container_temp_jsp.iMaxEndTime - jobshop_config.iTotalTimeSlot + 1) * container_temp_jsp.iTotalMachineNum(mm);
        end
        jobshop_config.iTotalTimeSlot = container_temp_jsp.iMaxEndTime;
        
        [stMachineConflictInfo, TotalConflictTimePerMachine, astMachineTimeUsage, iFirstMachineInConflict] = ...
            jsp_build_conflit_info_04(jobshop_config, container_temp_jsp, aMachineCapacity, iCurrTimeSlot);

        
    end
    for ii = 1:1:container_jsp_solution.iTotalJob
        if container_temp_jsp.iMaxEndTime <= container_temp_jsp.stJobSet(ii).iProcessEndTime(container_temp_jsp.stProcessPerJob(ii))
            container_temp_jsp.iMaxEndTime = container_temp_jsp.stJobSet(ii).iProcessEndTime(container_temp_jsp.stProcessPerJob(ii));
        end
    end

    [stTotalMachineConflictInfo, TotalConflictTotalTimePerMachine, astMachineTotalTimeUsage] = ...
            jsp_build_conflit_info_03(jobshop_config, container_temp_jsp, aMachineCapacity);
    if max(TotalConflictTotalTimePerMachine) == 0
        break;
    end
    
    if iPlotFlag >= 1
        figure_id = 2;
        psa_jsp_plot_jobsolution_2(container_temp_jsp, figure_id);
        title('Solution Scheduling for the Job Shop, Y-Group is Job');
            
        for kk = 1:1:jobshop_config.iTotalMachine
            for tt = 1:1:jobshop_config.iTotalTimeSlot
                MachineUsage(kk, tt) = astMachineTotalTimeUsage(kk, tt).iTotalJobProcess;
            end
        end
        tt_index = 1:1:jobshop_config.iTotalTimeSlot;
        figure_id = 3;
        figure(figure_id);
        plot(tt_index, MachineUsage, tt_index, aMachineCapacity, 'o');
        title('Machine Usage by Time');
        legend('Mach-1', 'Mach-2', 'Mach-3', 'CapMach-1', 'CapMach-2', 'CapMach-3');
    end
    
    iCurrTimeSlot = iCurrTimeSlot + 1;
end

container_jsp_solution.iMaxEndTime = container_temp_jsp.iMaxEndTime;
container_jsp_solution.stJobSet = container_temp_jsp.stJobSet;
