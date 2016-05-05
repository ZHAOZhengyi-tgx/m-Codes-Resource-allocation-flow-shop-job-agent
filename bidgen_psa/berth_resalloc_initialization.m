function [stInputResAlloc, stAgent_Solution_SinglePeriod]= berth_resalloc_initialization(strFilenameBerthMaster)
% Function Prototype
%    [stInputResAlloc]= berth_resalloc_initialization(strFilenameBerthMaster)
% Input Prototype
% strFilenameBerthMaster : a string pointing the the fullename of the
% master configuration file
%
% History
% YYYYMMDD  Notes
% 20070602  Release ComplementarySearch
% 20070614  add objective value in solution
% 20080321  resalloc_gen_perform_mip

stAgent_Solution_SinglePeriod = [];

%%%%%%%%%%% User Interface
if nargin == 0
    [stBerthJobInfo] = psa_berth_load_parameter;
elseif nargin == 1
    [stBerthJobInfo] = psa_berth_load_parameter(strFilenameBerthMaster);
else
    error('Only two inputs are allowed');
end
%%%%%%%%%%%%

iPlotFlag = stBerthJobInfo.iPlotFlag;
% == 0: no stop, plot least figure
% >= 1: plot some figures
% >= 3: stop for prompting
% >= 4: for NUS_ECE-SMU collaborate developers. 
stMachinePriceInfo = [];

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%  Read stJobListInfoAgent for each Agent, Get the maximum number of searching range of [PM, YC] by GenSch0
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
jsp_glb_define();

[stOutputLoadAgentInfo_GenSch0] = psa_fsp_get_maxusage_gensch0(stBerthJobInfo);
iMaxPrimeMoverUsageByGenSch0= stOutputLoadAgentInfo_GenSch0.iMaxPrimeMoverUsageByGenSch0 ;
iMaxYardCraneUsageByGenSch0 = stOutputLoadAgentInfo_GenSch0.iMaxYardCraneUsageByGenSch0  ;
stJobListInfoAgent = stOutputLoadAgentInfo_GenSch0.stJobListInfoAgent;
astResourceConfigGenSch0 = stOutputLoadAgentInfo_GenSch0.stResourceConfigGenSch0;
stBerthJobInfo.stJobListInfoAgent = stJobListInfoAgent;
stSchedule0_InfResourceModel = stOutputLoadAgentInfo_GenSch0.stSchedule0_InfResourceModel;

%%% Assign output structure
stInputResAlloc.astAgentMachineHourInfo = stOutputLoadAgentInfo_GenSch0.astAgentMachineHourInfo;
stInputResAlloc.stBerthJobInfo              = stBerthJobInfo               ;
stInputResAlloc.stJobListInfoAgent               = stJobListInfoAgent            ;
stInputResAlloc.iMaxPrimeMoverUsageByGenSch0= iMaxPrimeMoverUsageByGenSch0 ;
stInputResAlloc.iMaxYardCraneUsageByGenSch0 = iMaxYardCraneUsageByGenSch0  ;
stInputResAlloc.astResourceConfigGenSch0     = astResourceConfigGenSch0      ;
%%  20080321
stInputResAlloc.stResAllocGenJspAgent = stBerthJobInfo;
for aa = 1:1:stBerthJobInfo.iTotalAgent
    stInputResAlloc.astAgentJobListJspCfg(aa) = stInputResAlloc.stJobListInfoAgent(aa).jobshop_config;
end

%% 20080321
stSolutionInfo = [];  % 20070614

%input('Any key');
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%  Build initial bidding, according to different searching algorithm
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
if stBerthJobInfo.iAlgoChoice == 1
    [stAgent_Solution_SinglePeriod] = psa_bidgen_search_01(stInputResAlloc);
    stAgent_Solution = stAgent_Solution_SinglePeriod;
elseif stBerthJobInfo.iAlgoChoice == 2 | stBerthJobInfo.iAlgoChoice == 4 | stBerthJobInfo.iAlgoChoice == 5
    [stAgent_Solution_SinglePeriod] = psa_bidgen_search_04(stInputResAlloc);
    stAgent_Solution = stAgent_Solution_SinglePeriod;
