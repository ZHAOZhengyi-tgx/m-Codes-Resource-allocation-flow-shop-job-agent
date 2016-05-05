function fout_joblist_xls(stGeneticJobList, stXlsConfig)

strFilenameXls = stGeneticJobList.strJobListInputFilename;
iPosnDot = strfind(strFilenameXls, '.');

if length(iPosnDot) >= 1
    strFilenameXls = sprintf('%s.xls', strFilenameXls(1:(iPosnDot(end)-1)));
else
    strFilenameXls = sprintf('%s.xls', strFilenameXls);
end

nTotalMachType = stGeneticJobList.stAgentBiFSPJobMachConfig.iTotalMachType;
nTotalForwardJobs = stGeneticJobList.stAgentBiFSPJobMachConfig.iTotalForwardJobs;
nTotalReverseJobs = stGeneticJobList.stAgentBiFSPJobMachConfig.iTotalReverseJobs;
nTotalJobs = nTotalForwardJobs + nTotalReverseJobs;


iPosnRowXls = stXlsConfig.iTableDataStartRow - 2;
cXlsRowPosn = sprintf('%d', iPosnRowXls);
cXlsColPosn = char(stXlsConfig.cTableDataStartColumn);
cXlsColPosn = cvt_str_xls_col_posn(cXlsColPosn);
strCellToWriteInXls = strcat(cXlsColPosn, cXlsRowPosn);
strWriteCell = sprintf('[p_{ij}, m_{ij}, mi_{ij}, mr_{ij}]'); 
cellXlsWriteElement = {strWriteCell};
xlswrite(strFilenameXls, cellXlsWriteElement, stXlsConfig.strSheetName, strCellToWriteInXls);

iPosnRowXls = stXlsConfig.iTableDataStartRow - 1;
cXlsRowPosn = sprintf('%d', iPosnRowXls);
for mm = 1:1: nTotalMachType
    cXlsColPosn = char(stXlsConfig.cTableDataStartColumn) - 1 + mm;
    cXlsColPosn = cvt_str_xls_col_posn(cXlsColPosn);
    strCellToWriteInXls = strcat(cXlsColPosn, cXlsRowPosn);
    strWriteCell = sprintf('Proc%d', mm); 
    cellXlsWriteElement = {strWriteCell};
    xlswrite(strFilenameXls, cellXlsWriteElement, stXlsConfig.strSheetName, strCellToWriteInXls);
end


% column is spanning for job-id, row is spanning for machine/operation
%% forward jobs (normal flow shop)
for jj = 1:1: nTotalForwardJobs
    iPosnRowXls = stXlsConfig.iTableDataStartRow - 1 + jj;
    cXlsRowPosn = sprintf('%d', iPosnRowXls);
    %% handle when it is greater then 65536
    if iPosnRowXls > 65536
        error('Too many jobs, exceed excel 65536 rows');
    end
    for mm = 1:1: nTotalMachType
        
        cXlsColPosn = char(stXlsConfig.cTableDataStartColumn) - 1 + mm;
        %% handle when it is greater than 'Z'
        cXlsColPosn = cvt_str_xls_col_posn(cXlsColPosn);
        
        strCellToWriteInXls = strcat(cXlsColPosn, cXlsRowPosn);
        
        strWriteCell = sprintf('[%d, %d, %d, %d]', ...
            stGeneticJobList.astMachineProcTimeOnMachine(mm).aForwardTimeMachineCycle(jj), ...
            mm, ...
            stGeneticJobList.astMachineProcTimeOnMachine(mm).aForwardJobOnMachineId(jj), ...
            stGeneticJobList.astMachineProcTimeOnMachine(mm).aForwardRelTimeMachineCycle(jj)); 
%        cellXlsWriteElement = {stGeneticJobList.astMachineProcTimeOnMachine(mm).aForwardTimeMachineCycle(jj)}
        cellXlsWriteElement = {strWriteCell};

        xlswrite(strFilenameXls, ...
            cellXlsWriteElement, stXlsConfig.strSheetName, strCellToWriteInXls);
    end
    
