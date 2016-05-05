function [stInputResAlloc, iFlagUpdatePriceOnly]= rel_berth_resalloc_init(iFlagUpdatePriceOnly, strFilenameBerthMaster)
% Input Prototype
% iFlagUpdatePriceOnly  
%                      0 : starting from empty
%                      1, 2 : load initial resource bidding and schedule
%                      solution from files and goto price adjustment
%                      directly
%                      3 : 
% strFilenameBerthMaster :
%
% History
% YYYYMMDD  Notes
% 20070602  Release ComplementarySearch

%%%%%%%%%%% User Interface
if nargin == 0
    disp('0: start from empty;');
    disp('1, 2: clear memory then load previous solution(makespan matrix ...) ');
    disp('3: Generate Initial Bidding Only');
    iFlagUpdatePriceOnly = input('Input choise: ');

    if iFlagUpdatePriceOnly == 0
        clear all;
        iFlagUpdatePriceOnly = 0;
    elseif iFlagUpdatePriceOnly == 1 | iFlagUpdatePriceOnly == 2
        clear all
        uiload;
        iFlagUpdatePriceOnly = 1;
    elseif  iFlagUpdatePriceOnly == 3
        iFlagUpdatePriceOnly = 3;
    end
    [stBerthJobInfo] = psa_berth_load_parameter;
elseif nargin == 1
    if iFlagUpdatePriceOnly == 0
        clear all;
        iFlagUpdatePriceOnly = 0;
    elseif iFlagUpdatePriceOnly == 1 | iFlagUpdatePriceOnly == 2
        clear all
        uiload;
        iFlagUpdatePriceOnly = 1;
    elseif  iFlagUpdatePriceOnly == 3
    end
    [stBerthJobInfo] = psa_berth_load_parameter;
elseif nargin == 2
    if iFlagUpdatePriceOnly == 1 | iFlagUpdatePriceOnly == 2 | iFlagUpdatePriceOnly == 3
        uiload;
    end
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
[stOutputLoadAgentInfo_GenSch0] = psa_fsp_get_maxusage_gensch0(stBerthJobInfo);
iMaxPrimeMoverUsageByGenSch0= stOutputLoadAgentInfo_GenSch0.iMaxPrimeMoverUsageByGenSch0 ;
iMaxYardCraneUsageByGenSch0 = stOutputLoadAgentInfo_GenSch0.iMaxYardCraneUsageByGenSch0  ;
stJobListInfoAgent = stOutputLoadAgentInfo_GenSch0.stJobListInfoAgent;
astResourceConfigGenSch0 = stOutputLoadAgentInfo_GenSch0.stResourceConfigGenSch0;
stBerthJobInfo.stJobListInfoAgent = stJobListInfoAgent;
stSchedule0_InfResourceModel = stOutputLoadAgentInfo_GenSch0.stSchedule0_InfResourceModel;

%%% Assign output structure
stInputResAlloc.stBerthJobInfo              = stBerthJobInfo               ;
stInputResAlloc.stJobListInfoAgent               = stJobListInfoAgent            ;
stInputResAlloc.iMaxPrimeMoverUsageByGenSch0= iMaxPrimeMoverUsageByGenSch0 ;
stInputResAlloc.iMaxYardCraneUsageByGenSch0 = iMaxYardCraneUsageByGenSch0  ;
stInputResAlloc.astResourceConfigGenSch0     = astResourceConfigGenSch0      ;


