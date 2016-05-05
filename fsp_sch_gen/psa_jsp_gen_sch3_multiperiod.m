function [stContainerDischargeJobSequence, container_jsp_discha_schedule, stContainerLoadJobSequence, container_jsp_load_schedule, container_jsp_schedule] = psa_jsp_gen_sch3_multiperiod(stQuayCraneJobList)
%    Discharging and then Loading Scheduling Generation
%    Discharging Job: QC -> PM -> YC, Machine-1, Machine-2, Machine-3
%    Loading Job:     YC -> PM -> QC, Machine-3, Machine-2, Machine-1
%    so, total machine type is 3 {QC, PM, YC}
%    total number of QC(Quay Crane) is 1
%    total number of YC(Yard Crane) is MaxVirtualYardCrane
%    total number of PM is MaxVirtualPrimeMover
%    total number of jobs: = total number of containers (TotalContainer_Discharge + TotalContainer_Load)
%  Job can be done on specific PM or YC selected by the user, or automatically selected by the  solver
%
% input structure:
%    stContainerDischargeJobSequence, stContainerLoadJobSequence: an array of structure containing following
%    fields
%        fCycleTimeMachineType1      : Operation Time taken for QC
%        Time_PM      : Operation Time taken for Prime Mover
%        Time_YC      : Operation Time taken for YC
%        Time_PM_YC   : Operation Time taken for both PM and YC
%    
% output structure
%    stContainerDischargeJobSequence, stContainerLoadJobSequence: an array of structure containing following as well as the above two fields
%        StartTime    : starting time of i^th job
%        CompleteTime : completion time of i^th job
%        iPM_Id       : iPM_Id, the actual specific PrimeMover in use
%        iYC_Id       : the actual specific YardCrane in use

%%%%%%% Read input
aiPrimeMoverCapacityAtTimePoint = stQuayCraneJobList.stResourceConfig.stMachineConfig(2).afMaCapAtTimePoint;
afPrimeMoverCapLookUpTableTimeList = stQuayCraneJobList.stResourceConfig.stMachineConfig(2).afTimePointAtCap;
aiYardCraneCapacityAtTimePoint  = stQuayCraneJobList.stResourceConfig.stMachineConfig(3).afMaCapAtTimePoint;
afYardCraneCapLookUpTableTimeList  = stQuayCraneJobList.stResourceConfig.stMachineConfig(3).afTimePointAtCap;
MaxVirtualPrimeMover = max(aiPrimeMoverCapacityAtTimePoint);
MaxVirtualYardCrane = max(aiYardCraneCapacityAtTimePoint);
iStartingNumPrimeMover = aiPrimeMoverCapacityAtTimePoint(1);
iStartingNumYardCrane  = aiYardCraneCapacityAtTimePoint(1);
iLenPointsPrimeMoverCap = length(aiPrimeMoverCapacityAtTimePoint);
iLenPointsYardCraneCap = length(aiYardCraneCapacityAtTimePoint);

% following two sets of arrays will be used frequenctly later
%aiPrimeMoverCapacityAtTimePoint, afPrimeMoverCapLookUpTableTimeList,
%iLenPointsPrimeMoverCap
%aiYardCraneCapacityAtTimePoint,  afYardCraneCapLookUpTableTimeList,
%iLenPointsYardCraneCap

TotalContainer_Discharge = stQuayCraneJobList.TotalContainer_Discharge;
stContainerDischargeJobSequence = stQuayCraneJobList.stContainerDischargeJobSequence;
TotalContainer_Load = stQuayCraneJobList.TotalContainer_Load;
stContainerLoadJobSequence = stQuayCraneJobList.stContainerLoadJobSequence;


%%% Protatype of Output
%%% Construct Template Structure of Schedule Output
[container_jsp_schedule, container_jsp_discha_schedule, container_jsp_load_schedule] = fsp_constru_psa_sche_struct(stQuayCraneJobList);

fTotalTimePM = 0;
fTotalTimeYC = 0;
for ii = 1:1:TotalContainer_Discharge
    fTotalTimePM = fTotalTimePM + stContainerDischargeJobSequence(ii).Time_PM;
    fTotalTimeYC = fTotalTimeYC + stContainerDischargeJobSequence(ii).Time_YC;
end
for ii = 1:1:TotalContainer_Load
    fTotalTimePM = fTotalTimePM + stContainerLoadJobSequence(ii).Time_PM;
    fTotalTimeYC = fTotalTimeYC + stContainerLoadJobSequence(ii).Time_YC;
end

%%%%%%% Initialize all the PrimeMover to be available at the very beginning
for ii = 1:1:MaxVirtualPrimeMover
    stPrimeMoverDoingJobSet.aTimeSetPreviousJobCompleted(ii) = -(fTotalTimePM + fTotalTimeYC);
    stPrimeMoverDoingJobSet.iPM_Id(ii) = ii;
    stPrimeMoverDoingJobSet.aJob_Id(ii) = 0;
