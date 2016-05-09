function psa_jsp_plot_machusage_info_2(stJspSchedule, astMachineUsageTimeInfo, figure_id, jobshop_config, stResourceConfig)


figure(figure_id);
for mm = 1:1:stJspSchedule.iTotalMachine
    subplot(stJspSchedule.iTotalMachine, 1, mm);
    hold off;
    nMaxSupplyDemand = max(stResourceConfig.stMachineConfig(mm).afMaCapAtTimePoint);
    if(nMaxSupplyDemand < astMachineUsageTimeInfo(mm).iMaxUsage)
        nMaxSupplyDemand = astMachineUsageTimeInfo(mm).iMaxUsage;
    end
%    [-1, stJspSchedule.iMaxEndTime+1, -1, (nMaxSupplyDemand + 1)]
    axis([-1, stJspSchedule.iMaxEndTime+1, -1, (nMaxSupplyDemand +1)]); % axis([-1, stJspSchedule.iMaxEndTime+1, -1, nMaxSupplyDemand +1]);
    for jj = 1:1:astMachineUsageTimeInfo(mm).iTotalProcess * 2
        if jj == 1
            hold on;
            tt_1 = astMachineUsageTimeInfo(mm).aSortedTime(jj);
            usage_1 = 0;
            usage_2 = astMachineUsageTimeInfo(mm).aMachineUsageAfterTime(jj);
            plot([tt_1, tt_1], [usage_1, usage_2]);
            
        else
            tt_1 = astMachineUsageTimeInfo(mm).aSortedTime(jj-1);
            tt_2 = astMachineUsageTimeInfo(mm).aSortedTime(jj);
            usage_1 = astMachineUsageTimeInfo(mm).aMachineUsageAfterTime(jj-1);
            usage_2 = astMachineUsageTimeInfo(mm).aMachineUsageAfterTime(jj);
            plot([tt_1, tt_2], [usage_1, usage_1]);
            plot([tt_2, tt_2], [usage_1, usage_2]);

        end
    end
    if stResourceConfig.stMachineConfig(mm).iNumPointTimeCap == 1
        h = plot([0, stJspSchedule.iMaxEndTime], ...
             [stResourceConfig.stMachineConfig(mm).afMaCapAtTimePoint, stResourceConfig.stMachineConfig(mm).afMaCapAtTimePoint]);
        v = get(h);
        aColor = [1 0 0];
        set(h, 'Color', aColor);
             
    else
	    for jj = 1:1:stResourceConfig.stMachineConfig(mm).iNumPointTimeCap
	        if jj == 1
	            tt_1 = stResourceConfig.stMachineConfig(mm).afTimePointAtCap(jj);
	            cap_1 = 0;
	            cap_2 = stResourceConfig.stMachineConfig(mm).afMaCapAtTimePoint(jj);
	            h = plot([tt_1, tt_1], [cap_1, cap_2]);
		        v = get(h);
		        aColor = [1 0 0];
		        set(h, 'Color', aColor);
	            
	        else
	            tt_1 = stResourceConfig.stMachineConfig(mm).afTimePointAtCap(jj-1);
	            tt_2 = stResourceConfig.stMachineConfig(mm).afTimePointAtCap(jj);
	            cap_1 = stResourceConfig.stMachineConfig(mm).afMaCapAtTimePoint(jj-1);
	            cap_2 = stResourceConfig.stMachineConfig(mm).afMaCapAtTimePoint(jj);
	            h = plot([tt_1, tt_2], [cap_1, cap_1]);
		        v = get(h);
		        aColor = [1 0 0];
		        set(h, 'Color', aColor);
	            h = plot([tt_2, tt_2], [cap_1, cap_2]);
		        v = get(h);
		        aColor = [1 0 0];
		        set(h, 'Color', aColor);
	
	        end
	    end
	end
    strText = sprintf('Machine Usage for type %d machine', mm);
    title(strText);
end

