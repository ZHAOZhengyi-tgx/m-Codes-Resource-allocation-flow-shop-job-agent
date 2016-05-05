function [stSolutionInfo] = resalloc_ip_formu(stInputResAlloc)
% resource allocation, transform to IP (integer programming) formulation
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%  
%
%The MIT License (MIT)
%
%Copyright (c) 2016 ZHAOZhengyi-tgx
%
%Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the "Software"), to deal in the Software without restriction, including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions:
%
%The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.
%
%THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%
% Module: Solution for Resource Allocation among Scheduling Agents 
% Template for Problem Input
% OUTPUT from the solver: schedule for each job's process, dispatching for each machine
% During this whole document, % is for line commenting, which means any line starting with a % will not be taken into parsing.
%
% all right reserved (c)2016
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% all right reserved, @2016, Sg.LongRenE@gmail.com
%% [stSolutionInfo] = resalloc_ip_formu(stInputResAlloc)
% 
% History
% YYYYMMDD  Notes
% 20071127  variable hours per frame

%%
stResAllocGenJspAgent        = stInputResAlloc.stResAllocGenJspAgent;
stJssProbStructConfig        = stResAllocGenJspAgent.stJssProbStructConfig;
astAgentJobListBiFspCfg      = stInputResAlloc.astAgentJobListBiFspCfg;
% iMaxPrimeMoverUsageByGenSch0 = stInputResAlloc.iMaxPrimeMoverUsageByGenSch0;
% iMaxYardCraneUsageByGenSch0  = stInputResAlloc.iMaxYardCraneUsageByGenSch0 ;
astAgentJobListJspCfg = stInputResAlloc.astAgentJobListJspCfg;

stResourceConfig_ResAllocSys = stResAllocGenJspAgent.stResourceConfig;
stAgentJobInfo = stResAllocGenJspAgent.stAgentJobInfo;

iaSystemMachCapOnePer = stResourceConfig_ResAllocSys.iaMachCapOnePer;
stSystemMasterConfig = stResAllocGenJspAgent.stSystemMasterConfig;
nTotalMachineType = stSystemMasterConfig.iTotalMachType;
nTotalAgent = stSystemMasterConfig.iTotalAgent;

% vector of nTotalMachineType
iaMaxMachUsageByInfResSch = stInputResAlloc.astMachUsageInfRes(1).iaMaxMachUsageBySchOut;
for aa = 1:1:nTotalAgent
    %% vector addition
    iaMaxMachUsageByInfResSch = iaMaxMachUsageByInfResSch + stInputResAlloc.astMachUsageInfRes(aa).iaMaxMachUsageBySchOut;
end

tStartTimePoint = cputime;
%% allocate memory
for mm= 1:1:nTotalMachineType
    if mm == stSystemMasterConfig.iCriticalMachType
        iaMaxMachUsage(mm) = 1;
    else
        iaMaxMachUsage(mm) = min([iaSystemMachCapOnePer(mm), iaMaxMachUsageByInfResSch(mm)]);
    end
end

fSumMakeSpanTardinessCost = 0;
for ii = 1:1:nTotalAgent
%     fJobListWeight(ii) = stBerthJobInfo.stAgentJobInfo(ii).fPriceQuayCraneDollarPerFrame  + ...
%         stBerthJobInfo.stAgentJobInfo(ii).fLatePenalty_DollarPerFrame * 3600 / ...
%         etime(stBerthJobInfo.stAgentJobInfo(ii).atClockAgentJobDue.aClockYearMonthDateHourMinSec, ...
%         stBerthJobInfo.stAgentJobInfo(ii).atClockAgentJobStart.aClockYearMonthDateHourMinSec);
    tAgentExpectedDuration_sec(ii) = etime(stAgentJobInfo(ii).atClockAgentJobDue.aClockYearMonthDateHourMinSec, ...
        stAgentJobInfo(ii).atClockAgentJobStart.aClockYearMonthDateHourMinSec);
    %% heuristic weight per hour, 
    %% Agent's Hourly Price + DelayPenalty / ExpectedDuration_in_hour
    %% variable hours per frame % 20071127
    fJobListWeight(ii) = stAgentJobInfo(ii).fPriceAgentDollarPerFrame * stSystemMasterConfig.fTimeFrameUnitInHour + ...
        stAgentJobInfo(ii).fLatePenalty_DollarPerFrame * stSystemMasterConfig.fTimeFrameUnitInHour * 3600/tAgentExpectedDuration_sec(ii);
    
    fSumMakeSpanTardinessCost = fSumMakeSpanTardinessCost +  fJobListWeight(ii);
