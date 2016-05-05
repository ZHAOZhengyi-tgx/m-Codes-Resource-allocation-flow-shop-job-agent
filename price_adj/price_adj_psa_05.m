function [stMachinePriceInfo] = price_adj_psa_05(stBerthJobInfo, stMachineUsageInfo, stMachinePriceInfo)

% History
% YYYYMMDD  Notes
% 20070912  Create from template of price_adjustment 01
% 20080228  price smoother, anti-cycle

isCycle2 = stBerthJobInfo.stPriceDetectCycle.isCycle2; %%% 20080228

fNumeratorAlphaByUsage = 0;
fNumeratorAlphaByCapac = 0;
fDenominatorAlphaByUsage = 0;
fDenominatorAlphaByCapac = 0;
tPlanningStartTime_datenum = stBerthJobInfo.stPlanningStartTime.tPlanningStartTime_datenum;
tEarlistStartFrame = floor((stMachineUsageInfo.tEarliestStartTime - floor(stMachineUsageInfo.tEarliestStartTime))* 24 /stBerthJobInfo.fTimeFrameUnitInHour);
nActiveTotalFrame = stMachineUsageInfo.nActiveTotalFrame;
nTotalFrame = stMachineUsageInfo.nTotalFrame;
nTotalMachine = stBerthJobInfo.stSystemMasterConfig.iTotalMachType; % 2;  % assume constant
tEpsilon_datenum = 1/24/60; %% one minute

fViolationSumsqMachFrame = 0;

matNetDemandAtMachActiveFrame = zeros(nTotalMachine, nTotalFrame);
matTotalDemandMachineFrame = zeros(nTotalMachine, nTotalFrame);
for mm =1:1:nTotalMachine
    if mm ~= stBerthJobInfo.stSystemMasterConfig.iCriticalMachType
    % get the resource usage from clock (tt-1):0:0 to (t + fTimeDelta):0:0
    % fTimeDelta is introduced to avoid numerical trouncation error.
        for tt = 1:1:nTotalFrame

            tPeriodStartTime_datenum = tPlanningStartTime_datenum + (tt - 1)*stBerthJobInfo.fTimeFrameUnitInHour/24;
            tPeriodEndTime_datenum = tPlanningStartTime_datenum + tt*stBerthJobInfo.fTimeFrameUnitInHour/24 - tEpsilon_datenum;
            [fValueLookup, iIndex] = calc_lut_max_between(stMachineUsageInfo.astMachineUsage(mm).aMachineUsageAfterTime,  ...
                stMachineUsageInfo.astMachineUsage(mm).aSortedTime, ...
                tPeriodStartTime_datenum, tPeriodEndTime_datenum - tEpsilon_datenum);
    %  PriceAtHour_i: price at clock (i-1):0:0 to i:0:0
    %  UsageAtHour_i: usage at clock i:0:0 to (i+1):0:0
    %  CapacityAtHour_i: Capacity at clock i:0:0 to (i+1):0:0

            stMachinePriceInfo.astMachineUsage(mm).aUsageAtFrame(tt) = fValueLookup;
            stMachinePriceInfo.astMachineCapacity(mm).aCapacityAtFrame(tt) = stMachineUsageInfo.astMachineUsage(mm).iMaxCapacity;
            stMachinePriceInfo.astMachineViolation(mm).aViolateAtFrame(tt) = stMachinePriceInfo.astMachineUsage(mm).aUsageAtFrame(tt) - stMachineUsageInfo.astMachineUsage(mm).iMaxCapacity;

            fNumeratorAlphaByUsage = fNumeratorAlphaByUsage ... 
                + stMachinePriceInfo.astMachineUsage(mm).aUsageAtFrame(tt) * stMachineUsageInfo.stUtilityPriceInfo.astMachinePrice(mm).fPricePerFrame(tt);
            fDenominatorAlphaByUsage = fDenominatorAlphaByUsage + stMachinePriceInfo.astMachineUsage(mm).aUsageAtFrame(tt);

            fNumeratorAlphaByCapac = fNumeratorAlphaByCapac ... 
                + stMachineUsageInfo.astMachineUsage(mm).iMaxCapacity * stMachineUsageInfo.stUtilityPriceInfo.astMachinePrice(mm).fPricePerFrame(tt);

            %% only calculate net demand matrix for active frame(period)
            if stMachineUsageInfo.astMachineUsageByPeriod(mm).aiFlagIsActiveFrame(tt) == 1
                 matNetDemandAtMachActiveFrame(mm, tt) = stMachinePriceInfo.astMachineViolation(mm).aViolateAtFrame(tt);

                 fViolationSumsqMachFrame = fViolationSumsqMachFrame + matNetDemandAtMachActiveFrame(mm, tt) ^2;

                 matTotalDemandMachineFrame(mm, tt) = fValueLookup;
            else
                if fValueLookup >= 1
                    mm, tt
                    aMachineUsageAfterTime_mm = stMachineUsageInfo.astMachineUsage(mm).aMachineUsageAfterTime
                    aSortedTime_datestr = datestr(stMachineUsageInfo.astMachineUsage(mm).aSortedTime)
                    aiFlagMachIsActiveFrame = stMachineUsageInfo.astMachineUsageByPeriod(mm).aiFlagIsActiveFrame'
                    tPeriodStartTime_datestr = datestr(tPeriodStartTime_datenum)
                    tPeriodEndTime_datestr = datestr(tPeriodEndTime_datenum)
                    fValueLookup
                    matNetDemandAtMachActiveFrame
                    matTotalDemandMachineFrame
                    error('Check sum error: there is demand in non-active period');
                end
            end
        end
        % assume Capacity is constant
        fDenominatorAlphaByCapac = fDenominatorAlphaByCapac + stMachineUsageInfo.astMachineUsage(mm).iMaxCapacity * nActiveTotalFrame;
        
    end    
