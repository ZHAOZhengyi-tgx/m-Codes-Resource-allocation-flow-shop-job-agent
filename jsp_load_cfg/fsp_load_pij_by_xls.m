function astMachineProcTimeOnMachine = fsp_load_pij_by_xls(stAgentJobListBiFsp)

stXlsLoadMatrixInput.strJobListInputFilename = stAgentJobListBiFsp.strJobListInputFilename
stXlsLoadMatrixInput.stRefXlsInput = stAgentJobListBiFsp.stRefXlsInput
stXlsLoadMatrixInput.nTotalRows = stAgentJobListBiFsp.stAgentBiFSPJobMachConfig.iTotalForwardJobs + stAgentJobListBiFsp.stAgentBiFSPJobMachConfig.iTotalReverseJobs;
stXlsLoadMatrixInput.nTotalCols = stAgentJobListBiFsp.stAgentBiFSPJobMachConfig.iTotalMachType;
iTotalJob = stXlsLoadMatrixInput.nTotalRows;
iTotalMachType = stXlsLoadMatrixInput.nTotalCols;
[matNum, matTxt, matRaw] = xls_load_matrix(stXlsLoadMatrixInput);

% matRaw
% matNum

for ii = 1:1:iTotalJob
%    matRaw(ii, iTotalMachType + 1)
    strJobType_Id = char(matRaw(ii, iTotalMachType + 1));
    if strcmp(strJobType_Id(1:3), 'For') == 1
        idxForwardJobId = sscanf(strJobType_Id(5:end), '%d');
        for mm = 1:1:iTotalMachType
            aReadNumberRaw = round(cell2mat(matRaw(ii, mm)));
                if abs(matNum(ii,mm) - aReadNumberRaw) > 1
                    error('too large error from float to fix point');
                end
                fProcTime = matNum(ii, mm);
                iMachType = mm;
                iMachId = 0;
                fMachRelTime = 0;
                astMachineProcTimeOnMachine(iMachType).aForwardTimeMachineCycle(idxForwardJobId) = fProcTime;
                astMachineProcTimeOnMachine(iMachType).aForwardJobOnMachineId(idxForwardJobId) = iMachId;
                astMachineProcTimeOnMachine(iMachType).aForwardRelTimeMachineCycle(idxForwardJobId) = fMachRelTime;
            
        end
    elseif strcmp(strJobType_Id(1:3), 'Rev') == 1
        idxReverseJobId = sscanf(strJobType_Id(5:end), '%d');
        for mm = 1:1:iTotalMachType
            aReadNumberRaw = round(cell2mat(matRaw(ii, mm)));
                if abs(matNum(ii,mm) - aReadNumberRaw) > 1
                    error('too large error from float to fix point');
                end
                fProcTime = matNum(ii, mm);
                iMachType = iTotalMachType + 1 - mm;
                iMachId = 0;
                fMachRelTime = 0;
                astMachineProcTimeOnMachine(iMachType).aReverseTimeMachineCycle(idxReverseJobId) = fProcTime;
                astMachineProcTimeOnMachine(iMachType).aReverseJobOnMachineId(idxReverseJobId) = iMachId;
                astMachineProcTimeOnMachine(iMachType).aReverseRelTimeMachineCycle(idxReverseJobId) = fMachRelTime;
        end

    else
        error('Not Supported Job Type');
    end
end
stAgentJobListBiFsp.astMachineProcTimeOnMachine = astMachineProcTimeOnMachine;