%     stJobListInfoAgent(ii).stJssProbStructConfig = stBerthJobInfo.stJssProbStructConfig; %20070725
%     [jobshop_config] = psa_jsp_construct_jsp_config(stJobListInfoAgent(ii));
%     astAgentJobListJspCfg(ii) = jobshop_config;
end

%% allocation by above heuristic weight
astAgentJobListJspCfgHeu = astAgentJobListJspCfg;
for ii = 1:1:nTotalAgent
    for mm = 1:1:nTotalMachineType
        if mm == stSystemMasterConfig.iCriticalMachType
        else
            iNumPointTimeCap = astAgentJobListJspCfg(ii).stResourceConfig.stMachineConfig(mm).iNumPointTimeCap;
            for tt = 1:1:iNumPointTimeCap
                astAgentJobListJspCfgHeu(ii).stResourceConfig.stMachineConfig(mm).afMaCapAtTimePoint(tt) = ...
                    floor(iaSystemMachCapOnePer(mm) * fJobListWeight(ii)/fSumMakeSpanTardinessCost);
            end
        end
    end
    
    iJobSeqInJspCfg = astAgentJobListJspCfgHeu(ii).aiJobSeqInJspCfg;
    [stFspSchedule] = jsp_constr_sche_struct_by_cfg(astAgentJobListJspCfgHeu(ii));
    container_jsp_schedule = fsp_bd_multi_m_t_greedy_by_seq(stFspSchedule, astAgentJobListJspCfgHeu(ii), iJobSeqInJspCfg); 
    astBiFspScheduleHeu(ii) = container_jsp_schedule;
%     for tt = 1:1:stJobListInfoAgent(ii).stResourceConfig.stMachineConfig(2).iNumPointTimeCap
%         stJobListInfoAgent(ii).stResourceConfig.stMachineConfig(2).afMaCapAtTimePoint(tt) = ceil(stBerthJobInfo.iTotalPrimeMover * fJobListWeight(ii)/fSumMakeSpanTardinessCost);
%     end
%     for tt = 1:1:stJobListInfoAgent(ii).stResourceConfig.stMachineConfig(3).iNumPointTimeCap
%         stJobListInfoAgent(ii).stResourceConfig.stMachineConfig(3).afMaCapAtTimePoint(tt) = ceil(stBerthJobInfo.iTotalYardCrane * fJobListWeight(ii)/fSumMakeSpanTardinessCost);
%     end
%     [stContainerDischargeJobSequence, container_jsp_discha_schedule, stContainerLoadJobSequence, container_jsp_load_schedule, container_jsp_schedule] = ...
%         psa_jsp_gen_sch3_multiperiod(stJobListInfoAgent(ii));
    
    
%    astAgentJobListJspCfg(ii).iOptRule = stJobListInfoAgent(ii).iOptRule;
    astAgentJobListJspCfg(ii).iTotalTimeSlot = round(astBiFspScheduleHeu(ii).iMaxEndTime); %% heuristic has enough margin, even more time for planning in greedy
    astAgentJobListJspCfg(ii).iTimeStartFirstJobFirstProcess = astBiFspScheduleHeu(ii).stJobSet(1).iProcessStartTime(1) + 1;
    astAgentJobListJspCfg(ii).stLagrangianRelax.alpha_r = 1.0;
    astAgentJobListJspCfg(ii).stLagrangianRelax.iHeuristicAchieveFeasibility = 10;
    astAgentJobListJspCfg(ii).stLagrangianRelax.iMaxIter = 20;
    astAgentJobListJspCfg(ii).stLagrangianRelax.fDesiredDualityGap = 1.0;
