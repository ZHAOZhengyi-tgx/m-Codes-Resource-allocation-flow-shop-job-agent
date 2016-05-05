function [stAgent_Solution] = psa_bidgen_search_01(stInputResAlloc)

stBerthJobInfo               = stInputResAlloc.stBerthJobInfo              ;
stJobListInfoAgent                = stInputResAlloc.stJobListInfoAgent               ;
iMaxPrimeMoverUsageByGenSch0 = stInputResAlloc.iMaxPrimeMoverUsageByGenSch0;
iMaxYardCraneUsageByGenSch0  = stInputResAlloc.iMaxYardCraneUsageByGenSch0 ;

for ii = 1:1:stBerthJobInfo.iTotalAgent

    tStartTimePoint = cputime;
    %% Generate a schedule with infinite resources (infinite: large enough for all jobs)

    IniVirtualPrimeMover = stJobListInfoAgent(ii).MaxVirtualPrimeMover;
    IniVirtualYardCrane = stJobListInfoAgent(ii).MaxVirtualYardCrane;
    %%% initialize astMakespanInfo
    astMakespanInfo(ii).tMatrixMakespan_hour = zeros(stBerthJobInfo.iTotalPrimeMover, stBerthJobInfo.iTotalYardCrane);

    iCasePMYC = 0;
    if iMaxPrimeMoverUsageByGenSch0(ii) > stBerthJobInfo.iTotalPrimeMover
        iMaxPrimeMover = stBerthJobInfo.iTotalPrimeMover;
    else
        iMaxPrimeMover = iMaxPrimeMoverUsageByGenSch0(ii);
    end
    if iMaxYardCraneUsageByGenSch0(ii) > stBerthJobInfo.iTotalYardCrane
        iMaxYardCrane = stBerthJobInfo.iTotalYardCrane;
    else
        iMaxYardCrane = iMaxYardCraneUsageByGenSch0(ii);
    end

    for mNumPM = IniVirtualPrimeMover:1:iMaxPrimeMover
        for mNumYC = IniVirtualYardCrane:1:iMaxYardCrane
            iCasePMYC = iCasePMYC + 1
            stJobListInfoAgent(ii).MaxVirtualPrimeMover = mNumPM;
            stJobListInfoAgent(ii).MaxVirtualYardCrane  = mNumYC;

	        %%%%% calculation of makespan, resource cost, penalty cost, etc.
	        if stJobListInfoAgent(ii).iOptRule ==2
	            [jobshop_config] = psa_jsp_construct_jsp_config(stJobListInfoAgent(ii));
	    		[stContainerDischargeJobSequence, container_jsp_discha_schedule, stContainerLoadJobSequence, container_jsp_load_schedule, container_jsp_patial]...
	        		= psa_jsp_gen_job_schedule_4(stJobListInfoAgent(ii));
	        elseif stJobListInfoAgent(ii).iOptRule ==8
	        	[container_jsp_patial, jobshop_config] = psa_jsp_gen_job_schedule_8(stJobListInfoAgent(ii));
	        else
	        end

            stCostAtAgent(ii).stCostList(iCasePMYC).tMakeSpan_hour = container_jsp_patial.iMaxEndTime * container_jsp_patial.fTimeUnit_Min / 60;
            %%% update astMakespanInfo
            astMakespanInfo(ii).tMatrixMakespan_hour(mNumPM, mNumYC) = stCostAtAgent(ii).stCostList(iCasePMYC).tMakeSpan_hour;

    	    [fTardinessFine_Sgd, tAgentTardiness_hour] = resalloc_calc_tardi_fine(stBerthJobInfo, stBerthJobInfo.stAgentJobInfo(ii), stCostAtAgent(ii).stCostList(iCasePMYC).tMakeSpan_hour);
        	stCostAtAgent(ii).stCostList(iCasePMYC).fTardiness = tAgentTardiness_hour;
            
            if stBerthJobInfo.iObjFunction == 3
	            [fCostPerPM, fCostPerYC]  = ...
                       fsp_resalloc_calc_cost(stBerthJobInfo, stBerthJobInfo.stAgentJobInfo(ii), stCostAtAgent(ii).stCostList(iCasePMYC).tMakeSpan_hour);
                stCostAtAgent(ii).stCostList(iCasePMYC).fDelayPanelty =  fTardinessFine_Sgd;
                stCostAtAgent(ii).stCostList(iCasePMYC).fCostMakespan =  0;
            elseif stBerthJobInfo.iObjFunction == 4
	            [fCostPerPM, fCostPerYC]  = ...
                       fsp_resalloc_calc_cost(stBerthJobInfo, stBerthJobInfo.stAgentJobInfo(ii), stCostAtAgent(ii).stCostList(iCasePMYC).tMakeSpan_hour);
                stCostAtAgent(ii).stCostList(iCasePMYC).fDelayPanelty =  fTardinessFine_Sgd;
                stCostAtAgent(ii).stCostList(iCasePMYC).fCostMakespan =  stBerthJobInfo.stAgentJobInfo(ii).fPriceQuayCraneDollarPerFrame ...
                                * stCostAtAgent(ii).stCostList(iCasePMYC).tMakeSpan_hour / stBerthJobInfo.fTimeFrameUnitInHour;
            elseif stBerthJobInfo.iObjFunction == 2
                idxTimeFrameStart = floor(stBerthJobInfo.stAgentJobInfo(ii).atClockAgentJobStart.aClockYearMonthDateHourMinSec(4)/stBerthJobInfo.fTimeFrameUnitInHour) + 1;
                fCostPerPM = stBerthJobInfo.fPricePrimeMoverDollarPerFrame(idxTimeFrameStart);
                fCostPerYC = stBerthJobInfo.fPriceYardCraneDollarPerFrame(idxTimeFrameStart);
                stCostAtAgent(ii).stCostList(iCasePMYC).fDelayPanelty =  fTardinessFine_Sgd;
                stCostAtAgent(ii).stCostList(iCasePMYC).fCostMakespan =  0;
            elseif stBerthJobInfo.iObjFunction == 1
                idxTimeFrameStart = floor(stBerthJobInfo.stAgentJobInfo(ii).atClockAgentJobStart.aClockYearMonthDateHourMinSec(4)/stBerthJobInfo.fTimeFrameUnitInHour) + 1;
                fCostPerPM = stBerthJobInfo.fPricePrimeMoverDollarPerFrame(idxTimeFrameStart);
                fCostPerYC = stBerthJobInfo.fPriceYardCraneDollarPerFrame(idxTimeFrameStart);
                stCostAtAgent(ii).stCostList(iCasePMYC).fCostMakespan = stBerthJobInfo.fPriceQuayCraneDollarPerFrame(ii) ...
                                * stCostAtAgent(ii).stCostList(iCasePMYC).tMakeSpan_hour / stBerthJobInfo.fTimeFrameUnitInHour; 
                stCostAtAgent(ii).stCostList(iCasePMYC).fDelayPanelty = 0;
            end

            stCostAtAgent(ii).stCostList(iCasePMYC).fCostPM = mNumPM * fCostPerPM;
            stCostAtAgent(ii).stCostList(iCasePMYC).fCostYC = mNumYC * fCostPerYC;
            stCostAtAgent(ii).stCostList(iCasePMYC).stSchedule = container_jsp_patial;
            stCostAtAgent(ii).aiNumPM(iCasePMYC) = mNumPM;
            stCostAtAgent(ii).aiNumYC(iCasePMYC) = mNumYC;
            stCostAtAgent(ii).afTotalCost(iCasePMYC) = ...
                             stCostAtAgent(ii).stCostList(iCasePMYC).fCostPM ...
                             + stCostAtAgent(ii).stCostList(iCasePMYC).fCostYC ...
                             + stCostAtAgent(ii).stCostList(iCasePMYC).fDelayPanelty ...
                             + stCostAtAgent(ii).stCostList(iCasePMYC).fCostMakespan;
        end
    end
    
    stCostAtAgent(ii).iTotalCase = iCasePMYC;
    [fMinTotalCost,idxMinCost] = min(stCostAtAgent(ii).afTotalCost)
    [container_sequence_jsp, stSpecificMachineTimeInfo] = psa_jsp_dispatch_machine_02(stCostAtAgent(ii).stCostList(idxMinCost).stSchedule);

    tEndTimePoint = cputime;
    tSolutionTime_sec(ii) = tEndTimePoint - tStartTimePoint;
    
    stCostAtAgent(ii).stSolutionMinCost.stSchedule = container_sequence_jsp;
    stCostAtAgent(ii).stSolutionMinCost.iMaxPM = stCostAtAgent(ii).aiNumPM(idxMinCost);
    stCostAtAgent(ii).stSolutionMinCost.iMaxYC = stCostAtAgent(ii).aiNumYC(idxMinCost);
    stCostAtAgent(ii).tSolutionTime_sec = tSolutionTime_sec

    aiMinCost(ii) = idxMinCost;