%elseif stBerthJobInfo.iAlgoChoice == 3
elseif stBerthJobInfo.iAlgoChoice == 6   %% MIP solution, decentralized model
    [stAgent_Solution] = psa_bidgen_search_06(stInputResAlloc);
    [stAgent_Solution] = psa_bidgen_gen_perform_mip(stBerthJobInfo, stAgent_Solution, stJobListInfoAgent);
    stMachinePriceInfo = [];
elseif stBerthJobInfo.iAlgoChoice == 17  % only formulation, then save to data file for other solvers to tackle
    [stSolutionInfo] = psa_resalloc_ip_22(stInputResAlloc);
    stMachinePriceInfo = [];
    astResourceConfigSrchSinglePeriod = [];
    astResourceConfigGenSch0          = [];
    stAgent_Solution                     = [];
    stMachineUsageInfoSystem           = [];
    stMachineUsageInfoByAgent            = [];
elseif stBerthJobInfo.iAlgoChoice == 22 | stBerthJobInfo.iAlgoChoice == 25  %% MIP solution, decentralized model
    [stSolutionInfo] = psa_resalloc_ip_22(stInputResAlloc);
    
    iLenNameNoExt = strfind(stBerthJobInfo.strInputFilename, '.') - 1; %% 20080321
    strCmd_SaveFormulateInfoMatFile = sprintf('save %s_stSolutionInfo.mat stSolutionInfo stBerthJobInfo stInputResAlloc', stBerthJobInfo.strInputFilename(1:iLenNameNoExt));
    eval(strCmd_SaveFormulateInfoMatFile); %20080322
    
    if stBerthJobInfo.iAlgoChoice == 22   %% integer solution
        [stAgent_Solution] = psa_bld_solution_by_berth_mip(stSolutionInfo, stBerthJobInfo);
    else  % linear relaxation solution
%        [stAgent_Solution] = psa_bld_solution_by_berth_lpr(stSolutionInfo, stBerthJobInfo);
        stSolutionInfo.astAgentFormulateInfo = stSolutionInfo.stQuayCraneFormulateInfo;
        stSolutionInfo.stResAllocSystemJspCfg = stSolutionInfo.stBerthJspConfig;
        for qq = 1:1:stBerthJobInfo.iTotalAgent
            stInputResAllocPlugInGen.astAgentJobListBiFspCfg(qq) = cvt_joblist_by_port(stJobListInfoAgent(qq));
            stInputResAllocPlugInGen.astAgentJobListJspCfg(qq)   = stJobListInfoAgent(qq).jobshop_config;
            stInputResAllocPlugInGen.astAgentJobListJspCfg(qq).iOptRule = 28; %% multi-period, no-wait-in-process
            stInputResAllocPlugInGen.astAgentJobListJspCfg(qq).aiJobSeqInJspCfg = stJobListInfoAgent(qq).aiJobSeqInJspCfg
        end
        stInputResAllocPlugInGen.stResAllocGenJspAgent   = stBerthJobInfo;
        stInputResAllocPlugInGen.astAgentMachineHourInfo = stInputResAlloc.astAgentMachineHourInfo;
%         stInputResAllocPlugInGen.astAgentMachineHourInfo = ;
%         stInputResAllocPlugInGen.astAgentJobListJspCfg   = stJobListInfoAgent;
%         stInputResAllocPlugInGen.astAgentJobListBiFspCfg = ;
        [stAgent_Solution] = resalloc_bld_solution_by_lpr(stSolutionInfo, stInputResAllocPlugInGen);
    end
%    [stAgent_Solution] = psa_bidgen_gen_perform_mip(stBerthJobInfo, stAgent_Solution, stJobListInfoAgent);
    [stAgent_Solution] = resalloc_gen_perform_mip(stInputResAlloc, stAgent_Solution); % 20080321
    for qq = 1:1:stBerthJobInfo.iTotalAgent
        stBerthJobInfo.stAgentJobInfo(qq).atClockAgentJobStart.aClockYearMonthDateHourMinSec = datevec(stSolutionInfo.stBerthJspConfig.tEarlistStartTime_datenum);
    end
    stMachinePriceInfo = [];
    astResourceConfigSrchSinglePeriod = [];
    astResourceConfigGenSch0          = [];

    %% a solution structure compatible with the heuristic approach
    stSolutionInfo.nTotalFeasibleSolution = 1;
    stSolutionInfo.astFeasibleSolutionSet.astAgent_Solution = stAgent_Solution;
    fFeasibleObjValue = 0;
    for ii = 1:1:stBerthJobInfo.iTotalAgent
        fFeasibleObjValue = fFeasibleObjValue + stAgent_Solution(ii).stPerformReport.fCostMakespanTardiness;
    end
    stSolutionInfo.astFeasibleSolutionSet.fFeasibleObjValue = fFeasibleObjValue;
    stSolutionInfo.fTotalCostMakespanTardiness = fFeasibleObjValue;

