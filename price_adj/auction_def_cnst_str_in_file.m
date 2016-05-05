function [stConstStringAucionStrategy, stConstStringPriceAdjust, stConstBidGenSubProbSearch] = auction_def_cnst_str_in_file()
% auction-type solution method, definition of constant string used in config-file
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%  
%
%The MIT License (MIT)
%
%Copyright (c) 2016 ZHAOZhengyi-tgx
%
%Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the "Software"), to deal in the Software without restriction, including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions:
%
%The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.
%
%THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%
% Module: Solution for Resource Allocation among Scheduling Agents 
% Template for Problem Input
% OUTPUT from the solver: schedule for each job's process, dispatching for each machine
% During this whole document, % is for line commenting, which means any line starting with a % will not be taken into parsing.
%
% all right reserved (c)2016
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% all right reserved, @2016, Sg.LongRenE@gmail.com

%% structur for Auction Stretegy, stopping criterion, obj-function,
%% synchronous or asynchronous bidding
stConstStringAucionStrategy.strAuctionStrategyConfig = '[AUCTION_STRATEGY]';
stConstStringAucionStrategy.strConstMakeSpanFunction = 'FLAG_MAKESPAN_FUNCTION';
stConstStringAucionStrategy.strConstSynchronousBid = 'FLAG_SYNCHRONOUS_BIDDING_ADJUSTING';
stConstStringAucionStrategy.strConstHasWinnerDetermination = 'FLAG_WINNER_DETERMINATION';
stConstStringAucionStrategy.strConstMinIteration = 'MIN_NUM_ITERATION';
stConstStringAucionStrategy.strConstMaxIteration = 'MAX_NUM_ITERATION';
stConstStringAucionStrategy.strDeltaObj = 'DELTA_OBJECTIVE_VALUE';   
stConstStringAucionStrategy.strDeltaPrice = 'DELTA_PRICE';
stConstStringAucionStrategy.strMinNumFeasibleSolution = 'MIN_NUM_FEASIBLE_SOLUTION';
stConstStringAucionStrategy.strConvergingRule = 'CONVERGING_RULE';   
stConstStringAucionStrategy.strNumIterDeOscilating = 'NUM_ITER_DEOSCILATING';  


%% structure for Price Adjustment
stConstStringPriceAdjust.strPriceAjustStructConfig = '[PRICE_ADJUSTMENT_IN_AUCTION]';
stConstStringPriceAdjust.strConstFlagStrategy = 'PA_STRATEGY';
stConstStringPriceAdjust.strConstFlagAlpha = 'ALPHA_STEP_SIZE';

%% structure for bid-generation
stConstBidGenSubProbSearch.strConstMasterConfig = '[BIDGEN_SUBSEARCH_SETTING]';
stConstBidGenSubProbSearch.strConstFlagBidGenAlgo = 'BIDGEN_SUBSEARCH_ALGO';
stConstBidGenSubProbSearch.strConstFlagSortingPrice = 'BIDGEN_FLAG_SORTING_PRICE';
stConstBidGenSubProbSearch.strConstMaxIterSubSearch = 'BIDGEN_MAX_ITER_SUB_SEARCH';
stConstBidGenSubProbSearch.strConstFlagRunStrictSrch = 'BIDGEN_OPTION_STRICT_SEARCH';
