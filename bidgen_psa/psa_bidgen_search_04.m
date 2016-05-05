function [stAgent_Solution] = psa_bidgen_search_04(stInputResAlloc)

%% searching dimensions one after the other, keep other dimension fixed when searching any dimension, stop once makespan not decreasing.
%% At the same time, detect and quit if totalcost is less than the neighbouring four
%% 
%% constant to verify the decreasing of tMakeSpan_hour
tEpsilon = 1/3600;

%%
stBerthJobInfo               = stInputResAlloc.stBerthJobInfo              ;
stAgentJobListBiFsp                = stInputResAlloc.stJobListInfoAgent        ;
iMaxPrimeMoverUsageByGenSch0 = stInputResAlloc.iMaxPrimeMoverUsageByGenSch0;
iMaxYardCraneUsageByGenSch0  = stInputResAlloc.iMaxYardCraneUsageByGenSch0 ;

for ii = 1:1:stBerthJobInfo.iTotalAgent

    tStartTimePoint = cputime;
    %% Generate a schedule with infinite resources (infinite: large enough for all jobs)

    IniVirtualPrimeMover = stAgentJobListBiFsp(ii).MaxVirtualPrimeMover;
    IniVirtualYardCrane = stAgentJobListBiFsp(ii).MaxVirtualYardCrane;
    %%% initialize astMakespanInfo
    astMakespanInfo(ii).tMatrixMakespan_hour = zeros(stBerthJobInfo.iTotalPrimeMover, stBerthJobInfo.iTotalYardCrane);
    
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
    if IniVirtualPrimeMover > iMaxPrimeMover
        error('numDefPM > iMaxPrimeMover');
    end
    if IniVirtualYardCrane > iMaxYardCrane
        error('numDefYC > iMaxYardCrane');
    end
    
    %%% only used for iAlgoChoice == 4
    if stBerthJobInfo.iAlgoChoice == 4
        fTotalCostMatrix = zeros(iMaxPrimeMover - IniVirtualPrimeMover +1, iMaxYardCrane - IniVirtualYardCrane + 1);
    end
    
    %%% initialize preparation for searching
    iMaxSearchingCase = (iMaxPrimeMover - IniVirtualPrimeMover +1) * (iMaxYardCrane - IniVirtualYardCrane + 1)
    iCasePMYC = 0;
    iFlagContinueSearch = 1;
    mNumPM = IniVirtualPrimeMover;
    mNumYC = IniVirtualYardCrane;
    mPrevDirStartNumPM = mNumPM;
    mPrevDirStartNumYC = mNumYC;
    iSearchDim = 1; %% spanning from 1 to iMaxDimension;
    iMaxDimension = 2; %% for the case of [numPM, numYC]
    fTotalCostMatrix = zeros((iMaxPrimeMover - IniVirtualPrimeMover +1), (iMaxYardCrane - IniVirtualYardCrane + 1));

    while iCasePMYC +1 <= iMaxSearchingCase & iFlagContinueSearch == 1
        iCasePMYC = iCasePMYC + 1;
        
        stAgentJobListBiFsp(ii).MaxVirtualPrimeMover = mNumPM;
        stAgentJobListBiFsp(ii).MaxVirtualYardCrane  = mNumYC;
        
        %%%%% calculation of makespan, resource cost, penalty cost, etc.
        
        if stBerthJobInfo.iAlgoChoice == 19
            if stBerthJobInfo.stJssProbStructConfig.isCriticalOperateSeq == 1
%           [jobshop_config] = psa_jsp_construct_jsp_config(stAgentJobListBiFsp(ii));
%    		[stContainerDischargeJobSequence, container_jsp_discha_schedule, stContainerLoadJobSequence, container_jsp_load_schedule, container_jsp_patial]...
%                = psa_jsp_gen_sch3_multiperiod(stAgentJobListBiFsp(ii));
        		[stContainerDischargeJobSequence, container_jsp_discha_schedule, stContainerLoadJobSequence, container_jsp_load_schedule, container_jsp_patial]...
            		= psa_jsp_gen_job_schedule_4(stAgentJobListBiFsp(ii));
            else
                [container_jsp_patial] = fsp_multi_mach_greedy_seq(stAgentJobListBiFsp(ii));
            end
                
        elseif stAgentJobListBiFsp(ii).iOptRule ==2
