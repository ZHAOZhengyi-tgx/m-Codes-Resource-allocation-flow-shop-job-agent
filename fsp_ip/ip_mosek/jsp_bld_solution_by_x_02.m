function [stJspSchedule] = jsp_bld_solution_by_x_02(x_ip, stJspCfg)
%
%
% History
% YYYYMMDD Notes
% 20070626 to be more robust, could handle some non-zero small variables.
% from CSV input data, zzy
% 20070629 Add iTotalMachineNum into solution, zzy
% 20070114 Default Value of stJspSchedule

% 20070114
[stJspSchedule] = jsp_constr_sche_struct_by_cfg(stJspCfg);
global epsilon;  % eps = 1e-6; % 20070626
if isempty(epsilon)
    jsp_glb_define();
end

curr_row = 0;
iTotalTimeSlot = stJspCfg.iTotalTimeSlot;
for ii = 1:1:stJspCfg.iTotalJob
    for jj = 1:1:stJspCfg.stProcessPerJob(ii)
        stJobTime(ii).stProcessTime(jj).TimeVariable = x_ip(curr_row+1: curr_row + iTotalTimeSlot);
        curr_row = curr_row + iTotalTimeSlot;
        tt = 1;
        % to avoid numerical errors, ever happens in loading CSV files. % 20070626
%        while tt <= stJspCfg.iTotalTimeSlot & stJobTime(ii).stProcessTime(jj).TimeVariable(tt) == 0
        while tt <= stJspCfg.iTotalTimeSlot & stJobTime(ii).stProcessTime(jj).TimeVariable(tt) <= epsilon
            tt = tt + 1;
        end
        %%%% error case, when iTotalTimeSlot cannot contain all jobs
        if stJobTime(ii).stProcessTime(jj).TimeVariable(stJspCfg.iTotalTimeSlot) == 0
%            ii_jj = [ii, jj]
            stJspSchedule.stJobSet(ii).iProcessStartTime(jj) = stJspSchedule.stJobSet(ii).iProcessEndTime(jj-1);
            stJspSchedule.stJobSet(ii).iProcessEndTime(jj) = stJspSchedule.stJobSet(ii).iProcessEndTime(jj-1) ...
                + stJspCfg.jsp_process_time(ii).iProcessTime(jj);
            stJspSchedule.stJobSet(ii).fProcessStartTime(jj) = stJspSchedule.stJobSet(ii).iProcessStartTime(jj);
            stJspSchedule.stJobSet(ii).fProcessEndTime(jj) = stJspSchedule.stJobSet(ii).iProcessEndTime(jj);
            stJspSchedule.stJobSet(ii).iProcessMachine(jj) = stJspCfg.jsp_process_machine(ii).iProcessMachine(jj);
        else  %%% normal case
            stJspSchedule.stJobSet(ii).iProcessStartTime(jj) = tt - 1;
            stJspSchedule.stJobSet(ii).iProcessEndTime(jj) = tt -1 + stJspCfg.jsp_process_time(ii).iProcessTime(jj);
            stJspSchedule.stJobSet(ii).fProcessStartTime(jj) = stJspSchedule.stJobSet(ii).iProcessStartTime(jj);
            stJspSchedule.stJobSet(ii).fProcessEndTime(jj) = stJspSchedule.stJobSet(ii).iProcessEndTime(jj);
            stJspSchedule.stJobSet(ii).iProcessMachine(jj) = stJspCfg.jsp_process_machine(ii).iProcessMachine(jj);
        end
    end
end
stJspSchedule.stJobTime = stJobTime;
stJspSchedule.x_ip = x_ip;

fMaxEndTime = stJspSchedule.stJobSet(1).fProcessEndTime(stJspSchedule(1).stProcessPerJob(1));
for ii = 2:1:stJspSchedule.iTotalJob
    if fMaxEndTime < stJspSchedule.stJobSet(ii).fProcessEndTime(stJspSchedule.stProcessPerJob(ii))
        fMaxEndTime = stJspSchedule.stJobSet(ii).fProcessEndTime(stJspSchedule.stProcessPerJob(ii));
    end
end
stJspSchedule.MaxEndTime = fMaxEndTime;
stJspSchedule.iMaxEndTime = ceil(fMaxEndTime);
stJspSchedule.fTimeUnit_Min = stJspCfg.fTimeUnit_Min;