end
%%%%%%% Initialize all the Yard Crane to be available at the very beginning
for ii = 1:1:MaxVirtualYardCrane
    stYardCraneDoingJobSet.aTimeSetPreviousJobCompleted(ii) = -(fTotalTimePM + fTotalTimeYC);
    stYardCraneDoingJobSet.iYC_Id(ii) = ii;
    stYardCraneDoingJobSet.aJob_Id(ii) = 0;
end

%%%%%%% Generate Discharging Schedule
for ii = 1:1:TotalContainer_Discharge
    if ii <= iStartingNumPrimeMover & ii <= iStartingNumYardCrane
        if stContainerDischargeJobSequence(ii).PM_Id == 0
            stContainerDischargeJobSequence(ii).iPM_Id = ii;
            minTimeCompletePM = 0;
        elseif stContainerDischargeJobSequence(ii).PM_Id <= MaxVirtualPrimeMover
            stContainerDischargeJobSequence(ii).iPM_Id = stContainerDischargeJobSequence(ii).PM_Id;
            minTimeCompletePM = stPrimeMoverDoingJobSet.aTimeSetPreviousJobCompleted(stContainerDischargeJobSequence(ii).iPM_Id);
        else
            error('Violate the maximum PM number');
        end
        
        if stContainerDischargeJobSequence(ii).YC_Id == 0
        stContainerDischargeJobSequence(ii).iYC_Id = ii;
        minTimeCompleteYC = 0;
        elseif stContainerDischargeJobSequence(ii).YC_Id <= MaxVirtualYardCrane
            stContainerDischargeJobSequence(ii).iYC_Id = stContainerDischargeJobSequence(ii).YC_Id;
            minTimeCompleteYC = stYardCraneDoingJobSet.aTimeSetPreviousJobCompleted(stContainerDischargeJobSequence(ii).iYC_Id);
        else
            error('Violate the maximum YC number');
        end
            
        tEstimateTimeFromNearestAvailableYC = minTimeCompleteYC - stContainerDischargeJobSequence(ii).fCycleTimeMachineType1 - stContainerDischargeJobSequence(ii).Time_PM;
        tEstimateTimeFromNearestAvailablePM = minTimeCompletePM - stContainerDischargeJobSequence(ii).fCycleTimeMachineType1;
        if ii == 1
            stContainerDischargeJobSequence(ii).StartTime = 0;
            stContainerDischargeJobSequence(ii).CompleteTime = stContainerDischargeJobSequence(ii).fCycleTimeMachineType1 + stContainerDischargeJobSequence(ii).Time_PM_YC;
        else
            stContainerDischargeJobSequence(ii).StartTime = max([tEstimateTimeFromNearestAvailablePM, tEstimateTimeFromNearestAvailableYC, stContainerDischargeJobSequence(ii-1).StartTime + stContainerDischargeJobSequence(ii-1).fCycleTimeMachineType1]);
            stContainerDischargeJobSequence(ii).CompleteTime = stContainerDischargeJobSequence(ii).StartTime + stContainerDischargeJobSequence(ii).fCycleTimeMachineType1 + stContainerDischargeJobSequence(ii).Time_PM_YC;
        end
        stPrimeMoverDoingJobSet.aTimeSetPreviousJobCompleted(stContainerDischargeJobSequence(ii).iPM_Id) = stContainerDischargeJobSequence(ii).StartTime+ stContainerDischargeJobSequence(ii).fCycleTimeMachineType1 + stContainerDischargeJobSequence(ii).Time_PM;
        stPrimeMoverDoingJobSet.iPM_Id(stContainerDischargeJobSequence(ii).iPM_Id) = stContainerDischargeJobSequence(ii).iPM_Id;
        stPrimeMoverDoingJobSet.aJob_Id(stContainerDischargeJobSequence(ii).iPM_Id) = ii;
        
        stYardCraneDoingJobSet.aTimeSetPreviousJobCompleted(stContainerDischargeJobSequence(ii).iYC_Id) = stContainerDischargeJobSequence(ii).CompleteTime;
        stYardCraneDoingJobSet.iYC_Id(stContainerDischargeJobSequence(ii).iYC_Id) = stContainerDischargeJobSequence(ii).iYC_Id;
        stYardCraneDoingJobSet.aJob_Id(stContainerDischargeJobSequence(ii).iYC_Id) = ii;

    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% [iStartingNumYardCrane + 1, iStartingNumPrimeMover]
    elseif ii <= iStartingNumPrimeMover & ii > iStartingNumYardCrane
        if ii <= 1
            tEstimaFromPrevJobStartTime = 0;
        else
            tEstimaFromPrevJobStartTime = ...
                stContainerDischargeJobSequence(ii-1).StartTime + stContainerDischargeJobSequence(ii-1).fCycleTimeMachineType1;
        end
        [nMaxYardCraneRealTimeMultiPeriod, iIndexPointYardCraneMacap] = ...
            calc_table_look_up(aiYardCraneCapacityAtTimePoint, afYardCraneCapLookUpTableTimeList, tEstimaFromPrevJobStartTime);
        if stContainerDischargeJobSequence(ii).PM_Id == 0
            stContainerDischargeJobSequence(ii).iPM_Id = ii;
            minTimeCompletePM = 0;
        elseif stContainerDischargeJobSequence(ii).PM_Id <= MaxVirtualPrimeMover
            stContainerDischargeJobSequence(ii).iPM_Id = stContainerDischargeJobSequence(ii).PM_Id;
            minTimeCompletePM = stPrimeMoverDoingJobSet.aTimeSetPreviousJobCompleted(stContainerDischargeJobSequence(ii).iPM_Id);
        else
            error('Violate the maximum PM number');
        end
        stPrimeMoverDoingJobSet.iPM_Id(ii) = stContainerDischargeJobSequence(ii).iPM_Id;
        stPrimeMoverDoingJobSet.aJob_Id(ii) = ii;

