function [iJobSeqInJspCfg, stDebugInfo] = ga_fsp_bd_greedy(stJspScheduleTemplate, stJspCfg)
% genetic algorithm, flow-shop-problem build greedy
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

% History
% YYYYMMDD Notes
% 20070907 Created
% 20070910 Add initilization of random generator state
% 20071008 Add initial population, no worse than COS constraint
% 20071019 SemiCOS
% 20071109  ga_init_seed, add stGASetting into stJspCfg

%% 20071109
ga_init_seed(stJspCfg);
stGASetting = stJspCfg.stGASetting;

%% Initial Population
iGen = 1;
for pp = 1:1:stGASetting.iPopSize
    if pp == stGASetting.iPopSize   % 20071008
        astGaPop(pp, iGen).aJobSequence = 1:1:stJspCfg.iTotalJob;
%     elseif pp >= stGASetting.iPopSize/2
%         nFirstHalf = floor(stJspCfg.iTotalJob/2);
%         astGaPop(pp, iGen).aJobSequence = [randperm(nFirstHalf), nFirstHalf + randperm(stJspCfg.iTotalJob - nFirstHalf)];
%     else
%         astGaPop(pp, iGen).aJobSequence = randperm(stJspCfg.iTotalJob);
%    end          % 20071008
    %% use SemiCOS for combination of Forward and Reverse
    else % 20071019
        fStdJobType = std(stJspCfg.iJobType);
        if fStdJobType == 0 %% pure forward or reverse
            astGaPop(pp, iGen).aJobSequence = randperm(stJspCfg.iTotalJob);
        else
            aForwardFlowJobIdList = find(stJspCfg.iJobType == 1);
            nLenForwardFlowJobs = length(aForwardFlowJobIdList);
            aReverselFlowJobIdList = find(stJspCfg.iJobType == 2);
            nLenReverselFlowJobs = length(aReverselFlowJobIdList);
            
            if aForwardFlowJobIdList + nLenReverselFlowJobs ~= stJspCfg.iTotalJob
                %% check sum verify, only 2 types: either forward or reverse
                error('only 2 types: either forward or reverse, check JobType')
            end
            
            %% for such assumption: 1st machine is critical machine, (agent grouping) 
            astGaPop(pp, iGen).aJobSequence(1:nLenForwardFlowJobs) = aForwardFlowJobIdList(randperm(nLenForwardFlowJobs));
%             randperm(nLenReverselFlowJobs)
%             aReverselFlowJobIdList(randperm(nLenReverselFlowJobs))
            astGaPop(pp, iGen).aJobSequence((nLenForwardFlowJobs+1): (nLenForwardFlowJobs + nLenReverselFlowJobs)) = aReverselFlowJobIdList(randperm(nLenReverselFlowJobs));
        end
    end % 20071019
    
    if stJspCfg.iOptRule ==18 || stJspCfg.iOptRule ==28  % multi-period
        [fsp_bidir_sche_temp] = fsp_bd_multi_m_t_greedy_by_seq(stJspScheduleTemplate, stJspCfg, astGaPop(pp, iGen).aJobSequence);
    else
        [fsp_bidir_sche_temp] = fsp_multi_mach_greedy_by_seq(stJspScheduleTemplate, stJspCfg, astGaPop(pp, iGen).aJobSequence);
    end
    %% Calculate a fitness, which is to be maximized by GA
    matFitnessGen(pp, iGen) = 1/fsp_bidir_sche_temp.iMaxEndTime;
    matMakespanGen(pp, iGen) = fsp_bidir_sche_temp.iMaxEndTime;
end
% average and std
aAveFitnessGen(iGen) = mean(matFitnessGen(:, iGen));
aStdFitnessGen(iGen) = std(matFitnessGen(:, iGen));
aAveMakespanGen(iGen) = mean(matMakespanGen(:, iGen));
aStdMakespanGen(iGen) = std(matMakespanGen(:, iGen));


nIndCrossOver = stGASetting.iPopSize * stGASetting.fXoverRate;
while iGen < stGASetting.iTotalGen
    % Prepare for selection
    fMaxFitnessCurrGen= max(matFitnessGen(:, iGen));
    fMinFitnessCurrGen= min(matFitnessGen(:, iGen));
    fRangeFitnessCurrGen= fMaxFitnessCurrGen - fMinFitnessCurrGen;
        
    for iIndividual = 1:1:stGASetting.iPopSize
        if fRangeFitnessCurrGen >=0.000001
            fFitnessSelection(iIndividual) = (matFitnessGen(iIndividual,iGen)-fMinFitnessCurrGen)/fRangeFitnessCurrGen;
        else % range is 0
            fFitnessSelection(iIndividual) = 1;
        end
        
        fFitnessSelection(iIndividual) = fFitnessSelection(iIndividual).^2;
    end

