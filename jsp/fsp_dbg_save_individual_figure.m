function fsp_dbg_save_individual_figure(stBerthJobInfo, stIdFigure)

iPathStringList = strfind(stBerthJobInfo.strInputFilename, '\');
strPathName = stBerthJobInfo.strInputFilename(1:iPathStringList(end));

for qq = 1:1:stBerthJobInfo.iTotalAgent
    figure(stIdFigure.stFigureIndivAgent.aiFigureIdGroupByMachine(qq));
    strFilenameByMachine = sprintf('%sAgent-%d_ScheduleByMachine.jpg', strPathName, qq)
    saveas(gcf, strFilenameByMachine, 'jpg');
%     strFilenameByMachine = sprintf('%sAgent-%d_ScheduleByMachine.eps', strPathName, qq)
%     saveas(gcf, strFilenameByMachine, 'eps');

    figure(stIdFigure.stFigureIndivAgent.aiFigureIdGroupByJob(qq));
    strFilenameByJob = sprintf('%sAgent-%d_ScheduleByJob.jpg', strPathName, qq);
    saveas(gcf, strFilenameByJob, 'jpg');
%     strFilenameByJob = sprintf('%sAgent-%d_ScheduleByJob.eps', strPathName, qq);
%     saveas(gcf, strFilenameByJob, 'eps');
    
end
