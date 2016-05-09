function astPriorityAtJobSet = jsp_calc_priority_by_mach_sche(astMachineUsageTimeInfo, stJspSchedule)
%
% Created on 15/Jan/2008
nNumMachType = length(astMachineUsageTimeInfo);

%% by default, low priority, high value
nTotalJob = stJspSchedule.iTotalJob;
for ii = 1:1:nTotalJob
    nTotalProcAtJob = stJspSchedule.stProcessPerJob(ii);
    astPriorityAtJobSet(ii).aiStartPriorityAtProc = nTotalJob * ones(1, nTotalProcAtJob);
    astPriorityAtJobSet(ii).aiEndPriorityAtProc   = nTotalJob * ones(1, nTotalProcAtJob);
end

% priority 
%   on
for mm = 1:1:nNumMachType
    nTotalNumTasks = length(astMachineUsageTimeInfo(mm).aSortedDelta);
    iStartPriorityHighAtLowVal = 1; %% reset to highest priority
    iEndPriorityHighAtLowVal = 1;   
    for ii = 1:1:nTotalNumTasks
        iJobIdReg = astMachineUsageTimeInfo(mm).aSortedJob(ii);
        jProcIdReg = astMachineUsageTimeInfo(mm).aSortedProcess(ii);
        if astMachineUsageTimeInfo(mm).aSortedDelta(ii) > 0
            astPriorityAtJobSet(iJobIdReg).aiStartPriorityAtProc(jProcIdReg) = iStartPriorityHighAtLowVal;
            iStartPriorityHighAtLowVal = iStartPriorityHighAtLowVal + 1;
        else
            astPriorityAtJobSet(iJobIdReg).aiEndPriorityAtProc(jProcIdReg) = iEndPriorityHighAtLowVal;
            iEndPriorityHighAtLowVal = iEndPriorityHighAtLowVal + 1;
        end
    end
end