%aiPrimeMoverCapacityAtTimePoint, afPrimeMoverCapLookUpTableTimeList,
%iLenPointsPrimeMoverCap
%aiYardCraneCapacityAtTimePoint,  afYardCraneCapLookUpTableTimeList,
%iLenPointsYardCraneCap

        if stContainerDischargeJobSequence(ii).YC_Id == 0
            if iLenPointsYardCraneCap == iIndexPointYardCraneMacap | ...
               ( iLenPointsYardCraneCap > iIndexPointYardCraneMacap  & ...
                 aiYardCraneCapacityAtTimePoint(iIndexPointYardCraneMacap) <= aiYardCraneCapacityAtTimePoint(iIndexPointYardCraneMacap+1) ...
               )
                minTimeCompleteYC = stYardCraneDoingJobSet.aTimeSetPreviousJobCompleted(1);
                iYC_Id_minTime = stYardCraneDoingJobSet.iYC_Id(1);
                index_min_YC = 1;
                for jj = 2:1:nMaxYardCraneRealTimeMultiPeriod
                    if minTimeCompleteYC > stYardCraneDoingJobSet.aTimeSetPreviousJobCompleted(jj)
                        minTimeCompleteYC = stYardCraneDoingJobSet.aTimeSetPreviousJobCompleted(jj);
                        iYC_Id_minTime = stYardCraneDoingJobSet.iYC_Id(jj);
                        index_min_YC = jj;
                    end
                end
                stContainerDischargeJobSequence(ii).iYC_Id = iYC_Id_minTime;
            else
                minTimeCompleteYC = stYardCraneDoingJobSet.aTimeSetPreviousJobCompleted(1);
                iYC_Id_minTime = stYardCraneDoingJobSet.iYC_Id(1);
                index_min_YC = 1;
                for jj = 2:1:nMaxYardCraneRealTimeMultiPeriod
                    if minTimeCompleteYC > stYardCraneDoingJobSet.aTimeSetPreviousJobCompleted(jj) & ...
                        stYardCraneDoingJobSet.iYC_Id(jj) <= aiYardCraneCapacityAtTimePoint(iIndexPointYardCraneMacap+1)
                        minTimeCompleteYC = stYardCraneDoingJobSet.aTimeSetPreviousJobCompleted(jj);
                        iYC_Id_minTime = stYardCraneDoingJobSet.iYC_Id(jj);
                        index_min_YC = jj;
                    end
                end
                stContainerDischargeJobSequence(ii).iYC_Id = iYC_Id_minTime;
            end
        elseif stContainerDischargeJobSequence(ii).YC_Id <= MaxVirtualYardCrane
            stContainerDischargeJobSequence(ii).iYC_Id = stContainerDischargeJobSequence(ii).YC_Id;
            minTimeCompleteYC = stYardCraneDoingJobSet.aTimeSetPreviousJobCompleted(stContainerDischargeJobSequence(ii).iYC_Id);
        else
            error('Violate the maximum YC number');
        end
        
        if ii <= 1
            tEstimaFromPrevJobStartTime = 0;
        else
            tEstimaFromPrevJobStartTime = ...
                stContainerDischargeJobSequence(ii-1).StartTime + stContainerDischargeJobSequence(ii-1).fCycleTimeMachineType1;
        end
        tEstimateTimeFromNearestAvailableYC = minTimeCompleteYC - stContainerDischargeJobSequence(ii).fCycleTimeMachineType1 - stContainerDischargeJobSequence(ii).Time_PM;
        tEstimateTimeFromNearestAvailablePM = minTimeCompletePM - stContainerDischargeJobSequence(ii).fCycleTimeMachineType1;
        
        stContainerDischargeJobSequence(ii).StartTime = max([tEstimaFromPrevJobStartTime, tEstimateTimeFromNearestAvailableYC, tEstimateTimeFromNearestAvailablePM]);
        stContainerDischargeJobSequence(ii).CompleteTime = stContainerDischargeJobSequence(ii).StartTime + stContainerDischargeJobSequence(ii).fCycleTimeMachineType1 + stContainerDischargeJobSequence(ii).Time_PM_YC;

        %input('Any Key to proceed');
        %%% update the stPrimeMoverDoingJobSet and stYardCraneDoingJobSet
        stPrimeMoverDoingJobSet.aTimeSetPreviousJobCompleted(stContainerDischargeJobSequence(ii).iPM_Id) = stContainerDischargeJobSequence(ii).StartTime+ stContainerDischargeJobSequence(ii).fCycleTimeMachineType1 + stContainerDischargeJobSequence(ii).Time_PM;
        
        stYardCraneDoingJobSet.aTimeSetPreviousJobCompleted(stContainerDischargeJobSequence(ii).iYC_Id) = stContainerDischargeJobSequence(ii).CompleteTime;
        stYardCraneDoingJobSet.iYC_Id(stContainerDischargeJobSequence(ii).iYC_Id) = stContainerDischargeJobSequence(ii).iYC_Id;
        stYardCraneDoingJobSet.aJob_Id(stContainerDischargeJobSequence(ii).iYC_Id) = ii;

    %%%%%%%%%%%%%%%%%%%%%%%%%% [ iStartingNumPrimeMover + 1, iStartingNumYardCrane]
    elseif ii > iStartingNumPrimeMover & ii <= iStartingNumYardCrane
        tEstimaFromPrevJobStartTime = ...
            stContainerDischargeJobSequence(ii-1).StartTime + stContainerDischargeJobSequence(ii-1).fCycleTimeMachineType1;
        [nMaxPrimeMoverRealTimeMultiPeriod, iIndex] = ...
            calc_table_look_up(aiPrimeMoverCapacityAtTimePoint, afPrimeMoverCapLookUpTableTimeList, tEstimaFromPrevJobStartTime);
        if stContainerDischargeJobSequence(ii).YC_Id == 0
            stContainerDischargeJobSequence(ii).iYC_Id = ii;
            minTimeCompleteYC = 0;
        elseif stContainerDischargeJobSequence(ii).YC_Id <= MaxVirtualYardCrane
            stContainerDischargeJobSequence(ii).iYC_Id = stContainerDischargeJobSequence(ii).YC_Id;
            minTimeCompleteYC = stYardCraneDoingJobSet.aTimeSetPreviousJobCompleted(stContainerDischargeJobSequence(ii).iYC_Id);
        else
            error('Violate the maximum YC number');
        end
        stYardCraneDoingJobSet.iYC_Id(ii) = stContainerDischargeJobSequence(ii).iYC_Id;
        stYardCraneDoingJobSet.aJob_Id(ii) = ii;

        if stContainerDischargeJobSequence(ii).PM_Id == 0
            minTimeCompletePM = stPrimeMoverDoingJobSet.aTimeSetPreviousJobCompleted(1);
            iPM_Id_minTime = stPrimeMoverDoingJobSet.iPM_Id(1);
            index_min_PM = 1;
            for jj = 2:1:nMaxPrimeMoverRealTimeMultiPeriod
                if minTimeCompletePM > stPrimeMoverDoingJobSet.aTimeSetPreviousJobCompleted(jj)
                    minTimeCompletePM = stPrimeMoverDoingJobSet.aTimeSetPreviousJobCompleted(jj);
                    iPM_Id_minTime = stPrimeMoverDoingJobSet.iPM_Id(jj);
                    index_min_PM = jj;
                end
            end
            stContainerDischargeJobSequence(ii).iPM_Id = iPM_Id_minTime;
        elseif stContainerDischargeJobSequence(ii).PM_Id <= MaxVirtualPrimeMover
            stContainerDischargeJobSequence(ii).iPM_Id = stContainerDischargeJobSequence(ii).PM_Id;
            minTimeCompletePM = stPrimeMoverDoingJobSet.aTimeSetPreviousJobCompleted(stContainerDischargeJobSequence(ii).iPM_Id);
        else
            error('Violate the maximum PM number');
        end
        
        tEstimaFromPrevJobStartTime = ...
            stContainerDischargeJobSequence(ii-1).StartTime + stContainerDischargeJobSequence(ii-1).fCycleTimeMachineType1;
        tEstimateTimeFromNearestAvailablePM = minTimeCompletePM - stContainerDischargeJobSequence(ii).fCycleTimeMachineType1;
        tEstimateTimeFromNearestAvailableYC = minTimeCompleteYC - stContainerDischargeJobSequence(ii).fCycleTimeMachineType1 - stContainerDischargeJobSequence(ii).Time_PM;
        
        stContainerDischargeJobSequence(ii).StartTime = max([tEstimaFromPrevJobStartTime, tEstimateTimeFromNearestAvailableYC, tEstimateTimeFromNearestAvailablePM]);
        stContainerDischargeJobSequence(ii).CompleteTime = stContainerDischargeJobSequence(ii).StartTime + stContainerDischargeJobSequence(ii).fCycleTimeMachineType1 + stContainerDischargeJobSequence(ii).Time_PM_YC;
        
        %%% update the stPrimeMoverDoingJobSet and stYardCraneDoingJobSet
        stYardCraneDoingJobSet.aTimeSetPreviousJobCompleted(stContainerDischargeJobSequence(ii).iYC_Id) = stContainerDischargeJobSequence(ii).CompleteTime;
        
        stPrimeMoverDoingJobSet.aJob_Id(stContainerDischargeJobSequence(ii).iPM_Id) = ii;
        stPrimeMoverDoingJobSet.iPM_Id(stContainerDischargeJobSequence(ii).iPM_Id) = stContainerDischargeJobSequence(ii).iPM_Id;
        stPrimeMoverDoingJobSet.aTimeSetPreviousJobCompleted(stContainerDischargeJobSequence(ii).iPM_Id) = stContainerDischargeJobSequence(ii).StartTime+ stContainerDischargeJobSequence(ii).fCycleTimeMachineType1 + stContainerDischargeJobSequence(ii).Time_PM;
        
        
    %%%%%%%%%%%%%%%%%%%%%%%%%% [max(iStartingNumPrimeMover + 1,iStartingNumYardCrane + 1), N]
    else
        tEstimaFromPrevJobStartTime = ...
            stContainerDischargeJobSequence(ii-1).StartTime + stContainerDischargeJobSequence(ii-1).fCycleTimeMachineType1;
        [nMaxPrimeMoverRealTimeMultiPeriod, iIndex] = ...
            calc_table_look_up(aiPrimeMoverCapacityAtTimePoint, afPrimeMoverCapLookUpTableTimeList, tEstimaFromPrevJobStartTime);
        [nMaxYardCraneRealTimeMultiPeriod, iIndex] = ...
            calc_table_look_up(aiYardCraneCapacityAtTimePoint, afYardCraneCapLookUpTableTimeList, tEstimaFromPrevJobStartTime);

        if stContainerDischargeJobSequence(ii).PM_Id == 0
            minTimeCompletePM = stPrimeMoverDoingJobSet.aTimeSetPreviousJobCompleted(1);
            iPM_Id_minTime = stPrimeMoverDoingJobSet.iPM_Id(1);
            index_min_PM = 1;
            for jj = 2:1:nMaxPrimeMoverRealTimeMultiPeriod
                if minTimeCompletePM > stPrimeMoverDoingJobSet.aTimeSetPreviousJobCompleted(jj)
                    minTimeCompletePM = stPrimeMoverDoingJobSet.aTimeSetPreviousJobCompleted(jj);
                    iPM_Id_minTime = stPrimeMoverDoingJobSet.iPM_Id(jj);
                    index_min_PM = jj;
                end
            end
            stContainerDischargeJobSequence(ii).iPM_Id = iPM_Id_minTime;
        elseif stContainerDischargeJobSequence(ii).PM_Id <= MaxVirtualPrimeMover
            stContainerDischargeJobSequence(ii).iPM_Id = stContainerDischargeJobSequence(ii).PM_Id;
            minTimeCompletePM = stPrimeMoverDoingJobSet.aTimeSetPreviousJobCompleted(stContainerDischargeJobSequence(ii).iPM_Id);
        else
            error('Violate the maximum PM number');
        end

