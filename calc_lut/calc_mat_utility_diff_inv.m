function [matDiffCol, matDiffRow, matCellRowCol] = calc_mat_utility_diff_inv(matInput)
% calculate matrix utility difference and inverse
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

[mm, nn] = size(matInput);
matFlagDiffRow = zeros(mm, nn);
matFlagDiffCol = zeros(mm, nn);

%% calculate row difference

for ii = 2:1:mm
    for jj = 1:1:nn
        if(matInput(ii-1, jj) ~= 0) && (matInput(ii, jj) ~= 0 )
            matDiffRow(ii, jj) = matInput(ii-1, jj) - matInput(ii, jj);
            matFlagDiffRow(ii, jj) = 1;
            %% add one additional previous row
            if(matFlagDiffRow(ii - 1, jj) == 0)
                matFlagDiffRow(ii - 1, jj) = 1;
                matDiffRow(ii-1, jj) = matDiffRow(ii, jj);
            end
        end
    end
end

%% calculate column difference
for jj = 2:1:nn
    for ii = 1:1:mm
        if (matInput(ii, jj-1) ~= 0) && (matInput(ii, jj) ~= 0 )
            matDiffCol(ii, jj) = matInput(ii, jj-1) - matInput(ii, jj);
            matFlagDiffCol(ii, jj) = 1;
            %% add one additional previous column
            if(matFlagDiffCol(ii, jj - 1) == 0)
                matFlagDiffCol(ii, jj - 1) = 1;
                matDiffCol(ii, jj - 1) = matDiffCol(ii, jj);
            end
        end
    end
end

for ii = 1:1:mm
    for jj = 1:1:nn
        if matFlagDiffRow(ii, jj) == 1 && matFlagDiffCol(ii, jj) == 1
            strCell = sprintf('(%5.1f, %5.1f)', matDiffRow(ii, jj),  matDiffCol(ii, jj));
            matCellRowCol(ii, jj) = {strCell};
        end
    end
end

