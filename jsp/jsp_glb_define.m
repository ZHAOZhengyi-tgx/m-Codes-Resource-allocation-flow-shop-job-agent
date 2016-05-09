function jsp_glb_define()
% Job shop problem, global parameter definition
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

%%%%%%%%%%%%%             definition for rounding error
global epsilon;
global tEpsilonTime;
global epsilon_time;
global epsilon_slot;

%% for building the machine usage in continuous time model
epsilon = 1e-6;

%% for building bid by config
epsilon_time = 0.001 / 60/24;
%% for building config by schedule
epsilon_slot = 5e-7;

%% for machine task assignment in jsp(open shop, flow shop) mm(Multi-machine) sp(Single-period) 
tEpsilonTime = 1e-5;


%%%%%%%%%%%%%%   definition for machine context

global DEF_MAX_NUM_MACHINE_TYPE;

DEF_MAX_NUM_MACHINE_TYPE = 127;

%%%%%%%%%%%%%%  definition for maximum total period
global DEF_MAXIMUM_LENGTH_PRICE_LIST;

DEF_MAXIMUM_LENGTH_PRICE_LIST = 127;

%%%%%%%%%%%%%%   definition of agent's objective functions
global OBJ_MINIMIZE_MAKESPAN;                 
global OBJ_MINIMIZE_SUM_TARDINESS;
global OBJ_MINIMIZE_SUM_TARD_MAKESPAN;        
OBJ_MINIMIZE_MAKESPAN = 1;
OBJ_MINIMIZE_SUM_TARDINESS = 2;
OBJ_MINIMIZE_SUM_TARD_MAKESPAN = 3;
OBJ_MINIMIZE_SUM_TARD_MAKESPAN_RES = 4;


%%%%%%%%%%%%%%  constant for comment line
global CHAR_COMMENT_LINE;
CHAR_COMMENT_LINE = '%';

%%%% definition of IP solver option
global IP_SOLVER_OPT_MSK;
global IP_SOLVER_OPT_SEDUMI;
global IP_SOLVER_OPT_CPLEX;

IP_SOLVER_OPT_MSK = 1;
IP_SOLVER_OPT_SEDUMI = 2;
IP_SOLVER_OPT_CPLEX = 3;

