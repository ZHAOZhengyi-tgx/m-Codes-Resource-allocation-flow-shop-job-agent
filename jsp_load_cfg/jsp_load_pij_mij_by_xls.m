function [jsp_process_time, jsp_process_machine] = jsp_load_pij_mij_by_xls(stAgentJspCfg)

jsp_process_time = stAgentJspCfg.jsp_process_time;          % default value
jsp_process_machine = stAgentJspCfg.jsp_process_machine;    % default value
stProcessPerJob = stAgentJspCfg.stProcessPerJob;
nMaxTotalProcPerJob = max(stProcessPerJob);
nTotalJobs = stAgentJspCfg.iTotalJob;

if length(stAgentJspCfg.stProcTimeRefXlsInput) >= 1
    stXlsLoadMatrixInput.strJobListInputFilename = stAgentJspCfg.strJobListInputFilename;
    stXlsLoadMatrixInput.stRefXlsInput = stAgentJspCfg.stProcTimeRefXlsInput;
    stXlsLoadMatrixInput.nTotalRows = nTotalJobs;
    stXlsLoadMatrixInput.nTotalCols = nMaxTotalProcPerJob;
    [matNum, matTxt, matRaw] = xls_load_matrix(stXlsLoadMatrixInput);

    %size(matRaw)
    % matNum

    for ii = 1:1:nTotalJobs
    %    matRaw(ii, nMaxTotalProcPerJob + 1)
        for jj = 1:1:stProcessPerJob(ii)
            iReadNumberRaw = round(cell2mat(matRaw(ii, jj)));
            if abs(matNum(ii,jj) - iReadNumberRaw) > 1
                error('too large error from float to fix point');
            end
            jsp_process_time(ii).fProcessTime(jj) = matNum(ii,jj);
            jsp_process_time(ii).iProcessTime(jj) = iReadNumberRaw;

        end
    end
end

%% load process machine
iTotalMachType = stAgentJspCfg.iTotalMachine;

if length(stAgentJspCfg.stProcMachTypeRefXlsInp) >= 1
    stXlsLoadMatrixInput.strJobListInputFilename = stAgentJspCfg.strJobListInputFilename;
    stXlsLoadMatrixInput.stRefXlsInput = stAgentJspCfg.stProcMachTypeRefXlsInp;
    stXlsLoadMatrixInput.nTotalRows = nTotalJobs;
    stXlsLoadMatrixInput.nTotalCols = nMaxTotalProcPerJob;
    [matNum, matTxt, matRaw] = xls_load_matrix(stXlsLoadMatrixInput);
    
    % matRaw
    % matNum

    for ii = 1:1:nTotalJobs
    %    matRaw(ii, nMaxTotalProcPerJob + 1)
        for jj = 1:1:stProcessPerJob(ii)
            iReadNumberRaw = round(cell2mat(matRaw(ii, jj)));
            if abs(matNum(ii,jj) - iReadNumberRaw) > 1
                error('too large error from float to fix point');
            end
            jsp_process_machine(ii).iProcessMachine(jj) = iReadNumberRaw;

        end
    end
end

% jsp_process_machine