end

%alpha_std = stBerthJobInfo.stPriceAjustment.fAlpha * fNumeratorAlphaByCapac/fDenominatorAlphaByCapac /fRootMeanSqareViolation;
%fMeanAbsViolateMachActFrame = sum(sum(matAbsViolAtMachActiveFrame)) / (nTotalMachine * nActiveTotalFrame);  %% 2 dimensional summation
%s_r_std = alpha_std  / fMeanAbsViolateMachActFrame;

% calculate the root mean
fRootMeanSqareViolation = sqrt(fViolationSumsqMachFrame/(nActiveTotalFrame * nTotalMachine));

%% utility price
fAveUtilityPrice = fNumeratorAlphaByUsage/fDenominatorAlphaByUsage;
fAlpha_AveUtilPriceByRMSVio = fAveUtilityPrice/fRootMeanSqareViolation;

% DONOT use the denominator in formular by Fisher1985, DONOT use the root mean
%fAlpha_AveUtilPriceByRMSVio = fAveUtilityPrice/fViolationSumsqMachFrame;
% s_r_std_factor_alpha_PU = fAlpha_AveUtilPriceByRMSVio * stBerthJobInfo.stPriceAjustment.fAlpha;

% a variable step-size scheme, regulating the speed-factor s_r_std
for mm = 1:1:nTotalMachine
    if mm ~= stBerthJobInfo.stSystemMasterConfig.iCriticalMachType
        
        fMaxNetDemand(mm) = max(matNetDemandAtMachActiveFrame(mm, :) );

        % donot consider the last active frame
        aIdxActiveFrameList(:, mm) = find(stMachineUsageInfo.astMachineUsageByPeriod(mm).aiFlagIsActiveFrame == 1);
        fStdDemandActiveFrameNoLast(mm) = std(matTotalDemandMachineFrame(mm, aIdxActiveFrameList(1:end-1, mm)));
        fSpeedFactorStd(mm) = max([1, sign(fMaxNetDemand(mm)) * fStdDemandActiveFrameNoLast(mm)]);
        
        if fMaxNetDemand(mm) < 0
            fSpeedFactorMaxNetDemand(mm) = exp( - fMaxNetDemand(mm) * fMaxNetDemand(mm) );
        else
            fSpeedFactorMaxNetDemand(mm) = 2 - exp( - fMaxNetDemand(mm) * fMaxNetDemand(mm) );
        end
        
        s_r_std(mm) = fSpeedFactorStd(mm) * fSpeedFactorMaxNetDemand(mm);
% DONOT use the denominator in formular by Fisher1985, DONOT use the root mean
%        s_r_std(mm) = fSpeedFactorStd(mm) * fSpeedFactorMaxNetDemand(mm) * s_r_std_factor_alpha_PU;
    
%   protection
%     if s_r_std(mm) > 20
%         s_r_std(mm) = 20;
%     end
    else
        aIdxActiveFrameList(:, mm) = find(stMachineUsageInfo.astMachineUsageByPeriod(mm).aiFlagIsActiveFrame == 1);
    end
end

matPriceStepMachFrame = zeros(nTotalMachine, nTotalFrame);
for mm =1:1:nTotalMachine
    if mm ~= stBerthJobInfo.stSystemMasterConfig.iCriticalMachType
        for tt = 1:1:nTotalFrame
            matPriceStepMachFrame(mm, tt) = fAlpha_AveUtilPriceByRMSVio * s_r_std(mm) * stMachinePriceInfo.astMachineViolation(mm).aViolateAtFrame(tt);
        end
    end
end

