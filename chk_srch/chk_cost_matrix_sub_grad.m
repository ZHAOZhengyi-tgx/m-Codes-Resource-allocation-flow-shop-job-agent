function [bFlagExistLocalMinimum] = chk_cost_matrix_sub_grad(fTotalCostMatrix, idxCostMatrixRow, idxCostMatrixCol)

[mRow, mCol] = size(fTotalCostMatrix);

if idxCostMatrixRow == 1 & idxCostMatrixCol == 1
    nFurtherCheckPoints = 0;
    bFlagExistLocalMinimum = 0;
elseif (idxCostMatrixRow == 1 & idxCostMatrixCol == mCol) 
        nFurtherCheckPoints = 3;
        idxListRow(1) = 1;
        idxListCol(1) = mCol;
        idxListRow(2) = 2;
        idxListCol(2) = mCol;
        idxListRow(3) = 1;
        idxListCol(3) = mCol-1;

elseif (idxCostMatrixRow == mRow & idxCostMatrixCol == 1) 
    nFurtherCheckPoints = 3;
    idxListRow(1) = mRow;
    idxListCol(1) = 1;
    idxListRow(2) = mRow-1;
    idxListCol(2) = 1;
    idxListRow(3) = mRow;
    idxListCol(3) = 2;
    
elseif (idxCostMatrixRow == mRow & idxCostMatrixCol == mCol) 
    nFurtherCheckPoints = 3;
    idxListRow(1) = mRow;
    idxListCol(1) = mCol;
    idxListRow(2) = mRow-1;
    idxListCol(2) = mCol;
    idxListRow(3) = mRow;
    idxListCol(3) = mCol-1;
    
elseif (idxCostMatrixRow == 1 & idxCostMatrixCol >= 2 & idxCostMatrixCol <= mCol-1) 
    nFurtherCheckPoints = 4;
    idxListRow(1) = 1;
    idxListCol(1) = idxCostMatrixCol;
    idxListRow(2) = 1;
    idxListCol(2) = idxCostMatrixCol-1;
    idxListRow(3) = 1;
    idxListCol(3) = idxCostMatrixCol+1;
    idxListRow(4) = 2;
    idxListCol(4) = idxCostMatrixCol;

elseif (idxCostMatrixRow >= 2 & idxCostMatrixRow <= mRow -1 & idxCostMatrixCol == 1)
    nFurtherCheckPoints = 4;
    idxListRow(1) = idxCostMatrixRow;
    idxListCol(1) = 1;
    idxListRow(2) = idxCostMatrixRow+1;
    idxListCol(2) = 1;
    idxListRow(3) = idxCostMatrixRow-1;
    idxListCol(3) = 1;
    idxListRow(4) = idxCostMatrixRow;
    idxListCol(4) = 2;
    
elseif (idxCostMatrixRow == mRow & idxCostMatrixCol >= 2 & idxCostMatrixCol <= mCol-1)
    nFurtherCheckPoints = 4;
    idxListRow(1) = mRow;
    idxListCol(1) = idxCostMatrixCol;
    idxListRow(2) = mRow;
    idxListCol(2) = idxCostMatrixCol-1;
    idxListRow(3) = mRow;
    idxListCol(3) = idxCostMatrixCol+1;
    idxListRow(4) = mRow-1;
    idxListCol(4) = idxCostMatrixCol;
    
elseif (idxCostMatrixRow >= 2 & idxCostMatrixRow <= mRow -1 & idxCostMatrixCol == mCol)
    nFurtherCheckPoints = 4;
    idxListRow(1) = idxCostMatrixRow;
    idxListCol(1) = mCol;
    idxListRow(2) = idxCostMatrixRow+1;
    idxListCol(2) = mCol;
    idxListRow(3) = idxCostMatrixRow-1;
    idxListCol(3) = mCol;
    idxListRow(4) = idxCostMatrixRow;
    idxListCol(4) = mCol-1;
    
elseif idxCostMatrixRow >= 2 & idxCostMatrixRow <= mRow -1 & idxCostMatrixCol >= 2 & idxCostMatrixCol <= mCol-1
    nFurtherCheckPoints = 5;
    idxListRow(1) = idxCostMatrixRow;
    idxListCol(1) = idxCostMatrixCol;
    idxListRow(2) = idxCostMatrixRow+1;
    idxListCol(2) = idxCostMatrixCol;
    idxListRow(3) = idxCostMatrixRow-1;
    idxListCol(3) = idxCostMatrixCol;
    idxListRow(4) = idxCostMatrixRow;
    idxListCol(4) = idxCostMatrixCol+1;
    idxListRow(5) = idxCostMatrixRow;
    idxListCol(5) = idxCostMatrixCol-1;
    
else
    error('Check the index, cannot be zero or negative.');
end

% if nFurtherCheckPoints >= 3
%     idxCostMatrixRow, idxCostMatrixCol, nFurtherCheckPoints
%     idxListRow, idxListCol
% end

for ii = 1:1:nFurtherCheckPoints
    %%% compare each points with the neighbour, 
    %%% if a local minimum detected
    %%%   exit
    %%% 
    bFlagExistLocalMinimum = chk_cost_matrix_neighbour(fTotalCostMatrix, idxListRow(ii), idxListCol(ii));
    if bFlagExistLocalMinimum == 1
        break;
    end
end

