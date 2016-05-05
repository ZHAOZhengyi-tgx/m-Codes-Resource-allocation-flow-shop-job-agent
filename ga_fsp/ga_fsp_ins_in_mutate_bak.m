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