%% Multiperiod search
elseif stBerthJobInfo.iAlgoChoice == 23   %% lagrangian relaxation with UB and LB
    if iPlotFlag >= 3
        for qq = 1:1:stBerthJobInfo.iTotalAgent
            stAgent_SolutionInitInfResource(qq).stSchedule_MinCost = stSchedule0_InfResourceModel(qq);
        end
        psa_plot_resalloc_sch_all_in_1(stAgent_SolutionInitInfResource);
        input('Any key to proceed');
    end
        stInputResAlloc.iFlagSorting                = stBerthJobInfo.stBidGenSubProbSearch.iFlagSortingPrice;  % 0;  %% decending
        stInputResAlloc.iFlag_RunGenSch2            = stBerthJobInfo.stBidGenSubProbSearch.iFlagRunStrictSrch; % 1;
        stInputResAlloc.iMaxIter_BidGenOpt          = stBerthJobInfo.stBidGenSubProbSearch.iMaxIter_LocalSearchBidGen; % 2;
        stInputResAlloc.iMaxPrimeMoverUsageByGenSch0= iMaxPrimeMoverUsageByGenSch0 ;
        stInputResAlloc.iMaxYardCraneUsageByGenSch0 = iMaxYardCraneUsageByGenSch0  ;
    [stSolutionInfo] = price_adj_lg_rlx(stInputResAlloc, stSchedule0_InfResourceModel);
    stAgent_Solution = stSolutionInfo.stAgent_Solution;
    stMachinePriceInfo = stSolutionInfo.stMachinePriceInfo;
elseif stBerthJobInfo.iAlgoChoice == 7 | stBerthJobInfo.iAlgoChoice == 18 | stBerthJobInfo.iAlgoChoice == 20  ...
    | stBerthJobInfo.iAlgoChoice == 19 | stBerthJobInfo.iAlgoChoice == 21

    if stBerthJobInfo.iAlgoChoice == 7 |stBerthJobInfo.iAlgoChoice == 19 | stBerthJobInfo.iAlgoChoice == 21 ...
            | stBerthJobInfo.iAlgoChoice == 18
        [stAgent_Solution_SinglePeriod] = psa_bidgen_search_04(stInputResAlloc);
        for ii = 1:1:stBerthJobInfo.iTotalAgent
            [stBuildMachConfigOutput] = psa_fsp_bld_machfig_by_sch ...
                (stBerthJobInfo.fTimeFrameUnitInHour, stJobListInfoAgent(ii).stResourceConfig, stAgent_Solution_SinglePeriod(ii).stCostAtAgent.stSolutionMinCost.stSchedule);
            astResourceConfigSrchSinglePeriod(ii)      = stBuildMachConfigOutput.stResourceConfigSchOut;
        end
    else
        astResourceConfigSrchSinglePeriod          = astResourceConfigGenSch0  ;
    end
    if iPlotFlag >= 3
        for ii = 1:1:stBerthJobInfo.iTotalAgent
            iAgentId = ii
            Machine2ConfigArray = astResourceConfigSrchSinglePeriod(ii).stResourceConfig.stMachineConfig(2).afMaCapAtTimePoint
            Machine3ConfigArray = astResourceConfigSrchSinglePeriod(ii).stResourceConfig.stMachineConfig(3).afMaCapAtTimePoint
        end
    end
    % stInputResAlloc.iFlagSorting
    %       1: ascending order, searching from period with lowest price
    %       -1: ascending order, searching from period with highest price
    %       0: first period first search
    for ii = 1:1:stBerthJobInfo.iTotalAgent
        stInputResAlloc.iFlagSorting                = 0;  %% decending
        stInputResAlloc.iFlag_RunGenSch2            = 1;
        stInputResAlloc.iMaxIter_BidGenOpt          = 1;
        stInputResAlloc.stBerthJobInfo              = stBerthJobInfo               ;
        stInputResAlloc.stJobListInfoAgent_ii          = stJobListInfoAgent(ii)            ;
        stInputResAlloc.iMaxPrimeMoverUsageByGenSch0= iMaxPrimeMoverUsageByGenSch0 ;
        stInputResAlloc.iMaxYardCraneUsageByGenSch0 = iMaxYardCraneUsageByGenSch0  ;
        stInputResAlloc.stResourceConfigGenSch0_ii  = astResourceConfigGenSch0(ii)  ;
        stInputResAlloc.iQuayCrane_id               = ii;

        if stBerthJobInfo.iAlgoChoice == 18 |stBerthJobInfo.iAlgoChoice == 19 | stBerthJobInfo.iAlgoChoice == 21
            % start from single period period model
            stInputResAlloc.stResourceConfigSrchSinglePeriod_ii = astResourceConfigSrchSinglePeriod(ii);
        else % by default, start from schedule with infinite resource model
            stInputResAlloc.stResourceConfigSrchSinglePeriod_ii = astResourceConfigGenSch0(ii)  ;
        end

        [stAgent_Solution_ii] = psa_bidgen_mp_srch_rlx_rep(stInputResAlloc); % psa_bidgen_mp_srch_gensch3(stInputResAlloc);
        stAgent_Solution(ii) = stAgent_Solution_ii;
        QuayCraneId = ii;
        PerformReport_ii = stAgent_Solution(ii).stPerformReport;
    end
