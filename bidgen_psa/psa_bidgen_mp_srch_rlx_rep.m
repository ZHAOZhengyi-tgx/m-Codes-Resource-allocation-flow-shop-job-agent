function [stAgent_Solution] = psa_bidgen_mp_srch_rlx_rep(stInputResAlloc)
%
%
% adaptive from psa_bidgen_multiperiod_srch.m
% use GenSch3
%     decending order of price
%     local search by gradient, exit if local minimum is found
%
% 20070921  Add full combo search


%%%% Local Constant Parameter
iQuayCrane_id                = stInputResAlloc.iQuayCrane_id               ;
stBerthJobInfo               = stInputResAlloc.stBerthJobInfo              ;
%iFlagSorting                 = stInputResAlloc.iFlagSorting                ;
%iMaxIter                     = stInputResAlloc.iMaxIter_BidGenOpt          ;
%iFlag_RunGenSch2             = stInputResAlloc.iFlag_RunGenSch2            ;
%iMaxPrimeMoverUsageByGenSch0 = stInputResAlloc.iMaxPrimeMoverUsageByGenSch0;
%iMaxYardCraneUsageByGenSch0  = stInputResAlloc.iMaxYardCraneUsageByGenSch0 ;
%stResourceConfigGenSch0      = stInputResAlloc.stResourceConfigGenSch0_ii  ;
%stResourceConfigSrchSinglePeriod = stInputResAlloc.stResourceConfigSrchSinglePeriod_ii;

%%%% Local Volatile Structure Template
%stJobListInfoAgent           = stInputResAlloc.stJobListInfoAgent_ii            ;

stInputResAllocAgent.iAgentId_dbg      = stInputResAlloc.iQuayCrane_id               ;
stInputResAllocAgent.iFlagSorting       = stInputResAlloc.iFlagSorting                ;
stInputResAllocAgent.stBerthJobInfo     = stInputResAlloc.stBerthJobInfo              ;
stInputResAllocAgent.iMaxIter_BidGenOpt = stInputResAlloc.iMaxIter_BidGenOpt      ;
stInputResAllocAgent.iFlag_RunGenSch2   = stInputResAlloc.iFlag_RunGenSch2            ;
stInputResAllocAgent.stResourceConfigGenSch0 = stInputResAlloc.stResourceConfigGenSch0_ii  ;
stInputResAllocAgent.stResourceConfigSrchSinglePeriod = stInputResAlloc.stResourceConfigSrchSinglePeriod_ii;
stInputResAllocAgent.stAgentJobInfo = stBerthJobInfo.stAgentJobInfo(iQuayCrane_id);
stInputResAllocAgent.stJobListInfoAgent    = stBerthJobInfo.stJobListInfoAgent(iQuayCrane_id);

if isfield(stInputResAlloc,'stAgent_Solution')
    stInputResAllocAgent.stAgent_Solution = stInputResAlloc.stAgent_Solution;
end

if stInputResAllocAgent.stBerthJobInfo.iAlgoChoice == 18
    [stAgent_Solution] = bidgen_fsp_agent_ful_combo(stInputResAllocAgent);   % 20070921
else
    [stAgent_Solution] = bidgen_fsp_port_agent(stInputResAllocAgent);
end

