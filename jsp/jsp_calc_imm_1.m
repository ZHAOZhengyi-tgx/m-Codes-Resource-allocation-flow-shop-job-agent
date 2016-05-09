function [jJobIdReg, iProcIdReg, tProcStartTime, idxTaskInQueMinEndTime] = jsp_calc_imm_1(atTaskArriveTime, atProcTimeAtTask, stQuingTaskMachType, astQuingTask, tRelTimeOneMach)
% IMM scenario-1, Iterative Minimization Micro-Model
% IN: 
% atTaskArriveTime, atProcTimeAtTask, stQuingTaskMachType,
% astQuingTask, aMachineSet.atMachRelTime(1)
% OUT:
% jJobIdReg, iProcIdReg, tProcStartTime, idxTaskInQueMinEndTime 

nTotalTaskInQue = stQuingTaskMachType.iTotalTask;
if nTotalTaskInQue == 1
    jJobIdReg = stQuingTaskMachType.iJobSet(1);
    iProcIdReg = astQuingTask(jJobIdReg).iProcessToStart;
    tProcStartTime = max([atTaskArriveTime, tRelTimeOneMach]);
    idxTaskInQueMinEndTime = 1;
else
    [tArriveTimeSortTask, idxTaskInQueFirstArriveFirst] = sort(atTaskArriveTime);
    for ii = 1:1:nTotalTaskInQue
        if ii == 1  %% Initialization
            fMinCompleteTime = max(tRelTimeOneMach, tArriveTimeSortTask(1)) + atProcTimeAtTask(idxTaskInQueFirstArriveFirst(1));
            jJobIdReg = stQuingTaskMachType.iJobSet(idxTaskInQueFirstArriveFirst(1));
            iProcIdReg = astQuingTask(jJobIdReg).iProcessToStart;
            tProcStartTime = max(tRelTimeOneMach, tArriveTimeSortTask(1));
            idxTaskInQueMinEndTime = idxTaskInQueFirstArriveFirst(1);
        else
            if tArriveTimeSortTask(ii) <= tRelTimeOneMach
                if fMinCompleteTime > tRelTimeOneMach + atProcTimeAtTask(idxTaskInQueFirstArriveFirst(ii))
                    fMinCompleteTime = tRelTimeOneMach + atProcTimeAtTask(idxTaskInQueFirstArriveFirst(ii));
                    jJobIdReg = stQuingTaskMachType.iJobSet(idxTaskInQueFirstArriveFirst(ii));
                    iProcIdReg = astQuingTask(jJobIdReg).iProcessToStart;
                    tProcStartTime = tRelTimeOneMach;
                    idxTaskInQueMinEndTime = idxTaskInQueFirstArriveFirst(ii);
                end
            else
                if fMinCompleteTime > tArriveTimeSortTask(ii) + atProcTimeAtTask(idxTaskInQueFirstArriveFirst(ii));
                    fMinCompleteTime = tArriveTimeSortTask(ii) + atProcTimeAtTask(idxTaskInQueFirstArriveFirst(ii));
                    jJobIdReg = stQuingTaskMachType.iJobSet(idxTaskInQueFirstArriveFirst(ii));
                    iProcIdReg = astQuingTask(jJobIdReg).iProcessToStart;
                    tProcStartTime = tArriveTimeSortTask(ii);
                    idxTaskInQueMinEndTime = idxTaskInQueFirstArriveFirst(ii);
                end
            end
        end
    end
end