%input('Any key');
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%  Build initial bidding, according to different searching algorithm
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
if iFlagUpdatePriceOnly == 0 | iFlagUpdatePriceOnly == 3
    if stBerthJobInfo.iAlgoChoice == 7 | stBerthJobInfo.iAlgoChoice == 18 | stBerthJobInfo.iAlgoChoice == 20  ...
        | stBerthJobInfo.iAlgoChoice == 19 | stBerthJobInfo.iAlgoChoice == 21
    
        if stBerthJobInfo.iAlgoChoice == 7 |stBerthJobInfo.iAlgoChoice == 19 | stBerthJobInfo.iAlgoChoice == 21
            [stAgent_Solution_SinglePeriod] = psa_bidgen_search_04(stInputResAlloc);
            for ii = 1:1:stBerthJobInfo.iTotalAgent
                [stBuildMachConfigOutput] = psa_fsp_bld_machfig_by_sch ...
                    (stBerthJobInfo.fTimeFrameUnitInHour, stJobListInfoAgent(ii).stResourceConfig, stAgent_Solution_SinglePeriod(ii).stCostAtAgent.stSolutionMinCost.stSchedule);
                astResourceConfigSrchSinglePeriod(ii)      = stBuildMachConfigOutput.stResourceConfigSchOut;
            end
        else
            astResourceConfigSrchSinglePeriod          = astResourceConfigGenSch0  ;
        end
        if iPlotFlag >= 0
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
            stInputResAlloc.iMaxIter_BidGenOpt          = 2;
            stInputResAlloc.stBerthJobInfo              = stBerthJobInfo               ;
            stInputResAlloc.stJobListInfoAgent_ii          = stJobListInfoAgent(ii)            ;
            stInputResAlloc.iMaxPrimeMoverUsageByGenSch0= iMaxPrimeMoverUsageByGenSch0 ;
            stInputResAlloc.iMaxYardCraneUsageByGenSch0 = iMaxYardCraneUsageByGenSch0  ;
            stInputResAlloc.stResourceConfigGenSch0_ii  = astResourceConfigGenSch0(ii)  ;
            stInputResAlloc.iQuayCrane_id               = ii;
            
            if stBerthJobInfo.iAlgoChoice == 19 | stBerthJobInfo.iAlgoChoice == 21
                stInputResAlloc.stResourceConfigSrchSinglePeriod_ii = astResourceConfigSrchSinglePeriod(ii);
            else
                stInputResAlloc.stResourceConfigSrchSinglePeriod_ii = astResourceConfigGenSch0(ii)  ;
            end
            
            %if stBerthJobInfo.iAlgoChoice == 7
            %% By GenSch2
            %%    [stAgent_Solution_ii] = psa_bidgen_multiperiod_srch(stInputResAlloc);
            %else
            %%if stBerthJobInfo.iAlgoChoice == 21  % 20070602
                %% By GenSch3  % 20070602
            %%    [stAgent_Solution_ii] = psa_bidgen_mp_srch_grad(stInputResAlloc);                
            %%else
            %% By GenSch3
                [stAgent_Solution_ii] = psa_bidgen_mp_srch_rlx_rep(stInputResAlloc); % psa_bidgen_mp_srch_gensch3(stInputResAlloc);
            %%end  % 20070602
            stAgent_Solution(ii) = stAgent_Solution_ii;
            QuayCraneId = ii;
            PerformReport_ii = stAgent_Solution(ii).stPerformReport;
        end
    else
        error('Error Input');
    end
end




if ~isfield(stInputResAlloc,'iFlagSorting')
    stInputResAlloc.iFlagSorting  = 0;  %% by default no sorting price, first period first.
end
%%%%%%%%%%%%     Generate initial bidding
if stBerthJobInfo.iAlgoChoice == 7 | stBerthJobInfo.iAlgoChoice == 18 | stBerthJobInfo.iAlgoChoice == 19 | stBerthJobInfo.iAlgoChoice == 20 | stBerthJobInfo.iAlgoChoice == 21
    [stMachineUsageInfoBerth, stMachineUsageInfoByAgent] = psa_bidgen_build_bid_by_cfg(stBerthJobInfo, stAgent_Solution);
else
    [stMachineUsageInfoBerth, stMachineUsageInfoByAgent] = psa_bidgen_bld_mach_usage02(stBerthJobInfo, stAgent_Solution);
end

%%% Assign output structure
stInputResAlloc.astResourceConfigSrchSinglePeriod = astResourceConfigSrchSinglePeriod;
stInputResAlloc.astResourceConfigGenSch0          = astResourceConfigGenSch0;
stInputResAlloc.stAgent_Solution = stAgent_Solution;
%% Temperorily hard-coded, to be put in config file
stInputResAlloc.iMaxIter_BidGenOpt          = 2;
stInputResAlloc.stMachineUsageInfoBerth     = stMachineUsageInfoBerth;
stInputResAlloc.stMachineUsageInfoByAgent      = stMachineUsageInfoByAgent;
stInputResAlloc.stMachinePriceInfo          = stMachinePriceInfo;

%%%%%%%%%%%%     plotting
if iPlotFlag >= 4
    psa_plot_resalloc_sch_all_in_1(stAgent_Solution);
end
if iPlotFlag >= 3
    if stBerthJobInfo.iAlgoChoice == 7 | stBerthJobInfo.iAlgoChoice == 18 | stBerthJobInfo.iAlgoChoice == 19 ...
            | stBerthJobInfo.iAlgoChoice == 20 | stBerthJobInfo.iAlgoChoice == 21
        psa_plot_resalloc_sch(stAgent_Solution);
    end
end

%%%%%%%%%%%%   output init bidding report 
strNameSufix = 'Init';
psa_fsp_gen_bidding_report(stBerthJobInfo, stJobListInfoAgent, stAgent_Solution, stMachineUsageInfoByAgent, strNameSufix);


%%%%%%%%%%% Output
% stInputResAlloc