%        ii
%        minTimeCompletePM
%        iPM_Id_minTime
        if stContainerDischargeJobSequence(ii).YC_Id == 0
            minTimeCompleteYC = stYardCraneDoingJobSet.aTimeSetPreviousJobCompleted(1);
            iYC_Id_minTime = stYardCraneDoingJobSet.iYC_Id(1);
            index_min_YC = 1;
            for jj = 2:1:nMaxYardCraneRealTimeMultiPeriod
                if minTimeCompleteYC > stYardCraneDoingJobSet.aTimeSetPreviousJobCompleted(jj)
                    minTimeCompleteYC = stYardCraneDoingJobSet.aTimeSetPreviousJobCompleted(jj);
                    iYC_Id_minTime = stYardCraneDoingJobSet.iYC_Id(jj);
                    index_min_YC = jj;
                end
            end
            stContainerDischargeJobSequence(ii).iYC_Id = iYC_Id_minTime;
        elseif stContainerDischargeJobSequence(ii).YC_Id <= MaxVirtualYardCrane
            stContainerDischargeJobSequence(ii).iYC_Id = stContainerDischargeJobSequence(ii).YC_Id;
            minTimeCompleteYC = stYardCraneDoingJobSet.aTimeSetPreviousJobCompleted(stContainerDischargeJobSequence(ii).iYC_Id);
        else
            error('Violate the maximum YC number');
        end

        tEstimateTimeFromNearestAvailableYC = minTimeCompleteYC - stContainerDischargeJobSequence(ii).fCycleTimeMachineType1 - stContainerDischargeJobSequence(ii).Time_PM;
        tEstimateTimeFromNearestAvailablePM = minTimeCompletePM - stContainerDischargeJobSequence(ii).fCycleTimeMachineType1;
        
        stContainerDischargeJobSequence(ii).StartTime = ...
            max([tEstimaFromPrevJobStartTime, tEstimateTimeFromNearestAvailableYC, tEstimateTimeFromNearestAvailablePM]);
        stContainerDischargeJobSequence(ii).CompleteTime = ...
            stContainerDischargeJobSequence(ii).StartTime + stContainerDischargeJobSequence(ii).fCycleTimeMachineType1 + stContainerDischargeJobSequence(ii).Time_PM_YC;

        %%%%%%%% Updating the ProcessingJobSet
        stPrimeMoverDoingJobSet.aJob_Id(stContainerDischargeJobSequence(ii).iPM_Id) = ii;
        stPrimeMoverDoingJobSet.aTimeSetPreviousJobCompleted(stContainerDischargeJobSequence(ii).iPM_Id) = ...
            stContainerDischargeJobSequence(ii).StartTime+ stContainerDischargeJobSequence(ii).fCycleTimeMachineType1 + stContainerDischargeJobSequence(ii).Time_PM;
        stPrimeMoverDoingJobSet.iPM_Id(stContainerDischargeJobSequence(ii).iPM_Id) = stContainerDischargeJobSequence(ii).iPM_Id;

        stYardCraneDoingJobSet.aJob_Id(stContainerDischargeJobSequence(ii).iYC_Id) = ii;
        stYardCraneDoingJobSet.aTimeSetPreviousJobCompleted(stContainerDischargeJobSequence(ii).iYC_Id) = ...
            stContainerDischargeJobSequence(ii).CompleteTime;
        stYardCraneDoingJobSet.iYC_Id(stContainerDischargeJobSequence(ii).iYC_Id) = stContainerDischargeJobSequence(ii).iYC_Id;

    end
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%% Gernating Loading Job Scheduling
for ii = 1:1:TotalContainer_Load
    
    if ii == 1
        if TotalContainer_Discharge >= 1
            tEstimaFromPrevJobStartTime = ...
                stContainerDischargeJobSequence(TotalContainer_Discharge).StartTime + stContainerDischargeJobSequence(TotalContainer_Discharge).fCycleTimeMachineType1 ...
                - stContainerLoadJobSequence(1).Time_PM_YC;
        else
            tEstimaFromPrevJobStartTime = 0;
        end
    else
        tEstimaFromPrevJobStartTime = ...
            stContainerLoadJobSequence(ii-1).StartTime + stContainerLoadJobSequence(ii-1).Time_PM_YC + stContainerLoadJobSequence(ii-1).fCycleTimeMachineType1 ...
            - stContainerLoadJobSequence(ii).Time_PM_YC;
    end
    [nMaxPrimeMoverRealTimeMultiPeriod, iIndex] = ...
        calc_table_look_up(aiPrimeMoverCapacityAtTimePoint, afPrimeMoverCapLookUpTableTimeList, tEstimaFromPrevJobStartTime);
    [nMaxYardCraneRealTimeMultiPeriod, iIndex] = ...
        calc_table_look_up(aiYardCraneCapacityAtTimePoint, afYardCraneCapLookUpTableTimeList, tEstimaFromPrevJobStartTime);
        
    if stContainerLoadJobSequence(ii).PM_Id == 0
        minTimeCompletePM = stPrimeMoverDoingJobSet.aTimeSetPreviousJobCompleted(1);
        iPM_Id_minTime = stPrimeMoverDoingJobSet.iPM_Id(1);
        index_min_PM = 1;
        for jj = 2:1:nMaxPrimeMoverRealTimeMultiPeriod
            if minTimeCompletePM > stPrimeMoverDoingJobSet.aTimeSetPreviousJobCompleted(jj)
                minTimeCompletePM = stPrimeMoverDoingJobSet.aTimeSetPreviousJobCompleted(jj);
                iPM_Id_minTime = stPrimeMoverDoingJobSet.iPM_Id(jj);
                index_min_PM = jj;
            end
        end
        stContainerLoadJobSequence(ii).iPM_Id = iPM_Id_minTime;
    elseif stContainerLoadJobSequence(ii).PM_Id <= MaxVirtualPrimeMover
        stContainerLoadJobSequence(ii).iPM_Id = stContainerLoadJobSequence(ii).PM_Id;
        minTimeCompletePM = stPrimeMoverDoingJobSet.aTimeSetPreviousJobCompleted(stContainerLoadJobSequence(ii).iPM_Id);
    else
        error('Violate the maximum PM number');
    end

    if stContainerLoadJobSequence(ii).YC_Id == 0
        minTimeCompleteYC = stYardCraneDoingJobSet.aTimeSetPreviousJobCompleted(1);
        iYC_Id_minTime = stYardCraneDoingJobSet.iYC_Id(1);
        index_min_YC = 1;
        for jj = 2:1:nMaxYardCraneRealTimeMultiPeriod
            if minTimeCompleteYC > stYardCraneDoingJobSet.aTimeSetPreviousJobCompleted(jj)
                minTimeCompleteYC = stYardCraneDoingJobSet.aTimeSetPreviousJobCompleted(jj);
                iYC_Id_minTime = stYardCraneDoingJobSet.iYC_Id(jj);
                index_min_YC = jj;
            end
        end
        stContainerLoadJobSequence(ii).iYC_Id = iYC_Id_minTime;
    elseif stContainerLoadJobSequence(ii).YC_Id <= MaxVirtualYardCrane
        stContainerLoadJobSequence(ii).iYC_Id = stContainerLoadJobSequence(ii).YC_Id;
        minTimeCompleteYC = stYardCraneDoingJobSet.aTimeSetPreviousJobCompleted(stContainerLoadJobSequence(ii).iYC_Id);
    else
        error('Violate the maximum YC number');
    end
    
    tEstimateTimeFromNearestAvailableYC = minTimeCompleteYC;
    tEstimateTimeFromNearestAvailablePM = minTimeCompletePM - stContainerLoadJobSequence(ii).Time_YC;
    
    stContainerLoadJobSequence(ii).StartTime = ...
        max([tEstimaFromPrevJobStartTime, tEstimateTimeFromNearestAvailableYC, tEstimateTimeFromNearestAvailablePM]);
    stContainerLoadJobSequence(ii).CompleteTime = ...
        stContainerLoadJobSequence(ii).StartTime + stContainerLoadJobSequence(ii).Time_PM_YC + stContainerLoadJobSequence(ii).fCycleTimeMachineType1;
    
    %%%%%%%% Updating the ProcessingJobSet
    stPrimeMoverDoingJobSet.aJob_Id(stContainerLoadJobSequence(ii).iPM_Id) = ii;
    stPrimeMoverDoingJobSet.aTimeSetPreviousJobCompleted(stContainerLoadJobSequence(ii).iPM_Id) = ...
        stContainerLoadJobSequence(ii).StartTime+ stContainerLoadJobSequence(ii).Time_YC + stContainerLoadJobSequence(ii).Time_PM;
    stPrimeMoverDoingJobSet.iPM_Id(stContainerLoadJobSequence(ii).iPM_Id) = stContainerLoadJobSequence(ii).iPM_Id;
    
    stYardCraneDoingJobSet.aJob_Id(stContainerLoadJobSequence(ii).iYC_Id) = ii;
    stYardCraneDoingJobSet.aTimeSetPreviousJobCompleted(stContainerLoadJobSequence(ii).iYC_Id) = stContainerLoadJobSequence(ii).StartTime + stContainerLoadJobSequence(ii).Time_YC;
    stYardCraneDoingJobSet.iYC_Id(stContainerLoadJobSequence(ii).iYC_Id) = stContainerLoadJobSequence(ii).iYC_Id;
   