%     astAgentJobListJspCfg(ii).stResourceConfig = astAgentJobListBiFspCfg(ii).stResourceConfig;
%     astAgentJobListJspCfg(ii).iMaxMachineUsageInSch0 = [1, min([iMaxPrimeMoverUsageByGenSch0(ii), stBerthJobInfo.iTotalPrimeMover]), ...
%                                                 min([iMaxYardCraneUsageByGenSch0(ii), stBerthJobInfo.iTotalYardCrane])];
    astAgentJobListJspCfg(ii).iMaxMachineUsageInSch0 = iaMaxMachUsage;
    astAgentJobListJspCfg(ii).fOverallTardinessPenalty = stAgentJobInfo(ii).fLatePenalty_DollarPerFrame; % stBerthJobInfo.stAgentJobInfo(ii).fLatePenalty_DollarPerFrame;
    astAgentJobListJspCfg(ii).fMakespanCost = stAgentJobInfo(ii).fPriceAgentDollarPerFrame; % stBerthJobInfo.stAgentJobInfo(ii).fPriceQuayCraneDollarPerFrame;
    astAgentJobListJspCfg(ii).atClockJobStart = stAgentJobInfo(ii).atClockAgentJobStart; % stBerthJobInfo.stAgentJobInfo(ii).atClockAgentJobStart;
    astAgentJobListJspCfg(ii).atClockJobDue = stAgentJobInfo(ii).atClockAgentJobDue;     % stBerthJobInfo.stAgentJobInfo(ii).atClockAgentJobDue;
%     astAgentJobListJspCfg(ii).fTimeUnit_Min = stJobListInfoAgent(ii).fTimeUnit_Min;
    
    if ii == 1
        tEarlistStartTime_datenum = datenum(astAgentJobListJspCfg(ii).atClockJobStart.aClockYearMonthDateHourMinSec);
        tLatestEndTime_datenum = tEarlistStartTime_datenum + astBiFspScheduleHeu(ii).iMaxEndTime * astAgentJobListJspCfg(ii).fTimeUnit_Min / 60/24;
        tMinmumTimeUnit_Min = astAgentJobListJspCfg(ii).fTimeUnit_Min;
        iTotalMachineTypeAtSystem = astAgentJobListJspCfg(ii).iTotalMachine;
%         if iTotalMachineTypeAtSystem~= 3
%             error('Version 1 only support 3 machine types');
%         end
    else
        tCurrentStartTime_datenum = datenum(astAgentJobListJspCfg(ii).atClockJobStart.aClockYearMonthDateHourMinSec);
        tCurrentEndTime_datenum = tCurrentStartTime_datenum + astBiFspScheduleHeu(ii).iMaxEndTime * astAgentJobListJspCfg(ii).fTimeUnit_Min / 60/24;
        if tEarlistStartTime_datenum > tCurrentStartTime_datenum
            tEarlistStartTime_datenum = tCurrentStartTime_datenum;
        end
        if tLatestEndTime_datenum < tCurrentEndTime_datenum
            tLatestEndTime_datenum = tCurrentEndTime_datenum;
        end
        if tMinmumTimeUnit_Min < astAgentJobListJspCfg(ii).fTimeUnit_Min
            tMinmumTimeUnit_Min = astAgentJobListJspCfg(ii).fTimeUnit_Min;
            error('Time unit must be the same');
        end
        if iTotalMachineTypeAtSystem ~= astAgentJobListJspCfg(ii).iTotalMachine
            error('Total Machine type doesnot match');
        end
    end
    
     nTotalTimeSlotPerAgentEstima(ii) = astBiFspScheduleHeu(ii).iMaxEndTime;
