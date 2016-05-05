function [stMachineConflictInfo, TotalConflictTimePerMachine, astMachineTimeUsage, iFirstMachineInConflict] = jsp_build_conflit_info_04(jobshop_config, jobshop_temp_solution, aMachineCapacity, iCurrTimeSlot)
% prototype:
% [stMachineConflictInfo, TotalConflictTimePerMachine, astMachineTimeUsage,
% astRescheduleMachineTimeUsage, aRescheduleProcessIdPerJob, jsp_feasible_solution] = jsp_build_conflit_info_03(jobshop_config, jobshop_temp_solution, aMachineCapacity)
% input:
% jobshop_config, 
% jobshop_temp_solution, 
% aMachineCapacity
% iCurrTimeSlot
%
% output:
% stMachineConflictInfo, 
% TotalConflictTimePerMachine, 
% astMachineTimeUsage, 

%%%%% Initialization astMachineTimeUsage. astRescheduleMachineTimeUsage
for mm = 1:1:jobshop_config.iTotalMachine
    for tt = 1:1:jobshop_config.iTotalTimeSlot
        astMachineTimeUsage(mm, tt).iTotalJobProcess = 0;
        astMachineTimeUsage(mm, tt).aJobSet = [];
        astMachineTimeUsage(mm, tt).iProcessSet = [];
    end
end

if jobshop_config.iPlotFlag >= 4
    iCurrTimeSlot
    iTotalTimeSlot = jobshop_config.iTotalTimeSlot
end
%%%%% build machine usage information
for ii = 1:1:jobshop_config.iTotalJob
    for jj = 1:1:jobshop_config.stProcessPerJob(ii)
        mm = jobshop_config.jsp_process_machine(ii).iProcessMachine(jj);
        if jobshop_config.iPlotFlag >= 4
            StartTime = jobshop_temp_solution.stJobSet(ii).iProcessStartTime(jj)
            EndTime   = jobshop_temp_solution.stJobSet(ii).iProcessEndTime(jj)
            iCurrTimeSlot
            size_MachineTimeUsage = size(astMachineTimeUsage)
        end
        for tt = jobshop_temp_solution.stJobSet(ii).iProcessStartTime(jj):1:jobshop_temp_solution.stJobSet(ii).iProcessEndTime(jj)-1
            if jobshop_config.iPlotFlag >= 4
                tt + 1
            end
            if tt+1 >= iCurrTimeSlot
                
                astMachineTimeUsage(mm, tt+1).iTotalJobProcess = astMachineTimeUsage(mm, tt+1).iTotalJobProcess + 1;
                astMachineTimeUsage(mm, tt+1).aJobSet(astMachineTimeUsage(mm, tt+1).iTotalJobProcess) = ii;
                astMachineTimeUsage(mm, tt+1).iProcessSet(astMachineTimeUsage(mm, tt+1).iTotalJobProcess) = jj;
            end
        end
    end
end
iFirstMachineInConflict = 0;
TotalConflictTimePerMachine = zeros(jobshop_config.iTotalMachine, 1);
for mm = 1:1:jobshop_config.iTotalMachine
    stMachineConflictInfo(mm).aConflictTime = [];
    stMachineConflictInfo(mm).TimeConflitInfo = [];
     tt = iCurrTimeSlot;
     if astMachineTimeUsage(mm, tt).iTotalJobProcess > aMachineCapacity(mm, tt)
         iFirstMachineInConflict = mm;
         TotalConflictTimePerMachine(mm) = TotalConflictTimePerMachine(mm) + 1;
         stMachineConflictInfo(mm).aConflictTime(TotalConflictTimePerMachine(mm)) = tt;
         stMachineConflictInfo(mm).TimeConflitInfo(TotalConflictTimePerMachine(mm)).iTotalNumProcessInConflit = astMachineTimeUsage(mm, tt).iTotalJobProcess;
         for jj = 1:1:astMachineTimeUsage(mm, tt).iTotalJobProcess
             stMachineConflictInfo(mm).TimeConflitInfo(TotalConflictTimePerMachine(mm)).aConflitJobId(jj) = astMachineTimeUsage(mm, tt).aJobSet(jj);
             stMachineConflictInfo(mm).TimeConflitInfo(TotalConflictTimePerMachine(mm)).aConflitProcessId(jj) = astMachineTimeUsage(mm, tt).iProcessSet(jj);
         end
         break;
     end
end


