function [aPosnChar, nTotalMatch] = chk_strfind(strForSearch, chSingle)


nTotalLen = length(strForSearch);

nTotalMatch = 0;
% aPosnChar = []

for ii = 1:1:nTotalLen
    if strForSearch(ii) == chSingle
        nTotalMatch = nTotalMatch + 1;
        aPosnChar(nTotalMatch) = ii;
    end
end

