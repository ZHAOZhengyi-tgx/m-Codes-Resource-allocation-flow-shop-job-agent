function astMachineProcTimeOnMachine = fsp_load_joblist_by_xls(stAgentJobListBiFsp)

%%% Convert file name to be compatible with UNIX
[s, astrVer] = mtlb_system_version(); % 20070729

if s == 0 %% it is a dos-windows system
    disp('it is a dos-windows system');
    iPathStringList = strfind(stAgentJobListBiFsp.strJobListInputFilename, '\');
    strPathname = stAgentJobListBiFsp.strJobListInputFilename(1:iPathStringList(end));

else %% it is a UNIX or Linux system
    disp('it is a UNIX or Linux system');
    iPathStringList = strfind(stAgentJobListBiFsp.strJobListInputFilename, '\');
    for ii = 1:1:length(iPathStringList)
        stAgentJobListBiFsp.strJobListInputFilename(iPathStringList(ii)) = '/';
    end
    strPathname = strFileFullName(1:iPathStringList(end));
end
strXlsFullFilename = strcat(strPathname, stAgentJobListBiFsp.stRefXlsInput.strFilenameRelativePath)

iTotalJob = stAgentJobListBiFsp.stAgentBiFSPJobMachConfig.iTotalForwardJobs + stAgentJobListBiFsp.stAgentBiFSPJobMachConfig.iTotalReverseJobs;
iTotalMachType = stAgentJobListBiFsp.stAgentBiFSPJobMachConfig.iTotalMachType;
strStartCell = sprintf('%s%d', stAgentJobListBiFsp.stRefXlsInput.strColStart, stAgentJobListBiFsp.stRefXlsInput.iRowStart);

if length(stAgentJobListBiFsp.stRefXlsInput.strColStart) >= 2
    error('Start Cell must has column <= Z');
else
    cEndColPosn = char(stAgentJobListBiFsp.stRefXlsInput.strColStart) + iTotalMachType;
    cEndColPosn = cvt_str_xls_col_posn(cEndColPosn);
end
iEndRowPosn = stAgentJobListBiFsp.stRefXlsInput.iRowStart + iTotalJob - 1;

% strStartCell
% cEndColPosn
% iEndRowPosn
strRangeLoadXls = sprintf('%s:%s%d', strStartCell, char(cEndColPosn), iEndRowPosn);
[matNum, matTxt, matRaw] = xlsread(strXlsFullFilename, stAgentJobListBiFsp.stRefXlsInput.strSheetname, strRangeLoadXls);
%     matRaw

for ii = 1:1:iTotalJob
    strJobType_Id = char(matRaw(ii, iTotalMachType + 1));
    if strcmp(strJobType_Id(1:3), 'For') == 1
        idxForwardJobId = sscanf(strJobType_Id(5:end), '%d');
        for mm = 1:1:iTotalMachType
            strProcCycleTime_MachType_MI_MR = char(matRaw(ii, mm));
            [aReadNumber, iCount] = sscanf(strProcCycleTime_MachType_MI_MR, '[%d, %d, %d, %d]');
            if iCount < 4
                error('Error Format, should contain [p_{ij}, m_{ij}, mi_{ij}, mr_{ij}]');
            else
                fProcTime = aReadNumber(1);
                iMachType = aReadNumber(2);
                iMachId = aReadNumber(3);
                fMachRelTime = aReadNumber(4);
                astMachineProcTimeOnMachine(iMachType).aForwardTimeMachineCycle(idxForwardJobId) = fProcTime;
                astMachineProcTimeOnMachine(iMachType).aForwardJobOnMachineId(idxForwardJobId) = iMachId;
                astMachineProcTimeOnMachine(iMachType).aForwardRelTimeMachineCycle(idxForwardJobId) = fMachRelTime;
            end
        end
    elseif strcmp(strJobType_Id(1:3), 'Rev') == 1
        idxReverseJobId = sscanf(strJobType_Id(5:end), '%d');
        for mm = 1:1:iTotalMachType
            strProcCycleTime_MachType_MI_MR = char(matRaw(ii, mm));
            [aReadNumber, iCount] = sscanf(strProcCycleTime_MachType_MI_MR, '[%d, %d, %d, %d]');
            if iCount < 4
                error('Error Format, should contain [p_{ij}, m_{ij}, mi_{ij}, mr_{ij}]');
            else
                fProcTime = aReadNumber(1);
                iMachType = aReadNumber(2);
                iMachId = aReadNumber(3);
                fMachRelTime = aReadNumber(4);
                astMachineProcTimeOnMachine(iMachType).aReverseTimeMachineCycle(idxReverseJobId) = fProcTime;
                astMachineProcTimeOnMachine(iMachType).aReverseJobOnMachineId(idxReverseJobId) = iMachId;
                astMachineProcTimeOnMachine(iMachType).aReverseRelTimeMachineCycle(idxReverseJobId) = fMachRelTime;
            end
        end

    else
        error('Not Supported Job Type');
    end
end
stAgentJobListBiFsp.astMachineProcTimeOnMachine = astMachineProcTimeOnMachine;
