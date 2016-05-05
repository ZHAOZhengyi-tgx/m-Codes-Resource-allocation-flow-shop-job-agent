function [container_temp_jsp, aMachineCapacity, jobshop_config] = psa_jsp_shift_solve_one_t(jobshop_config, container_temp_jsp, aMachineCapacity, stMachineConflictInfo, TotalConflictTimePerMachine, astMachineTimeUsage, iFirstMachineInConflict, iCurrTimeSlot)

iPlotFlag = jobshop_config.iPlotFlag;
FlagExistConflict = sum(TotalConflictTimePerMachine);
while FlagExistConflict >= 1
    iProcessRankLatestStart = stMachineConflictInfo(iFirstMachineInConflict).TimeConflitInfo.iTotalNumProcessInConflit - ...
        container_temp_jsp.iTotalMachineNum(iFirstMachineInConflict);    
  
    if iProcessRankLatestStart == 1
        % exclude the first job, whose shifting cannot resolve the
        % confliction
        iBestIndex = 2;
        iLatestStartJobId = stMachineConflictInfo(iFirstMachineInConflict).TimeConflitInfo.aConflitJobId(2);
        tLatestStartTime = container_temp_jsp.stJobSet(iLatestStartJobId).iProcessStartTime(1);
        for ii = 2:1:stMachineConflictInfo(iFirstMachineInConflict).TimeConflitInfo.iTotalNumProcessInConflit
            iJobId = stMachineConflictInfo(iFirstMachineInConflict).TimeConflitInfo.aConflitJobId(ii);
            if tLatestStartTime <= container_temp_jsp.stJobSet(iJobId).iProcessStartTime(1)
                iLatestStartJobId = iJobId;
                iBestIndex = ii;
                tLatestStartTime = container_temp_jsp.stJobSet(iLatestStartJobId).iProcessStartTime(1);
            end
        end
        iLatestStartProcessId = stMachineConflictInfo(iFirstMachineInConflict).TimeConflitInfo.aConflitProcessId(iBestIndex);
    else
        iJobIdList = [];
        iProcessIdList = [];
        tLatestStartTimeList = [];
        % exclude the first job, whose shifting cannot resolve the
        % confliction
        for ii = 2:1:stMachineConflictInfo(iFirstMachineInConflict).TimeConflitInfo.iTotalNumProcessInConflit 
            iJobIdList(ii) = stMachineConflictInfo(iFirstMachineInConflict).TimeConflitInfo.aConflitJobId(ii);
            iProcessIdList(ii) = stMachineConflictInfo(iFirstMachineInConflict).TimeConflitInfo.aConflitProcessId(ii);
            tLatestStartTimeList(ii) = -container_temp_jsp.stJobSet(iJobIdList(ii)).iProcessStartTime(1);
        end
        [atSortedTimeList, iSortedIndex] = sort(tLatestStartTimeList);
        iBestIndex = iSortedIndex(iProcessRankLatestStart);
        iLatestStartProcessId = iProcessIdList(iBestIndex);
        iLatestStartJobId = iJobIdList(iBestIndex);
    end
    
    if iPlotFlag >= 1
        iBestIndex
        iProcessRankLatestStart
        TotalConflictTimePerMachine
        iLatestStartJobId
        iCurrTimeSlot
    end
    %        tShiftTime = iCurrTimeSlot - tLatestStartTime;
    
    tShiftTime = iCurrTimeSlot - container_temp_jsp.stJobSet(iLatestStartJobId).iProcessStartTime(iLatestStartProcessId);
    for ii = iLatestStartJobId:1:container_temp_jsp.iTotalJob
        for jj = 1:1:container_temp_jsp.stProcessPerJob(ii)
            container_temp_jsp.stJobSet(ii).iProcessStartTime(jj) = container_temp_jsp.stJobSet(ii).iProcessStartTime(jj) + tShiftTime;
            container_temp_jsp.stJobSet(ii).iProcessEndTime(jj) = container_temp_jsp.stJobSet(ii).iProcessEndTime(jj) + tShiftTime;
            container_temp_jsp.stJobSet(ii).fProcessStartTime(jj) = container_temp_jsp.stJobSet(ii).iProcessStartTime(jj);
            container_temp_jsp.stJobSet(ii).fProcessEndTime(jj) = container_temp_jsp.stJobSet(ii).iProcessEndTime(jj);
        end
    end
    
%    container_temp_jsp.iMaxEndTime = container_temp_jsp.stJobSet(container_temp_jsp.iTotalJob).iProcessEndTime(container_temp_jsp.stProcessPerJob(container_temp_jsp.iTotalJob));
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

    FlagExistConflict = sum(TotalConflictTimePerMachine);
end

for ii = 1:1:container_temp_jsp.iTotalJob
    if container_temp_jsp.iMaxEndTime <= container_temp_jsp.stJobSet(ii).iProcessEndTime(container_temp_jsp.stProcessPerJob(ii))
        container_temp_jsp.iMaxEndTime = container_temp_jsp.stJobSet(ii).iProcessEndTime(container_temp_jsp.stProcessPerJob(ii));
    end
end

   