end

iMaxEndTime = 0;
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
container_jsp_discha_schedule.iTotalJob = TotalContainer_Discharge;
container_jsp_discha_schedule.iTotalMachine = 3;
container_jsp_discha_schedule.iTotalMachineNum = [1, MaxVirtualPrimeMover, MaxVirtualYardCrane];
container_jsp_discha_schedule.stProcessPerJob = 3 * ones(1,TotalContainer_Discharge);
for ii = 1:1:TotalContainer_Discharge
    container_jsp_discha_schedule.stJobSet(ii).iProcessStartTime(1) = stContainerDischargeJobSequence(ii).StartTime;
    container_jsp_discha_schedule.stJobSet(ii).iProcessEndTime(1) = stContainerDischargeJobSequence(ii).StartTime + stContainerDischargeJobSequence(ii).fCycleTimeMachineType1;
    container_jsp_discha_schedule.stJobSet(ii).iProcessStartTime(2) = stContainerDischargeJobSequence(ii).StartTime + stContainerDischargeJobSequence(ii).fCycleTimeMachineType1;
    container_jsp_discha_schedule.stJobSet(ii).iProcessEndTime(2) = container_jsp_discha_schedule.stJobSet(ii).iProcessStartTime(2) + stContainerDischargeJobSequence(ii).Time_PM;
    container_jsp_discha_schedule.stJobSet(ii).iProcessStartTime(3) = container_jsp_discha_schedule.stJobSet(ii).iProcessEndTime(2);
    container_jsp_discha_schedule.stJobSet(ii).iProcessEndTime(3) = container_jsp_discha_schedule.stJobSet(ii).iProcessStartTime(3) + stContainerDischargeJobSequence(ii).Time_YC;
    container_jsp_discha_schedule.stJobSet(ii).iProcessMachine(1) = 1;
    container_jsp_discha_schedule.stJobSet(ii).iProcessMachine(2) = 2;
    container_jsp_discha_schedule.stJobSet(ii).iProcessMachine(3) = 3;
    container_jsp_discha_schedule.stJobSet(ii).iProcessMachineId(1) = 1;
    container_jsp_discha_schedule.stJobSet(ii).iProcessMachineId(2) = stContainerDischargeJobSequence(ii).iPM_Id;
    container_jsp_discha_schedule.stJobSet(ii).iProcessMachineId(3) = stContainerDischargeJobSequence(ii).iYC_Id;
    
    container_jsp_discha_schedule.stJobSet(ii).fProcessStartTime = container_jsp_discha_schedule.stJobSet(ii).iProcessStartTime;
    container_jsp_discha_schedule.stJobSet(ii).fProcessEndTime = container_jsp_discha_schedule.stJobSet(ii).iProcessEndTime;
    
    if iMaxEndTime < container_jsp_discha_schedule.stJobSet(ii).iProcessEndTime(3)
        iMaxEndTime = container_jsp_discha_schedule.stJobSet(ii).iProcessEndTime(3);
    end
    
