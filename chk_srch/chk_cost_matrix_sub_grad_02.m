function [bFlagExistLocalMinimum] = chk_cost_matrix_sub_grad_02(fTotalCostMatrix, idxCostMatrixRow, idxCostMatrixCol)

%%% Do not include the boundary point as a candiate
[mRow, mCol] = size(fTotalCostMatrix);

if idxCostMatrixRow == 1 & idxCostMatrixCol == 1
    nFurtherCheckPoints = 0;
    bFlagExistLocalMinimum = 0;
elseif (idxCostMatrixRow == 1 & idxCostMatrixCol == mCol) 
    nFurtherCheckPoints = 0;
    bFlagExistLocalMinimum = 0;
    
elseif (idxCostMatrixRow == mRow & idxCostMatrixCol == 1) 
    nFurtherCheckPoints = 0;
    bFlagExistLocalMinimum = 0;
    
elseif (idxCostMatrixRow == mRow & idxCostMatrixCol == mCol) 
    nFurtherCheckPoints = 0;
    bFlagExistLocalMinimum = 0;
    
elseif (idxCostMatrixRow == 1 & idxCostMatrixCol >= 2 & idxCostMatrixCol <= mCol-1) 
    nFurtherCheckPoints = 0;
    bFlagExistLocalMinimum = 0;

elseif (idxCostMatrixRow >= 2 & idxCostMatrixRow <= mRow -1 & idxCostMatrixCol == 1)
    nFurtherCheckPoints = 0;
    bFlagExistLocalMinimum = 0;
    
elseif (idxCostMatrixRow == mRow & idxCostMatrixCol >= 2 & idxCostMatrixCol <= mCol-1)
    nFurtherCheckPoints = 1;
    idxListRow(1) = mRow-1;
    idxListCol(1) = idxCostMatrixCol;
    
elseif (idxCostMatrixRow >= 2 & idxCostMatrixRow <= mRow -1 & idxCostMatrixCol == mCol)
    nFurtherCheckPoints = 1;
    idxListRow(1) = idxCostMatrixRow;
    idxListCol(1) = mCol-1;
    
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

nFurtherCheckPoints
for ii = 1:1:nFurtherCheckPoints
    %%% compare each points with the neighbour, 
    %%% if a local minimum detected
    %%%   exit
    %%% 
    bFlagExistLocalMinimum = comp_cost_matrix_neighbour(fTotalCostMatrix, idxListRow(ii), idxListCol(ii));
    if bFlagExistLocalMinimum == 1
        break;
    end
end

