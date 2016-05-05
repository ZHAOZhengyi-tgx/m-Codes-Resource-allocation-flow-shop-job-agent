function ga_init_seed(stJspCfg)
% genetic algorithm initializating the seed
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

stGASetting = stJspCfg.stGASetting;

iListPosnDot = strfind(stJspCfg.strJobListInputFilename, '.');
if isempty(iListPosnDot)
    strFilenamePrefix = stJspCfg.strJobListInputFilename;
else
    strFilenamePrefix = stJspCfg.strJobListInputFilename(1:(iListPosnDot(end)-1));
end
strFilefullname = sprintf('%s_fspgard.txt', strFilenamePrefix);

%% initialize the random generator state
fRandState = 0; % by default
if stGASetting.iFlagInitRandGeneratorSeed == 0 % by default
    fRandState = 0;
elseif stGASetting.iFlagInitRandGeneratorSeed == 1
    fptr = fopen(strFilefullname, 'r');
    if fptr == 4  %% successfully open
        fRandState = fscanf(fptr, 'GA_RAND_GENERATOR_STATE = %e');
        strText = sprintf('Load Rand Generator State: %e', fRandState);
        disp(strText);
        fclose(fptr);
    end
elseif stGASetting.iFlagInitRandGeneratorSeed == -1
    fRandState = sum(100*clock);
end
rand('state', fRandState);

if stGASetting.iFlagInitRandGeneratorSeed == 0  ...
    || stGASetting.iFlagInitRandGeneratorSeed == -1
    fptr = fopen(strFilefullname, 'w');
    fprintf(fptr, 'GA_RAND_GENERATOR_STATE = %e', fRandState);
    strText = sprintf('Save Rand Generator State: %e', fRandState);
    disp(strText);
    fclose(fptr);
end
