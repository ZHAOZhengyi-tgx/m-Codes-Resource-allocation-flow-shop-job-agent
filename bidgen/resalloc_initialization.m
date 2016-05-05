function [stInputResAlloc]= resalloc_initialization(strFilenameResAllocMaster)
% resource allocation initialization
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
% History
% YYYYMMDD  Notes
% 20080321  resalloc_gen_perform_mip

jsp_glb_define();

if nargin == 0
    [stResAllocGenJspAgent] = resalloc_load_glb_parameter;
elseif nargin == 1
    [stResAllocGenJspAgent] = resalloc_load_glb_parameter(strFilenameResAllocMaster);
else
    error('Only two inputs are allowed');
end
stSystemMasterConfig = stResAllocGenJspAgent.stSystemMasterConfig;

stInputResAlloc = resalloc_get_inf_res_sche_fsp(stResAllocGenJspAgent);
astAgentJobListJspCfg = stInputResAlloc.astAgentJobListJspCfg;
astMachUsageInfRes = stInputResAlloc.astMachUsageInfRes;
for ii = 1:1:stSystemMasterConfig.iTotalAgent
    astResourceConfigGenSch0(ii)          = astMachUsageInfRes(ii).stResourceConfig;
end

iPlotFlag = stResAllocGenJspAgent.stSystemMasterConfig.iPlotFlag;
% == 0: no stop, plot least figure
% >= 1: plot some figures
% >= 3: stop for prompting
% >= 4: for NUS_ECE-SMU collaborate developers. 
stSolutionInfo = [];  % 20070614
stMachinePriceInfo = [];

if stSystemMasterConfig.iAlgoChoice == 17  % only formulation, then save to data file for other solvers to tackle
    [stSolutionInfo] = resalloc_ip_formu(stInputResAlloc);
    stMachinePriceInfo = [];
    astResourceConfigSrchSinglePeriod = [];
    stAgent_Solution                  = [];
    stMachineUsageInfoSystem           = [];
    stMachineUsageInfoByAgent         = [];
elseif stSystemMasterConfig.iAlgoChoice == 22 || stSystemMasterConfig.iAlgoChoice == 25  %% MIP solution, decentralized model
    [stSolutionInfo] = resalloc_ip_formu(stInputResAlloc);
    iLenNameNoExt = strfind(stBerthJobInfo.strInputFilename, '.') - 1; %% 20080321
    strCmd_SaveFormulateInfoMatFile = sprintf('save %s_stSolutionInfo.mat stSolutionInfo stInputResAlloc', stBerthJobInfo.strInputFilename(1:iLenNameNoExt));
    eval(strCmd_SaveFormulateInfoMatFile); %20080322
    if stSystemMasterConfig.iAlgoChoice == 22   %% integer solution
        [stAgent_Solution] = resalloc_bld_sltn_by_mip_01(stSolutionInfo, stSystemMasterConfig);
    else  % linear relaxation solution
        [stAgent_Solution] = resalloc_bld_solution_by_lpr(stSolutionInfo, stInputResAlloc);
    end
    [stAgent_Solution] = resalloc_gen_perform_mip(stInputResAlloc, stAgent_Solution);
    stMachinePriceInfo = [];
    astResourceConfigSrchSinglePeriod = [];

    %% a solution structure compatible with the heuristic approach
    stSolutionInfo.nTotalFeasibleSolution = 1;
    stSolutionInfo.astFeasibleSolutionSet.astAgent_Solution = stAgent_Solution;
    fFeasibleObjValue = 0;
    for ii = 1:1:stSystemMasterConfig.iTotalAgent
        fFeasibleObjValue = fFeasibleObjValue + stAgent_Solution(ii).stPerformReport.fCostMakespanTardiness;
    end
    stSolutionInfo.astFeasibleSolutionSet.fFeasibleObjValue = fFeasibleObjValue;
    stSolutionInfo.fTotalCostMakespanTardiness = fFeasibleObjValue;
