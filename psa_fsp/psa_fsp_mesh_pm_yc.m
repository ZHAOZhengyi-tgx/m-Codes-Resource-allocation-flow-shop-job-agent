function psa_fsp_mesh_pm_yc(iFigureId, stCostAtAgent, Z_array)
% port of Singapore Authority flow-shop-problem mesh PM and YC
% PM: Prime mover, all vehicles
% YC: Yard crane
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

    
    xPM = min(stCostAtAgent.aiNumPM): 1:max(stCostAtAgent.aiNumPM);
    yYC = min(stCostAtAgent.aiNumYC): 1:max(stCostAtAgent.aiNumYC);
%    iCase = 1;
    Z_TotalMatrix = zeros(length(xPM), length(yYC));
    for ii = 1:1:length(stCostAtAgent.aiNumPM)
        Z_TotalMatrix(stCostAtAgent.aiNumPM(ii), stCostAtAgent.aiNumYC(ii)) = Z_array(ii);
    end
    Z_MeshMatrix = Z_TotalMatrix(xPM, yYC);

    sizeMeshMatrix = size(Z_MeshMatrix);
    sizeTotalMatrix = size(Z_TotalMatrix);
    lenX = length(xPM);
    lenY = length(yYC);
disp(['size Mesh Matrix: ', num2str(sizeMeshMatrix), '; size Total Matrix: ', num2str(sizeTotalMatrix), '; length xPM: ', num2str(lenX), '; length yYC', lenY]);
%     for pp = 1:1:length(xPM)
%         for yy = 1:1:length(yYC)
%             Z_TotalMatrix(yy, pp) = Z_array(iCase);
%             iCase = iCase + 1;
%         end
%     end
    figure(iFigureId)
%    Z_TotalMatrix
    if length(xPM) >= 2 & length(yYC) >= 2
        mesh(yYC, xPM,Z_MeshMatrix);
        view(3);
        hold on;
        xlabel('Num. of PM');
        ylabel('Num. of YC');
    end
