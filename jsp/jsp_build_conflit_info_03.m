function [stMachineConflictInfo, TotalConflictTimePerMachine, astMachineTimeUsage] = jsp_build_conflit_info_03(jobshop_config, jobshop_temp_solution, aMachineCapacity)
% prototype:
% [stMachineConflictInfo, TotalConflictTimePerMachine, astMachineTimeUsage]
% = jsp_build_conflit_info_03(jobshop_config,
% jobshop_temp_solution, aMachineCapacity)
% input:
% jobshop_config, 
% jobshop_temp_solution, 
% aMachineCapacity
%
% output:
% stMachineConflictInfo, 
% TotalConflictTimePerMachine, 
% astMachineTimeUsage, 
% astRescheduleMachineTimeUsage, 
% aRescheduleProcessIdPerJob, 
% jsp_feasible_solution

%%%%% Initialization astMachineTimeUsage. astRescheduleMachineTimeUsage
iMaxEndTime = max([jobshop_config.iTotalTimeSlot, jobshop_temp_solution.iMaxEndTime]);
for mm = 1:1:jobshop_config.iTotalMachine
    for tt = 1:1:iMaxEndTime  %jobshop_config.iTotalTimeSlot
        astMachineTimeUsage(mm, tt).iTotalJobProcess = 0;
        astMachineTimeUsage(mm, tt).aJobSet = [];
        astMachineTimeUsage(mm, tt).iProcessSet = [];
    end
end
%jobshop_config.iTotalJob
%iMaxEndTime = jobshop_temp_solution.stJobSet(jobshop_config.iTotalJob).iProcessEndTime(jobshop_config.stProcessPerJob(jobshop_config.iTotalJob))
%%%%% build machine usage information
%size(astMachineTimeUsage)
for ii = 1:1:jobshop_config.iTotalJob
%    ii
    for jj = 1:1:jobshop_config.stProcessPerJob(ii)
%        jj
        mm = jobshop_config.jsp_process_machine(ii).iProcessMachine(jj);
        for tt = jobshop_temp_solution.stJobSet(ii).iProcessStartTime(jj):1:jobshop_temp_solution.stJobSet(ii).iProcessEndTime(jj)-1
%            tt
            astMachineTimeUsage(mm, tt+1).iTotalJobProcess = astMachineTimeUsage(mm, tt+1).iTotalJobProcess + 1;
            astMachineTimeUsage(mm, tt+1).aJobSet(astMachineTimeUsage(mm, tt+1).iTotalJobProcess) = ii;
            astMachineTimeUsage(mm, tt+1).iProcessSet(astMachineTimeUsage(mm, tt+1).iTotalJobProcess) = jj;
        end
    end
end

TotalConflictTimePerMachine = zeros(jobshop_config.iTotalMachine, 1);

for mm = 1:1:jobshop_config.iTotalMachine
    stMachineConflictInfo(mm).aConflictTime = [];
    stMachineConflictInfo(mm).TimeConflitInfo = [];
    for tt = 1:1:jobshop_config.iTotalTimeSlot
        if astMachineTimeUsage(mm, tt).iTotalJobProcess > aMachineCapacity(mm, tt)
            TotalConflictTimePerMachine(mm) = TotalConflictTimePerMachine(mm) + 1;
            stMachineConflictInfo(mm).aConflictTime(TotalConflictTimePerMachine(mm)) = tt;
            stMachineConflictInfo(mm).TimeConflitInfo(TotalConflictTimePerMachine(mm)).iTotalNumProcessInConflit = astMachineTimeUsage(mm, tt).iTotalJobProcess;
            for jj = 1:1:astMachineTimeUsage(mm, tt).iTotalJobProcess
                stMachineConflictInfo(mm).TimeConflitInfo(TotalConflictTimePerMachine(mm)).aConflitJobId(jj) = astMachineTimeUsage(mm, tt).aJobSet(jj);
                stMachineConflictInfo(mm).TimeConflitInfo(TotalConflictTimePerMachine(mm)).aConflitProcessId(jj) = astMachineTimeUsage(mm, tt).iProcessSet(jj);
            end
        end
    end
end


