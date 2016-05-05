function [stFileList_3] = cfg_load_file_lists_3(strFileFullName)
% History
% YYYYMMDD  Notes
% 20070726  Created for genetic batch file reader in matlab
% 20071210  Add file format

strConstWholeConfigLabel = '[FILE_LISTS_CONFIG]';
strConstNumFilesInList_1 = 'NUM_FILES_IN_LIST_1';
strConstNumFilesInList_2 = 'NUM_FILES_IN_LIST_2';
strConstNumFilesInList_3 = 'NUM_FILES_IN_LIST_3';
strConstConfigNameFileList_1 = 'CONFIG_NAME_FILE_LIST_1';
strConstConfigNameFileList_2 = 'CONFIG_NAME_FILE_LIST_2';
strConstConfigNameFileList_3 = 'CONFIG_NAME_FILE_LIST_3';
strConstPropertyNameFileList_1 = 'PROPERTY_NAME_FILE_LIST_1';
strConstPropertyNameFileList_2 = 'PROPERTY_NAME_FILE_LIST_2';
strConstPropertyNameFileList_3 = 'PROPERTY_NAME_FILE_LIST_3';
strConstFlagFileFormat = 'FLAG_FILE_FORMAT'; % 20071210

astrFileListsCaseConfig.strConstWholeConfigLabel = strConstWholeConfigLabel;
astrFileListsCaseConfig.strConstNumFilesInList_1 = strConstNumFilesInList_1;
astrFileListsCaseConfig.strConstNumFilesInList_2 = strConstNumFilesInList_2;
astrFileListsCaseConfig.strConstNumFilesInList_3 = strConstNumFilesInList_3;
astrFileListsCaseConfig.strConstConfigNameFileList_1 = strConstConfigNameFileList_1;
astrFileListsCaseConfig.strConstConfigNameFileList_2 = strConstConfigNameFileList_2;
astrFileListsCaseConfig.strConstConfigNameFileList_3 = strConstConfigNameFileList_3;
astrFileListsCaseConfig.strConstPropertyNameFileList_1 = strConstPropertyNameFileList_1;
astrFileListsCaseConfig.strConstPropertyNameFileList_2 = strConstPropertyNameFileList_2;
astrFileListsCaseConfig.strConstPropertyNameFileList_3 = strConstPropertyNameFileList_3;
astrFileListsCaseConfig.strConstFlagFileFormat = strConstFlagFileFormat; % 20071210

%%% to be loaded later
astrFileListsCaseConfig.fptr = [];
astrFileListsCaseConfig.astConfigPropertyFile(1).iTotalItem = [];
astrFileListsCaseConfig.astConfigPropertyFile(1).strConstConfigLabel = [];
astrFileListsCaseConfig.astConfigPropertyFile(1).strConstPropertyLabel = [];
astrFileListsCaseConfig.astConfigPropertyFile(1).fptrInputLink = [];

astrFileListsCaseConfig.astConfigPropertyFile(2).iTotalItem = [];
astrFileListsCaseConfig.astConfigPropertyFile(2).strConstConfigLabel = [];
astrFileListsCaseConfig.astConfigPropertyFile(2).strConstPropertyLabel = [];
astrFileListsCaseConfig.astConfigPropertyFile(2).fptrInputLink = [];

astrFileListsCaseConfig.astConfigPropertyFile(3).iTotalItem = [];
astrFileListsCaseConfig.astConfigPropertyFile(3).strConstConfigLabel = [];
astrFileListsCaseConfig.astConfigPropertyFile(3).strConstPropertyLabel = [];
astrFileListsCaseConfig.astConfigPropertyFile(3).fptrInputLink = [];


%%%%%%%%%%%%% for version compatible

if ~exist('strFileFullName')
    disp('Input the data file --- *.txt');
    [Filename, Pathname] = uigetfile('*.txt', 'Pick an Text file as Filename 3-Lists Short Cut');
    strFileFullName = strcat(Pathname , Filename);
