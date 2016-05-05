function [stLagrangianRelax, strLine, iReadCount] = cfg_load_lg_relax(fptrConfigFile, stConstStringLagRelax)

%%% default value
stLagrangianRelax = lgrlx_struct_def();

%%%
strConstFlagOptionRepair = stConstStringLagRelax.strConstFlagOptionRepair;
lenConstFlagOptionRepair = length(strConstFlagOptionRepair);

strConstMaxIter = stConstStringLagRelax.strConstMaxIter;
lenConstMaxIter = length(strConstMaxIter);

strConstDesireDualGap = stConstStringLagRelax.strConstDesireDualGap;
lenConstDesireDualGap = length(strConstDesireDualGap);

strConstStepSizeAlpha = stConstStringLagRelax.strConstStepSizeAlpha;
lenConstStepSizeAlpha = length(strConstStepSizeAlpha);

iReadCount = 0;
strLine = fgets(fptrConfigFile);

while strLine(1) ~= '['
   strLine = sprintf('%sMINIMIMLENGTH_TO_BE_COMPATIBLE_WITH_READER', strLine);
   if strLine(1:lenConstFlagOptionRepair) == strConstFlagOptionRepair
%       strLine
       stLagrangianRelax.iHeuristicAchieveFeasibility = sscanf(strLine((lenConstFlagOptionRepair + 1): end), ' = %d');
       iReadCount = iReadCount + 1;

   elseif strLine(1:lenConstMaxIter) == strConstMaxIter
%       strLine
       stLagrangianRelax.iMaxIter = sscanf(strLine((lenConstMaxIter + 1): end), ' = %d');
       iReadCount = iReadCount + 1;

   elseif strLine(1:lenConstStepSizeAlpha) == strConstStepSizeAlpha
       stLagrangianRelax.alpha_r = sscanf(strLine((lenConstStepSizeAlpha + 1): end), ' = %f');
       iReadCount = iReadCount + 1;

   elseif strLine(1:lenConstDesireDualGap) == strConstDesireDualGap
       stLagrangianRelax.fDesiredDualityGap = sscanf(strLine((lenConstDesireDualGap + 1): end), ' = %f');
       iReadCount = iReadCount + 1;
       
       
   elseif feof(fptrConfigFile)
       error('Not compatible input.');
   end
   strLine = fgets(fptrConfigFile);
end

strLine = sprintf('%sMINIMIMLENGTH_TO_BE_COMPATIBLE_WITH_READER', strLine);
