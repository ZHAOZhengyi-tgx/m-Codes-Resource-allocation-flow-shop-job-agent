function stResAllocGenJspAgentLoad = gen_resalloc_bifsp_jseq_by_port(strFilenamePortResAllocator, strDestiResallocPath)

iDestAlgoOptResAlloc = 17;
iDestAlgoOptSchGen = 8;

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


%% modify job sequencing
nOriTotalMachType = stResAllocGenJspAgent.stResourceConfig.iTotalMachine; % bakup
nTotalMachType = nOriTotalMachType;
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

stGeneticBiFspAgent = stResAllocGenJspAgent.stGeneticCfgBiFsp;
nTotalAgent = stResAllocGenJspAgent.stSystemMasterConfig.iTotalAgent;
for aa = 1:1:nTotalAgent
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
    nTotalJobs = nTotalForwardJobs + nTotalReverseJobs;
    aiSortedForwardJobs = 1:1:nTotalForwardJobs;
    aiSortedReverseJobs = 1:1:nTotalReverseJobs;
    for ii = 1:1:nTotalJobs
        if bitand(ii, 1) == 1
            aiJobSeqInJspCfg(ii) = aiSortedForwardJobs( (ii + 1)/2);
        else
            aiJobSeqInJspCfg(ii) = aiSortedReverseJobs( ii/2) + nTotalForwardJobs;
        end
    end
    stGeneticBiFspAgent(aa).aiJobSeqInJspCfg = aiJobSeqInJspCfg;
    
    stGeneticBiFspAgent(aa).stAgentBiFSPJobMachConfig.iOptRule = iDestAlgoOptSchGen;
end


stResAllocGenJspAgent.stGeneticCfgBiFsp = stGeneticBiFspAgent;
stResAllocGenJspAgent.stSystemMasterConfig.iAlgoChoice = iDestAlgoOptResAlloc;


%% save
strFilenamePrefix = strDestiResallocPath;
for aa = 1:1:nTotalAgent
    stBiFlowShopJobListInfo = stResAllocGenJspAgent.stGeneticCfgBiFsp(aa);
    strFilenamePrefixAgent = sprintf('%sAgent_%d',strFilenamePrefix, aa);
    [strFileName] = fsp_save_joblist(stBiFlowShopJobListInfo, strFilenamePrefixAgent);
    stResAllocGenJspAgent.strFileAgentJobList(aa).strFilename = strFileName;
end
[strResAllocGlbFileName] = resalloc_save_config(stResAllocGenJspAgent, strFilenamePrefix);

stResAllocGenJspAgentLoad = resalloc_load_glb_parameter(strResAllocGlbFileName);
