function [stAgent_Solution] = psa_bidgen_search_06(stInputResAlloc)

%% searching dimensions one after the other, keep other dimension fixed when searching any dimension, stop once makespan not decreasing.
%% At the same time, detect and quit if totalcost is less than the neighbouring four
%% 

%%
stBerthJobInfo               = stInputResAlloc.stBerthJobInfo              ;
stJobListInfoAgent                = stInputResAlloc.stJobListInfoAgent               ;
iMaxPrimeMoverUsageByGenSch0 = stInputResAlloc.iMaxPrimeMoverUsageByGenSch0;
iMaxYardCraneUsageByGenSch0  = stInputResAlloc.iMaxYardCraneUsageByGenSch0 ;

%for ii = 1:1:stBerthJobInfo.iTotalAgent
for ii = stBerthJobInfo.iTotalAgent:-1:1

    [container_jsp_patial_heu, jobshop_config] = psa_jsp_gen_job_schedule_8(stJobListInfoAgent(ii));
    
    jobshop_config.iOptRule = stJobListInfoAgent(ii).iOptRule;
    jobshop_config.iTotalTimeSlot = round(1.1 * container_jsp_patial_heu.iMaxEndTime);
    TotalTimeSlot = jobshop_config.iTotalTimeSlot
    jobshop_config.iTimeStartFirstJobFirstProcess = container_jsp_patial_heu.stJobSet(1).iProcessStartTime(1) + 1;
    jobshop_config.stLagrangianRelax.alpha_r = 1.0;
    jobshop_config.stLagrangianRelax.iHeuristicAchieveFeasibility = 10;
    jobshop_config.stLagrangianRelax.iMaxIter = 20;
    jobshop_config.stLagrangianRelax.fDesiredDualityGap = 1.0;
    jobshop_config.stResourceConfig = stJobListInfoAgent(ii).stResourceConfig;
    jobshop_config.iMaxMachineUsageInSch0 = [1, min([iMaxPrimeMoverUsageByGenSch0(ii), stBerthJobInfo.iTotalPrimeMover]), ...
                                                min([iMaxYardCraneUsageByGenSch0(ii), stBerthJobInfo.iTotalYardCrane])];
    jobshop_config.fOverallTardinessPenalty = stBerthJobInfo.stAgentJobInfo(ii).fLatePenalty_SgdPerFrame;
    jobshop_config.fMakespanCost = stBerthJobInfo.stAgentJobInfo(ii).fPriceQuayCraneSgdPerFrame;
    jobshop_config.atClockJobStart = stBerthJobInfo.stAgentJobInfo(ii).atClockAgentJobStart;
    jobshop_config.atClockJobDue = stBerthJobInfo.stAgentJobInfo(ii).atClockAgentJobDue;
    jobshop_config.fTimeUnit_Min = stJobListInfoAgent(ii).fTimeUnit_Min;
    
    [fsp_resalloc_formulation, stMachineProcessMapping, lagrangian_info] = fsp_bidgen_formulate_mosek(jobshop_config, stBerthJobInfo);
    
    [x_ip] = psa_resalloc_build_xip_by_heu(jobshop_config, stBerthJobInfo, lagrangian_info, container_jsp_patial_heu);
    fsp_resalloc_formulation.mosek_form.sol.int.xx = x_ip;
    tStartTimePoint = cputime;
    
    param.MSK_IPAR_MIO_MAX_NUM_BRANCHES = 10000;
    [r, res] = mosekopt('minimize', fsp_resalloc_formulation.mosek_form, param);
    x_ip = res.sol.int.xx;
    [container_jsp_patial_ii] = jsp_build_solution_from_x(x_ip, jobshop_config, fsp_resalloc_formulation);

%    [container_jsp_patial_ii] = jsp_mosek(fsp_resalloc_formulation, jobshop_config);

    tEndTimePoint = cputime;
    tSolutionTime_sec = tEndTimePoint - tStartTimePoint;
    [astMachineUsageTimeInfo] = jsp_build_machine_usage_con_tm(container_jsp_patial_ii);
    container_jsp_patial_ii.iTotalMachineNum = [1, astMachineUsageTimeInfo(2).iMaxUsage, astMachineUsageTimeInfo(3).iMaxUsage];
    
    %%% Temperaily for dispatching
    stResourceConfig_ii = stJobListInfoAgent(ii).stResourceConfig;
    stResourceConfig_ii.stMachineConfig(2).iNumPointTimeCap = 1;
    stResourceConfig_ii.stMachineConfig(2).afTimePointAtCap = 0;
    stResourceConfig_ii.stMachineConfig(2).afMaCapAtTimePoint = astMachineUsageTimeInfo(2).iMaxUsage;
    stResourceConfig_ii.stMachineConfig(3).iNumPointTimeCap = 1;
    stResourceConfig_ii.stMachineConfig(3).afTimePointAtCap = 0;
    stResourceConfig_ii.stMachineConfig(3).afMaCapAtTimePoint = astMachineUsageTimeInfo(3).iMaxUsage;
    container_jsp_patial_ii.stResourceConfig = stResourceConfig_ii;
    
    [container_sequence_jsp, stSpecificMachineTimeInfo] = psa_jsp_dispatch_machine_02(container_jsp_patial_ii);
    
    
    stCostAtAgent(ii).stSolutionMinCost.stSchedule = container_sequence_jsp;
    stCostAtAgent(ii).tSolutionTime_sec = tSolutionTime_sec
    astFormulationInfo(ii).fsp_resalloc_formulation = fsp_resalloc_formulation; 
    astFormulationInfo(ii).stMachineProcessMapping  = stMachineProcessMapping;
    astFormulationInfo(ii).lagrangian_info          = lagrangian_info;
    astSolutionInfo(ii).x_ip                        = x_ip;
end

%%%% Assign Output
for ii = 1:1:stBerthJobInfo.iTotalAgent
    stAgent_Solution(ii).stCostAtAgent = stCostAtAgent(ii);
    stAgent_Solution(ii).stResourceUsageGenSch0.iMaxPM = iMaxPrimeMoverUsageByGenSch0(ii);
    stAgent_Solution(ii).stResourceUsageGenSch0.iMaxYC = iMaxYardCraneUsageByGenSch0(ii);
    stAgent_Solution(ii).stBidGenMipInfo.stFormulationInfo   = astFormulationInfo(ii);
    stAgent_Solution(ii).stBidGenMipInfo.stSolutionInfo      = astSolutionInfo(ii);
%    stAgent_Solution(ii).astMakespanInfo = astMakespanInfo(ii);
end