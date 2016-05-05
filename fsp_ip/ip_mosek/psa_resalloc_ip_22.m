function [stSolutionInfo] = psa_resalloc_ip_22(stInputResAlloc)
%% searching dimensions one after the other, keep other dimension fixed when searching any dimension, stop once makespan not decreasing.
%% At the same time, detect and quit if totalcost is less than the neighbouring four
%% 
% 20080322 Debug
%%
stBerthJobInfo               = stInputResAlloc.stBerthJobInfo;
stJobListInfoAgent       = stInputResAlloc.stJobListInfoAgent;
iMaxPrimeMoverUsageByGenSch0 = stInputResAlloc.iMaxPrimeMoverUsageByGenSch0;
iMaxYardCraneUsageByGenSch0  = stInputResAlloc.iMaxYardCraneUsageByGenSch0 ;

tStartTimePoint = cputime;

fSumMakeSpanTardinessCost = 0;
for ii = 1:1:stBerthJobInfo.iTotalAgent
    fJobListWeight(ii) = stBerthJobInfo.stAgentJobInfo(ii).fPriceQuayCraneDollarPerFrame  + ...
        stBerthJobInfo.stAgentJobInfo(ii).fLatePenalty_DollarPerFrame * 3600 /etime(stBerthJobInfo.stAgentJobInfo(ii).atClockAgentJobDue.aClockYearMonthDateHourMinSec, stBerthJobInfo.stAgentJobInfo(ii).atClockAgentJobStart.aClockYearMonthDateHourMinSec);
    fSumMakeSpanTardinessCost = fSumMakeSpanTardinessCost +  fJobListWeight(ii);
    stJobListInfoAgent(ii).stJssProbStructConfig = stBerthJobInfo.stJssProbStructConfig; %20070725
    [jobshop_config] = psa_jsp_construct_jsp_config(stJobListInfoAgent(ii));
    stJspConfigList(ii) = jobshop_config;

end

for ii = 1:1:stBerthJobInfo.iTotalAgent
    
    for tt = 1:1:stJobListInfoAgent(ii).stResourceConfig.stMachineConfig(2).iNumPointTimeCap
        stJobListInfoAgent(ii).stResourceConfig.stMachineConfig(2).afMaCapAtTimePoint(tt) = ceil(stBerthJobInfo.iTotalPrimeMover * fJobListWeight(ii)/fSumMakeSpanTardinessCost);
    end
    for tt = 1:1:stJobListInfoAgent(ii).stResourceConfig.stMachineConfig(3).iNumPointTimeCap
        stJobListInfoAgent(ii).stResourceConfig.stMachineConfig(3).afMaCapAtTimePoint(tt) = ceil(stBerthJobInfo.iTotalYardCrane * fJobListWeight(ii)/fSumMakeSpanTardinessCost);
    end
    [stContainerDischargeJobSequence, container_jsp_discha_schedule, stContainerLoadJobSequence, container_jsp_load_schedule, container_jsp_schedule] = ...
        psa_jsp_gen_sch3_multiperiod(stJobListInfoAgent(ii));
    
    
    stJspConfigList(ii).iOptRule = stJobListInfoAgent(ii).iOptRule;
    stJspConfigList(ii).iTotalTimeSlot = round(1.1 * container_jsp_schedule.iMaxEndTime);
    stJspConfigList(ii).iTimeStartFirstJobFirstProcess = container_jsp_schedule.stJobSet(1).iProcessStartTime(1) + 1;
    stJspConfigList(ii).stLagrangianRelax.alpha_r = 1.0;
    stJspConfigList(ii).stLagrangianRelax.iHeuristicAchieveFeasibility = 10;
    stJspConfigList(ii).stLagrangianRelax.iMaxIter = 20;
    stJspConfigList(ii).stLagrangianRelax.fDesiredDualityGap = 1.0;
    stJspConfigList(ii).stResourceConfig = stJobListInfoAgent(ii).stResourceConfig;
    stJspConfigList(ii).iMaxMachineUsageInSch0 = [1, min([iMaxPrimeMoverUsageByGenSch0(ii), stBerthJobInfo.iTotalPrimeMover]), ...
                                                min([iMaxYardCraneUsageByGenSch0(ii), stBerthJobInfo.iTotalYardCrane])];
    stJspConfigList(ii).fOverallTardinessPenalty = stBerthJobInfo.stAgentJobInfo(ii).fLatePenalty_DollarPerFrame;
    stJspConfigList(ii).fMakespanCost = stBerthJobInfo.stAgentJobInfo(ii).fPriceQuayCraneDollarPerFrame;
    stJspConfigList(ii).atClockJobStart = stBerthJobInfo.stAgentJobInfo(ii).atClockAgentJobStart;
    stJspConfigList(ii).atClockJobDue = stBerthJobInfo.stAgentJobInfo(ii).atClockAgentJobDue;
    stJspConfigList(ii).fTimeUnit_Min = stJobListInfoAgent(ii).fTimeUnit_Min;
    
    if ii == 1
        tEarlistStartTime_datenum = datenum(stJspConfigList(ii).atClockJobStart.aClockYearMonthDateHourMinSec);
        tLatestEndTime_datenum = tEarlistStartTime_datenum + stJspConfigList(ii).iTotalTimeSlot * stJspConfigList(ii).fTimeUnit_Min / 60/24;
        tMinmumTimeUnit_Min = stJspConfigList(ii).fTimeUnit_Min;
        iTotalMachineTypeAtBerth = stJspConfigList(ii).iTotalMachine;
        if iTotalMachineTypeAtBerth~= 3
            error('Version 1 only support 3 machine types');
        end
    else
        tCurrentStartTime_datenum = datenum(stJspConfigList(ii).atClockJobStart.aClockYearMonthDateHourMinSec);
        tCurrentEndTime_datenum = tCurrentStartTime_datenum + stJspConfigList(ii).iTotalTimeSlot * stJspConfigList(ii).fTimeUnit_Min / 60/24;
        if tEarlistStartTime_datenum > tCurrentStartTime_datenum
            tEarlistStartTime_datenum = tCurrentStartTime_datenum;
        end
        if tLatestEndTime_datenum < tCurrentEndTime_datenum
            tLatestEndTime_datenum = tCurrentEndTime_datenum;
        end
        if tMinmumTimeUnit_Min < stJspConfigList(ii).fTimeUnit_Min
            tMinmumTimeUnit_Min = stJspConfigList(ii).fTimeUnit_Min;
            error('Time unit must be the same');
        end
        if iTotalMachineTypeAtBerth ~= stJspConfigList(ii).iTotalMachine
            error('Total Machine type doesnot match');
        end
    end
    
     nTotalTimeSlotPerAgentEstima(ii) = stJspConfigList(ii).iTotalTimeSlot;