else
    error('Error Input');
end

if  iPlotFlag >= 4 & (stBerthJobInfo.iAlgoChoice == 7 |stBerthJobInfo.iAlgoChoice == 19 | stBerthJobInfo.iAlgoChoice == 20 |stBerthJobInfo.iAlgoChoice == 21 ...
            | stBerthJobInfo.iAlgoChoice == 18 | stBerthJobInfo.iAlgoChoice == 2 | stBerthJobInfo.iAlgoChoice == 1)
    fsp_plot_berth_agent_alloc(stAgent_Solution_SinglePeriod);
    fsp_save_one_per_srch_fig(stBerthJobInfo);
    psa_mesh_berth_resalloc(stAgent_Solution_SinglePeriod);

end

if  stBerthJobInfo.iAlgoChoice == 2 | stBerthJobInfo.iAlgoChoice == 1
    stInputResAlloc.stAgent_Solution = stAgent_Solution;
    return;
end

if ~isfield(stInputResAlloc,'iFlagSorting')
    stInputResAlloc.iFlagSorting  = 0;  %% by default no sorting price, first period first.
end
%%%%%%%%%%%%     Generate initial bidding
if stBerthJobInfo.iAlgoChoice == 7 | stBerthJobInfo.iAlgoChoice == 18 | stBerthJobInfo.iAlgoChoice == 19 | stBerthJobInfo.iAlgoChoice == 20 ...
        | stBerthJobInfo.iAlgoChoice == 21
    [stMachineUsageInfoSystem, stMachineUsageInfoByAgent] = psa_bidgen_build_bid_by_cfg(stBerthJobInfo, stAgent_Solution);
elseif stBerthJobInfo.iAlgoChoice == 6 | stBerthJobInfo.iAlgoChoice == 22 | stBerthJobInfo.iAlgoChoice == 23 ...
            | stBerthJobInfo.iAlgoChoice == 25 | stBerthJobInfo.iAlgoChoice == 1 |  stBerthJobInfo.iAlgoChoice == 2  ...
            | stBerthJobInfo.iAlgoChoice == 4 | stBerthJobInfo.iAlgoChoice == 5 
    [stMachineUsageInfoSystem, stMachineUsageInfoByAgent] = psa_bidgen_bld_mach_usage02(stBerthJobInfo, stAgent_Solution);
end

