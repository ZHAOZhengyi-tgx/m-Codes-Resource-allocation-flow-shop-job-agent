function bIsLocalMinimum = chk_cost_matrix_neighbour(fTotalCostMatrix, idxCostMatrixRow, idxCostMatrixCol)

%% 

[mRow, mCol] = size(fTotalCostMatrix);

if idxCostMatrixRow == 1 & idxCostMatrixCol == 1
    nNeighbourPoints = 0;
    idxListRow(1) = 2;
    idxListCol(1) = 1;
    idxListRow(2) = 1;
    idxListCol(2) = 2;
    
elseif (idxCostMatrixRow == 1 & idxCostMatrixCol == mCol) 
    nNeighbourPoints = 2;
    idxListRow(1) = 2;
    idxListCol(1) = mCol;
    idxListRow(2) = 1;
    idxListCol(2) = mCol-1;
    
elseif (idxCostMatrixRow == mRow & idxCostMatrixCol == 1) 
    nNeighbourPoints = 2;
    idxListRow(1) = mRow-1;
    idxListCol(1) = 1;
    idxListRow(2) = mRow;
    idxListCol(2) = 2;
    
elseif (idxCostMatrixRow == mRow & idxCostMatrixCol == mCol) 
    nNeighbourPoints = 2;
    idxListRow(1) = mRow-1;
    idxListCol(1) = mCol;
    idxListRow(2) = mRow;
    idxListCol(2) = mCol-1;
    
elseif (idxCostMatrixRow == 1 & idxCostMatrixCol >= 2 & idxCostMatrixCol <= mCol-1) 
    nNeighbourPoints = 3;
    idxListRow(1) = 1;
    idxListCol(1) = idxCostMatrixCol-1;
    idxListRow(2) = 1;
    idxListCol(2) = idxCostMatrixCol+1;
    idxListRow(3) = 2;
    idxListCol(3) = idxCostMatrixCol;

elseif (idxCostMatrixRow >= 2 & idxCostMatrixRow <= mRow -1 & idxCostMatrixCol == 1)
    nNeighbourPoints = 3;
    idxListRow(1) = idxCostMatrixRow+1;
    idxListCol(1) = 1;
    idxListRow(2) = idxCostMatrixRow-1;
    idxListCol(2) = 1;
    idxListRow(3) = idxCostMatrixRow;
    idxListCol(3) = 2;
    
elseif (idxCostMatrixRow == mRow & idxCostMatrixCol >= 2 & idxCostMatrixCol <= mCol-1)
    nNeighbourPoints = 3;
    idxListRow(1) = mRow;
    idxListCol(1) = idxCostMatrixCol-1;
    idxListRow(2) = mRow;
    idxListCol(2) = idxCostMatrixCol+1;
    idxListRow(3) = mRow-1;
    idxListCol(3) = idxCostMatrixCol;
    
elseif (idxCostMatrixRow >= 2 & idxCostMatrixRow <= mRow -1 & idxCostMatrixCol == mCol)
    nNeighbourPoints = 3;
    idxListRow(1) = idxCostMatrixRow+1;
    idxListCol(1) = mCol;
    idxListRow(2) = idxCostMatrixRow-1;
    idxListCol(2) = mCol;
    idxListRow(3) = idxCostMatrixRow;
    idxListCol(3) = mCol-1;
    
elseif idxCostMatrixRow >= 2 & idxCostMatrixRow <= mRow -1 & idxCostMatrixCol >= 2 & idxCostMatrixCol <= mCol-1
    nNeighbourPoints = 4;
    idxListRow(1) = idxCostMatrixRow+1;
    idxListCol(1) = idxCostMatrixCol;
    idxListRow(2) = idxCostMatrixRow-1;
    idxListCol(2) = idxCostMatrixCol;
    idxListRow(3) = idxCostMatrixRow;
    idxListCol(3) = idxCostMatrixCol+1;
    idxListRow(4) = idxCostMatrixRow;
    idxListCol(4) = idxCostMatrixCol-1;
    
else
    error('Check the index, cannot be zero or negative.');
end

fValueToBeCompare = fTotalCostMatrix(idxCostMatrixRow, idxCostMatrixCol);
if fValueToBeCompare == 0
    bIsLocalMinimum = 0;
else
    bIsLocalMinimum = 1;
%     idxCostMatrixRow, idxCostMatrixCol, idxListRow, idxListCol
    for ii = 1:1:nNeighbourPoints
        if fValueToBeCompare > fTotalCostMatrix(idxListRow(ii), idxListCol(ii))
            bIsLocalMinimum = 0;
            break;
        end
    end
end