%    fFitnessSelection
    %Selection -- use Roulette Wheel Selection scheme
    astSelPopAtCurrGen = [];
    nSelPopAtCurrGen=0;
    ind = 1;
    while nSelPopAtCurrGen < nIndCrossOver
        if nSelPopAtCurrGen == nIndCrossOver - 1      % 20071008
            [fBestFitness, idxIndBestFitness] = max(matFitnessGen(:, iGen));
            nSelPopAtCurrGen = nSelPopAtCurrGen + 1;
            astSelPopAtCurrGen(nSelPopAtCurrGen).aJobSequence = astGaPop(idxIndBestFitness, iGen).aJobSequence;
           
        else                          % 20071008
            trial=rand;
            if fFitnessSelection(ind)>trial
                nSelPopAtCurrGen = nSelPopAtCurrGen + 1;
                astSelPopAtCurrGen(nSelPopAtCurrGen).aJobSequence = astGaPop(ind, iGen).aJobSequence;
            else
                sel=0;
            end
        end

        ind=ind+1;
        ind=mod(ind, stGASetting.iPopSize);
        if ind==0
           ind=1;
        end
    end
    
    % crossover - use provided crossover operator
    [astNewPopCurrGenByMate]=ga_fsp_cross_over(astSelPopAtCurrGen, stJspCfg);
%     disp('after x-over')
%     astNewPopCurrGenByMate.aJobSequence
    
    % mutate
    [astNewPopCurrGen]=ga_fsp_mutate_ins(astNewPopCurrGenByMate,stGASetting.fMutateRate);
%     disp('after mutate')
%     astNewPopCurrGen.aJobSequence
    
    % Form the new generation
    nPopNewGen = length(astNewPopCurrGen);
    for pp = 1:1:nPopNewGen
        
        if stJspCfg.iOptRule ==18 || stJspCfg.iOptRule ==28  % multi-period % fsp_bd_multi_m_t_greedy_by_seq
            [fsp_bidir_sche_temp] = fsp_bd_multi_m_t_greedy_by_seq(stJspScheduleTemplate, stJspCfg, astNewPopCurrGen(pp).aJobSequence);
        else
            [fsp_bidir_sche_temp] = fsp_multi_mach_greedy_by_seq(stJspScheduleTemplate, stJspCfg, astNewPopCurrGen(pp).aJobSequence);
        end

        %% Calculate a fitness, which is to be maximized by GA
        aFitnessNewGen(pp) = 1/fsp_bidir_sche_temp.iMaxEndTime;
        aMakespanNewGen(pp) = fsp_bidir_sche_temp.iMaxEndTime;
    end
    aFitnessTotalGen = [matFitnessGen(:, iGen); aFitnessNewGen'];
    [aSortedFitness, aSortedIndex] = sort(-aFitnessTotalGen); % 20071008
    iGen = iGen + 1;
    for pp = 1:1:stGASetting.iPopSize
        %% select the best top fitness, sort is for ascending order by
        %% default
        %ind = nPopNewGen + pp;
        ind = aSortedIndex(pp);  % 20071008
        if ind <= stGASetting.iPopSize
            % it belongs to previous gen
            astGaPop(pp, iGen).aJobSequence = astGaPop(ind, iGen-1).aJobSequence;
            matFitnessGen(pp, iGen) = matFitnessGen(ind, iGen-1);
            matMakespanGen(pp, iGen) = matMakespanGen(ind, iGen-1);
        else
            % it is from new gen
            astGaPop(pp, iGen).aJobSequence = astNewPopCurrGen(ind - stGASetting.iPopSize).aJobSequence;
            matFitnessGen(pp, iGen) = aFitnessNewGen(ind - stGASetting.iPopSize);
            matMakespanGen(pp, iGen) = aMakespanNewGen(ind - stGASetting.iPopSize);
        end
    end
    % average and std
    aAveFitnessGen(iGen) = mean(matFitnessGen(:, iGen));
    aStdFitnessGen(iGen) = std(matFitnessGen(:, iGen));
    aAveMakespanGen(iGen) = mean(matMakespanGen(:, iGen));
    aStdMakespanGen(iGen) = std(matMakespanGen(:, iGen));
    
    if aStdMakespanGen(iGen)/aAveMakespanGen(iGen) < stGASetting.fEpsStdByAveMakespan
        break;
    end

end

% output the best solution in the last generation
iJobSeqInJspCfg = astGaPop(stGASetting.iPopSize, iGen).aJobSequence;
stDebugInfo.astGaPop = astGaPop;
stDebugInfo.aAveFitnessGen = aAveFitnessGen;
stDebugInfo.aStdFitnessGen = aStdFitnessGen;
stDebugInfo.matFitnessGen = matFitnessGen;
stDebugInfo.aAveMakespanGen = aAveMakespanGen;
stDebugInfo.aStdMakespanGen = aStdMakespanGen;
stDebugInfo.matMakespanGen = matMakespanGen;
stDebugInfo.iActualTotalIter = iGen;