end

nTotalTimeSlotPerAgentEstima

stBerthJspConfig.stJspConfigList = stJspConfigList;
stBerthJspConfig.tEarlistStartTime_datenum = tEarlistStartTime_datenum;
stBerthJspConfig.tLatestEndTime_datenum = tLatestEndTime_datenum;
stBerthJspConfig.iTotalTimeSlot = ceil((tLatestEndTime_datenum - tEarlistStartTime_datenum)*24*60/tMinmumTimeUnit_Min);
stBerthJspConfig.iTotalTimeFrame = ceil(stBerthJspConfig.iTotalTimeSlot * tMinmumTimeUnit_Min/60);
stBerthJspConfig.tMinmumTimeUnit_Min = tMinmumTimeUnit_Min;
stBerthJspConfig.iTotalMachineTypeAtBerth = iTotalMachineTypeAtBerth;
for pp = 1:1:stBerthJspConfig.iTotalTimeFrame
    stBerthJspConfig.astMachineCapAtPeriod(pp).aiMaxMachineCapacity = [stBerthJobInfo.iTotalAgent, stBerthJobInfo.iTotalPrimeMover, stBerthJobInfo.iTotalYardCrane];
end
stBerthJobInfo.iTotalMachType = 3; %% compatible
[fsp_resalloc_formulation, stQuayCraneFormulateInfo] = fsp_resalloc_formulate_mosek(stBerthJspConfig, stBerthJobInfo, stBerthJobInfo.stJssProbStructConfig);

if stBerthJobInfo.iAlgoChoice == 25
    fsp_resalloc_formulation.mosek_form.ints.sub = [];
end

global IP_SOLVER_OPT_MSK;
global IP_SOLVER_OPT_SEDUMI;
global IP_SOLVER_OPT_CPLEX;

if stBerthJobInfo.iAlgoChoice ~= 17
    if stBerthJobInfo.stSystemMasterConfig.iSolverPackage == IP_SOLVER_OPT_MSK  %% mosek % 20080322
        param.MSK_IPAR_MIO_MAX_NUM_BRANCHES = 500;
        [r, res] = mosekopt('minimize', fsp_resalloc_formulation.mosek_form, param);

        if stBerthJobInfo.iAlgoChoice == 25
            stSolutionInfo.stMipSolution.xip = res.sol.itr.xx;    

        else
            stSolutionInfo.stMipSolution.xip = res.sol.int.xx;
        end

        stSolutionInfo.fObjValue         = fsp_resalloc_formulation.obj_offset + stSolutionInfo.stMipSolution.xip' * fsp_resalloc_formulation.mosek_form.c;  % 20070614
    elseif stBerthJobInfo.stSystemMasterConfig.iSolverPackage == IP_SOLVER_OPT_SEDUMI %% sedumi, % 20080322
        fsp_resalloc_formulation.sedumi_form = resalloc_cvt_sedumi_by_mosek(fsp_resalloc_formulation.mosek_form);
%        fsp_resalloc_formulation.sedumi_form = sedumi_form;
        fsp_resalloc_formulation.mosek_form = [];
        par.eps = 1e-7;
        par.maxiter = 50;

        [x, y, info] = sedumi(fsp_resalloc_formulation.sedumi_form.A, ...
            fsp_resalloc_formulation.sedumi_form.b, ...
            fsp_resalloc_formulation.sedumi_form.c, ...
            fsp_resalloc_formulation.sedumi_form.K, par);
        stSolutionInfo.stMipSolution.xip = x;
        stSolutionInfo.fObjValue         = fsp_resalloc_formulation.obj_offset + x' * fsp_resalloc_formulation.sedumi_form.c;  % 20070614
    else
        error('unknown Solver Package. 1: MOSEK, 2: SEDUMI');
            
    end

end

tEndTimePoint = cputime;
tSolutionTime_sec = tEndTimePoint - tStartTimePoint;

stSolutionInfo.fsp_resalloc_formulation = fsp_resalloc_formulation;
stSolutionInfo.stQuayCraneFormulateInfo = stQuayCraneFormulateInfo;
stSolutionInfo.stBerthJspConfig         = stBerthJspConfig;
stSolutionInfo.tSolutionTime_sec        = tSolutionTime_sec;

