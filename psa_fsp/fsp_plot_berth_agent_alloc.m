function fsp_plot_berth_agent_alloc(stAgent_Solution, iPlotOption)
% flow-shop-problem plot berth agent allocation
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
% YYYYMMDD  Notes
% 20071022  rename from psa_fsp_plot_berth_qc_alloc

if nargin < 2
    iPlotOption = 15;
end

strFilenameXls = 'D:\Zhengyi\MyWork\Doc_MS_Tex\ResAlloc\IEEE_TASE_ResAlloc_Auction\TableFig_src\UtiltyPrice2.xls';
strSheetnameXls = 'UtilityPriceByMatlab_Ag3';
strFilenameBidGenSearchDetailsXls = 'D:\Zhengyi\MyWork\Doc_MS_Tex\ResAlloc\IEEE_TASE_ResAlloc_Auction\TableFig_src\BidGen_LocalSearch_SampleProb.xls';
strSheetnameBidGenSearchDetailsXls = 'BidGen_SingPer_Ag3';

iTotalAgent = length(stAgent_Solution);
for ii = 1:1:iTotalAgent
    matMakespan = [];
    matResouceCost = [];
    matMakespanTardCost = [];
    matBidGenSrchDetail = [];
    
    iCasePMYC = length(stAgent_Solution(ii).stCostAtAgent.stCostList);
    mNumPM = stAgent_Solution(ii).stResourceUsageGenSch0.iMaxPM;
    mNumYC = stAgent_Solution(ii).stResourceUsageGenSch0.iMaxYC;