end

container_jsp_discha_schedule.iMaxEndTime = iMaxEndTime;

%%%%%% Loading case
container_jsp_load_schedule.iTotalJob = TotalContainer_Load;
container_jsp_load_schedule.iTotalMachine = 3;
container_jsp_load_schedule.iTotalMachineNum = [1, MaxVirtualPrimeMover, MaxVirtualYardCrane];
container_jsp_load_schedule.stProcessPerJob = 3 * ones(1,TotalContainer_Load);
for ii = 1:1:TotalContainer_Load
    container_jsp_load_schedule.stJobSet(ii).iProcessStartTime(1) = stContainerLoadJobSequence(ii).StartTime;
    container_jsp_load_schedule.stJobSet(ii).iProcessEndTime(1) = stContainerLoadJobSequence(ii).StartTime + stContainerLoadJobSequence(ii).Time_YC;
    container_jsp_load_schedule.stJobSet(ii).iProcessStartTime(2) = container_jsp_load_schedule.stJobSet(ii).iProcessEndTime(1);
    container_jsp_load_schedule.stJobSet(ii).iProcessEndTime(2) = container_jsp_load_schedule.stJobSet(ii).iProcessStartTime(2) + stContainerLoadJobSequence(ii).Time_PM;
    container_jsp_load_schedule.stJobSet(ii).iProcessStartTime(3) = container_jsp_load_schedule.stJobSet(ii).iProcessEndTime(2);
    container_jsp_load_schedule.stJobSet(ii).iProcessEndTime(3) = container_jsp_load_schedule.stJobSet(ii).iProcessStartTime(3) + stContainerLoadJobSequence(ii).fCycleTimeMachineType1;
    container_jsp_load_schedule.stJobSet(ii).iProcessMachine(1) = 3;
    container_jsp_load_schedule.stJobSet(ii).iProcessMachine(2) = 2;
    container_jsp_load_schedule.stJobSet(ii).iProcessMachine(3) = 1;
    container_jsp_load_schedule.stJobSet(ii).iProcessMachineId(1) = stContainerLoadJobSequence(ii).iYC_Id;
    container_jsp_load_schedule.stJobSet(ii).iProcessMachineId(2) = stContainerLoadJobSequence(ii).iPM_Id;
    container_jsp_load_schedule.stJobSet(ii).iProcessMachineId(3) = 1;
    
    container_jsp_load_schedule.stJobSet(ii).fProcessStartTime = container_jsp_load_schedule.stJobSet(ii).iProcessStartTime;
    container_jsp_load_schedule.stJobSet(ii).fProcessEndTime = container_jsp_load_schedule.stJobSet(ii).iProcessEndTime;

    if iMaxEndTime < container_jsp_load_schedule.stJobSet(ii).iProcessEndTime(3)
        iMaxEndTime = container_jsp_load_schedule.stJobSet(ii).iProcessEndTime(3);
    end