end
%%% Convert file name to be compatible with UNIX
strVer = ver;
%% strVer(1).Version; % it is a string
if str2num(strVer(1).Version) >= 7.0
	[s,strSystem] = system('ver');
	if s == 0 %% it is a dos-windows system
	else %% it is a UNIX or Linux system
	    iPathStringList = strfind(strFileFullName, '\');
	    if length(iPathStringList) > 0
		    for ii = 1:1:length(iPathStringList)
		        strFileFullName(iPathStringList(ii)) = '/';
		    end
	    end
	end
end

strConfigurationFile = strFileFullName
stFileList_3.strJobListInputFilename = strFileFullName;
fptr = fopen(strFileFullName, 'r');
astrFileListsCaseConfig.fptr = fptr;

%%%%%%%%  20070724 Default Parameter
stJssProbStructConfig.isCriticalOperateSeq = 1;
stJssProbStructConfig.isWaitInProcess = 0;
stJssProbStructConfig.isPreemptiveProcess = 0;

iFlagLoadedConfigName = 0;
strLine = fgets(fptr);

while(~feof(fptr))
   strLine = sprintf('%sMINIMIMLENGTH_TO_BE_COMPATIBLE_WITH_READER', strLine);
   if strLine(1) == '%'
       % skip the comment line
   else
       if strLine(1:length(strConstWholeConfigLabel)) == strConstWholeConfigLabel
           [astConfigPropertyFile, stMasterCfg, strLine, iReadCount] =  cfg_load_master_label(astrFileListsCaseConfig);
           astrFileListsCaseConfig.astConfigPropertyFile = astConfigPropertyFile;
%            if iReadCount == 10
               iFlagLoadedConfigName = 1;
%            end
       end
      if iFlagLoadedConfigName == 1
          
		  if strLine(1:length(astConfigPropertyFile(1).strConstConfigLabel)) == astConfigPropertyFile(1).strConstConfigLabel
		      [strFilenameList] = cfg_load_property_para_str(astConfigPropertyFile(1).fptrInputLink, astConfigPropertyFile(1).strConstPropertyLabel, astConfigPropertyFile(1).iTotalItem);
		      for ii = 1:1:astConfigPropertyFile(1).iTotalItem
    		      astFilenameGroups(1).astFilenameList(ii).strFilename = strFilenameList(ii).strText;
    		  end
		  end

		  if strLine(1:length(astConfigPropertyFile(2).strConstConfigLabel)) == astConfigPropertyFile(2).strConstConfigLabel
		      [strFilenameList] = cfg_load_property_para_str(astConfigPropertyFile(2).fptrInputLink, astConfigPropertyFile(2).strConstPropertyLabel, astConfigPropertyFile(2).iTotalItem);
		      for ii = 1:1:astConfigPropertyFile(1).iTotalItem
    		      astFilenameGroups(2).astFilenameList(ii).strFilename = strFilenameList(ii).strText;
    		  end
		  end

		  if strLine(1:length(astConfigPropertyFile(3).strConstConfigLabel)) == astConfigPropertyFile(3).strConstConfigLabel
		      [strFilenameList] = cfg_load_property_para_str(astConfigPropertyFile(3).fptrInputLink, astConfigPropertyFile(3).strConstPropertyLabel, astConfigPropertyFile(3).iTotalItem);
		      for ii = 1:1:astConfigPropertyFile(1).iTotalItem
    		      astFilenameGroups(3).astFilenameList(ii).strFilename = strFilenameList(ii).strText;
    		  end
		  end

       end
   end
   strLine = fgets(fptr);
end


fclose(fptr);

stFileList_3.astConfigPropertyFile = astConfigPropertyFile;
stFileList_3.astFilenameGroups = astFilenameGroups;
stFileList_3.stMasterCfg = stMasterCfg;

