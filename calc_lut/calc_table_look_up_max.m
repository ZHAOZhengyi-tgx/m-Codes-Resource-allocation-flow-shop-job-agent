function  [fValueLookup, iIndex] = calc_table_look_up_max(fValueListLookUp, fInputListLookup, fInput, fDelta)
% Function Input:
% fInput:           a scalar    
% fInputListLookup: must be ascending order
% fValueListLookUp: must have the same length as fInputListLookup
% 
% Function Output:
% iIndex          : ii
% fValueLookup    : fValueListLookUp(ii), 
%                     such that: fInput >= fInputListLookup(ii) & fInput < fInputListLookup(ii+1)

fDelta = abs(fDelta);

iLen = length(fInputListLookup);
if iLen ~= length(fValueListLookUp)
    error('size not match, value and Input');
end

if iLen == 1
    fValueLookup = fValueListLookUp(1);
    iIndex = 1;
else
    if fInput < fInputListLookup(1)
        fValueLookup = 0;
        iIndex = 1;
    elseif fInput >= fInputListLookup(iLen)
        iIndex = iLen;
        fValueLookup = fValueListLookUp(iLen);
    else
        ii = 1;
        iFlagGetIndex = 0;
        while ii <= iLen -1 & iFlagGetIndex ~= -1
            if fInputListLookup(ii) >= (fInput - fDelta)  &  fInputListLookup(ii) <= (fInput + fDelta)
                if iFlagGetIndex == 0
                    iFlagGetIndex = 1;
                    fValueLookup = fValueListLookUp(ii);
                    iIndex = ii;
                else
                    iFlagGetIndex = iFlagGetIndex + 1;
                    if fValueLookup < fValueListLookUp(ii)
                        fValueLookup = fValueListLookUp(ii);
                        iIndex = ii;
                    end
                end
                if fInputListLookup(ii) > (fInput + fDelta)
                    iFlagGetIndex = -1;
                end
            end
            ii = ii+1;
        end
    end
end