iPlotFlag = stBerthJobInfo.iPlotFlag;
if iPlotFlag >= 2
    for mm =1:1:nTotalMachine
        if mm ~= stBerthJobInfo.stSystemMasterConfig.iCriticalMachType
            strTextPrint = sprintf('Machine No-%d, [Price, Period]: ', mm);
            for tt = 1:1:nTotalFrame
                if stMachineUsageInfo.astMachineUsageByPeriod(mm).aiFlagIsActiveFrame(tt) == 1
                    strTextPrint = sprintf('%s [%f, %d],', strTextPrint, stMachinePriceInfo.astMachinePrice(mm).fPricePerFrame(tt), tt);
                end
            end
            disp(strTextPrint);
        end
    end
    for mm = 1:1:nTotalMachine
        if mm ~= stBerthJobInfo.stSystemMasterConfig.iCriticalMachType
            strTextPrint = sprintf('Machine No-%d, [Usage, NetDemand, Period]: ', mm);
            for tt = 1:1:nTotalFrame
                if stMachineUsageInfo.astMachineUsageByPeriod(mm).aiFlagIsActiveFrame(tt) == 1
                    strTextPrint = sprintf('%s [%d, %d, %d],', strTextPrint, stMachinePriceInfo.astMachineUsage(mm).aUsageAtFrame(tt), ...
                        stMachinePriceInfo.astMachineViolation(mm).aViolateAtFrame(tt), tt);
                end
            end
            disp(strTextPrint);
        end
    end
    strTextPrint = sprintf('S_r:');
    for mm = 1:1:nTotalMachine
        strTextPrint = sprintf('%s %4.2f', strTextPrint, s_r_std(mm) );
    end
    disp(strTextPrint);
end

%% machine prices immediately go to zero for those non-active periods
for mm =1:1:nTotalMachine
    if mm ~= stBerthJobInfo.stSystemMasterConfig.iCriticalMachType
        for tt = 1:1:nTotalFrame
            if stMachineUsageInfo.astMachineUsageByPeriod(mm).aiFlagIsActiveFrame(tt) == 0
                fNewPrice = 0;
            else
                if isCycle2 == 0  %% Cycle Not happens
                    fNewPrice = stMachinePriceInfo.astMachinePrice(mm).fPricePerFrame(tt) + ...
                        matPriceStepMachFrame(mm, tt);
                else %% when bad cycle happens, only increase the price for a feasible solution 20080228
                    fNewPrice = stMachinePriceInfo.astMachinePrice(mm).fPricePerFrame(tt) ...
                        + abs(matPriceStepMachFrame(mm, tt));
                end
            end
            
            if fNewPrice >= 0
                stMachinePriceInfo.astMachinePrice(mm).fPricePerFrame(tt) = fNewPrice;
            else
                stMachinePriceInfo.astMachinePrice(mm).fPricePerFrame(tt) = 0;
            end
        end
    end
end

%% price smoother, %20080228
% for mm =1:1:nTotalMachine
%     if mm ~= stBerthJobInfo.stSystemMasterConfig.iCriticalMachType
%         afSmoothedPrice = stMachinePriceInfo.astMachinePrice(mm).fPricePerFrame;
%         for tt = 1:1:nTotalFrame
%             if tt == 2 | tt == nTotalFrame - 1
% %                [tt-1: tt+1]
%                 afSmoothedPrice(tt) = mean(stMachinePriceInfo.astMachinePrice(mm).fPricePerFrame([tt-1: tt+1]));
%             elseif tt >= 3 & tt <= nTotalFrame - 2
%                 afSmoothedPrice(tt) = mean(stMachinePriceInfo.astMachinePrice(mm).fPricePerFrame([tt-2: tt+2]));
%             end
%         end
%         stMachinePriceInfo.astMachinePrice(mm).fPricePerFrame = afSmoothedPrice;
%     end
% end

stMachinePriceInfo.alpha = fAlpha_AveUtilPriceByRMSVio;
stMachinePriceInfo.s_r = s_r_std;
% stMachinePriceInfo.matPriceStepMachFrame = matPriceStepMachFrame;
% stMachinePriceInfo.matTotalDemandMachineFrame = matTotalDemandMachineFrame;

%% output structure
% stMachinePriceInfo.astMachineUsage: 1..nTotalMachine
% stMachinePriceInfo.astMachineCapacity
% stMachinePriceInfo.astMachineViolation
% stMachinePriceInfo.s_r
% stMachinePriceInfo.alpha 

if stBerthJobInfo.iPlotFlag >= 4
%    fRootMeanSqareViolation
    aIdxActiveFrameList
    NetDemandAtMachActiveFrame = matNetDemandAtMachActiveFrame(:, aIdxActiveFrameList) 
    fViolationSumsqMachFrame, 
    TotalDemandMachineActiveFrame = matTotalDemandMachineFrame(:, aIdxActiveFrameList)
    fMaxNetDemand, 
    aIdxActiveFrameList, 
    fStdDemandActiveFrameNoLast, 
    fSpeedFactorStd, 
    fSpeedFactorMaxNetDemand, 
    s_r_std, 
    PriceStepMachActiveFrame = matPriceStepMachFrame(:, aIdxActiveFrameList)
    fAveUtilityPrice, 
    fAlpha_AveUtilPriceByRMSVio

    input('any key');
end
