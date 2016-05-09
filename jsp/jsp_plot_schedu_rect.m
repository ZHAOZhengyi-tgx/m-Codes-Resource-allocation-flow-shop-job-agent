function jsp_plot_schedu_rect(stJspCfg, stJspSchedule, iFigId)

figure(iFigId)
clf(iFigId);
psa_jsp_plot_jobsolution(stJspSchedule, iFigId);
grid on
figure(iFigId+1)
clf(iFigId+1);
jsp_plot_jobsolution_2(stJspSchedule, iFigId+1);
grid on

if stJspCfg.iPlotFlag >= 3
    iPathStringList = strfind(stJspCfg.strJobListInputFilename, '\');
    strPathName = stJspCfg.strJobListInputFilename(1:iPathStringList(end));

    figure(iFigId)
    strFilenameFigure = sprintf('%s_1Bat.jpg', strcat(strPathName, 'ScheduleByMachine'));
    saveas(gcf, strFilenameFigure, 'jpg')
    if stJspCfg.iPlotFlag == 5
        strFilenameFigure = sprintf('%s_1Bat.eps', strcat(strPathName, 'ScheduleByMachine'));
        saveas(gcf, strFilenameFigure, 'eps')
    end
    figure(iFigId+1)
    strFilenameFigure = sprintf('%s_1Bat.jpg', strcat(strPathName, 'ScheduleByJob'));
    saveas(gcf, strFilenameFigure, 'jpg')
    if stJspCfg.iPlotFlag == 5
        strFilenameFigure = sprintf('%s_1Bat.eps', strcat(strPathName, 'ScheduleByJob'));
        saveas(gcf, strFilenameFigure, 'eps')
    end
end