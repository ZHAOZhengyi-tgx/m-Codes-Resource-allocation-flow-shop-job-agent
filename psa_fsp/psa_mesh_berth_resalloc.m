function psa_mesh_berth_resalloc(stAgent_Solution)
% port of Singapore Authority, mesh-plot berth resource allocation
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%  
%
%The MIT License (MIT)
%
%Copyright (c) 2016 ZHAOZhengyi-tgx
%
%Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the "Software"), to deal in the Software without restriction, including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions:
%
%The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.
%
%THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%
% Module: Solution for Resource Allocation among Scheduling Agents 
% Template for Problem Input
% OUTPUT from the solver: schedule for each job's process, dispatching for each machine
% During this whole document, % is for line commenting, which means any line starting with a % will not be taken into parsing.
%
% all right reserved (c)2016
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% all right reserved, @2016, Sg.LongRenE@gmail.com

iTotalAgent = length(stAgent_Solution);
for ii = 1:1:iTotalAgent
    
    iCasePMYC = length(stAgent_Solution(ii).stCostAtAgent.stCostList);
    stCostAtAgent = stAgent_Solution(ii).stCostAtAgent;
    
    iFigureId = ii*10+5;
    psa_fsp_mesh_pm_yc(iFigureId, stCostAtAgent, stCostAtAgent.afTotalCost);
    title(strcat('Total Cost Mesh, Agent #',num2str(ii)));

    iFigureId = ii*10+5+1;
    for iCase = 1:1:iCasePMYC
        afDelayPenalty(iCase) = stCostAtAgent.stCostList(iCase).fDelayPanelty;
    end
    psa_fsp_mesh_pm_yc(iFigureId, stCostAtAgent, afDelayPenalty);
    title(strcat('Penalty Mesh, Agent #',num2str(ii)));

    iFigureId = ii*10+5+2;
    for iCase = 1:1:iCasePMYC
        aiMakeSpan(iCase) = stCostAtAgent.stCostList(iCase).tMakeSpan_hour;
    end
    psa_fsp_mesh_pm_yc(iFigureId, stCostAtAgent, aiMakeSpan);
    title(strcat('MakeSpan Mesh, Agent #',num2str(ii)));
    zlabel('in Hour');

    iFigureId = ii*10+5+3;
    for iCase = 1:1:iCasePMYC
        aiResourceCost(iCase) = stCostAtAgent.stCostList(iCase).fCostPM + stCostAtAgent.stCostList(iCase).fCostYC;
    end
    psa_fsp_mesh_pm_yc(iFigureId, stCostAtAgent, aiResourceCost);
    title(strcat('Resource Cost(PM, YC) Mesh, Agent #',num2str(ii)));
    zlabel('in Hour');

end