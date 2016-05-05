function [stAuctionStrategy, strLine, iReadCount] = cfg_load_auction_strategy(fptrConfigFile, stConstStringAucionStrategy)
% History
% YYYYMMDD  Notes
% 20070605  improve stoping criterion zzy

%%% default value
stAuctionStrategy.iFlagMakeSpanFunction  = 0;
stAuctionStrategy.iSynchUpdatingBid       = 1;
stAuctionStrategy.iHasWinnerDetermination = 0;
stAuctionStrategy.iMinIteration           = 10;
stAuctionStrategy.iMaxIteration           = 20;
stAuctionStrategy.fDeltaObj               = realmax;  % return a matlab constant % 20070605
stAuctionStrategy.fDeltaPrice             = 1000;
stAuctionStrategy.iMinNumFeasibleSolution = 1;
stAuctionStrategy.iConvergingRule         = 0;
stAuctionStrategy.iNumIterDeOscilating    = stAuctionStrategy.iMinNumFeasibleSolution; % 20070605
%%%

% iFlagMakeSpanFunction
strConstMakeSpanFunction = stConstStringAucionStrategy.strConstMakeSpanFunction;
lenConstMakeSpanFunction = length(strConstMakeSpanFunction);

% iSynchUpdatingBid
strConstSynchronousBid = stConstStringAucionStrategy.strConstSynchronousBid;
lenConstSynchronousBid = length(strConstSynchronousBid);

% iHasWinnerDetermination
strConstHasWinnerDetermination = stConstStringAucionStrategy.strConstHasWinnerDetermination;
lenConstHasWinnerDetermination = length(strConstHasWinnerDetermination);

% iMinIteration
strConstMinIteration = stConstStringAucionStrategy.strConstMinIteration;
lenConstMinIteration = length(strConstMinIteration);

% iMaxIteration
strConstMaxIteration = stConstStringAucionStrategy.strConstMaxIteration;
lenConstMaxIteration = length(strConstMaxIteration);
% 20070605
% fDeltaObj
strConstDeltaObj = stConstStringAucionStrategy.strDeltaObj;
lenConstDeltaObj = length(strConstDeltaObj);

% fDeltaPrice
strConstDeltaPrice = stConstStringAucionStrategy.strDeltaPrice;
lenConstDeltaPrice = length(strConstDeltaPrice);

% iMinNumFeasibleSolution
strConstMinNumFeasibleSolution = stConstStringAucionStrategy.strMinNumFeasibleSolution;
lenConstMinNumFeasibleSolution = length(strConstMinNumFeasibleSolution);

% iConvergingRule
strConstConvergingRule = stConstStringAucionStrategy.strConvergingRule;
lenConstConvergingRule = length(strConstConvergingRule);

% iNumIterDeOscilating
strConstNumIterDeOscilating = stConstStringAucionStrategy.strNumIterDeOscilating;
lenConstNumIterDeOscilating = length(strConstNumIterDeOscilating);

% 20070605

iReadCount = 0;
strLine = fgets(fptrConfigFile);

while strLine(1) ~= '['
   strLine = sprintf('%sMINIMIMLENGTH_TO_BE_COMPATIBLE_WITH_READER', strLine);
   if strLine(1:lenConstMakeSpanFunction) == strConstMakeSpanFunction
%       strLine
       stAuctionStrategy.iFlagMakeSpanFunction = sscanf(strLine((lenConstMakeSpanFunction + 1): end), ' = %d');
       iReadCount = iReadCount + 1;

   elseif strLine(1:lenConstSynchronousBid) == strConstSynchronousBid
       stAuctionStrategy.iSynchUpdatingBid = sscanf(strLine((lenConstSynchronousBid + 1): end), ' = %f');
       iReadCount = iReadCount + 1;

   elseif strLine(1:lenConstHasWinnerDetermination) == strConstHasWinnerDetermination
       stAuctionStrategy.iHasWinnerDetermination = sscanf(strLine((lenConstHasWinnerDetermination + 1): end), ' = %f');
       iReadCount = iReadCount + 1;

   elseif strLine(1:lenConstMinIteration) == strConstMinIteration
       stAuctionStrategy.iMinIteration = sscanf(strLine((lenConstMinIteration + 1): end), ' = %f');
       iReadCount = iReadCount + 1;
       
   elseif strLine(1:lenConstMaxIteration) == strConstMaxIteration
       stAuctionStrategy.iMaxIteration = sscanf(strLine((lenConstMaxIteration + 1): end), ' = %f');
       iReadCount = iReadCount + 1;
       
% 20070605
   elseif strLine(1:lenConstDeltaObj) == strConstDeltaObj
       stAuctionStrategy.fDeltaObj = sscanf(strLine((lenConstDeltaObj + 1): end), ' = %f');
       iReadCount = iReadCount + 1;

   elseif strLine(1:lenConstDeltaPrice) == strConstDeltaPrice
       stAuctionStrategy.fDeltaPrice = sscanf(strLine((lenConstDeltaPrice + 1): end), ' = %f');
       iReadCount = iReadCount + 1;

   elseif strLine(1:lenConstMinNumFeasibleSolution) == strConstMinNumFeasibleSolution
       stAuctionStrategy.iMinNumFeasibleSolution = sscanf(strLine((lenConstMinNumFeasibleSolution + 1): end), ' = %f');
       iReadCount = iReadCount + 1;

   elseif strLine(1:lenConstConvergingRule) == strConstConvergingRule
       stAuctionStrategy.iConvergingRule = sscanf(strLine((lenConstConvergingRule + 1): end), ' = %f');
       iReadCount = iReadCount + 1;

   elseif strLine(1:lenConstNumIterDeOscilating) == strConstNumIterDeOscilating
       stAuctionStrategy.iNumIterDeOscilating = sscanf(strLine((lenConstNumIterDeOscilating + 1): end), ' = %f');
       iReadCount = iReadCount + 1;
% 20070605

   elseif feof(fptrConfigFile)
       error('Not compatible input.');
   end
   strLine = fgets(fptrConfigFile);
end
strLine = sprintf('%sMINIMIMLENGTH_TO_BE_COMPATIBLE_WITH_READER', strLine);

%% Checking sensibility of input, % 20070605
if stAuctionStrategy.iMaxIteration <= 0
    error('iMaxIteration must be >0');
end
if stAuctionStrategy.iMinNumFeasibleSolution <= 0
    error('iMinNumFeasibleSolution must be >0');
end
if stAuctionStrategy.fDeltaObj <= 0
    error('fDeltaObj must be >0');
end
if stAuctionStrategy.fDeltaPrice <= 0
    error('fDeltaPrice must be >0');
end

if stAuctionStrategy.iNumIterDeOscilating > stAuctionStrategy.iMinNumFeasibleSolution
    error('NUM_ITER_DEOSCILATING cannot be less than MIN_NUM_FEASIBLE_SOLUTION');
end