%            [jobshop_config] = psa_jsp_construct_jsp_config(stAgentJobListBiFsp(ii));
    		[stContainerDischargeJobSequence, container_jsp_discha_schedule, stContainerLoadJobSequence, container_jsp_load_schedule, container_jsp_patial]...
        		= psa_jsp_gen_job_schedule_4(stAgentJobListBiFsp(ii));
        		
        elseif stBerthJobInfo.iAlgoChoice == 2 | stBerthJobInfo.iAlgoChoice == 4 | stBerthJobInfo.iAlgoChoice == 5
        	[container_jsp_patial, jobshop_config] = psa_jsp_gen_job_schedule_8(stAgentJobListBiFsp(ii));
        
        else % stAgentJobListBiFsp(ii).iOptRule ==8 | stAgentJobListBiFsp(ii).iOptRule ==7
            error('Error Algorithm Input');
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
            fCostPerPM = stBerthJobInfo.fPricePrimeMoverSgdPerFrame(idxTimeFrameStart);
            fCostPerYC = stBerthJobInfo.fPriceYardCraneSgdPerFrame(idxTimeFrameStart);
            stCostAtAgent(ii).stCostList(iCasePMYC).fDelayPanelty =  fTardinessFine_Sgd;
            stCostAtAgent(ii).stCostList(iCasePMYC).fCostMakespan =  0;
        elseif stBerthJobInfo.iObjFunction == 1
            idxTimeFrameStart = floor(stBerthJobInfo.stAgentJobInfo(ii).atClockAgentJobStart.aClockYearMonthDateHourMinSec(4)/stBerthJobInfo.fTimeFrameUnitInHour) + 1;
            fCostPerPM = stBerthJobInfo.fPricePrimeMoverSgdPerFrame(idxTimeFrameStart);
            fCostPerYC = stBerthJobInfo.fPriceYardCraneSgdPerFrame(idxTimeFrameStart);
            stCostAtAgent(ii).stCostList(iCasePMYC).fCostMakespan = stBerthJobInfo.stAgentJobInfo(ii).fPriceQuayCraneDollarPerFrame ...
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

       %%% only used for iAlgoChoice == 4
%        if stBerthJobInfo.iAlgoChoice == 4
           %%%% Update the fTotalCostMatrix
           idxCostMatrixRow = mNumPM - IniVirtualPrimeMover +1;
           idxCostMatrixCol = mNumYC - IniVirtualYardCrane + 1;
           fTotalCostMatrix(idxCostMatrixRow, idxCostMatrixCol) = stCostAtAgent(ii).afTotalCost(iCasePMYC);
%        end
                         
       %%% update (mNumPM, mNumYC)
       if iCasePMYC > 1
           %%% if not decreasing, or have reached one boundary of searching region
           if (  (stCostAtAgent(ii).stCostList(iCasePMYC).tMakeSpan_hour <= tPrevMakeSpan ...
                    & stCostAtAgent(ii).stCostList(iCasePMYC).tMakeSpan_hour > tPrevMakeSpan - tEpsilon ...
                  ) ...
                | ( mNumPM + 1) > iMaxPrimeMover ...
                | ( mNumYC + 1) > iMaxYardCrane ...
              )
               iSearchDim = mod(iSearchDim, iMaxDimension) + 1;
               if iSearchDim == 1
                   mPrevDirStartNumPM = mPrevDirStartNumPM + 1;
                   mPrevDirStartNumYC = mPrevDirStartNumYC + 1;
                   if(mPrevDirStartNumPM > iMaxPrimeMover) 
                       mPrevDirStartNumPM = iMaxPrimeMover; 
                   end
                   if mPrevDirStartNumYC > iMaxYardCrane
                       mPrevDirStartNumYC = iMaxYardCrane;
                   end
                   mNextNumPM = mPrevDirStartNumPM;
                   mNextNumYC = mPrevDirStartNumYC;
               elseif iSearchDim == 2
                   mNextNumPM = mPrevDirStartNumPM;
                   mNextNumYC = mPrevDirStartNumYC +1;
                   if mNextNumYC > iMaxYardCrane
                       mNextNumYC = iMaxYardCrane;
                   end
               else
               end
           else
	           if iSearchDim == 1
	               mNextNumPM = mNumPM + 1;
                   if(mNextNumPM > iMaxPrimeMover) 
                       mNextNumPM = iMaxPrimeMover; 
                   end
	           elseif iSearchDim == 2
	               mNextNumYC = mNumYC + 1;
                   if mNextNumYC > iMaxYardCrane
                       mNextNumYC = iMaxYardCrane;
                   end
	           else
	           end
           end
           
       else
           %% initial searching direction is along PM, or iSearchDim == 1
           mNextNumPM = mNumPM + 1;
           mNextNumYC = mNumYC;
           tPrevMakeSpan = stCostAtAgent(ii).stCostList(1).tMakeSpan_hour;
       end
       
       if stBerthJobInfo.iPlotFlag >= 3
           iCase_PrevMakespan_CurrMakespan_FlagContinuSearch_iPM_iYC_iDir_mPrevDirPM_mPrevDirYC = ...
                  [iCasePMYC, tPrevMakeSpan, stCostAtAgent(ii).stCostList(iCasePMYC).tMakeSpan_hour, iFlagContinueSearch, ...
                   mNumPM, mNumYC, iSearchDim, mPrevDirStartNumPM, mPrevDirStartNumYC, mNextNumPM, mNextNumYC, iMaxPrimeMover, iMaxYardCrane]
       end
       
       % (mPrevDirStartNumPM == iMaxPrimeMover & mPrevDirStartNumYC > iMaxYardCrane) ...
       % | (mPrevDirStartNumYC == iMaxYardCrane & mPrevDirStartNumPM >iMaxPrimeMover) ...
       
       if(mNextNumPM > iMaxPrimeMover) | mNextNumYC > iMaxYardCrane
           mNextNumPM
           iMaxPrimeMover
           mNextNumYC
           iMaxYardCrane
           input('any key');
       end
       if( (mPrevDirStartNumPM >= iMaxPrimeMover ) ...
           & (mPrevDirStartNumYC >= iMaxYardCrane) ...
         )
           iFlagContinueSearch = 0;
           disp('complete iterative direction search.');
           iCasePMYC
       else
           mNumPM = mNextNumPM;
           mNumYC = mNextNumYC;
       end
         
       tPrevMakeSpan = stCostAtAgent(ii).stCostList(iCasePMYC).tMakeSpan_hour;
           idxCostMatrixRow = mNumPM - IniVirtualPrimeMover +1;
           idxCostMatrixCol = mNumYC - IniVirtualYardCrane + 1;
       
       %%% only used for iAlgoChoice == 4
