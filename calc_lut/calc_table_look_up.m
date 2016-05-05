function  [fValueLookup, iIndex] = calc_table_look_up(fValueListLookUp, fInputListLookup, fInput)
% Function Input:
% fInput:           a scalar    
% fInputListLookup: must be ascending order
% fValueListLookUp: must have the same length as fInputListLookup
% 
% Function Output:
% iIndex          : ii
% fValueLookup    : fValueListLookUp(ii), 
%                     such that: fInput >= fInputListLookup(ii) & fInput < fInputListLookup(ii+1)


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
        while ii <= iLen -1 & iFlagGetIndex == 0
            if fInput >= fInputListLookup(ii) & fInput < fInputListLookup(ii+1)
                fValueLookup = fValueListLookUp(ii);
                iIndex = ii;
                iFlagGetIndex = 1;
            end
            ii = ii+1;
        end
    end
end

