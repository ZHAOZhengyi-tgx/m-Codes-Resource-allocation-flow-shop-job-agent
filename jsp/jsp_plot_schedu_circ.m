function jsp_plot_schedu_circ(stJspCfg, stJspSchedule, iFigId)


figure(iFigId+2)
clf(iFigId+2);
jsp_plot_schede_job_circu(stJspSchedule, iFigId +2);
figure(iFigId+3)
clf(iFigId+3);
jsp_plot_schedu_mach_circu(stJspSchedule, iFigId +3);
if stJspCfg.iPlotFlag >= 3
    iPathStringList = strfind(stJspCfg.strJobListInputFilename, '\');
    strPathName = stJspCfg.strJobListInputFilename(1:iPathStringList(end));

    figure(iFigId+2)
    strFilenameFigure = sprintf('%s_1Bat.jpg', strcat(strPathName, 'CircuJob'));
    saveas(gcf, strFilenameFigure, 'jpg')
    if stJspCfg.iPlotFlag == 5
        strFilenameFigure = sprintf('%s_1Bat.eps', strcat(strPathName, 'CircuJob'));
        saveas(gcf, strFilenameFigure, 'eps')
    end

    figure(iFigId+3)
    strFilenameFigure = sprintf('%s_1Bat.jpg', strcat(strPathName, 'CircuMach'));
    saveas(gcf, strFilenameFigure, 'jpg')
    if stJspCfg.iPlotFlag == 5
        strFilenameFigure = sprintf('%s_1Bat.eps', strcat(strPathName, 'CircuMach'));
        saveas(gcf, strFilenameFigure, 'eps')
    end
end
