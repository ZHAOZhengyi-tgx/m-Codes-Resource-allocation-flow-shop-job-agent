function [stResAllocSolution, stResAllocGenJspAgent, stInputResAlloc] = resalloc_gensch(strFilenameResAllocMaster)
% berth_resalloc_gensch
%    test interface specially built for port related flow-shop
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
%
%nargin = 1
%
% prototype:
% [stResAllocSolution, stResAllocGenJspAgent, stInputResAlloc] = resalloc_gensch(strFilenameResAllocMaster)
% strFilenameResAllocMaster: master configuration filename
% History
% YYYYMMDD  Notes
% 20070524  Initialization stSolutionInfo by zzy
% 20070602  Release ComplementarySearch zzy
% 20070605  improve stoping criterion zzy
% 20070614  add objective value in solution
% 20070704  add MachinePrice information
% 20070812  global dispatching
% 20071109 Add global parameter definition
% 20080406 legacy for psa_gen_sch_perform_rpt_by_cfg

close all;

t0 = cputime;
jsp_glb_define(); % 20071109

%%%%%%%%%%% Auction Initialization, including
if nargin == 0
    [stInputResAlloc] = resalloc_initialization;
elseif nargin == 1
    [stInputResAlloc] = resalloc_initialization(strFilenameResAllocMaster);
else
    disp('resalloc_gensch(strFilenameBerthMaster)');
    error('error input format');
end

stResAllocGenJspAgent           = stInputResAlloc.stResAllocGenJspAgent;
astAgentJobListBiFspCfg         = stInputResAlloc.astAgentJobListBiFspCfg;
stSystemMasterConfig  = stResAllocGenJspAgent.stSystemMasterConfig;
iPlotFlag = stSystemMasterConfig.iPlotFlag;
% == 0: no stop, plot least figure
% >= 1: stop for prompting
% >= 2: plot all figures

% legacy for psa_gen_sch_perform_rpt_by_cfg, 20080406
for aa = 1:1:stSystemMasterConfig.iTotalAgent
    stJobListInfoAgent(aa).stResourceConfig = stInputResAlloc.astAgentJobListBiFspCfg(aa).stResourceConfig;
    stJobListInfoAgent(aa).stJobListBiFsp   = stInputResAlloc.astAgentJobListBiFspCfg(aa);
    stJobListInfoAgent(aa).fTimeUnit_Min    = stInputResAlloc.astAgentJobListBiFspCfg(aa).stAgentBiFSPJobMachConfig.fTimeUnit_Min;
end
stInputResAlloc.stJobListInfoAgent= stJobListInfoAgent;

% astAgentJobListBiFspCfg = stResAllocGenJspAgent.astAgentJobListBiFspCfg;

% Schedule Solution
stAgent_Solution = stInputResAlloc.stAgent_Solution;
% Machine Usage for the initial price in the master config file
stMachineUsageInfoSystem    = stInputResAlloc.stMachineUsageInfoSystem    ;
stMachineUsageInfoByAgent   = stInputResAlloc.stMachineUsageInfoByAgent      ;
stMachinePriceInfo          = stInputResAlloc.stMachinePriceInfo          ;
stSolutionInfo              = stInputResAlloc.stSolutionInfo;  % 20070524

t1 = cputime;

%%% initialize output structure
stConstraintVialationInfo.nTotalCaseViolation = 0;
stConstraintVialationInfo.astCaseViolation    = [];

if stSystemMasterConfig.iAlgoChoice == 17
    stResAllocSolution = stInputResAlloc.stSolutionInfo;
    mosekopt('write(d:\myprob.mps.gz)', stInputResAlloc.stSolutionInfo.fsp_resalloc_formulation.mosek_form)
    return;
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%% Multi-period Auction
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% interative adjust price for single period problem
stInputResAlloc.stMachinePriceInfo = [];

if stSystemMasterConfig.iAlgoChoice == 6 || stSystemMasterConfig.iAlgoChoice == 22 || ...
        stSystemMasterConfig.iAlgoChoice == 23 || stSystemMasterConfig.iAlgoChoice == 25
    %%%%%%%%%%%%%%%%%

