function add_path_fsp_jsp(strZyiPath)
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

addpath(strcat(strZyiPath, 'common'))

%% schedule wait-jsp-fsp, fsp-bifsp-nowait
addpath(strcat(strZyiPath, 'common\ga_fsp'))
addpath(strcat(strZyiPath, 'common\jsp'))
addpath(strcat(strZyiPath, 'common\jsp_load_cfg'))
addpath(strcat(strZyiPath, 'common\fsp_sch_gen'))
addpath(strcat(strZyiPath, 'common\load_cfg'))
addpath(strcat(strZyiPath, 'common\chk_srch'))

%% res-allocation related
addpath(strcat(strZyiPath, 'common\price_adj'))
addpath(strcat(strZyiPath, 'common\bidgen_psa'))
addpath(strcat(strZyiPath, 'common\bidgen'))
addpath(strcat(strZyiPath, 'common\calc_lut'))
addpath(strcat(strZyiPath, 'common\time_date'))

%% IP related: Sedumi, MOSEK, CPLEX
addpath(strcat(strZyiPath, 'common\fsp_ip_mosek'))
addpath(strcat(strZyiPath, 'common\fsp_ip_lag_mosek'))

%% CPLEX related
addpath(strcat(strZyiPath, 'cplex\Convert'));    

%% EXCEL related
addpath(strcat(strZyiPath, 'common\xls'))

%% batch testing related
addpath(strcat(strZyiPath, 'psa_jsp\batchtest'));
addpath(strcat(strZyiPath, 'fsp_jsp_app\batchtest'));

%% port-related, bi-fsp-nowait-cos
addpath(strcat(strZyiPath, 'common\psa_fsp'))
addpath(strcat(strZyiPath, 'common\psa_fsp\flowshop'))
addpath(strcat(strZyiPath, 'common\psa_fsp\psa_load_cfg'))
