function strCellColPosn = cvt_str_xls_col_posn(cColPosn)
% 
% convert a number to a string,
%  The number is a char type, indicating the column in a EXCEL table,
%  'A' to 'Z'
%

nLenAlphabet = 'Z'-'A' + 1;
if cColPosn > 'Z'
    cAbsColPosn = cColPosn - 'A' + 1;
    cOfst0ColPosn = mod(cAbsColPosn, nLenAlphabet);
    cOfst1ColPosn = floor(cAbsColPosn/nLenAlphabet);
    
    strCellColPosn = sprintf('%c%c', cOfst1ColPosn + 'A' - 1, cOfst0ColPosn + 'A' - 1);
else
    strCellColPosn = cColPosn;
end