% elseif stSystemMasterConfig.iAlgoChoice == 1 | stSystemMasterConfig.iAlgoChoice == 2 | stSystemMasterConfig.iAlgoChoice == 4 | stSystemMasterConfig.iAlgoChoice == 5 
%     [stMachineUsageInfoSystem, stMachineUsageInfoByAgent, stAgent_Solution, stSolutionInfo, stMachinePriceInfo] = psa_resalloc_by_auction(stInputResAlloc); % 20070704
%     if iPlotFlag >= 1
%         figure(4);
%         plot(stSolutionInfo.s_r);
%         title('Price adjustment factor');
%         xlabel('No. Iteration');
%     end
elseif  stSystemMasterConfig.iAlgoChoice == 18
    stInputResAlloc.stResAllocGenJspAgent.iTotalAgent           = stSystemMasterConfig.iTotalAgent;
    stInputResAlloc.stResAllocGenJspAgent.fTimeFrameUnitInHour  = stSystemMasterConfig.fTimeFrameUnitInHour;
    stInputResAlloc.stResAllocGenJspAgent.iTotalMachType        = stSystemMasterConfig.iTotalMachType;
    stInputResAlloc.stResAllocGenJspAgent.tPlanningWindow_Hours = stSystemMasterConfig.tPlanningWindow_Hours;
    stInputResAlloc.stResAllocGenJspAgent.iPlotFlag             = stSystemMasterConfig.iPlotFlag;
    stInputResAlloc.stResAllocGenJspAgent.iAlgoChoice = stSystemMasterConfig.iAlgoChoice;
    stInputResAlloc.stResAllocGenJspAgent.iObjFunction       = stSystemMasterConfig.iObjFunction;
    [stOutputResAlloc] = resalloc_fsp_port3m_by_auction(stInputResAlloc);
    stMachineUsageInfoSystem = stOutputResAlloc.stMachineUsageInfoBerth ;
    stMachineUsageInfoByAgent  = stOutputResAlloc.stMachineUsageInfoByAgent  ;
    stAgent_Solution           = stOutputResAlloc.stAgent_Solution           ;
    stSolutionInfo          = stOutputResAlloc.stSolutionInfo          ;
    stMachinePriceInfo      = stOutputResAlloc.stMachinePriceInfo     ; 
    stConstraintVialationInfo = stOutputResAlloc.stConstraintVialationInfo; %20070605

    % 20070704
    nTotalMachine = 2; %% temporarily hard coded
    stInputReportPrice.iPlotFlag = iPlotFlag;
    stInputReportPrice.iCriticalMachType = stSystemMasterConfig.iCriticalMachType;
    stInputReportPrice.iFigureIdPriceAdjustFactor = 4;
    stInputReportPrice.iFigureIdNetDemandAndPriceByMachine = 200 + [1:nTotalMachine];
    iLenNameNoExt = strfind(stResAllocGenJspAgent.strInputFilename, '.') - 1;
    strFileName = sprintf('%s_PriceAdjustInfo.txt', ...
                   stResAllocGenJspAgent.strInputFilename(1:iLenNameNoExt));
    stInputReportPrice.strReportFilename = strFileName;
    stInputReportPrice.stSolutionInfo = stSolutionInfo;
    price_adj_out_report(stInputReportPrice);
    % 20070704
    stResAllocGenJspAgent.iTotalAgent           = stSystemMasterConfig.iTotalAgent;
    stResAllocGenJspAgent.iPlotFlag   = stSystemMasterConfig.iPlotFlag;
    stResAllocGenJspAgent.fTimeFrameUnitInHour = stSystemMasterConfig.fTimeFrameUnitInHour;
    stResAllocGenJspAgent.iTotalMachType = stSystemMasterConfig.iTotalMachType;
    stResAllocGenJspAgent.tPlanningWindow_Hours = stSystemMasterConfig.iMaxFramesForPlanning * stSystemMasterConfig.fTimeFrameUnitInHour;
    [stMachineUsageInfoSystem, stMachineUsageInfoByAgent] = psa_bidgen_build_bid_by_cfg(stResAllocGenJspAgent, stAgent_Solution);
end


% global dispatching 20070812
stResAllocGenJspAgent.iTotalAgent = stSystemMasterConfig.iTotalAgent; % for version compatible
stResAllocGenJspAgent.iAlgoChoice = stSystemMasterConfig.iAlgoChoice;
stResAllocGenJspAgent.iPlotFlag   = stSystemMasterConfig.iPlotFlag;
stResAllocGenJspAgent.iObjFunction = stSystemMasterConfig.iObjFunction;
stResAllocGenJspAgent.fTimeFrameUnitInHour = stSystemMasterConfig.fTimeFrameUnitInHour;
stResAllocGenJspAgent.iTotalMachType = stSystemMasterConfig.iTotalMachType;
[stAgent_Solution, stDebugOutput] = psa_jsp_dispatch_machine_glb(stResAllocGenJspAgent, stAgent_Solution);

%% computation time donot considering plotting.
t2 = cputime;

