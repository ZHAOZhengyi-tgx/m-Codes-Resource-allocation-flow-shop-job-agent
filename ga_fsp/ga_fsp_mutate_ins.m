function [astNewPopCurrGen] = ga_fsp_mutate_ins(astNewPopCurrGenByMate, fMutateRate)
% Mutate
%
% History
% YYYYMMDD Notes
% 20070907 Created

nTotalPop = length(astNewPopCurrGenByMate);
aMutatedList = find(rand(size(nTotalPop))<fMutateRate);
nTotalMutate = length(aMutatedList);

astNewPopCurrGen = astNewPopCurrGenByMate;
for ii = 1:1:nTotalMutate
    ind = aMutatedList(ii);
    aJobOldSequence = astNewPopCurrGen(ind).aJobSequence;
    [aJobNewSequence] = ga_fsp_ins_in_mutate(aJobOldSequence);
    astNewPopCurrGen(ind).aJobSequence = aJobNewSequence;
end


%%%% random insertion operation for mutation
function [aJobNewSequence] = ga_fsp_ins_in_mutate(aJobOldSequence)

nTotalJob = length(aJobOldSequence);

iPickJob = round(rand * nTotalJob);
if iPickJob == 0
    iPickJob = 1;
end

iPlaceInsert = round(rand * nTotalJob);
if iPlaceInsert == 0
    iPlaceInsert = 1;
end

aJobNewSequence = aJobOldSequence;
if iPickJob ~= iPlaceInsert
    if iPickJob > iPlaceInsert
        aJobNewSequence(iPlaceInsert) = aJobOldSequence(iPickJob);
        for ii = iPlaceInsert+1:1:iPickJob
            aJobNewSequence(ii) = aJobOldSequence(ii-1);
        end
    else
        aJobNewSequence(iPlaceInsert) = aJobOldSequence(iPickJob);
        for ii = iPlaceInsert-1:-1:iPickJob
            aJobNewSequence(ii) = aJobOldSequence(ii+1);
        end
    end
end
