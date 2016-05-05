function [container_jsp_schedule, container_jsp_discha_schedule, container_jsp_load_schedule] = fsp_constru_psa_sche_struct(stQuayCraneJobList)

% History
% YYYYMMDD  Notes
% 20071023  Initialization of StartTime EndTime,
%

%%% Prototype of Output
container_jsp_schedule.iTotalJob = [];
container_jsp_schedule.iTotalMachine = [];
container_jsp_schedule.iTotalMachineNum = [];
container_jsp_schedule.stProcessPerJob = [];
container_jsp_schedule.stJobSet = ...
  struct('fProcessStartTime', [], 'fProcessEndTime', [], 'iProcessStartTime', [], 'iProcessEndTime', [], 'iProcessMachine', [], 'iProcessMachineId', []);
container_jsp_schedule.iMaxEndTime = [];

container_jsp_discha_schedule.iTotalJob = [];
container_jsp_discha_schedule.iTotalMachine = [];
container_jsp_discha_schedule.iTotalMachineNum = [];
container_jsp_discha_schedule.stProcessPerJob = [];
container_jsp_discha_schedule.stJobSet = ...
  struct('fProcessStartTime', [], 'fProcessEndTime', [], 'iProcessStartTime', [], 'iProcessEndTime', [], 'iProcessMachine', [], 'iProcessMachineId', []);
container_jsp_discha_schedule.iMaxEndTime = [];

container_jsp_load_schedule.iTotalJob = [];
container_jsp_load_schedule.iTotalMachine = [];
container_jsp_load_schedule.iTotalMachineNum = [];
container_jsp_load_schedule.stProcessPerJob = [];
container_jsp_load_schedule.stJobSet = ...
  struct('fProcessStartTime', [], 'fProcessEndTime', [], 'iProcessStartTime', [], 'iProcessEndTime', [], 'iProcessMachine', [], 'iProcessMachineId', []);
container_jsp_load_schedule.iMaxEndTime = [];

%%%%

if isfield(stQuayCraneJobList, 'stResourceConfig')
    stResourceConfig = stQuayCraneJobList.stResourceConfig;
    nTotalPrimeMoverCommonPoolAllPeriod_ByCfg = max(stResourceConfig.stMachineConfig(2).afMaCapAtTimePoint);
    nTotalYardCraneCommonPoolAllPeriod_ByCfg = max(stResourceConfig.stMachineConfig(3).afMaCapAtTimePoint);
    nTotalPrimeMoverCommonPoolAllPeriod_Const = stQuayCraneJobList.MaxVirtualPrimeMover;
    nTotalYardCraneCommonPoolAllPeriod_Const = stQuayCraneJobList.MaxVirtualYardCrane;
    if nTotalPrimeMoverCommonPoolAllPeriod_ByCfg > nTotalPrimeMoverCommonPoolAllPeriod_Const
        nTotalPrimeMoverCommonPoolAllPeriod = nTotalPrimeMoverCommonPoolAllPeriod_ByCfg;
    else
        nTotalPrimeMoverCommonPoolAllPeriod = nTotalPrimeMoverCommonPoolAllPeriod_Const;
    end
    if nTotalYardCraneCommonPoolAllPeriod_ByCfg > nTotalYardCraneCommonPoolAllPeriod_Const
        nTotalYardCraneCommonPoolAllPeriod = nTotalYardCraneCommonPoolAllPeriod_ByCfg;
    else
        nTotalYardCraneCommonPoolAllPeriod = nTotalYardCraneCommonPoolAllPeriod_Const;
    end
else
    nTotalPrimeMoverCommonPoolAllPeriod_Const = stQuayCraneJobList.MaxVirtualPrimeMover;
    nTotalYardCraneCommonPoolAllPeriod_Const = stQuayCraneJobList.MaxVirtualYardCrane;
end


TotalContainer_Discharge = stQuayCraneJobList.TotalContainer_Discharge;
TotalContainer_Load = stQuayCraneJobList.TotalContainer_Load;

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%% Discharge case
container_jsp_discha_schedule.iTotalJob = TotalContainer_Discharge;
container_jsp_discha_schedule.iTotalMachine = 3;
container_jsp_discha_schedule.iTotalMachineNum = [1, nTotalPrimeMoverCommonPoolAllPeriod, nTotalYardCraneCommonPoolAllPeriod];
container_jsp_discha_schedule.stProcessPerJob = 3 * ones(1,TotalContainer_Discharge);

%%%%%% Loading case
container_jsp_load_schedule.iTotalJob = TotalContainer_Load;
container_jsp_load_schedule.iTotalMachine = 3;
container_jsp_load_schedule.iTotalMachineNum = [1, nTotalPrimeMoverCommonPoolAllPeriod, nTotalYardCraneCommonPoolAllPeriod];
container_jsp_load_schedule.stProcessPerJob = 3 * ones(1,TotalContainer_Load);

%%%%%% jsp format
container_jsp_schedule.iTotalJob = container_jsp_discha_schedule.iTotalJob + container_jsp_load_schedule.iTotalJob;
container_jsp_schedule.iTotalMachine = 3;
container_jsp_schedule.iTotalMachineNum = [1, nTotalPrimeMoverCommonPoolAllPeriod, nTotalYardCraneCommonPoolAllPeriod];
container_jsp_schedule.stProcessPerJob = 3 * ones(1,TotalContainer_Load + TotalContainer_Discharge);

%%%%%% Resource Configuration, a constant structure
container_jsp_schedule.stResourceConfig = stQuayCraneJobList.stResourceConfig;
container_jsp_schedule.fTimeUnit_Min    = stQuayCraneJobList.fTimeUnit_Min;

for ii = 1:1:container_jsp_schedule.iTotalJob
    if ii <= TotalContainer_Discharge
        container_jsp_schedule.stJobSet(ii).iProcessMachine(1) = 1;
        container_jsp_schedule.stJobSet(ii).iProcessMachine(2) = 2;
        container_jsp_schedule.stJobSet(ii).iProcessMachine(3) = 3;
    else
        container_jsp_schedule.stJobSet(ii).iProcessMachine(1) = 3;
        container_jsp_schedule.stJobSet(ii).iProcessMachine(2) = 2;
        container_jsp_schedule.stJobSet(ii).iProcessMachine(3) = 1;
    end
    % 20071023
    container_jsp_schedule.stJobSet(ii).iProcessStartTime  = zeros(container_jsp_schedule.stProcessPerJob(ii), 1);
    container_jsp_schedule.stJobSet(ii).iProcessEndTime    = zeros(container_jsp_schedule.stProcessPerJob(ii), 1);
    container_jsp_schedule.stJobSet(ii).fProcessStartTime  = zeros(container_jsp_schedule.stProcessPerJob(ii), 1);
    container_jsp_schedule.stJobSet(ii).fProcessEndTime    = zeros(container_jsp_schedule.stProcessPerJob(ii), 1);
    
end
