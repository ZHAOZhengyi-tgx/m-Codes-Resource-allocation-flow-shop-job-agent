function mTypeNext = jsp_get_next_mach_type(stJspCfg, astQuingTask, astRelTimeMachType, astQuingTaskMachType, stJobSet)

    mTypeNext = 0;
    tSumProcessingTimeArrivalTime = 0;
    tSumProcessingTime = 0;
%    tSumMachineReleaseTime = zeros()
    for kk = 1:1:stJspCfg.iTotalMachine
        if astQuingTaskMachType(kk).iTotalTask >= 1
            tMeanMachineRelTime = mean(astRelTimeMachType(kk).tRelTimeAtOneMach);
            tSumProcessingTimeArrivalTime = 0;
            tSumProcessingTime = 0;
            for ii = 1:1:astQuingTaskMachType(kk).iTotalTask
                jJobId = astQuingTaskMachType(kk).iJobSet(ii);
                iProcId = astQuingTask(jJobId).iProcessToStart;
                if iProcId >= 2
                    tTaskArriveTime = stJobSet(jJobId).iProcessEndTime(iProcId - 1);
                else
                    tTaskArriveTime = 0;
                end
                tSumProcessingTimeArrivalTime = tSumProcessingTimeArrivalTime + astQuingTask(jJobId).ProcessTime + tTaskArriveTime;
                tSumProcessingTime = tSumProcessingTime + astQuingTask(jJobId).ProcessTime;
                if tTaskArriveTime > tMeanMachineRelTime
                    tMeanMachRelTimeAfterSche = tTaskArriveTime + astQuingTask(jJobId).ProcessTime;
                else
                    tMeanMachRelTimeAfterSche = tMeanMachineRelTime + astQuingTask(jJobId).ProcessTime;
                end
                if ii == 1
                    tExpectMachRelTime = tMeanMachRelTimeAfterSche;
                else
                    if tExpectMachRelTime > tMeanMachRelTimeAfterSche
                        tExpectMachRelTime = tMeanMachRelTimeAfterSche;
                    end
                end
            end
            
            tSumMachineReleaseTime = sum(astRelTimeMachType(kk).tRelTimeAtOneMach);
            if mTypeNext == 0
                mTypeNext = kk;
                tMinSumProcessingTimeArrivalTime = tSumProcessingTimeArrivalTime;
                tMaxSumProcessingTimeArrivalTime = tSumProcessingTimeArrivalTime;
                tMinSumMachineRelaeseTime = tSumMachineReleaseTime;
                tMaxSumMachineRelaeseTime = tSumMachineReleaseTime;
                tMinSumProcessingTime = tSumProcessingTime;
                tMinExpectMachRelTime = tExpectMachRelTime;
                tMaxExpectMachRelTime = tExpectMachRelTime;
            else
                if tMinExpectMachRelTime > tExpectMachRelTime % & kk ~= mm
                    mTypeNext = kk;
                    tMinExpectMachRelTime = tExpectMachRelTime;
                end
%                 if tMaxExpectMachRelTime < tExpectMachRelTime % & kk ~= mm
%                     mTypeNext = kk;
%                     tMaxExpectMachRelTime = tExpectMachRelTime;
%                 end
%                 if tMinSumProcessingTime > tSumProcessingTime % & kk ~= mm
%                     mTypeNext = kk;
%                     tMinSumProcessingTime = tSumProcessingTime;
%                 end
%                 if tMinSumProcessingTimeArrivalTime > tSumProcessingTimeArrivalTime % & kk ~= mm
%                     mTypeNext = kk;
%                     tMinSumProcessingTimeArrivalTime = tSumProcessingTimeArrivalTime;
%                 end
%                 if tMaxSumProcessingTimeArrivalTime < tSumProcessingTimeArrivalTime % & kk ~= mm
%                     mTypeNext = kk;
%                     tMaxSumProcessingTimeArrivalTime = tSumProcessingTimeArrivalTime;
%                 end
%                 if tMinSumMachineRelaeseTime > tSumMachineReleaseTime % & kk ~= mm
%                     mTypeNext = kk;
%                     tMinSumMachineRelaeseTime = tSumMachineReleaseTime;
%                 end
%                 if tMaxSumMachineRelaeseTime < tSumMachineReleaseTime % & kk ~= mm
%                     mTypeNext = kk;
%                     tMaxSumMachineRelaeseTime = tSumMachineReleaseTime;
%                 end
            end
        end
    end
