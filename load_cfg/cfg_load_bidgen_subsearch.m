function [stBidGenSubProbSearch, strLine, iReadCount] = cfg_load_bidgen_subsearch(fptrConfigFile, stConstBidGenSubProbSearch)
% % cfg_load_bidgen_subsearch(fptrConfigFile, stConstBidGenSubProbSearch)
% load configuration setting for bid generation
%   bid generation is a subproblem decomposed from whole problem
%   setting is for defined local search, but not exact optimization model
% [stBidGenSubProbSearch, strLine, iReadCount] = cfg_load_bidgen_subsearch
% 
%% History
%% YYYYMMDD Notes
% 20080301 Changed default value

%%% default value
stBidGenSubProbSearch = jsp_def_st_bidgen_subprobsrch(); % 20080301

%%%
strConstFlagBidGenAlgo = stConstBidGenSubProbSearch.strConstFlagBidGenAlgo;
lenConstFlagBidGenAlgo = length(strConstFlagBidGenAlgo);

strConstFlagSortingPrice = stConstBidGenSubProbSearch.strConstFlagSortingPrice;
lenConstFlagSortingPrice = length(strConstFlagSortingPrice);

strConstMaxIterSubSearch = stConstBidGenSubProbSearch.strConstMaxIterSubSearch;
lenConstMaxIterSubSearch = length(strConstMaxIterSubSearch);

strConstFlagRunStrictSrch = stConstBidGenSubProbSearch.strConstFlagRunStrictSrch;
lenConstFlagRunStrictSrch = length(strConstFlagRunStrictSrch);

iReadCount = 0;
strLine = fgets(fptrConfigFile);

while strLine(1) ~= '['
   strLine = sprintf('%sMINIMIMLENGTH_TO_BE_COMPATIBLE_WITH_READER', strLine);
   if strLine(1:lenConstFlagBidGenAlgo) == strConstFlagBidGenAlgo
%       strLine
       stBidGenSubProbSearch.iFlag_BidGenAlgo = sscanf(strLine((lenConstFlagBidGenAlgo + 1): end), ' = %d');
       iReadCount = iReadCount + 1;

   elseif strLine(1:lenConstFlagSortingPrice) == strConstFlagSortingPrice
       stBidGenSubProbSearch.iFlagSortingPrice = sscanf(strLine((lenConstFlagSortingPrice + 1): end), ' = %d');
       iReadCount = iReadCount + 1;

   elseif strLine(1:lenConstMaxIterSubSearch) == strConstMaxIterSubSearch
       stBidGenSubProbSearch.iMaxIter_LocalSearchBidGen = sscanf(strLine((lenConstMaxIterSubSearch + 1): end), ' = %d');
       iReadCount = iReadCount + 1;
       
   elseif strLine(1:lenConstFlagRunStrictSrch) == strConstFlagRunStrictSrch
       stBidGenSubProbSearch.iFlagRunStrictSrch = sscanf(strLine((lenConstFlagRunStrictSrch + 1): end), ' = %d');
       iReadCount = iReadCount + 1;
       
   elseif feof(fptrConfigFile)
       error('Not compatible input.');
   end
   strLine = fgets(fptrConfigFile);
end

strLine = sprintf('%sMINIMIMLENGTH_TO_BE_COMPATIBLE_WITH_READER', strLine);
