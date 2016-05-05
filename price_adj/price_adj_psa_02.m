function [stMachinePriceInfo] = price_adj_psa_02(stBerthJobInfo, stMachineUsageInfo, stMachinePriceInfo)
%% output structure
% stMachinePriceInfo.astMachineUsage: 1..nTotalMachine
% stMachinePriceInfo.astMachineCapacity
% stMachinePriceInfo.astMachineViolation
% stMachinePriceInfo.s_r
% stMachinePriceInfo.alpha 

% History
% YYYYMMDD  Notes
% 20080225  Generalize for multi-machine

fTimeDelta = 0.1;
fNumeratorAlphaByUsage = 0;
fNumeratorAlphaByCapac = 0;
fDenominatorAlphaByUsage = 0;
fDenominatorAlphaByCapac = 0;

alpha = stBerthJobInfo.stPriceAjustment.fAlpha;
%% Constaints:  
%%  (1) Daily planning, 
%%  (2) constant number of resources over time frames
iTotalFrame = ceil(24/stBerthJobInfo.fTimeFrameUnitInHour);

nTotalMachine = stBerthJobInfo.stSystemMasterConfig.iTotalMachType; % 2;  % assume constant % 20080225
fViolationSumsq = zeros(nTotalMachine, 1); % 20080225
%%
for mm =1:1:nTotalMachine  % 20080225
    if mm ~= stBerthJobInfo.stSystemMasterConfig.iCriticalMachType % 20080225
        for tt = 1:1:iTotalFrame
    % get the resource usage from clock (tt-1):0:0 to (t + fTimeDelta):0:0
    % fTimeDelta is introduced to avoid numerical trouncation error.
    %        [fValueLookup, iIndex] = ...
    %            calc_table_look_up_max(stMachineUsageInfo.astMachineUsage(mm).aMachineUsageAfterTime, ...
    %            stMachineUsageInfo.astMachineUsage(mm).aSortedTime_inHour,  tt-1,   fTimeDelta);
            [fValueLookup, iIndex] = calc_lut_max_between(stMachineUsageInfo.astMachineUsage(mm).aMachineUsageAfterTime, stMachineUsageInfo.astMachineUsage(mm).aSortedTime_inHour, ...
                tt-1, tt);
    %  PriceAtHour_tt: price at clock (tt-1):0:0 to tt:0:0
    %  UsageAtHour_tt: usage at clock tt:0:0 to (tt+1):0:0
    %  CapacityAtHour_tt: Capacity at clock tt:0:0 to (tt+1):0:0

            stMachinePriceInfo.astMachineUsage(mm).aUsageAtFrame(tt) = fValueLookup;
            stMachinePriceInfo.astMachineCapacity(mm).aCapacityAtFrame(tt) = stMachineUsageInfo.astMachineUsage(mm).iMaxCapacity;
            stMachinePriceInfo.astMachineViolation(mm).aViolateAtFrame(tt) = stMachinePriceInfo.astMachineUsage(mm).aUsageAtFrame(tt) - stMachineUsageInfo.astMachineUsage(mm).iMaxCapacity;

            fNumeratorAlphaByUsage = fNumeratorAlphaByUsage + ...
                stMachinePriceInfo.astMachineUsage(mm).aUsageAtFrame(tt) * stMachinePriceInfo.astMachinePrice(mm).fPricePerFrame(tt);
            fDenominatorAlphaByUsage = fDenominatorAlphaByUsage + stMachinePriceInfo.astMachineUsage(mm).aUsageAtFrame(tt);

    %        fViolationFactor(mm, tt) = stMachinePriceInfo.astMachineViolation(mm).aViolateAtFrame(tt) ...
    %           /stMachinePriceInfo.astMachineCapacity(mm).aCapacityAtFrame(tt);

        end
    end
end

fNormalizeFactor = fNumeratorAlphaByUsage/fDenominatorAlphaByUsage;

stMachinePriceInfo.s_r = alpha * fNormalizeFactor;

for mm =1:1:nTotalMachine  % 20080225
    if mm ~= stBerthJobInfo.stSystemMasterConfig.iCriticalMachType  % 20080225
        for tt = 1:1:iTotalFrame
            fNewPrice = stMachinePriceInfo.astMachinePrice(mm).fPricePerFrame(tt) + ...
                stMachinePriceInfo.s_r *  ...
                (stMachinePriceInfo.astMachineViolation(mm).aViolateAtFrame(tt)/stMachinePriceInfo.astMachineCapacity(mm).aCapacityAtFrame(tt));
            if fNewPrice >= 0
                stMachinePriceInfo.astMachinePrice(mm).fPricePerFrame(tt) = fNewPrice;
            else
                stMachinePriceInfo.astMachinePrice(mm).fPricePerFrame(tt) = 0;
            end
        end
    end
end

stMachinePriceInfo.alpha = alpha;