end

% nTotalTimeSlotPerAgentEstima

stResAllocSystemJspCfg.stJspConfigList = astAgentJobListJspCfg;  %% for version compatible 
stResAllocSystemJspCfg.tEarlistStartTime_datenum = tEarlistStartTime_datenum;
stResAllocSystemJspCfg.tLatestEndTime_datenum = tLatestEndTime_datenum;
stResAllocSystemJspCfg.iTotalTimeSlot = ceil((tLatestEndTime_datenum - tEarlistStartTime_datenum)*24*60/tMinmumTimeUnit_Min);
%% variable hours per frame % 20071127
stResAllocSystemJspCfg.iTotalTimeFrame = ceil(stResAllocSystemJspCfg.iTotalTimeSlot * tMinmumTimeUnit_Min/60 /stSystemMasterConfig.fTimeFrameUnitInHour);  
stResAllocSystemJspCfg.tMinmumTimeUnit_Min = tMinmumTimeUnit_Min;
stResAllocSystemJspCfg.iTotalMachineTypeAtSystem = iTotalMachineTypeAtSystem;

%% to handle dynamic resource (machine) allocation, 
%% consider  stResourceConfig_ResAllocSys
for pp = 1:1:stResAllocSystemJspCfg.iTotalTimeFrame
%     for mm = 1:1:nTotalMachineType
%         if mm == stSystemMasterConfig.iCriticalMachType
%             stResAllocSystemJspCfg.astMachineCapAtPeriod(pp).aiMaxMachineCapacity(mm) = nTotalAgent;
%         else
%             stResAllocSystemJspCfg.astMachineCapAtPeriod(pp).aiMaxMachineCapacity(mm) = iaSystemMachCapOnePer(mm);
%         end
%     end
    stResAllocSystemJspCfg.astMachineCapAtPeriod(pp).aiMaxMachineCapacity = iaSystemMachCapOnePer;
end
% stJssProbStructConfig can be agent dependant
[fsp_resalloc_formulation, astAgentFormulateInfo] = fsp_resalloc_formulate_mosek(stResAllocSystemJspCfg, stSystemMasterConfig, stJssProbStructConfig);

if stSystemMasterConfig.iAlgoChoice == 25
    fsp_resalloc_formulation.mosek_form.ints.sub = [];
end

global IP_SOLVER_OPT_MSK;
global IP_SOLVER_OPT_SEDUMI;
global IP_SOLVER_OPT_CPLEX;

if stSystemMasterConfig.iAlgoChoice ~= 17
    if stSystemMasterConfig.iSolverPackage == IP_SOLVER_OPT_MSK  %% mosek
        param.MSK_IPAR_MIO_MAX_NUM_BRANCHES = 500;
        [r, res] = mosekopt('minimize', fsp_resalloc_formulation.mosek_form, param);

        if stSystemMasterConfig.iAlgoChoice == 25
            stSolutionInfo.stMipSolution.xip = res.sol.itr.xx;    
        else
            stSolutionInfo.stMipSolution.xip = res.sol.int.xx;
        end
        stSolutionInfo.fObjValue         = fsp_resalloc_formulation.obj_offset + stSolutionInfo.stMipSolution.xip' * fsp_resalloc_formulation.mosek_form.c;  % 20070614
    elseif stSystemMasterConfig.iSolverPackage == IP_SOLVER_OPT_SEDUMI %% sedumi
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
stSolutionInfo.astAgentFormulateInfo    = astAgentFormulateInfo;
stSolutionInfo.stResAllocSystemJspCfg   = stResAllocSystemJspCfg;
stSolutionInfo.tSolutionTime_sec        = tSolutionTime_sec;

