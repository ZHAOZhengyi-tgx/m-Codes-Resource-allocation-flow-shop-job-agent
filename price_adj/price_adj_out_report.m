function price_adj_out_report(stInputReportPrice)
%
%
%
% History
% YYYYMMDD  Notes
% 20070704  Add feasible solution information

stSolutionInfo = stInputReportPrice.stSolutionInfo;
iPlotFlag = stInputReportPrice.iPlotFlag;
astMachinePriceInfo = stSolutionInfo.astMachinePriceInfo;
astMachineUsageInfoGlobal = stSolutionInfo.astMachineUsageInfoGlobal;    
astFeasibleSolutionSet = stSolutionInfo.astFeasibleSolutionSet;    %(n_feas).iIterationInAuction

if iPlotFlag >= 0
    figure(stInputReportPrice.iFigureIdPriceAdjustFactor);
    plot(stSolutionInfo.s_r);
    title('Price adjustment factor');
    xlabel('No. Iteration');
    
    figure(stInputReportPrice.iFigureIdNetDemandAndPriceByMachine(1))
    subplot(2,1,1);
    plot(stSolutionInfo.aMaxNetDemandPrimeMover);
    title('Maximum Net Demand Resource 1');
    subplot(2,1,2);
    plot(stSolutionInfo.aMaxPricePrimeMover);
    title('Maximum Price Resource 1');
    
    figure(stInputReportPrice.iFigureIdNetDemandAndPriceByMachine(2))
    subplot(2,1,1);
    plot(stSolutionInfo.aMaxNetDemandYardCrane);
    title('Maximum Net Demand Resource 2');
    subplot(2,1,2);
    plot(stSolutionInfo.aMaxPriceYardCrane);
    title('Maximum Price Resource 2');
end

nTotalIter = length(stSolutionInfo.aMaxNetDemandPrimeMover); % 20080420

fptr = fopen(stInputReportPrice.strReportFilename, 'w');
iMaxFramesForPlanning = stSolutionInfo.iMaxFramesForPlanning; % 20080420

try
    fprintf(fptr, '%% Iter PriceAdjustFactor, [PeriodStartTime, PeriodEndTime, {MachineName, TotalUsag, NetDemand, Price}, {MachineName, TotalUsag, NetDemand, Price}, ...], ...\n');
    for ii = 1:1:nTotalIter
         tEarliestStartTime_datenum = astMachineUsageInfoGlobal(ii).tEarliestStartTime;
         pEarliestStartPeriodBase0 = floor((tEarliestStartTime_datenum - floor(tEarliestStartTime_datenum)) * 24);
         fprintf(fptr, '%d, %8.3f, ', ii, stSolutionInfo.s_r(ii));
         nTotalPeriod = astMachineUsageInfoGlobal(ii).astMachineUsageByPeriod(1).nActiveTotalFrame;
         for pp = 1:1:nTotalPeriod
             fprintf(fptr, '[%s, %s, ', ...
                           char(astMachineUsageInfoGlobal(ii).astMachineUsageByPeriod(1).cellStartTime(pp)), ...
                                char(astMachineUsageInfoGlobal(ii).astMachineUsageByPeriod(1).cellEndTime(pp)));
             nTotalMachine = length(astMachineUsageInfoGlobal(ii).astMachineUsageByPeriod);
             for mm = 1:1:nTotalMachine
                 if mm ~= stInputReportPrice.iCriticalMachType
                     if iMaxFramesForPlanning >= pEarliestStartPeriodBase0 + pp % 20080420
                         fprintf(fptr, '{%s, %8.1f, %8.1f, %8.3f}', ...
                                          astMachineUsageInfoGlobal(ii).astMachineUsageByPeriod(mm).strName, ...
                                              astMachineUsageInfoGlobal(ii).astMachineUsageByPeriod(mm).aMachineMaxUsage(pp), ...
                                                     astMachineUsageInfoGlobal(ii).astMachineUsageByPeriod(mm).aMachineNetDemand(pp), ...
                                                            astMachinePriceInfo(ii).astMachinePrice(mm).fPricePerFrame(pEarliestStartPeriodBase0 + pp));
                     else
                         fprintf(fptr, '{%s, %8.1f, %8.1f, %8.3f}', ...
                                          astMachineUsageInfoGlobal(ii).astMachineUsageByPeriod(mm).strName, ...
                                              astMachineUsageInfoGlobal(ii).astMachineUsageByPeriod(mm).aMachineMaxUsage(pp), ...
                                                     astMachineUsageInfoGlobal(ii).astMachineUsageByPeriod(mm).aMachineNetDemand(pp), ...
                                                            astMachinePriceInfo(ii).astMachinePrice(mm).fPricePerFrame(iMaxFramesForPlanning)); % 20080420
                     end
                     
                     if mm ~= nTotalMachine
                         fprintf(fptr, ',');
                     else
                         fprintf(fptr, ']');
                     end
                 end
             end
             if pp ~= nTotalPeriod
                 fprintf(fptr, ',');
             else
                 fprintf(fptr, '\n');
             end
         end
    end
catch
    len_MachMaxU_MachNetDem_Price = ...
                         [length(astMachineUsageInfoGlobal(ii).astMachineUsageByPeriod(mm).aMachineMaxUsage), ...
                          length(astMachineUsageInfoGlobal(ii).astMachineUsageByPeriod(mm).aMachineNetDemand), ...
                          length(astMachinePriceInfo(ii).astMachinePrice(mm).fPricePerFrame)];
    pEarliestStartPeriodBase0
    pp
    lasterr
end

%%%% Next output the feasible solution record in the searching history % 20070704
fprintf(fptr, '\n\n%%%%%%%% Next output the feasible solution record in the searching history \n');
fprintf(fptr, '%% Iter,  TotalCost(The Smaller the better performance)\n');
nTotalFeasibleSolution = length(astFeasibleSolutionSet);
for ii = 1:1: nTotalFeasibleSolution
    fprintf(fptr, '%d, %8.3f\n', ...
                    astFeasibleSolutionSet(ii).iIterationInAuction,  ...
                         astFeasibleSolutionSet(ii).fFeasibleObjValue);
end

%%%% next print maximum price information
fprintf(fptr, '\n\n%%%%%%%% Max Price Infomation \n');
fprintf(fptr, '%% Iter PriceAdjustFactor,  MaxNetDemandPrimeMover(PM),  MaxPricePM, IdxHourMaxPricePM, MaxNetDemandYardCrane(YC),  MaxPriceYC, IdxHourMaxPriceYC\n');
for ii = 1:1:nTotalIter
    fprintf(fptr, '%d, %8.3f, %8.3f, %8.3f, %8.3f, %8.3f, %8.3f, %8.3f\n', ...
        ii, stSolutionInfo.s_r(ii), ...
        stSolutionInfo.aMaxNetDemandPrimeMover(ii), stSolutionInfo.aMaxPricePrimeMover(ii), stSolutionInfo.aidxMaxPricePrimeMover(ii), ...
        stSolutionInfo.aMaxNetDemandYardCrane(ii), stSolutionInfo.aMaxPriceYardCrane(ii), stSolutionInfo.aidxMaxPriceYardCrane(ii));
end


fclose(fptr);
