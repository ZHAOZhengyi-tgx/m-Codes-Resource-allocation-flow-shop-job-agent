function [matNum, matTxt, matRaw] = xls_load_matrix(stXlsLoadMatrixInput)

% History
% YYYYMMDD  Notes
% 20080415  use system('dir') but not mtlb_system_version to judge DOS or
% UNIX system

iFlagDos =  0; % system('dir');
%   stXlsLoadMatrixInput
%%% Convert file name to be compatible with UNIX
%[iFlagDos, astrVer] = mtlb_system_version(); % 20070729

if iFlagDos == 0 %% it is a dos-windows system
%     disp('it is a dos-windows system');
    iPathStringList = strfind(stXlsLoadMatrixInput.strJobListInputFilename, '\');
    strPathname = stXlsLoadMatrixInput.strJobListInputFilename(1:iPathStringList(end));

else %% it is a UNIX or Linux system
    error('Only Windows system support XLS COM function');
end
strXlsFullFilename = strcat(strPathname, stXlsLoadMatrixInput.stRefXlsInput.strFilenameRelativePath)

nTotalRows = stXlsLoadMatrixInput.nTotalRows;
nTotalCols = stXlsLoadMatrixInput.nTotalCols;
strStartCell = sprintf('%s%d', stXlsLoadMatrixInput.stRefXlsInput.strColStart, stXlsLoadMatrixInput.stRefXlsInput.iRowStart)

if length(stXlsLoadMatrixInput.stRefXlsInput.strColStart) >= 2
    error('Start Cell must has column <= Z');
else
    cEndColPosn = char(stXlsLoadMatrixInput.stRefXlsInput.strColStart) + nTotalCols;
    cEndColPosn = cvt_str_xls_col_posn(cEndColPosn);
end
iEndRowPosn = stXlsLoadMatrixInput.stRefXlsInput.iRowStart + nTotalRows - 1;

% strStartCell
% cEndColPosn
% iEndRowPosn
strRangeLoadXls = sprintf('%s:%s%d', strStartCell, char(cEndColPosn), iEndRowPosn);

%%
iPlotFlag = 0;
if iPlotFlag >= 3
    strRangeLoadXls
    strSheetname = stXlsLoadMatrixInput.stRefXlsInput.strSheetname
    strXlsFullFilename
end

[matNum, matTxt, matRaw] = xlsread(strXlsFullFilename, stXlsLoadMatrixInput.stRefXlsInput.strSheetname, strRangeLoadXls);
