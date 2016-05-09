function stJspCfg = jsp_def_struct_cfg()
% 20071109  add GA Setting
% 20071115  Reordering, renaming
% 20080322  Add iReleaseTimeSlotGlobal

stJspCfg = struct('iTotalJob', [], ...
                        'iTotalMachine', [], ...
                        'fTimeUnit_Min', [], ...   %% a time unit for discretization, unit is minute
                        'iTotalTimeSlot', [], ...  %% an estimation of time span for all jobs to complete, used in IP formulation
                        'iOptRule', [], ...        %% Scheduling Generation Rules, maps to different algorithms
                        'iPlotFlag', [], ...       %% a flag for debugging
                        'iReleaseTimeSlotGlobal', [], ... %% for synchronization of multiple agents
                        'iTotalMachineNum', [], ... %%%%%%  array with len of iTotalMachine, single period problem, each kind of machine is available from beginning to
                        'stProcessPerJob', [], ...  %% array with len of iTotalJob
                        'iJobType', [], ...        %% for reverse flowjob, or forward flowjob
                        'jsp_process_machine', [], ...
                        'jsp_process_time', [], ...
                        'strJobListInputFilename', [], ...
                        'stJssProbStructConfig', [], ...  %% Job Shop Scheduling Structure Config, defined in jssp_load_prob_struct.m
                        'aJobWeight', [], ...
                        'stResourceConfig', [], ... %% multi-period structure for multiple period, multi-machine problem.
                        'stGASetting', [] ...  %% 20071109
                        );