elseif stSystemMasterConfig.iAlgoChoice == 7 || stSystemMasterConfig.iAlgoChoice == 18 || stSystemMasterConfig.iAlgoChoice == 20  ...
    || stSystemMasterConfig.iAlgoChoice == 19 || stSystemMasterConfig.iAlgoChoice == 21

    if stSystemMasterConfig.iAlgoChoice == 7 || stSystemMasterConfig.iAlgoChoice == 19 || stSystemMasterConfig.iAlgoChoice == 21 ...
            || stSystemMasterConfig.iAlgoChoice == 18
        [stAgent_Solution_SinglePeriod] = bidgen_search_single_per(stInputResAlloc);
        stAgent_Solution = stAgent_Solution_SinglePeriod;
        for ii = 1:1:stSystemMasterConfig.iTotalAgent
            [stBuildMachConfigOutput] = jsp_bld_machfig_by_sch ...
                (stSystemMasterConfig, stAgent_Solution_SinglePeriod(ii).stCostAtAgent.stSolutionMinCost.stSchedule);
            astResourceConfigSrchSinglePeriod(ii)      = stBuildMachConfigOutput.stResourceConfig;
            stAgent_Solution(ii).stCostAtAgent.stSolutionMinCost.stSchedule.stResourceConfig = stBuildMachConfigOutput.stResourceConfig;
            stAgent_Solution(ii).stMinCostResourceConfig = stBuildMachConfigOutput.stResourceConfig;
        end
    else
        for ii = 1:1:stSystemMasterConfig.iTotalAgent
            stAgent_Solution(ii).stCostAtAgent.stSolutionMinCost.stSchedule = stInputResAlloc.astFspScheduleInfRes(ii);
            stAgent_Solution(ii).stCostAtAgent.stSolutionMinCost.stSchedule.stResourceConfig = astResourceConfigGenSch0(ii);
            stAgent_Solution(ii).stMinCostResourceConfig = astResourceConfigGenSch0(ii);
        end
    end
else
    error('Error Input');
end


if  iPlotFlag >= 4 && (stSystemMasterConfig.iAlgoChoice == 7 ||stSystemMasterConfig.iAlgoChoice == 19 || stSystemMasterConfig.iAlgoChoice == 20 |stSystemMasterConfig.iAlgoChoice == 21 ...
            || stSystemMasterConfig.iAlgoChoice == 18 || stSystemMasterConfig.iAlgoChoice == 2 || stSystemMasterConfig.iAlgoChoice == 1)
    fsp_plot_berth_agent_alloc(stAgent_Solution_SinglePeriod);
    fsp_save_one_per_srch_fig(stResAllocGenJspAgent);
    psa_mesh_berth_resalloc(stAgent_Solution_SinglePeriod);

end

if  stSystemMasterConfig.iAlgoChoice == 2 || stSystemMasterConfig.iAlgoChoice == 1
    stInputResAlloc.stAgent_Solution = stAgent_Solution;
    return;
end

%%%%%%%%%%%%     Generate initial bidding
if stSystemMasterConfig.iAlgoChoice == 7 || stSystemMasterConfig.iAlgoChoice == 18 || stSystemMasterConfig.iAlgoChoice == 19 || stSystemMasterConfig.iAlgoChoice == 20 ...
        || stSystemMasterConfig.iAlgoChoice == 21
    stResAllocGenJspAgent.iTotalAgent           = stSystemMasterConfig.iTotalAgent;
    stResAllocGenJspAgent.fTimeFrameUnitInHour  = stSystemMasterConfig.fTimeFrameUnitInHour;
    stResAllocGenJspAgent.iTotalMachType        = stSystemMasterConfig.iTotalMachType;
    stResAllocGenJspAgent.tPlanningWindow_Hours = stSystemMasterConfig.tPlanningWindow_Hours;
    [stMachineUsageInfoSystem, stMachineUsageInfoByAgent] = psa_bidgen_build_bid_by_cfg(stResAllocGenJspAgent, stAgent_Solution);
