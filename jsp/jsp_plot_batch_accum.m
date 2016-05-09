function jsp_plot_batch_accum(stJspSchedule, iFigIdAllBatch)

figure(iFigIdAllBatch);
hold on;
psa_jsp_plot_jobsolution(stJspSchedule, iFigIdAllBatch);
figure(iFigIdAllBatch + 1);
hold on;
jsp_plot_schede_job_circu(stJspSchedule, iFigIdAllBatch + 1);
figure(iFigIdAllBatch + 2)
hold on;
jsp_plot_schedu_mach_circu(stJspSchedule, iFigIdAllBatch + 2);
