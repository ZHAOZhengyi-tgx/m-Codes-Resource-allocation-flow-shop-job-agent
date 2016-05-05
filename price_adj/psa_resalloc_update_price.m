function [stMachinePriceInfo] = psa_resalloc_update_price(stBerthJobInfo, stMachineUsageInfo, stMachinePriceInfo)
% port of singapore authority, resource allocation update price
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
%% output structure
% stMachinePriceInfo.astMachineUsage: 1..nTotalMachine
% stMachinePriceInfo.astMachineCapacity
% stMachinePriceInfo.astMachineViolation
% stMachinePriceInfo.s_r
% stMachinePriceInfo.alpha 

% History
% YYYYMMDD  Notes
% 20080225  Generalize for multi-machine

%alpha = 200;
%fTimeDelta = 0.2;
fNumeratorAlphaByUsage = 0;
fNumeratorAlphaByCapac = 0;
fDenominatorAlphaByUsage = 0;
fDenominatorAlphaByCapac = 0;
nTotalMachine = stBerthJobInfo.stSystemMasterConfig.iTotalMachType; % 2;  % assume constant % 20080225

iTotalFrame = ceil(24/stBerthJobInfo.fTimeFrameUnitInHour);
for mm =1:1:nTotalMachine  % 20080225
    if mm ~= stBerthJobInfo.stSystemMasterConfig.iCriticalMachType % 20080225
    % get the resource usage from clock (tt-1):0:0 to (t + fTimeDelta):0:0
    % fTimeDelta is introduced to avoid numerical trouncation error.
        for tt = 1:1:iTotalFrame
    %        [fValueLookup, iIndex] = ...
    %            calc_table_look_up_max(stMachineUsageInfo.astMachineUsage(mm).aMachineUsageAfterTime, stMachineUsageInfo.astMachineUsage(mm).aSortedTime_inHour, tt-1, fTimeDelta);
    %stMachineUsageInfo.astMachineUsage(mm).aMachineUsageAfterTime
    %stMachineUsageInfo.astMachineUsage(mm).aSortedTime_inHour
    %tt
            [fValueLookup, iIndex] = calc_lut_max_between(stMachineUsageInfo.astMachineUsage(mm).aMachineUsageAfterTime, stMachineUsageInfo.astMachineUsage(mm).aSortedTime_inHour, ...
                tt-1, tt);
    %  PriceAtHour_i: price at clock (i-1):0:0 to i:0:0
    %  UsageAtHour_i: usage at clock i:0:0 to (i+1):0:0
    %  CapacityAtHour_i: Capacity at clock i:0:0 to (i+1):0:0


            stMachinePriceInfo.astMachineUsage(mm).aUsageAtFrame(tt) = fValueLookup;
            stMachinePriceInfo.astMachineCapacity(mm).aCapacityAtFrame(tt) = stMachineUsageInfo.astMachineUsage(mm).iMaxCapacity;
            stMachinePriceInfo.astMachineViolation(mm).aViolateAtFrame(tt) = stMachinePriceInfo.astMachineUsage(mm).aUsageAtFrame(tt) - stMachineUsageInfo.astMachineUsage(mm).iMaxCapacity;

            fNumeratorAlphaByUsage = fNumeratorAlphaByUsage + stMachinePriceInfo.astMachineUsage(mm).aUsageAtFrame(tt) * stMachinePriceInfo.astMachinePrice(mm).fPricePerFrame(tt);
            fDenominatorAlphaByUsage = fDenominatorAlphaByUsage + stMachinePriceInfo.astMachineUsage(mm).aUsageAtFrame(tt);

            fNumeratorAlphaByCapac = fNumeratorAlphaByCapac + stMachineUsageInfo.astMachineUsage(mm).iMaxCapacity * stMachinePriceInfo.astMachinePrice(mm).fPricePerFrame(tt);
        end

        fDenominatorAlphaByCapac = fDenominatorAlphaByCapac + stMachineUsageInfo.astMachineUsage(mm).iMaxCapacity * iTotalFrame;

        fViolationSumsq(mm) = sqrt((stMachinePriceInfo.astMachineViolation(mm).aViolateAtFrame * ...
               (stMachinePriceInfo.astMachineViolation(mm).aViolateAtFrame)') ...
               /iTotalFrame);
    end    
end
sumVioloation = sum(fViolationSumsq);

%alpha = fNumeratorAlphaByUsage/fDenominatorAlphaByUsage;
alpha = stBerthJobInfo.stPriceAjustment.fAlpha * fNumeratorAlphaByCapac/fDenominatorAlphaByCapac;

stMachinePriceInfo.s_r = alpha /sumVioloation;

for mm =1:1:nTotalMachine  % 20080225
    if mm ~= stBerthJobInfo.stSystemMasterConfig.iCriticalMachType % 20080225
        for tt = 1:1:iTotalFrame
            fNewPrice = stMachinePriceInfo.astMachinePrice(mm).fPricePerFrame(tt) + stMachinePriceInfo.s_r * stMachinePriceInfo.astMachineViolation(mm).aViolateAtFrame(tt);
            if fNewPrice >= 0
                stMachinePriceInfo.astMachinePrice(mm).fPricePerFrame(tt) = fNewPrice;
            else
                stMachinePriceInfo.astMachinePrice(mm).fPricePerFrame(tt) = 0;
            end
        end
    end
end

stMachinePriceInfo.alpha = alpha;
