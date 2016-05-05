function aJobNewSequence = ga_fsp_mate_gen_new_seq(aJobSequence1, aJobSequence2, jobshop_config)
% mate for cross-over
% use NXO in paper by CEYDA OGUZ and M.FIKRET ERCAN, JS2005
%

nTotalGene = length(aJobSequence1);
if nTotalGene ~= length(aJobSequence2)
    error('Error, total number of genes not match');
end

for ii = 1:1:jobshop_config.iTotalJob
    afSumProcessTime(ii) = sum(jobshop_config.jsp_process_time(ii).iProcessTime);
end

idxCurrGeneParent1 = 1;
selected_gene = aJobSequence1(1);
idxGene = 1;
aJobNewSequence(idxGene) = selected_gene;

while idxGene < nTotalGene
    idxCurrGeneParent1 = find(aJobSequence1 == selected_gene);
    if idxCurrGeneParent1 == nTotalGene
        isNextAvailableInParent1 = 0;
    else
        idxNextGeneParent1 = idxCurrGeneParent1 + 1;
        next_gene1 = aJobSequence1(idxNextGeneParent1);
        if find(aJobNewSequence == next_gene1)
            isNextAvailableInParent1 = 0;
        else
            isNextAvailableInParent1 = 1;
        end
    end
    
    idxCurrGeneParent2 = find(aJobSequence2 == selected_gene);
    if idxCurrGeneParent2 == nTotalGene
        isNextAvailableInParent2 = 0;
    else
        idxNextGeneParent2 = idxCurrGeneParent2 + 1;
        next_gene2 = aJobSequence2(idxNextGeneParent2);
        if find(aJobNewSequence == next_gene2)
            isNextAvailableInParent2 = 0;
        else
            isNextAvailableInParent2 = 1;
        end
    end
    
    if isNextAvailableInParent1 == 1 & isNextAvailableInParent2 == 0
        temp = next_gene1;
        idxParentPreviousGene = 1;
    elseif isNextAvailableInParent1 == 0 & isNextAvailableInParent2 == 1
        temp = next_gene2;
        idxParentPreviousGene = 2;
    elseif isNextAvailableInParent1 == 1 & isNextAvailableInParent2 == 1
        if afSumProcessTime(next_gene1) >= afSumProcessTime(next_gene2)
            temp = next_gene1;
            idxParentPreviousGene = 1;
        else
            temp = next_gene2;
            idxParentPreviousGene = 2;
        end
    else
        iFlagFindAvailableGene = 0;
        iProtectDeadLoop = 1;
        while iProtectDeadLoop <= nTotalGene & iFlagFindAvailableGene == 0
            idxNextGeneParent1 = idxNextGeneParent1 + 1;
            idxNextGeneParent1 = mod(idxNextGeneParent1, nTotalGene);
            if idxNextGeneParent1 == 0
                idxNextGeneParent1 = 1;
            end
            next_gene1 = aJobSequence1(idxNextGeneParent1);
            if find(aJobNewSequence == next_gene1)
                idxNextGeneParent2 = idxNextGeneParent2 + 1;
                idxNextGeneParent2 = mod(idxNextGeneParent2, nTotalGene);
                if idxNextGeneParent2 == 0
                    idxNextGeneParent2 = 1;
                end
                next_gene2 = aJobSequence2(idxNextGeneParent2);
                if find(aJobNewSequence == next_gene2)
                    iProtectDeadLoop = iProtectDeadLoop + 1;
                else
                    temp = next_gene2;
                    idxParentPreviousGene = 2;
                    iFlagFindAvailableGene = 1;
                end
            else
                temp = next_gene1;
                idxParentPreviousGene = 1;
                iFlagFindAvailableGene = 1;
            end

        end
    end

    selected_gene = temp;
    idxGene = idxGene + 1;
    aJobNewSequence(idxGene) = selected_gene;
end