%% plotting 
stIdFigure.iGlobalMachUsage = 5;
stIdFigure.iAllScheGroupByMachine = 301;
stIdFigure.iAllScheGroupByJob = 302;
stIdFigure.iAllScheduleInOnePicByMach = 303;
if iPlotFlag >= 0.5
    psa_jsp_plot_ycpm_usage(stMachineUsageInfoSystem, stIdFigure.iGlobalMachUsage);
    psa_plot_resalloc_sch_all_in_1(stAgent_Solution, stIdFigure);

    figure(stIdFigure.iAllScheduleInOnePicByMach);
    jsp_plot_jobsolution_glb(stResAllocGenJspAgent, stAgent_Solution, stIdFigure.iAllScheduleInOnePicByMach);
end

if iPlotFlag >= 1.5
    stIdFigure.iAllScheGroupByMachine = 101;
    stIdFigure.iAllScheGroupByJob = 102;
    psa_plot_resalloc_sch_all_in_1(stAgent_Solution, stIdFigure);
    [stFigureIndivAgent] = psa_plot_resalloc_sch(stAgent_Solution);
    stIdFigure.stFigureIndivAgent = stFigureIndivAgent;
    fsp_dbg_save_figure(stResAllocGenJspAgent, stIdFigure);
end
stResAllocSolution.stIdFigure      = stIdFigure;

stResAllocSolution.tSolutionTime_sec = t2 - t1;
stResAllocSolution.stAgent_Solution     = stAgent_Solution;
stResAllocSolution.tSolutionTimeInitialization_sec = t1 - t0;
stResAllocSolution.stSolutionInfo  = stSolutionInfo;
stResAllocSolution.stConstraintVialationInfo = stConstraintVialationInfo;  %20070605

%%% Output file: Final Report
if stSystemMasterConfig.iAlgoChoice == 4 || stSystemMasterConfig.iAlgoChoice == 5 || ...
        stSystemMasterConfig.iAlgoChoice == 7 || stSystemMasterConfig.iAlgoChoice == 18 || ...
        stSystemMasterConfig.iAlgoChoice == 19 || stSystemMasterConfig.iAlgoChoice == 20 || ...
        stSystemMasterConfig.iAlgoChoice == 21
    strNameSufix = 'Final';
    
    strFileName = resalloc_gen_bid_sche_report(stResAllocGenJspAgent, ...
        astAgentJobListBiFspCfg, stAgent_Solution, stMachineUsageInfoByAgent, strNameSufix, stResAllocSolution);
elseif stSystemMasterConfig.iAlgoChoice == 22 || stSystemMasterConfig.iAlgoChoice == 23 || ...
        stSystemMasterConfig.iAlgoChoice == 25
    strNameSufix = 'Final';
    save 20071206.mat stResAllocGenJspAgent astAgentJobListBiFspCfg stAgent_Solution stMachineUsageInfoByAgent strNameSufix stResAllocSolution;
    strFileName = resalloc_gen_bid_sche_report(stResAllocGenJspAgent, astAgentJobListBiFspCfg, stAgent_Solution, stMachineUsageInfoByAgent, strNameSufix, stResAllocSolution);
    
    %save BerthSolution.mat stResAllocSolution 
end
    
if iPlotFlag >= 2
    if stSystemMasterConfig.iAlgoChoice == 6 || stSystemMasterConfig.iAlgoChoice == 7 || ...
            stSystemMasterConfig.iAlgoChoice == 18 || stSystemMasterConfig.iAlgoChoice == 19 ...
            || stSystemMasterConfig.iAlgoChoice == 20 || stSystemMasterConfig.iAlgoChoice == 21 || ...
            stSystemMasterConfig.iAlgoChoice == 22 || stSystemMasterConfig.iAlgoChoice == 23 ...
            || stSystemMasterConfig.iAlgoChoice == 25
        psa_plot_resalloc_sch(stAgent_Solution);
    elseif  stSystemMasterConfig.iAlgoChoice == 1 ||  stSystemMasterConfig.iAlgoChoice == 2 || ...
            stSystemMasterConfig.iAlgoChoice == 4 || stSystemMasterConfig.iAlgoChoice == 5 
        psa_plot_resalloc_sch(stAgent_Solution);
        fsp_plot_berth_agent_alloc(stAgent_Solution);
    else
    end
end

stResAllocSolution.stMachinePriceInfo = stMachinePriceInfo;  % 20070704

if stSystemMasterConfig.iAlgoChoice == 1 || stSystemMasterConfig.iAlgoChoice == 2 || stSystemMasterConfig.iAlgoChoice == 4 || stSystemMasterConfig.iAlgoChoice == 5 
    psa_fsp_plot_berth_agent_alloc(stAgent_Solution);
    psa_mesh_berth_resalloc(stAgent_Solution);
end


% iPlotFlag
if iPlotFlag < 1
    close all;
else
    disp('close all figures and continue');
end