%        if stBerthJobInfo.iAlgoChoice == 4
       if mPrevDirStartNumPM > IniVirtualPrimeMover & mPrevDirStartNumYC - IniVirtualYardCrane
%            %%% Check whether a local minimum has come up in the TotalMatrix
          bFlagExistLocalMinimum = chk_cost_matrix_sub_grad(fTotalCostMatrix, idxCostMatrixRow, idxCostMatrixCol);
          if bFlagExistLocalMinimum == 1
              iFlagContinueSearch = 0;
              disp('Local minimum has been detected.');
              iCasePMYC
          end
        end
       
    end  %%% while loop
    
    stCostAtAgent(ii).iTotalCase = iCasePMYC;
    [fMinTotalCost,idxMinCost] = min(stCostAtAgent(ii).afTotalCost);
    if stBerthJobInfo.iAlgoChoice == 2 | stBerthJobInfo.iAlgoChoice == 4 | stBerthJobInfo.iAlgoChoice == 5
        [container_sequence_jsp, stSpecificMachineTimeInfo] = psa_jsp_dispatch_machine_02(stCostAtAgent(ii).stCostList(idxMinCost).stSchedule);
    else
        container_sequence_jsp = stCostAtAgent(ii).stCostList(idxMinCost).stSchedule;
    end

    tEndTimePoint = cputime;
    tSolutionTime_sec(ii) = tEndTimePoint - tStartTimePoint;
    
    stCostAtAgent(ii).stSolutionMinCost.stSchedule = container_sequence_jsp;
    stCostAtAgent(ii).stSolutionMinCost.iMaxPM = stCostAtAgent(ii).aiNumPM(idxMinCost);
    stCostAtAgent(ii).stSolutionMinCost.iMaxYC = stCostAtAgent(ii).aiNumYC(idxMinCost);
    stCostAtAgent(ii).tSolutionTime_sec = tSolutionTime_sec(ii)
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
    stAgent_Solution(ii).stPerformReport.tMinCostGrossCraneRate = (stAgentJobListBiFsp(ii).TotalContainer_Load + stAgentJobListBiFsp(ii).TotalContainer_Discharge)/ stAgent_Solution(ii).stPerformReport.tMinCostMakeSpan_hour;
    stAgent_Solution(ii).stPerformReport.fCostMakespanTardiness = tMinCostMakeSpan_hour * stBerthJobInfo.stAgentJobInfo(ii).fPriceQuayCraneDollarPerFrame + stCostAtAgent(ii).stCostList(aiMinCost(ii)).fDelayPanelty;
    stAgent_Solution(ii).stPerformReport.fMinCost              =   stCostAtAgent(ii).stCostList(aiMinCost(ii)).fCostPM ...
                                                                + stCostAtAgent(ii).stCostList(aiMinCost(ii)).fCostYC ...
                                                                + stAgent_Solution(ii).stPerformReport.fCostMakespanTardiness;
    stAgent_Solution(ii).stPerformReport.tSolutionTime_sec = tSolutionTime_sec(ii);
end