function [iMaxEndTime] = psa_jsp_plot_jobsolution_2(jobshop_solution, figure_id)
% plot the job scheduling, 
%    (1) job grouping by Y-axis,
%    (2) process grouping by colour, 
%    (3) Yard Cranes Operation is integrated in PrimeMover
% jobshop_solution: a struct with following variables
%    iTotalJob:  Total number of jobs
%    iTotalMachine:    total number of machine types
%    iTotalMachineNum: total number of machines in each type, an array with length of iTotalMachine
%    stProcessPerJob:  total number of processes per each job
%    iMaxEndTime:      Final completion time for all processes of all jobs
%    stJobSet: 
% jobshop_solution.stJobSet: an array (length of jobshop_solution.iTotalJob )of struct with following variables
%    iProcessStartTime: start time for the process of the job, an array with length as jobshop_solution.stProcessPerJob
%    iProcessEndTime:   end time for the process of the job, an array with length as jobshop_solution.stProcessPerJob
%    iProcessMachine:   MachineType for the process of the job, an array with length as jobshop_solution.stProcessPerJob
%    iProcessMachineId: MachineId for the process of the job, an array with length as jobshop_solution.stProcessPerJob
%    fProcessStartTime: floating point start time for the process of the job, an array with length as jobshop_solution.stProcessPerJob
%    fProcessEndTime:   floating point end time for the process of the job, an array with length as jobshop_solution.stProcessPerJob
%
% 20080620 Add for simplicity port scheme

iFlagSimplePortScheme = 0;

figure(figure_id);
iMaxEndTime = jobshop_solution.iMaxEndTime;
iFlagHoldOnce = 1;

iMaxAxisX = round(double(iMaxEndTime) + 2);
iMaxAxisY = round(double(jobshop_solution.iTotalJob) + 2);
axis([-1, iMaxAxisX , 0, iMaxAxisY]);
grid off;

for ii = 1:1:double(jobshop_solution.iTotalJob)
    for jj = 1:1:double(jobshop_solution.stProcessPerJob(ii))
        x1 = double(jobshop_solution.stJobSet(ii).iProcessStartTime(jj));
        x2 = double(jobshop_solution.stJobSet(ii).iProcessEndTime(jj));
%        iMachType = jobshop_solution.stJobSet(ii).iProcessMachine(jj);
        fWidthY = 0.8;
        y1 = ii;
        y2 = y1 + fWidthY;
      
        h = plot([x1, x2], [y1, y1], [x1, x2], [y2, y2], [x1, x1], [y1, y2], [x2, x2], [y1, y2]);
        v = get(h);

        mType = jobshop_solution.stJobSet(ii).iProcessMachine(jj);
        if mType == 1
            aColor = [1 0 0];
        elseif mType == 2
            aColor = [0 0 0];
        elseif mType == 3
            aColor = [0 0 1];
        else
            aColor = [0 0 0];
            rgbStep3 = ceil(max(jobshop_solution.stProcessPerJob(ii)) /3);
            iMachType = jobshop_solution.stJobSet(ii).iProcessMachine(jj);
    %        rgbAxis = ceil(jj/rgbStep3);
            rgbAxis = ceil(iMachType/rgbStep3);
            rgbColorNumber = (rem(iMachType,rgbStep3)+1)/rgbStep3;
            aColor(rgbAxis) = rgbColorNumber;
        end
        set(h, 'Color', aColor);
        fill([x1, x2, x2, x1], [y1, y1, y2, y2], aColor)

        if iFlagHoldOnce == 1
            hold on;
            iFlagHoldOnce = 0;
        end
        
        if iFlagSimplePortScheme == 1
            strText_NameM2 = sprintf('PM');
            strText_NameM3 = sprintf('YC');

        else
%            strText_NameM2 = sprintf('M2');
%            strText_NameM3 = sprintf('M3');
            if jobshop_solution.iTotalJob <= 40 % & iMachType <= 3
                if jobshop_solution.stJobSet(ii).iProcessMachine(jj) == 2
                    strText_NameM2 = sprintf('M2-%d', jobshop_solution.stJobSet(ii).iProcessMachineId(jj));
%                    text(x1, (y1 + y2)/2, strText_NameM2);
                elseif jobshop_solution.stJobSet(ii).iProcessMachine(jj) == 3
                    strText_NameM3 = sprintf('M3-%d', jobshop_solution.stJobSet(ii).iProcessMachineId(jj));
%                    text(x1, (y1 + y2)/2, strText_NameM3);
                end
            end
        end
        aColor = [1, 1, 1];
        if jobshop_solution.stJobSet(ii).iProcessMachine(jj) == 2
            text(x1, (y1 + y2)/2, strText_NameM2, 'Color', aColor);
        elseif jobshop_solution.stJobSet(ii).iProcessMachine(jj) == 3
            text(x1, (y1 + y2)/2, strText_NameM3, 'Color', aColor);
        end
        
    end
end
xlabel('Time', 'FontSize', 16);    %xlabel('time slot (Colour Group is process)');
ylabel('Jobs', 'FontSize', 16);    %ylabel('Job Id')
%title('Schedule'); % title('Solution Scheduling for the Job Shop, Y-Group is Job');
%% title include the makespan
strTitle = sprintf('Job schedule Gantt chart for job/flow shop, Makespan = %d', iMaxEndTime);
title(strTitle, 'FontSize', 18);

%% generate grid by myself
iMaxGridX = round(iMaxEndTime + 1); %axis([-1, iMaxAxisX , 0, iMaxAxisY]);
for ii = 1:1:iMaxGridX
    plot([ii, ii], [0, iMaxAxisY], '-.')
end

for ii = 1:1:iMaxAxisY
    plot([0, iMaxGridX], [ii, ii], '-.')
end


hold off;