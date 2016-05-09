function stResAllocGenJspAgentLoad = gen_resalloc_mach5_frm_mach3(strFilenamePortResAllocator, strDestiResallocPath)

nCapMachType4 = 12;
nCapMachType5 = 10;
iDestAlgoChoice = 17;


stResAllocPortCfg = psa_berth_load_parameter(strFilenamePortResAllocator);

nTotalAgent = stResAllocPortCfg.iTotalAgent;
for aa = 1:1:stResAllocPortCfg.iTotalAgent
    stJobListInfoAgent(aa) = jsp_load_port_bifsp_list(stResAllocPortCfg.strFileAgentJobList(aa).strFilename);

%     stJobListInfoAgent(aa).stJssProbStructConfig
%     stJobListInfoAgent(aa).stJssProbStructConfig.isMachineReleaseImmediate
end
stResAllocPortCfg.stJobListInfoAgent = stJobListInfoAgent;
%% convert ResAllocator, including job-list agent
stResAllocGenJspAgent = cvt_resalloc_by_port(stResAllocPortCfg);


%% modify total number of machine type
nOriTotalMachType = stResAllocGenJspAgent.stResourceConfig.iTotalMachine; % bakup
nTotalMachType = 5;
stResAllocGenJspAgent.stSystemMasterConfig.iTotalMachType = nTotalMachType;
stResAllocGenJspAgent.stResourceConfig.iTotalMachine = nTotalMachType;
nTotalFrame4Pricing = stResAllocGenJspAgent.stSystemMasterConfig.iMaxFramesForPlanning;
% allocate memory
for ii = 1:1:nTotalMachType
    stResAllocGenJspAgent.stResourceConfig.stMachineConfig(ii).strName = sprintf('M-%d', ii);
    if ii > nOriTotalMachType
        stResAllocGenJspAgent.stResourceConfig.stMachineConfig(ii).iNumPointTimeCap = 1;
        stResAllocGenJspAgent.stResourceConfig.stMachineConfig(ii).afTimePointAtCap = 0;
        stResAllocGenJspAgent.astResourceInitPrice(ii).strName = stResAllocGenJspAgent.stResourceConfig.stMachineConfig(ii).strName;
        stResAllocGenJspAgent.astResourceInitPrice(ii).iTotalFrame4Pricing =nTotalFrame4Pricing;
        stResAllocGenJspAgent.astResourceInitPrice(ii).afMachinePriceListPerFrame = zeros(nTotalFrame4Pricing, 1);
    end
end

stResAllocGenJspAgent.stResourceConfig.stMachineConfig(4).afMaCapAtTimePoint = nCapMachType4;
stResAllocGenJspAgent.stResourceConfig.stMachineConfig(5).afMaCapAtTimePoint = nCapMachType5;
stResAllocGenJspAgent.stResourceConfig.iaMachCapOnePer(4) = nCapMachType4;
stResAllocGenJspAgent.stResourceConfig.iaMachCapOnePer(5) = nCapMachType5;

