function fsp_dbg_write_file(fptr, stSolution, iCaseSolution)
%
% 20080211 Add iCriticalMachType into stResourceConfig

%fprintf(fptr, 'CaseId,  ResourcePM, ResourceYC,  MakeSpan_hour, CostMakeSpanTardiness, CostResource, TotalCost\n');

fprintf(fptr, '%d, [', iCaseSolution);
stResourceConfig = stSolution.astCase(iCaseSolution).stResourceConfig;
iTotalMachine = stResourceConfig.iTotalMachine;

iTotalPeriod = stResourceConfig.stMachineConfig(iTotalMachine).iNumPointTimeCap;
for mm = 1:1:iTotalMachine
    %    stResourceConfig.stMachineConfig(mm).afMaCapAtTimePoint
    if mm ~= stResourceConfig.iCriticalMachType % 20080211
        for ii = 1:1:iTotalPeriod - 1
            fprintf(fptr, '%d, ', stResourceConfig.stMachineConfig(mm).afMaCapAtTimePoint(ii));
        end

        if mm == iTotalMachine
            fprintf(fptr, '%d], ', stResourceConfig.stMachineConfig(mm).afMaCapAtTimePoint(iTotalPeriod));
        else
            fprintf(fptr, '%d], [', stResourceConfig.stMachineConfig(mm).afMaCapAtTimePoint(iTotalPeriod));
        end
    end
end

% for ii = 1:1:iTotalPeriod - 1
%     fprintf(fptr, '%d, ', stResourceConfig.stMachineConfig(3).afMaCapAtTimePoint(ii));
% end
% 
% fprintf(fptr, '%d], ', stResourceConfig.stMachineConfig(3).afMaCapAtTimePoint(iTotalPeriod));
        
fprintf(fptr, '%4.2f, %4.2f, %4.2f, %4.2f\n', ...
    stSolution.aMakeSpan_hour(iCaseSolution), ...
    stSolution.aCostTardinessMakespan(iCaseSolution), ...
    stSolution.aTotalCost(iCaseSolution) - stSolution.aCostTardinessMakespan(iCaseSolution), ...
    stSolution.aTotalCost(iCaseSolution) );
