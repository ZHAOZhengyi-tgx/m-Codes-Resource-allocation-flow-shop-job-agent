function [stLookUpTableOutput] = calc_lut_get_value_first(stLookUpTableInput)
%
% calc_lut_get_value_first
% input structure: stLookUpTableInput
%    afLookUpTableValueList:
%    afLookUpTableIndexList: 
%    fValueIndexInput      :
% return the first value with the 
%  fValueIndexInput >=
% stLookUpTableInput.afLookUpTableIndexList(ii)
% lut: look-up-table, a table with ascending order of  stLookUpTableInput.afLookUpTableIndexList
%     stLookUpTableInput.afLookUpTableValueList, stLookUpTableInput.afLookUpTableIndexList
% 


nTableLen = length(stLookUpTableInput.afLookUpTableValueList);
if nTableLen ~= length(stLookUpTableInput.afLookUpTableIndexList)
    error('Error length not match, Table value and Table index');
end

for ii = 1:1:nTableLen - 1
    if stLookUpTableInput.afLookUpTableIndexList(ii) > stLookUpTableInput.afLookUpTableIndexList(ii+1)
        error('Look up table index must be in ascending order');
    end
end

if stLookUpTableInput.fValueIndexInput <= stLookUpTableInput.afLookUpTableIndexList(1)
    fValueOutput = stLookUpTableInput.afLookUpTableValueList(1);
    fValueIndex  = stLookUpTableInput.afLookUpTableIndexList(1);
    iIndex = 0;
elseif stLookUpTableInput.fValueIndexInput >= stLookUpTableInput.afLookUpTableIndexList(nTableLen)
    fValueOutput = stLookUpTableInput.afLookUpTableValueList(nTableLen);
    fValueIndex  = stLookUpTableInput.afLookUpTableIndexList(nTableLen);
    iIndex = nTableLen;
else
    for ii = 1:1: nTableLen - 1
        if stLookUpTableInput.fValueIndexInput >= stLookUpTableInput.afLookUpTableIndexList(ii) & stLookUpTableInput.fValueIndexInput < stLookUpTableInput.afLookUpTableIndexList(ii + 1)
            fValueOutput = stLookUpTableInput.afLookUpTableValueList(ii);
            fValueIndex  = stLookUpTableInput.afLookUpTableIndexList(ii);
            iIndex = ii;
            break;
        end
    end    
end



stLookUpTableOutput.fValueOutput = fValueOutput;
stLookUpTableOutput.fValueIndex  = fValueIndex;
stLookUpTableOutput.iIndex       = iIndex;