end

%%%% Assign Output
for ii = 1:1:stBerthJobInfo.iTotalAgent
    stAgent_Solution(ii).stCostAtAgent = stCostAtAgent(ii);
    stAgent_Solution(ii).stResourceUsageGenSch0.iMaxPM = iMaxPrimeMoverUsageByGenSch0(ii);
    stAgent_Solution(ii).stResourceUsageGenSch0.iMaxYC = iMaxYardCraneUsageByGenSch0(ii);
    stAgent_Solution(ii).astMakespanInfo = astMakespanInfo(ii);
end

for ii = 1:1:stBerthJobInfo.iTotalAgent
    tMinCostMakeSpan_hour = stCostAtAgent(ii).stCostList(aiMinCost(ii)).tMakeSpan_hour;
    stAgent_Solution(ii).stPerformReport.tMinCostMakeSpan_hour = tMinCostMakeSpan_hour;
    stAgent_Solution(ii).stPerformReport.tMinCostGrossCraneRate = (stJobListInfoAgent(ii).TotalContainer_Load + stJobListInfoAgent(ii).TotalContainer_Discharge)/ stAgent_Solution(ii).stPerformReport.tMinCostMakeSpan_hour;
    stAgent_Solution(ii).stPerformReport.fCostMakespanTardiness = tMinCostMakeSpan_hour * stBerthJobInfo.stAgentJobInfo(ii).fPriceQuayCraneDollarPerFrame + stCostAtAgent(ii).stCostList(aiMinCost(ii)).fDelayPanelty;
    stAgent_Solution(ii).stPerformReport.fMinCost              =   stCostAtAgent(ii).stCostList(aiMinCost(ii)).fCostPM ...
                                                                + stCostAtAgent(ii).stCostList(aiMinCost(ii)).fCostYC ...
                                                                + stAgent_Solution(ii).stPerformReport.fCostMakespanTardiness;
    stAgent_Solution(ii).stPerformReport.tSolutionTime_sec = tSolutionTime_sec(ii);
end