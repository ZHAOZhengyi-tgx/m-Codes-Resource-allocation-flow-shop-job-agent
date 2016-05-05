function [astNewPopCurrGen] = ga_fsp_cross_over(astSelPopAtCurrGen, jobshop_config)
% genetic algorithm flow-shop-problem cross-over
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

% cross-over
% 
% History
% YYYYMMDD Notes
% 20070907 Created
% 20070910 debugging mod

nInd = length(astSelPopAtCurrGen);

nCouples = ceil(nInd/2);
for ii = 1:1:nCouples
    idxParent1 = (ii - 1) * 2 + 1;
    idxParent2 = ii * 2;
    if idxParent2 > nInd
        idxParent2 = 1;
    end
    
    astNewPopCurrGen(ii).aJobSequence = ga_fsp_mate_gen_new_seq( ...
        astSelPopAtCurrGen(idxParent1).aJobSequence, ...
        astSelPopAtCurrGen(idxParent2).aJobSequence, ...
        jobshop_config);
%     if(astNewPopCurrGen(ii).aJobSequence(10) == astNewPopCurrGen(ii).aJobSequence(9))
%         astSelPopAtCurrGen(idxParent1).aJobSequence
%         astSelPopAtCurrGen(idxParent2).aJobSequence
%         astNewPopCurrGen(ii).aJobSequence
%         error('Not a proper sequence');
%     end
end

%%%% mate function for cross-over
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
    
    if isNextAvailableInParent1 == 1 && isNextAvailableInParent2 == 0
        temp = next_gene1;
        idxParentPreviousGene = 1;
    elseif isNextAvailableInParent1 == 0 && isNextAvailableInParent2 == 1
        temp = next_gene2;
        idxParentPreviousGene = 2;
    elseif isNextAvailableInParent1 == 1 && isNextAvailableInParent2 == 1
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
        while iProtectDeadLoop <= nTotalGene && iFlagFindAvailableGene == 0
            idxNextGeneParent1 = idxNextGeneParent1 + 1;
            idxNextGeneParent1 = mod(idxNextGeneParent1, nTotalGene);
            if idxNextGeneParent1 == 0
                idxNextGeneParent1 = nTotalGene; % range of feasibility, [1, ..., nTotalGene], % 20070910
            end
            next_gene1 = aJobSequence1(idxNextGeneParent1);
            if find(aJobNewSequence == next_gene1)
                idxNextGeneParent2 = idxNextGeneParent2 + 1;
                idxNextGeneParent2 = mod(idxNextGeneParent2, nTotalGene);
                if idxNextGeneParent2 == 0
                    idxNextGeneParent2 = nTotalGene; % 20070910
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
% aJobNewSequence;
% afSumProcessTime