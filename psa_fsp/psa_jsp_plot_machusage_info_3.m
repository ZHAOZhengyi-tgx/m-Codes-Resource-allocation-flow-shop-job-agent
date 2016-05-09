function psa_jsp_plot_machusage_info_3(container_sequence_jsp, astMachineUsageTimeInfo, figure_id)

fFactorHourPerSlot = container_sequence_jsp.fTimeUnit_Min/60;
figure(figure_id);
for mm = 1:1:container_sequence_jsp.iTotalMachine
    subplot(container_sequence_jsp.iTotalMachine, 1, mm);
    hold off;
    fMaxX = container_sequence_jsp.iMaxEndTime * fFactorHourPerSlot +1;
    axis([-1, fMaxX, -1, astMachineUsageTimeInfo(mm).iMaxUsage+1]);
    for jj = 1:1:astMachineUsageTimeInfo(mm).iTotalProcess * 2
        if jj == 1
            hold on;
            tt_1 = astMachineUsageTimeInfo(mm).aSortedTime(jj) * fFactorHourPerSlot;
            usage_1 = 0;
            usage_2 = astMachineUsageTimeInfo(mm).aMachineUsageAfterTime(jj);
            plot([tt_1, tt_1], [usage_1, usage_2]);
            
        else
            tt_1 = astMachineUsageTimeInfo(mm).aSortedTime(jj-1) * fFactorHourPerSlot;
            tt_2 = astMachineUsageTimeInfo(mm).aSortedTime(jj) * fFactorHourPerSlot;
            usage_1 = astMachineUsageTimeInfo(mm).aMachineUsageAfterTime(jj-1);
            usage_2 = astMachineUsageTimeInfo(mm).aMachineUsageAfterTime(jj);
            plot([tt_1, tt_2], [usage_1, usage_1]);
            plot([tt_2, tt_2], [usage_1, usage_2]);

        end
    end
    xlabel('Unit in Hour');
    strText = sprintf('Machine Usage for type %d machine', mm);
    title(strText);
end

