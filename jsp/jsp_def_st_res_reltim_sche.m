function astRelTimeMachType = jsp_def_st_res_reltim_sche(stJspSchedule)
% 
% get default value of machine (resource) release time by schedule

stResourceConfig = stJspSchedule.stResourceConfig;
iTotalMachine = stJspSchedule.iTotalMachine;

for mm = 1:1:iTotalMachine
    nMachCapOnePer = stResourceConfig.iaMachCapOnePer(mm);
    astRelTimeMachType(mm).nTotalAvailMach = nMachCapOnePer;
    for mi = 1:1:nMachCapOnePer
        astRelTimeMachType(mm).tRelTimeAtOneMach(mi) = stJspSchedule.iMaxEndTime;
    end
end