end

container_jsp_load_schedule.iMaxEndTime = iMaxEndTime;

container_jsp_schedule.iTotalJob = TotalContainer_Load + TotalContainer_Discharge;
container_jsp_schedule.iTotalMachine = 3;
container_jsp_schedule.iTotalMachineNum = [1, MaxVirtualPrimeMover, MaxVirtualYardCrane];
container_jsp_schedule.stProcessPerJob = 3 * ones(1,TotalContainer_Load + TotalContainer_Discharge);
for ii = 1:1:container_jsp_schedule.iTotalJob
    if ii <= TotalContainer_Discharge
        container_jsp_schedule.stJobSet(ii) = container_jsp_discha_schedule.stJobSet(ii);
    else
        container_jsp_schedule.stJobSet(ii) = container_jsp_load_schedule.stJobSet(ii - TotalContainer_Discharge);
    end
end
container_jsp_schedule.iMaxEndTime = iMaxEndTime;
container_jsp_schedule.fTimeUnit_Min = stQuayCraneJobList.fTimeUnit_Min;

%%%%%%%%%%%%%% shift for negative starting time
iFlagExistNegativeTime = 0;
tNegMinimumStartTime = 0;
for jjJob = 1:1:container_jsp_schedule.iTotalJob
    if container_jsp_schedule.stJobSet(jjJob).iProcessStartTime(1) < 0
        if iFlagExistNegativeTime == 0
            iFlagExistNegativeTime = 1;
        end
        if container_jsp_schedule.stJobSet(jjJob).iProcessStartTime(1) < tNegMinimumStartTime
            tNegMinimumStartTime = container_jsp_schedule.stJobSet(jjJob).iProcessStartTime(1);
        end
    end
end
if iFlagExistNegativeTime == 1
    tPosShiftTime = - tNegMinimumStartTime;
    for jjJob = 1:1:container_jsp_schedule.iTotalJob
        for jj = 1:1:container_jsp_schedule.stProcessPerJob(jjJob)
            container_jsp_schedule.stJobSet(jjJob).iProcessStartTime(jj) = container_jsp_schedule.stJobSet(jjJob).iProcessStartTime(jj) + tPosShiftTime; 
            container_jsp_schedule.stJobSet(jjJob).iProcessEndTime(jj) = container_jsp_schedule.stJobSet(jjJob).iProcessEndTime(jj) + tPosShiftTime;
        end
        container_jsp_schedule.stJobSet(jjJob).fProcessEndTime = container_jsp_schedule.stJobSet(jjJob).iProcessEndTime;
        container_jsp_schedule.stJobSet(jjJob).fProcessStartTime = container_jsp_schedule.stJobSet(jjJob).iProcessStartTime;
    end
    container_jsp_schedule.iMaxEndTime = ceil(container_jsp_schedule.iMaxEndTime + tPosShiftTime);
end

