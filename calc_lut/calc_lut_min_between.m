function  [fValueLookup, iIndex] = calc_lut_min_between(fValueListLookUp, fInputListLookup, fInputLower, fInputUpper)
% Function Input:
% fValueListLookUp: must have the same length as fInputListLookup
% fInputListLookup: must be ascending order
% fInputLower     : Input Lower Bound 
% fInputUpper     : Input Upper Bound
%
% Function Output:
% iIndex          : ii
% fValueLookup    : fValueListLookUp(ii), 
%                     such that: fInput >= fInputListLookup(ii) & fInput < fInputListLookup(ii+1)

if fInputLower > fInputUpper
    temp = fInputLower;
    fInputLower = fInputUpper;
    fInputUpper = temp;
end

iLen = length(fInputListLookup);
if iLen ~= length(fValueListLookUp)
    error('size not match, value and Input');
end

if iLen == 1
    fValueLookup = fValueListLookUp(1);
    iIndex = 1;
else
    if fInputUpper < fInputListLookup(1)
        fValueLookup = 0;
        iIndex = 1;
    elseif fInputLower >= fInputListLookup(iLen)
        iIndex = iLen;
        fValueLookup = fValueListLookUp(iLen);
    else
        ii = 1;
        iFlagGetIndex = 0;
        while ii <= iLen - 1 & iFlagGetIndex ~= -1
            if fInputListLookup(ii) >= fInputLower  &  fInputListLookup(ii) <= fInputUpper
                if iFlagGetIndex == 0
                    iFlagGetIndex = 1;
                    fValueLookup = fValueListLookUp(ii);
                    iIndex = ii;
                else
%                    iFlagGetIndex = iFlagGetIndex + 1;
                    if fValueLookup > fValueListLookUp(ii)   % find the minimum value between a range
                        fValueLookup = fValueListLookUp(ii);
                        iIndex = ii;
                    end
                end
                if fInputListLookup(ii) > fInputUpper
                    iFlagGetIndex = -1;
%                    disp('Exit before end');
                end
            elseif fInputListLookup(ii) <= fInputLower & fInputListLookup(ii+1) >= fInputUpper
                    iFlagGetIndex = 1;
                    fValueLookup = fValueListLookUp(ii);
                    iIndex = ii;
            end
            ii = ii+1;
        end
        if fInputListLookup(iLen) >= fInputLower  &  fInputListLookup(iLen) <= fInputUpper
            iFlagGetIndex = 1;
            fValueLookup = fValueListLookUp(iLen);
            iIndex = iLen;
        end
    end
end


%fValueLookup, iIndex