%     cXlsColPosn = char(stXlsConfig.cTableDataStartColumn) + nTotalMachType;
%     strCellToWriteInXls = strcat(cXlsColPosn, cXlsRowPosn);
%     cellXlsWriteElement = {'Forward'};
%     xlswrite(strFilenameXls, ...
%         cellXlsWriteElement, stXlsConfig.strSheetName, strCellToWriteInXls);
    
end

%%% Column: JobType_JobId: For_%d
cXlsColPosn = char(stXlsConfig.cTableDataStartColumn) + nTotalMachType;
for jj = 1:1: nTotalForwardJobs
    iPosnRowXls = stXlsConfig.iTableDataStartRow - 1 + jj;
    cXlsRowPosn = sprintf('%d', iPosnRowXls);
    strCellToWriteInXls = strcat(cXlsColPosn, cXlsRowPosn);
    strWriteCell = sprintf('For_%d', jj); 
%        cellXlsWriteElement = {stGeneticJobList.astMachineProcTimeOnMachine(mm).aForwardTimeMachineCycle(jj)}
    cellXlsWriteElement = {strWriteCell};
    xlswrite(strFilenameXls, ...
            cellXlsWriteElement, stXlsConfig.strSheetName, strCellToWriteInXls);
    
end

%%% Column Row: p_{ij}/m_{ij}, reverse jobs
for jj = 1:1: nTotalReverseJobs
    iPosnRowXls = stXlsConfig.iTableDataStartRow - 1 + jj + nTotalForwardJobs;
    cXlsRowPosn = sprintf('%d', iPosnRowXls);
    %% handle when it is greater then 65536
    if iPosnRowXls > 65536
        error('Too many jobs, exceed excel 65536 rows');
    end

    for mm = nTotalMachType:-1:1 
        iProcId = nTotalMachType - mm + 1; %% reverse job, the process sequence just reversed
        cXlsColPosn = char(stXlsConfig.cTableDataStartColumn) - 1 + iProcId;
        %% handle when it is greater than 'Z'
        cXlsColPosn = cvt_str_xls_col_posn(cXlsColPosn);
        
        strCellToWriteInXls = strcat(cXlsColPosn, cXlsRowPosn);

        strWriteCell = sprintf('[%d, %d, %d, %d]', ...
            stGeneticJobList.astMachineProcTimeOnMachine(mm).aReverseTimeMachineCycle(jj), ...
            mm, ...
            stGeneticJobList.astMachineProcTimeOnMachine(mm).aReverseJobOnMachineId(jj), ...
            stGeneticJobList.astMachineProcTimeOnMachine(mm).aReverseRelTimeMachineCycle(jj)); 
 %       cellXlsWriteElement = {stGeneticJobList.astMachineProcTimeOnMachine(mm).aReverseTimeMachineCycle(jj)}
        cellXlsWriteElement = {strWriteCell};
        
        xlswrite(strFilenameXls, ...
            cellXlsWriteElement, stXlsConfig.strSheetName, strCellToWriteInXls);
    end

%     cXlsColPosn = char(stXlsConfig.cTableDataStartColumn) + nTotalMachType;
%     strCellToWriteInXls = strcat(cXlsColPosn, cXlsRowPosn);
%     cellXlsWriteElement = {'Reverse'};
%     xlswrite(strFilenameXls, ...
%         cellXlsWriteElement, stXlsConfig.strSheetName, strCellToWriteInXls);
end

%%% Column: JobType_JobId: For_%d
cXlsColPosn = char(stXlsConfig.cTableDataStartColumn) + nTotalMachType;
for jj = 1:1: nTotalReverseJobs
    iPosnRowXls = stXlsConfig.iTableDataStartRow - 1 + jj + nTotalForwardJobs;
    cXlsRowPosn = sprintf('%d', iPosnRowXls);
    strCellToWriteInXls = strcat(cXlsColPosn, cXlsRowPosn);
    strWriteCell = sprintf('Rev_%d', jj); 
%        cellXlsWriteElement = {stGeneticJobList.astMachineProcTimeOnMachine(mm).aForwardTimeMachineCycle(jj)}
    cellXlsWriteElement = {strWriteCell};
    xlswrite(strFilenameXls, ...
            cellXlsWriteElement, stXlsConfig.strSheetName, strCellToWriteInXls);
end

