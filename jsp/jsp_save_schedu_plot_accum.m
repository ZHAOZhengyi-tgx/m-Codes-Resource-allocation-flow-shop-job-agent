function jsp_save_schedu_plot_accum(stJspCfg, iFigId)

if stJspCfg.iPlotFlag >= 3
    iPathStringList = strfind(stJspCfg.strJobListInputFilename, '\');
    strPathName = stJspCfg.strJobListInputFilename(1:iPathStringList(end));

    figure(iFigId)
    strFilenameFigure = sprintf('%s_AllBat.jpg', strcat(strPathName, 'ScheduleByMachine'));
    saveas(gcf, strFilenameFigure, 'jpg')
    if stJspCfg.iPlotFlag == 5
        strFilenameFigure = sprintf('%s_AllBat.eps', strcat(strPathName, 'ScheduleByMachine'));
        saveas(gcf, strFilenameFigure, 'eps')
    end

    figure(iFigId+1)
    strFilenameFigure = sprintf('%s_AllBat.jpg', strcat(strPathName, 'CircuJob'));
    saveas(gcf, strFilenameFigure, 'jpg')
    if stJspCfg.iPlotFlag == 5
        strFilenameFigure = sprintf('%s_AllBat.eps', strcat(strPathName, 'CircuJob'));
        saveas(gcf, strFilenameFigure, 'eps')
    end

    figure(iFigId+2)
    strFilenameFigure = sprintf('%s_AllBat.jpg', strcat(strPathName, 'CircuMach'));
    saveas(gcf, strFilenameFigure, 'jpg')
    if stJspCfg.iPlotFlag == 5
        strFilenameFigure = sprintf('%s_AllBat.eps', strcat(strPathName, 'CircuMach'));
        saveas(gcf, strFilenameFigure, 'eps')
    end
end
