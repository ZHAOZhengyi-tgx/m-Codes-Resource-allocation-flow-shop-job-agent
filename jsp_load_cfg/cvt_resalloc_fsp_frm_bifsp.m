function [stResAllocGenJspAgentLoad, stResAllocGenJspAgent] = cvt_resalloc_fsp_frm_bifsp(strFilenamePortResAllocator, strDestiResallocPath)

iDestAlgoChoice = 18;
% nTotalMachType = 5;
iFlagRandGen = 2; % 
% 1: uniform distribution
% 2: normal distribution

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

% %% modify total number of machine type
% nOriTotalMachType = stResAllocGenJspAgent.stResourceConfig.iTotalMachine; % bakup
% nTotalMachType = nOriTotalMachType;
% 
% stResAllocGenJspAgent.stSystemMasterConfig.iTotalMachType = nTotalMachType;
% stResAllocGenJspAgent.stResourceConfig.iTotalMachine = nTotalMachType;
% nTotalFrame4Pricing = stResAllocGenJspAgent.stSystemMasterConfig.iMaxFramesForPlanning;
% % allocate memory
% for ii = 1:1:nTotalMachType
%     stResAllocGenJspAgent.stResourceConfig.stMachineConfig(ii).strName = sprintf('M-%d', ii);
%     if ii > nOriTotalMachType
%         stResAllocGenJspAgent.stResourceConfig.stMachineConfig(ii).iNumPointTimeCap = 1;
%         stResAllocGenJspAgent.stResourceConfig.stMachineConfig(ii).afTimePointAtCap = 0;
%         stResAllocGenJspAgent.astResourceInitPrice(ii).strName = stResAllocGenJspAgent.stResourceConfig.stMachineConfig(ii).strName;
%         stResAllocGenJspAgent.astResourceInitPrice(ii).iTotalFrame4Pricing =nTotalFrame4Pricing;
%         stResAllocGenJspAgent.astResourceInitPrice(ii).afMachinePriceListPerFrame = zeros(nTotalFrame4Pricing, 1);
%     end
% end

%stGeneticBiFspAgent = stResAllocGenJspAgent.stGeneticCfgBiFsp;
% nTotalAgent = stResAllocGenJspAgent.stSystemMasterConfig.iTotalAgent;
% for aa = 1:1:nTotalAgent
%     [stAgentJobList] = cvt_joblist_by_port(stJobListInfoAgent(aa));
%     stGeneticBiFspAgent(aa) = stAgentJobList;
    
%     stGeneticBiFspAgent(aa).stAgentBiFSPJobMachConfig.iTotalMachType = nTotalMachType;
%     stGeneticBiFspAgent(aa).stResourceConfig.iTotalMachine = nTotalMachType;
%     %% allocating memory
%     for ii = 1:1:nTotalMachType
%         stGeneticBiFspAgent(aa).stResourceConfig.stMachineConfig(ii).strName = sprintf('M-%d', ii);
%         stGeneticBiFspAgent(aa).stResourceConfig.stMachineConfig(ii).iNumPointTimeCap = 1;
%         stGeneticBiFspAgent(aa).stResourceConfig.stMachineConfig(ii).afTimePointAtCap = 0;
%         stGeneticBiFspAgent(aa).stResourceConfig.stMachineConfig(ii).afMaCapAtTimePoint = 1;  %% baseline machine, 1
%         if ii > nOriTotalMachType
%             stGeneticBiFspAgent(aa).stResourceConfig.iaMachCapOnePer(ii) = 1; % baseline machine
%         end
%     end
%     
%     %% job processing time, machine release time, dedicated machine-id
%     nTotalNumOriForwardJobs = stGeneticBiFspAgent(aa).stAgentBiFSPJobMachConfig.iTotalForwardJobs;
%     nTotalForwardJobs = nTotalNumFlowJobs; %
%     nTotalNumOriReverseJobs = stGeneticBiFspAgent(aa).stAgentBiFSPJobMachConfig.iTotalReverseJobs;
%     nTotalReverseJobs = 0; % 
%     astMachineProcTimeOnMachine = stGeneticBiFspAgent(aa).astMachineProcTimeOnMachine;
%     
%     stGeneticBiFspAgent(aa).stAgentBiFSPJobMachConfig.iTotalForwardJobs = nTotalForwardJobs;
%     stGeneticBiFspAgent(aa).stAgentBiFSPJobMachConfig.iTotalReverseJobs = nTotalReverseJobs;
%     for mm = 1:1:nTotalMachType
%         % if more jobs
%         if nTotalNumOriForwardJobs < nTotalForwardJobs
%             %% evaluate original mean and standard deviation
%             fMeanProcTime = mean([astMachineProcTimeOnMachine(mm).aForwardTimeMachineCycle, astMachineProcTimeOnMachine(mm).aReverseTimeMachineCycle]);
%             fStdProcTime = std([astMachineProcTimeOnMachine(mm).aForwardTimeMachineCycle, astMachineProcTimeOnMachine(mm).aReverseTimeMachineCycle]);
%             astMachineProcTimeOnMachine(mm).aForwardTimeMachineCycle(ii)    =
%             for ii = (nTotalNumOriForwardJobs+1):1:nTotalForwardJobs
%                 % should allocation memory, done by matlab
%                 % keep the original mean and standard deviation, use uniform
%                 % distribution
%                 if iFlagRandGen == 1
%                     astMachineProcTimeOnMachine(mm).aForwardTimeMachineCycle(ii)    = ...
%                         round(rand() * fStdProcTime * sqrt(12) - 0.5 + fMeanProcTime);
%                 elseif iFlagRandGen == 2
%                     astMachineProcTimeOnMachine(mm).aForwardTimeMachineCycle(ii)    = ...
%                         round(randn() * fStdProcTime + fMeanProcTime);
%                 else
%                     error('Only uniform and normal distribution is allowed')
%                 end
%                 astMachineProcTimeOnMachine(mm).aForwardJobOnMachineId(ii)      = 0;
%                 astMachineProcTimeOnMachine(mm).aForwardRelTimeMachineCycle(ii) = 0;
%                 astMachineProcTimeOnMachine(mm).aReverseTimeMachineCycle(ii)    = 0;
%                 astMachineProcTimeOnMachine(mm).aReverseJobOnMachineId(ii)      = 0;
%                 astMachineProcTimeOnMachine(mm).aReverseRelTimeMachineCycle(ii) = 0;
%             end
%         end
%     end
    
    %% NoCOS constraint, General FSP
%     stGeneticBiFspAgent(aa).aiJobSeqInJspCfg = 1:nTotalForwardJobs; %% by default, actually there is no COS constraint
%     stGeneticBiFspAgent(aa).stJssProbStructConfig = stJobListInfoAgent(aa).stJssProbStructConfig;
    
%     stGeneticBiFspAgent(aa).stJssProbStructConfig.isCriticalOperateSeq = 0;
%     stGeneticBiFspAgent(aa).stJssProbStructConfig.isSemiCOS = 0;
%     stGeneticBiFspAgent(aa).stJssProbStructConfig.isFlexiCOS = 0;
    
%     stGeneticBiFspAgent(aa).astMachineProcTimeOnMachine = astMachineProcTimeOnMachine;
% end


stResAllocGenJspAgent.stGeneticCfgBiFsp = stResAllocGenJspAgent.stGeneticCfgBiFsp;
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

%stResAllocGenJspAgent.stSystemMasterConfig.iAlgoChoice = iDestAlgoChoice;

stResAllocGenJspAgentLoad = resalloc_load_glb_parameter(strResAllocGlbFileName);
