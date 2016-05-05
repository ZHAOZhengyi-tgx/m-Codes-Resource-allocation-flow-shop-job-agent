function  [fValueLookup, iIndex] = calc_lut_max_between(fValueListLookUp, fInputListLookup, fInputLower, fInputUpper)
% calculation look-up-table maxium value between
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
% Function Input:
% fValueListLookUp: must have the same length as fInputListLookup
% fInputListLookup: must be ascending order
% fInputLower     : Input Lower Bound 
% fInputUpper     : Input Upper Bound
%
% Function Output:
% iIndex          : ii
% fValueLookup    : fValueListLookUp(ii), 
%                     such that: fInput >= fInputListLookup(ii) & fInput < fInputListLookup(ii+1)

if fInputLower > fInputUpper
    temp = fInputLower;
    fInputLower = fInputUpper;
    fInputUpper = temp;
end

iLen = length(fInputListLookup);
if iLen ~= length(fValueListLookUp)
    error('size not match, value and Input');
end

if iLen == 1
    fValueLookup = fValueListLookUp(1);
    iIndex = 1;
else
    if fInputUpper < fInputListLookup(1)
        fValueLookup = 0;
        iIndex = 1;
    elseif fInputLower >= fInputListLookup(iLen)
        iIndex = iLen;
        fValueLookup = fValueListLookUp(iLen);
    else
        ii = 1;
        iFlagGetIndex = 0;
        while ii <= iLen - 1 && iFlagGetIndex ~= -1
            if fInputListLookup(ii) >= fInputLower  &&  fInputListLookup(ii) <= fInputUpper
                if iFlagGetIndex == 0
                    iFlagGetIndex = 1;
                    fValueLookup = fValueListLookUp(ii);
                    iIndex = ii;
                else
%                    iFlagGetIndex = iFlagGetIndex + 1;
                    if fValueLookup < fValueListLookUp(ii)
                        fValueLookup = fValueListLookUp(ii);
                        iIndex = ii;
                    end
                end
                if fInputListLookup(ii) > fInputUpper
                    iFlagGetIndex = -1;
%                    disp('Exit before end');
                end
            elseif fInputListLookup(ii) <= fInputLower && fInputListLookup(ii+1) >= fInputUpper
                    iFlagGetIndex = 1;
                    fValueLookup = fValueListLookUp(ii);
                    iIndex = ii;
            end
            ii = ii+1;
        end
        if fInputListLookup(iLen) >= fInputLower  &&  fInputListLookup(iLen) <= fInputUpper
            iFlagGetIndex = 1;
            fValueLookup = fValueListLookUp(iLen);
            iIndex = iLen;
        end
    end
end

% output_ValueLut_Index = [fValueLookup, iIndex]