%    NumPM_NumYC = [mNumPM, mNumYC]
    stCostAtAgent = stAgent_Solution(ii).stCostAtAgent;
    [fMinTotalCost,idxMinCost] = min(stCostAtAgent.afTotalCost);

    matBidGenSrchDetail = (1:iCasePMYC)'; %% for saving to xls
    if bitand(iPlotOption, 1) ~= 0
        figure (ii*10);
        hold off;
        axis([0, mNumPM+1, 0, mNumYC+1]);
        hold on;
        for iCase = 1:1:iCasePMYC
            if iCase >=2
                plot([stCostAtAgent.aiNumPM(iCase-1), stCostAtAgent.aiNumPM(iCase)], [stCostAtAgent.aiNumYC(iCase-1), stCostAtAgent.aiNumYC(iCase)]);
            end
            strCost = sprintf('%4.0f', stCostAtAgent.afTotalCost(iCase));
            h = text(stCostAtAgent.aiNumPM(iCase), stCostAtAgent.aiNumYC(iCase), strCost, 'FontSize', 14);
            v = get(h);
            if iCase == idxMinCost
                aColor = [1 0 0];
            else
                aColor = [0 0 0];
            end
            set(h, 'Color', aColor);
            
            matBidGenSrchDetail(iCase, 2) = stCostAtAgent.aiNumPM(iCase); %% for saving to xls
            matBidGenSrchDetail(iCase, 3) = stCostAtAgent.aiNumYC(iCase); %% for saving to xls
            matBidGenSrchDetail(iCase, 6) = stCostAtAgent.afTotalCost(iCase); %% for saving to xls

        end
        xlabel('Num. of Res-1', 'FontSize', 16);
        ylabel('Num. of Res-2', 'FontSize', 16);
        title(strcat('Total Cost Matrix, Agent #',num2str(ii)), 'FontSize', 19);
    end
    
    if bitand(iPlotOption, 2) ~= 0
        figure (ii*10+1);
        axis([0, mNumPM+1, 0, mNumYC+1]);
        hold on;
        for iCase = 1:1:iCasePMYC
            strPenalty = sprintf('%4.1f', stCostAtAgent.stCostList(iCase).fDelayPanelty + stCostAtAgent.stCostList(iCase).fCostMakespan);
            h = text(stCostAtAgent.aiNumPM(iCase), stCostAtAgent.aiNumYC(iCase), strPenalty);
            v = get(h);
            if iCase == idxMinCost
                aColor = [1 0 0];
            else
                aColor = [0 0 0];
            end
            set(h, 'Color', aColor);
            
            matMakespanTardCost(stCostAtAgent.aiNumPM(iCase), stCostAtAgent.aiNumYC(iCase)) = ...
                stCostAtAgent.stCostList(iCase).fDelayPanelty + stCostAtAgent.stCostList(iCase).fCostMakespan;
        end
        xlabel('Num. of Res-1');
        ylabel('Num. of Res-2');
        title(strcat('Makespan Tardiness Cost Matrix, Agent #',num2str(ii)));
    end

    if bitand(iPlotOption, 4) ~= 0
        figure (ii*10+2);
        hold off;
        axis([0, mNumPM+1, 0, mNumYC+1]);
        hold on;
        for iCase = 1:1:iCasePMYC
            if iCase >=2
                plot([stCostAtAgent.aiNumPM(iCase-1), stCostAtAgent.aiNumPM(iCase)], [stCostAtAgent.aiNumYC(iCase-1), stCostAtAgent.aiNumYC(iCase)]);
            end
            if iCase == idxMinCost
                strMakeSpan = sprintf('* %4.1f', stCostAtAgent.stCostList(iCase).tMakeSpan_hour);
            else
                strMakeSpan = sprintf('%4.1f', stCostAtAgent.stCostList(iCase).tMakeSpan_hour);
            end
            h = text(stCostAtAgent.aiNumPM(iCase), stCostAtAgent.aiNumYC(iCase), strMakeSpan, 'FontSize', 15);
            v = get(h);
            if iCase == idxMinCost
                aColor = [1 0 0];
            else
                aColor = [0 0 0];
            end
            set(h, 'Color', aColor);
            matBidGenSrchDetail(iCase, 5) = stCostAtAgent.stCostList(iCase).tMakeSpan_hour; %% for saving to xls

            matMakespan(stCostAtAgent.aiNumPM(iCase), stCostAtAgent.aiNumYC(iCase)) = ...
                stCostAtAgent.stCostList(iCase).tMakeSpan_hour;
            
        end
        xlabel('Num. of Res-1', 'FontSize', 16);
        ylabel('Num. of Res-2', 'FontSize', 16);
        title(strcat('MakeSpan (Hour) Matrix, Agent #',num2str(ii)), 'FontSize', 19);
    end

    if bitand(iPlotOption, 8) ~= 0
        figure (ii*10+3);
        hold off;
        axis([0, mNumPM+1, 0, mNumYC+1]);
        hold on;
        for iCase = 1:1:iCasePMYC
            strCostResource = sprintf('%4.1f', stCostAtAgent.stCostList(iCase).fCostPM + stCostAtAgent.stCostList(iCase).fCostYC);
            h = text(stCostAtAgent.aiNumPM(iCase), stCostAtAgent.aiNumYC(iCase), strCostResource);
            v = get(h);
            if iCase == idxMinCost
                aColor = [1 0 0];
            else
                aColor = [0 0 0];
            end
            set(h, 'Color', aColor);
            matResouceCost(stCostAtAgent.aiNumPM(iCase), stCostAtAgent.aiNumYC(iCase)) = ...
                stCostAtAgent.stCostList(iCase).fCostPM + stCostAtAgent.stCostList(iCase).fCostYC;
        end
        xlabel('Num. of Res-1');
        ylabel('Num. of Res-2');
        title(strcat('Resource (Res-1, Res-2)Cost Matrix, Agent #',num2str(ii)));
    end
    
    %% only output agent -3

   if ii == 3
       xlswrite(strFilenameXls,  matResouceCost, strSheetnameXls, 'D5');
       [matDiffCol, matDiffRow, matResouceCostCellRowCol] = calc_mat_utility_diff_inv(matResouceCost);
       xlswrite(strFilenameXls,  matResouceCostCellRowCol, strSheetnameXls, 'K5');
       
       
       xlswrite(strFilenameXls,  matMakespanTardCost, strSheetnameXls, 'D15');
       [matDiffCol, matDiffRow, matMakespanTardCostCellRowCol] = calc_mat_utility_diff_inv(matMakespanTardCost);
       xlswrite(strFilenameXls,  matMakespanTardCostCellRowCol, strSheetnameXls, 'K15');
       
       xlswrite(strFilenameXls,  matMakespan, strSheetnameXls, 'D26');
       
       xlswrite(strFilenameBidGenSearchDetailsXls,  matBidGenSrchDetail, strSheetnameBidGenSearchDetailsXls, 'C6');
    
   end
end
