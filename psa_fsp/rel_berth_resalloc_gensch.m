function [stBerthSolution, stBerthJobInfo, stInputResAlloc] = rel_berth_resalloc_gensch(iFlagUpdatePriceOnly, strFilenameBerthMaster)
% prototype:
% [stBerthSolution, stBerthJobInfo, stInputResAlloc] = rel_berth_resalloc_gensch(iFlagUpdatePriceOnly, strFilenameBerthMaster)
% iFlagUpdatePriceOnly: a flag to speed the process, adjusting price from current solution
%       0: start from empty
%       1, 2: clear memory then load previous solution(makespan matrix ...) 
%       3: Generate Initial Bidding Only
%
% strFilenameBerthMaster: master configuration filename
%
% History
% YYYYMMDD  Notes
% 20070524  Initialization stSolutionInfo by zzy
% 20070602  Release ComplementarySearch zzy
% 20070605  improve stoping criterion zzy

close all;

t0 = cputime;

%%%%%%%%%%% Auction Initialization, including
if nargin == 0
    [stInputResAlloc, iFlagUpdatePriceOnly] = rel_berth_resalloc_init;
elseif nargin == 1
    [stInputResAlloc, iFlagUpdatePriceOnly] = rel_berth_resalloc_init(iFlagUpdatePriceOnly);
elseif nargin == 2
    [stInputResAlloc, iFlagUpdatePriceOnly] = rel_berth_resalloc_init(iFlagUpdatePriceOnly, strFilenameBerthMaster);
else
    disp('berth_resalloc_gensch(iFlagUpdatePriceOnly, strFilenameBerthMaster)');
    error('error input format');
end


stBerthJobInfo = stInputResAlloc.stBerthJobInfo;
iPlotFlag = stBerthJobInfo.iPlotFlag;
% == 0: no stop, plot least figure
% >= 1: stop for prompting
% >= 2: plot all figures
stJobListInfoQC = stBerthJobInfo.stJobListInfoQC;

% Schedule Solution
stQC_Solution = stInputResAlloc.stQC_Solution;
% Machine Usage for the initial price in the master config file
stMachineUsageInfoBerth = stInputResAlloc.stMachineUsageInfoBerth    ;
stMachineUsageInfoByQc = stInputResAlloc.stMachineUsageInfoByQc      ;
stMachinePriceInfo     = stInputResAlloc.stMachinePriceInfo          ;

t1 = cputime;

%%% initialize output structure
stSolutionInfo = [];  % 20070524
stConstraintVialationInfo.nTotalCaseViolation = 0;
stConstraintVialationInfo.astCaseViolation    = [];
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%% Multi-period Auction
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
if iFlagUpdatePriceOnly == 3

else
        %% interative adjust price for single period problem
        if iFlagUpdatePriceOnly == 0
            stInputResAlloc.stMachinePriceInfo = [];
        else
            stInputResAlloc.stMachinePriceInfo = stMachinePriceInfo;
        end
        stInputResAlloc.iFlagUpdatePriceOnly = iFlagUpdatePriceOnly;
        stInputResAlloc.iMaxIter_Auction = 20;
        
    if stBerthJobInfo.iAlgoChoice == 7 | stBerthJobInfo.iAlgoChoice == 18 | stBerthJobInfo.iAlgoChoice == 19 | stBerthJobInfo.iAlgoChoice == 20 | ...
       stBerthJobInfo.iAlgoChoice == 21  % 20070602
        [stOutputResAlloc] = resalloc_fsp_by_auction(stInputResAlloc);
        stMachineUsageInfoBerth = stOutputResAlloc.stMachineUsageInfoBerth ;
        stMachineUsageInfoByQc  = stOutputResAlloc.stMachineUsageInfoByQc  ;
        stQC_Solution           = stOutputResAlloc.stQC_Solution           ;
        stSolutionInfo          = stOutputResAlloc.stSolutionInfo          ;
        stMachinePriceInfo      = stOutputResAlloc.stMachinePriceInfo      ;
        stConstraintVialationInfo = stOutputResAlloc.stConstraintVialationInfo; %20070605

        if iPlotFlag >= 0
            figure(4);
            plot(stSolutionInfo.s_r);
            title('Price adjustment factor');
            xlabel('No. Iteration');
        end
    end

    [stMachineUsageInfoBerth, stMachineUsageInfoByQc] = psa_bidgen_build_bid_by_cfg(stBerthJobInfo, stQC_Solution);
    psa_jsp_plot_ycpm_usage(stMachineUsageInfoBerth, 11);

end

t2 = cputime;
stBerthSolution.tSolutionTime_sec = t2 - t1;
stBerthSolution.stQC_Solution     = stQC_Solution;
stBerthSolution.tSolutionTimeInitialization_sec = t1 - t0;
stBerthSolution.stSolutionInfo  = stSolutionInfo;
stBerthSolution.stConstraintVialationInfo = stConstraintVialationInfo;  %20070605

%%% Output file: Final Report
if iFlagUpdatePriceOnly == 3
else
    if stBerthJobInfo.iAlgoChoice == 7 | stBerthJobInfo.iAlgoChoice == 18 | ...
            stBerthJobInfo.iAlgoChoice == 19 | stBerthJobInfo.iAlgoChoice == 20 | stBerthJobInfo.iAlgoChoice == 21  % 20070602
        strNameSufix = 'Final';
        stBerthJobInfo.fPricePrimeMoverDollarPerFrame = stMachinePriceInfo.astMachinePrice(1).fPricePerFrame;
        stBerthJobInfo.fPriceYardCraneDollarPerFrame = stMachinePriceInfo.astMachinePrice(2).fPricePerFrame;

        psa_fsp_gen_bidding_report(stBerthJobInfo, stJobListInfoQC, stQC_Solution, stMachineUsageInfoByQc, strNameSufix, stBerthSolution);

    end
end


if iFlagUpdatePriceOnly == 3
else
    stBerthSolution.stMachinePriceInfo = stMachinePriceInfo;
end

if stBerthJobInfo.iAlgoChoice == 1
    psa_mesh_berth_resalloc(stQC_Solution)
end
    
