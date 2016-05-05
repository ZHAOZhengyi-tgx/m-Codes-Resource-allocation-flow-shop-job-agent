function [iFlagVectorAlreadySearched] = chk_search_vector(astSearchVectorSpace, aNewSearchVector)

iLen = length(astSearchVectorSpace);

iFlagVectorAlreadySearched = 0;
for ii = 1:1:iLen
    if length(astSearchVectorSpace(ii).aVector) == length(aNewSearchVector)
        if astSearchVectorSpace(ii).aVector == aNewSearchVector
            iFlagVectorAlreadySearched = ii;
            break;
        end
    end
end