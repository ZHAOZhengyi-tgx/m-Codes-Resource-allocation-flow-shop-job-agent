function [stMachinePriceInfo] = price_adj_psa_06(stBerthJobInfo, stMachineUsageInfo, stMachinePriceInfo)
% History
% YYYYMMDD  Notes
% 20070912  Create from template of price_adjustment 01
% 20080228  price smoother, anti-cycle

isCycle2 = stBerthJobInfo.stPriceDetectCycle.isCycle2; %%% 20080228

%alpha = 200;
%fTimeDelta = 0.2;
fNumeratorAlphaByUsage = 0;
fNumeratorAlphaByCapac = 0;
fDenominatorAlphaByUsage = 0;
fDenominatorAlphaByCapac = 0;
nActiveTotalFrame = stMachineUsageInfo.nActiveTotalFrame;
nTotalMachine = stBerthJobInfo.stSystemMasterConfig.iTotalMachType; % 2;  % assume constant
fSumViolationMachFrame = zeros(nTotalMachine, 1);
epsilon_time = 0.1 / 60;

% fPriceMakespanSumAgent = 0;
% for qq = 1:1:stBerthJobInfo.iTotalAgent
%     fPriceMakespanSumAgent = fPriceMakespanSumAgent + stBerthJobInfo.stAgentJobInfo(qq).fPriceQuayCraneDollarPerFrame;
% end
% fPriceFactorAveMakespan = fPriceMakespanSumAgent/stBerthJobInfo.iTotalAgent;