%%% Assign output structure
stInputResAlloc.astResourceConfigSrchSinglePeriod = astResourceConfigSrchSinglePeriod;
stInputResAlloc.astResourceConfigGenSch0          = astResourceConfigGenSch0;
stInputResAlloc.stAgent_Solution = stAgent_Solution;
%% Temperorily hard-coded, to be put in config file
stInputResAlloc.iMaxIter_BidGenOpt          = 1;
stInputResAlloc.stMachineUsageInfoSystem     = stMachineUsageInfoSystem;
stInputResAlloc.stMachineUsageInfoByAgent      = stMachineUsageInfoByAgent;
stInputResAlloc.stMachinePriceInfo          = stMachinePriceInfo;
stInputResAlloc.stSolutionInfo             = stSolutionInfo;  % 20070614

if stBerthJobInfo.iAlgoChoice == 17
    iLenNameNoExt = strfind(stBerthJobInfo.strInputFilename, '.') - 1;
    stBerthSolution = stSolutionInfo;  % 20070614
    strCmd_SaveMatFile = sprintf('save %s_Formulation.mat stBerthSolution stBerthJobInfo stInputResAlloc', stBerthJobInfo.strInputFilename(1:iLenNameNoExt))

    [s,strSystem] = system('ver');
    if s == 0 %% it is a dos-windows system
    else %% it is a UNIX or Linux system
        iPathStringList = strfind(strCmd_SaveMatFile, '\');
        for ii = 1:1:length(iPathStringList)
            strCmd_SaveMatFile(iPathStringList(ii)) = '/';
        end
    end
    eval(strCmd_SaveMatFile);
    strCmd_SaveCplxDatFile = sprintf('%s_cplx_in.dat', stBerthJobInfo.strInputFilename(1:iLenNameNoExt));
    cvt_gen_ilog_data_from_msk02(stBerthSolution.fsp_resalloc_formulation.mosek_form, strCmd_SaveCplxDatFile);
    return;
end

%%%%%%%%%%%%     plotting
if iPlotFlag >= 10
    psa_plot_resalloc_sch_all_in_1(stAgent_Solution);
end
if iPlotFlag >= 10
    if stBerthJobInfo.iAlgoChoice == 6 | stBerthJobInfo.iAlgoChoice == 7 | stBerthJobInfo.iAlgoChoice == 18 | stBerthJobInfo.iAlgoChoice == 19 ...
            | stBerthJobInfo.iAlgoChoice == 20 | stBerthJobInfo.iAlgoChoice == 21 | stBerthJobInfo.iAlgoChoice == 22 | stBerthJobInfo.iAlgoChoice == 23 ...
            | stBerthJobInfo.iAlgoChoice == 25
        psa_plot_resalloc_sch(stAgent_Solution);
    elseif  stBerthJobInfo.iAlgoChoice == 1 |  stBerthJobInfo.iAlgoChoice == 2 |  stBerthJobInfo.iAlgoChoice == 4 | stBerthJobInfo.iAlgoChoice == 5 
        psa_plot_resalloc_sch(stAgent_Solution);
        fsp_plot_berth_agent_alloc(stAgent_Solution);
    end
end

%%%%%%%%%%%%   output init bidding report 
strNameSufix = 'Init';
psa_fsp_gen_bidding_report(stBerthJobInfo, stJobListInfoAgent, stAgent_Solution, stMachineUsageInfoByAgent, strNameSufix);

%%% clean output structure
if isfield(stInputResAlloc, 'stJobListInfoAgent_ii')
    stInputResAlloc = rmfield(stInputResAlloc, 'stJobListInfoAgent_ii');
end
if isfield(stInputResAlloc, 'stResourceConfigGenSch0_ii')
    stInputResAlloc = rmfield(stInputResAlloc, 'stResourceConfigGenSch0_ii');
end
if isfield(stInputResAlloc, 'iQuayCrane_id')
    stInputResAlloc = rmfield(stInputResAlloc, 'iQuayCrane_id');
end
if isfield(stInputResAlloc, 'stResourceConfigSrchSinglePeriod_ii')
    stInputResAlloc = rmfield(stInputResAlloc, 'stResourceConfigSrchSinglePeriod_ii');
end

%%%%%%%%%%% Output
% stInputResAlloc
