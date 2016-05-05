function [astConfigPropertyFile, stMasterCfg, strLine, iReadCount] = cfg_load_master_label(astrFileListsCaseConfig)

% History
% YYYYMMDD  Notes
% 20071210  Add file format
fptr = astrFileListsCaseConfig.fptr; 

strConstNumFilesInList_1 = astrFileListsCaseConfig.strConstNumFilesInList_1 ;
strConstNumFilesInList_2 = astrFileListsCaseConfig.strConstNumFilesInList_2 ;
strConstNumFilesInList_3 = astrFileListsCaseConfig.strConstNumFilesInList_3 ;
strConstConfigNameFileList_1= astrFileListsCaseConfig.strConstConfigNameFileList_1;
strConstConfigNameFileList_2= astrFileListsCaseConfig.strConstConfigNameFileList_2;
strConstConfigNameFileList_3= astrFileListsCaseConfig.strConstConfigNameFileList_3;
strConstPropertyNameFileList_1 = astrFileListsCaseConfig.strConstPropertyNameFileList_1;
strConstPropertyNameFileList_2 = astrFileListsCaseConfig.strConstPropertyNameFileList_2;
strConstPropertyNameFileList_3 = astrFileListsCaseConfig.strConstPropertyNameFileList_3;
strConstFlagFileFormat = astrFileListsCaseConfig.strConstFlagFileFormat;  % 20071210

lenConstNumFilesInList_1= length(strConstNumFilesInList_1);
lenConstNumFilesInList_2= length(strConstNumFilesInList_2);
lenConstNumFilesInList_3= length(strConstNumFilesInList_3);

lenConstConfigNameFileList_1 = length(strConstConfigNameFileList_1);
lenConstConfigNameFileList_2 = length(strConstConfigNameFileList_2);
lenConstConfigNameFileList_3 = length(strConstConfigNameFileList_3);

lenConstPropertyNameFileList_1 = length(strConstPropertyNameFileList_1);
lenConstPropertyNameFileList_2 = length(strConstPropertyNameFileList_2);
lenConstPropertyNameFileList_3 = length(strConstPropertyNameFileList_3);

lenConstFlagFileFormat = length(strConstFlagFileFormat);  % 20071210
iTotalVarRead = 9 +1;  % 3 * count{NumFilesInList, ConfigName, PropertyName} % 20071210

% default value
stMasterCfg.iFlagFileFormat = 0;
% 0: berth resource alloc
% 1: Genetic BiFSP ResAlloc

iReadCount = 0;
strLine = fgets(fptr);

while strLine(1) ~= '['
   strLine = sprintf('%sMINIMIMLENGTH_TO_BE_COMPATIBLE_WITH_READER', strLine);
   if strLine(1:lenConstNumFilesInList_1) == strConstNumFilesInList_1
       astConfigPropertyFile(1).iTotalItem = sscanf(strLine((lenConstNumFilesInList_1 + 1): end), ' = %d');
       iReadCount = iReadCount + 1;
   elseif strLine(1:lenConstConfigNameFileList_1) == strConstConfigNameFileList_1
       strConfigWithoutBracket = sscanf(strLine((lenConstConfigNameFileList_1 + 1): end), ' = %s');
       astConfigPropertyFile(1).strConstConfigLabel = sprintf('[%s]', strConfigWithoutBracket);
       iReadCount = iReadCount + 1;
   elseif strLine(1:lenConstPropertyNameFileList_1) == strConstPropertyNameFileList_1
       astConfigPropertyFile(1).strConstPropertyLabel = sscanf(strLine((lenConstPropertyNameFileList_1 + 1): end), ' = %s');
       iReadCount = iReadCount + 1;
       
   elseif strLine(1:lenConstNumFilesInList_2) == strConstNumFilesInList_2
       astConfigPropertyFile(2).iTotalItem = sscanf(strLine((lenConstNumFilesInList_2 + 1): end), ' = %d');
       iReadCount = iReadCount + 1;
   elseif strLine(1:lenConstConfigNameFileList_2) == strConstConfigNameFileList_2
       strConfigWithoutBracket = sscanf(strLine((lenConstConfigNameFileList_2 + 1): end), ' = %s');
       astConfigPropertyFile(2).strConstConfigLabel = sprintf('[%s]', strConfigWithoutBracket);
       iReadCount = iReadCount + 1;
   elseif strLine(1:lenConstPropertyNameFileList_2) == strConstPropertyNameFileList_2
       astConfigPropertyFile(2).strConstPropertyLabel = sscanf(strLine((lenConstPropertyNameFileList_2 + 1): end), ' = %s');
       iReadCount = iReadCount + 1;
       
   elseif strLine(1:lenConstNumFilesInList_3) == strConstNumFilesInList_3
       astConfigPropertyFile(3).iTotalItem = sscanf(strLine((lenConstNumFilesInList_3 + 1): end), ' = %d');
       iReadCount = iReadCount + 1;
   elseif strLine(1:lenConstConfigNameFileList_3) == strConstConfigNameFileList_3
       strConfigWithoutBracket = sscanf(strLine((lenConstConfigNameFileList_3 + 1): end), ' = %s');
       astConfigPropertyFile(3).strConstConfigLabel = sprintf('[%s]', strConfigWithoutBracket);
       iReadCount = iReadCount + 1;
   elseif strLine(1:lenConstPropertyNameFileList_3) == strConstPropertyNameFileList_3
       astConfigPropertyFile(3).strConstPropertyLabel = sscanf(strLine((lenConstPropertyNameFileList_3 + 1): end), ' = %s');
       iReadCount = iReadCount + 1;

   elseif strLine(1:lenConstFlagFileFormat) == strConstFlagFileFormat  % 20071210
       stMasterCfg.iFlagFileFormat = sscanf(strLine((lenConstFlagFileFormat + 1): end), ' = %d');
       iReadCount = iReadCount + 1;
   % 20071210
   elseif feof(fptr)
       error('Not compatible input.');
   end
   strLine = fgets(fptr);
end

% checksum verify
% if iReadCount ~= iTotalVarRead
%     error('too few input, must be .');
% end

astConfigPropertyFile(1).fptrInputLink = fptr;
astConfigPropertyFile(2).fptrInputLink = fptr;
astConfigPropertyFile(3).fptrInputLink = fptr;

strLine = sprintf('%sMINIMIMLENGTH_TO_BE_COMPATIBLE_WITH_READER', strLine);