stGeneticBiFspAgent = stResAllocGenJspAgent.stGeneticCfgBiFsp;
nTotalAgent = stResAllocGenJspAgent.stSystemMasterConfig.iTotalAgent;
for aa = 1:1:nTotalAgent
    stGeneticBiFspAgent(aa).stAgentBiFSPJobMachConfig.iTotalMachType = nTotalMachType;
    stGeneticBiFspAgent(aa).stResourceConfig.iTotalMachine = nTotalMachType;
    %% allocating memory
    for ii = 1:1:nTotalMachType
        stGeneticBiFspAgent(aa).stResourceConfig.stMachineConfig(ii).strName = sprintf('M-%d', ii);
        stGeneticBiFspAgent(aa).stResourceConfig.stMachineConfig(ii).iNumPointTimeCap = 1;
        stGeneticBiFspAgent(aa).stResourceConfig.stMachineConfig(ii).afTimePointAtCap = 0;
        stGeneticBiFspAgent(aa).stResourceConfig.stMachineConfig(ii).afMaCapAtTimePoint = 1;  %% baseline machine, 1
        if ii > nOriTotalMachType
            stGeneticBiFspAgent(aa).stResourceConfig.iaMachCapOnePer(ii) = 1; % baseline machine
        end
    end
    
    %% job processing time, machine release time, dedicated machine-id
    nTotalForwardJobs = stGeneticBiFspAgent(aa).stAgentBiFSPJobMachConfig.iTotalForwardJobs;
    nTotalReverseJobs = stGeneticBiFspAgent(aa).stAgentBiFSPJobMachConfig.iTotalReverseJobs;
    astMachineProcTimeOnMachine = stGeneticBiFspAgent(aa).astMachineProcTimeOnMachine;
    
    fMeanProcTime2ndProc = mean([astMachineProcTimeOnMachine(2).aForwardTimeMachineCycle, astMachineProcTimeOnMachine(2).aReverseTimeMachineCycle]);
    fStdProcTime2ndProc = std([astMachineProcTimeOnMachine(2).aForwardTimeMachineCycle, astMachineProcTimeOnMachine(2).aReverseTimeMachineCycle]);
    for mm = (nOriTotalMachType+1):1:nTotalMachType
        fFactorProcTime = stResAllocGenJspAgent.stResourceConfig.stMachineConfig(mm).afMaCapAtTimePoint ...
            / stResAllocGenJspAgent.stResourceConfig.stMachineConfig(2).afMaCapAtTimePoint;
        fMeanProcTime = fMeanProcTime2ndProc * fFactorProcTime;
        fStdProcTime = fStdProcTime2ndProc * fFactorProcTime;
        astMachineProcTimeOnMachine(mm).aForwardTimeMachineCycle    = round(rand(1, nTotalForwardJobs) * fStdProcTime * sqrt(12) - 0.5 + fMeanProcTime);
        astMachineProcTimeOnMachine(mm).aForwardJobOnMachineId      = zeros(1, nTotalForwardJobs);
        astMachineProcTimeOnMachine(mm).aForwardRelTimeMachineCycle = zeros(1, nTotalForwardJobs);
        astMachineProcTimeOnMachine(mm).aReverseTimeMachineCycle    = round(rand(1, nTotalReverseJobs) * fStdProcTime * sqrt(12) - 0.5 + fMeanProcTime);
        astMachineProcTimeOnMachine(mm).aReverseJobOnMachineId      = zeros(1, nTotalReverseJobs);
        astMachineProcTimeOnMachine(mm).aReverseRelTimeMachineCycle = zeros(1, nTotalReverseJobs);
    end
    stGeneticBiFspAgent(aa).astMachineProcTimeOnMachine = astMachineProcTimeOnMachine;
end


stResAllocGenJspAgent.stGeneticCfgBiFsp = stGeneticBiFspAgent;
% stResAllocGenJspAgent.strInputFilename = ''

%% save
strFilenamePrefix = strDestiResallocPath;
for aa = 1:1:nTotalAgent
    stBiFlowShopJobListInfo = stResAllocGenJspAgent.stGeneticCfgBiFsp(aa);
    strFilenamePrefixAgent = sprintf('%sAgent_%d',strFilenamePrefix, aa);
    [strFileName] = fsp_save_joblist(stBiFlowShopJobListInfo, strFilenamePrefixAgent);
    stResAllocGenJspAgent.strFileAgentJobList(aa).strFilename = strFileName;
end
[strResAllocGlbFileName] = resalloc_save_config(stResAllocGenJspAgent, strFilenamePrefix);

stResAllocGenJspAgent.stSystemMasterConfig.iAlgoChoice = iDestAlgoChoice;

stResAllocGenJspAgentLoad = resalloc_load_glb_parameter(strResAllocGlbFileName);