iTotalFrame = ceil(24/stBerthJobInfo.fTimeFrameUnitInHour);
for mm =1:1:nTotalMachine
    if mm ~= stBerthJobInfo.stSystemMasterConfig.iCriticalMachType
    % get the resource usage from clock (tt-1):0:0 to (t + fTimeDelta):0:0
    % fTimeDelta is introduced to avoid numerical trouncation error.
        for tt = 1:1:iTotalFrame
    %        [fValueLookup, iIndex] = ...
    %            calc_table_look_up_max(stMachineUsageInfo.astMachineUsage(mm).aMachineUsageAfterTime, stMachineUsageInfo.astMachineUsage(mm).aSortedTime_inHour, tt-1, fTimeDelta);
    %stMachineUsageInfo.astMachineUsage(mm).aMachineUsageAfterTime
    %stMachineUsageInfo.astMachineUsage(mm).aSortedTime_inHour
    %tt
            [fValueLookup, iIndex] = calc_lut_max_between(stMachineUsageInfo.astMachineUsage(mm).aMachineUsageAfterTime, stMachineUsageInfo.astMachineUsage(mm).aSortedTime_inHour, ...
                tt-1, tt - epsilon_time);
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
                 fSumViolationMachFrame(mm) = fSumViolationMachFrame(mm) + stMachinePriceInfo.astMachineViolation(mm).aViolateAtFrame(tt);
            end
        end
    
        fDenominatorAlphaByCapac = fDenominatorAlphaByCapac + stMachineUsageInfo.astMachineUsage(mm).iMaxCapacity * iTotalFrame;

        fViolationSumsqPerMach(mm) = stMachinePriceInfo.astMachineViolation(mm).aViolateAtFrame * ...
               (stMachinePriceInfo.astMachineViolation(mm).aViolateAtFrame)';
        fViolationSumsq(mm) = sqrt((stMachinePriceInfo.astMachineViolation(mm).aViolateAtFrame * ...
               (stMachinePriceInfo.astMachineViolation(mm).aViolateAtFrame)') ...
               /nActiveTotalFrame);
    end
    
end
alpha = stBerthJobInfo.stPriceAjustment.fAlpha * fNumeratorAlphaByCapac/fDenominatorAlphaByCapac;

% DONOT
% sumVioloation = sum(fViolationSumsq);
% fStepIterStd = alpha /sumVioloation;

% use the denominator in formular by Fisher1985, DONOT use the root mean
% fViolationSumsq = sum(fViolationSumsqPerMach);
% fStepIterStd = alpha /fViolationSumsq;  %sumVioloation;
fViolationRMS = sqrt(sum(fViolationSumsqPerMach)/nActiveTotalFrame/nTotalMachine);
fStepIterStd = alpha /fViolationRMS;  %sumVioloation;

% fSumViolationMachFrame
% for mm = 1:1:nTotalMachine
% %    fStepPriceFactorMach(mm) = exp(abs(fSumViolationMachFrame(mm))/stMachineUsageInfo.astMachineUsage(mm).iMaxCapacity);
%     fStepPriceFactorMach(mm) = abs(fSumViolationMachFrame(mm))/stMachineUsageInfo.astMachineUsage(mm).iMaxCapacity;
% end
% fStepPriceFactorMach
iPlotFlag = stBerthJobInfo.iPlotFlag;
if iPlotFlag >= 2
    for mm =1:1:nTotalMachine
        if mm ~= stBerthJobInfo.stSystemMasterConfig.iCriticalMachType
            strTextPrint = sprintf('Machine No-%d, [Price, Period]: ', mm);
            for tt = 1:1:iTotalFrame
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
            for tt = 1:1:iTotalFrame
                if stMachineUsageInfo.astMachineUsageByPeriod(mm).aiFlagIsActiveFrame(tt) == 1
                    strTextPrint = sprintf('%s [%d, %d, %d],', strTextPrint, stMachinePriceInfo.astMachineUsage(mm).aUsageAtFrame(tt), ...
                        stMachinePriceInfo.astMachineViolation(mm).aViolateAtFrame(tt), tt);
                end
            end
            disp(strTextPrint);
        end
    end
    strTextPrint = sprintf('S_r: %4.2f', fStepIterStd );
    disp(strTextPrint);
end

for mm =1:1:nTotalMachine
    if mm ~= stBerthJobInfo.stSystemMasterConfig.iCriticalMachType
        for tt = 1:1:iTotalFrame
            if stMachineUsageInfo.astMachineUsageByPeriod(mm).aiFlagIsActiveFrame(tt) == 0
                fNewPrice = 0;
            else
                if isCycle2 == 0  %% Cycle Not happens
                    fNewPrice = stMachinePriceInfo.astMachinePrice(mm).fPricePerFrame(tt) ...
                        + fStepIterStd * stMachinePriceInfo.astMachineViolation(mm).aViolateAtFrame(tt);
                else %% when bad cycle happens, only increase the price for a feasible solution 20080228
                    fNewPrice = stMachinePriceInfo.astMachinePrice(mm).fPricePerFrame(tt) ...
                        + abs(fStepIterStd * stMachinePriceInfo.astMachineViolation(mm).aViolateAtFrame(tt));
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
%         for tt = 1:1:iTotalFrame
%             if tt == 2 | tt == iTotalFrame - 1
% %                [tt-1: tt+1]
%                 afSmoothedPrice(tt) = mean(stMachinePriceInfo.astMachinePrice(mm).fPricePerFrame([tt-1: tt+1]));
%             elseif tt >= 3 & tt <= iTotalFrame - 2
%                 afSmoothedPrice(tt) = mean(stMachinePriceInfo.astMachinePrice(mm).fPricePerFrame([tt-2: tt+2]));
%             end
%         end
%         stMachinePriceInfo.astMachinePrice(mm).fPricePerFrame = afSmoothedPrice;
%     end
% end

stMachinePriceInfo.alpha = alpha;
stMachinePriceInfo.s_r = fStepIterStd * ones(1, nTotalMachine);

%% output structure
% stMachinePriceInfo.astMachineUsage: 1..nTotalMachine
% stMachinePriceInfo.astMachineCapacity
% stMachinePriceInfo.astMachineViolation
% stMachinePriceInfo.s_r
% stMachinePriceInfo.alpha 
if iPlotFlag >= 5
    for mm = 1:1:nTotalMachine
        strTextPrint = sprintf('Machine No-%d, [NewPrice, Period]: ', mm);
        for tt = 1:1:iTotalFrame
            if stMachineUsageInfo.astMachineUsageByPeriod(mm).aiFlagIsActiveFrame(tt) == 1
                strTextPrint = sprintf('%s [%f, %d],', strTextPrint, stMachinePriceInfo.astMachinePrice(mm).fPricePerFrame(tt), tt);
            end
        end
        disp(strTextPrint);
    end
    input('Any key');
end