elseif stSystemMasterConfig.iAlgoChoice == 6 || stSystemMasterConfig.iAlgoChoice == 22 || stSystemMasterConfig.iAlgoChoice == 23 ...
            || stSystemMasterConfig.iAlgoChoice == 25 || stSystemMasterConfig.iAlgoChoice == 1 ||  stSystemMasterConfig.iAlgoChoice == 2  ...
            || stSystemMasterConfig.iAlgoChoice == 4 || stSystemMasterConfig.iAlgoChoice == 5
    [stMachineUsageInfoSystem, stMachineUsageInfoByAgent] = resalloc_bld_mach_usage(stResAllocGenJspAgent, stAgent_Solution);
end

%%% Assign output structure
stInputResAlloc.astResourceConfigSrchSinglePeriod = astResourceConfigSrchSinglePeriod;
stInputResAlloc.astResourceConfigGenSch0          = astResourceConfigGenSch0;
stInputResAlloc.stAgent_Solution = stAgent_Solution;
%% Temperorily hard-coded, to be put in config file
stInputResAlloc.stMachineUsageInfoSystem     = stMachineUsageInfoSystem;
stInputResAlloc.stMachineUsageInfoByAgent      = stMachineUsageInfoByAgent;
stInputResAlloc.stMachinePriceInfo          = stMachinePriceInfo;
stInputResAlloc.stSolutionInfo             = stSolutionInfo;  % 20070614
% stInputResAlloc.anUppBoundSrchMachCap = anUppBoundSrchMachCap;

if stSystemMasterConfig.iAlgoChoice == 17
    iLenNameNoExt = strfind(stResAllocGenJspAgent.strInputFilename, '.') - 1;
    stBerthSolution = stSolutionInfo;  % 20070614
    strCmd_SaveMatFile = sprintf('save %s_Formulation.mat stBerthSolution stResAllocGenJspAgent stInputResAlloc', stResAllocGenJspAgent.strInputFilename(1:iLenNameNoExt));

    [s,strSystem] = system('ver');
    if s == 0 %% it is a dos-windows system
    else %% it is a UNIX or Linux system
        iPathStringList = strfind(strCmd_SaveMatFile, '\');
        for ii = 1:1:length(iPathStringList)
            strCmd_SaveMatFile(iPathStringList(ii)) = '/';
        end
    end
    eval(strCmd_SaveMatFile);
    strCmd_SaveCplxDatFile = sprintf('%s_cplx_in.dat', stResAllocGenJspAgent.strInputFilename(1:iLenNameNoExt));
    cvt_gen_ilog_data_from_msk02(stBerthSolution.fsp_resalloc_formulation.mosek_form, strCmd_SaveCplxDatFile);
    return;
end

%%% 
stIdFigure.iGlobalMachUsage = 5;
stIdFigure.iAllScheGroupByMachine = 401;
stIdFigure.iAllScheGroupByJob = 402;
stIdFigure.iAllScheduleInOnePicByMach = 403;
if iPlotFlag >= 4.5
    psa_jsp_plot_ycpm_usage(stMachineUsageInfoSystem, stIdFigure.iGlobalMachUsage);
    psa_plot_resalloc_sch_all_in_1(stAgent_Solution, stIdFigure);

    figure(stIdFigure.iAllScheduleInOnePicByMach);
    stResAllocGenJspAgent.iTotalAgent = stSystemMasterConfig.iTotalAgent; % for version compatible
    stResAllocGenJspAgent.iAlgoChoice = stSystemMasterConfig.iAlgoChoice;
    stResAllocGenJspAgent.iPlotFlag   = stSystemMasterConfig.iPlotFlag;
    jsp_plot_jobsolution_glb(stResAllocGenJspAgent, stAgent_Solution, stIdFigure.iAllScheduleInOnePicByMach);
end
