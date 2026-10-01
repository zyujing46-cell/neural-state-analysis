function [drinkLabel, trialSetRange, blockStart] = groupTrialSets(drinkbehav, maxLen)
% Group consecutive trials with the same label into trial sets of at most
% maxLen trials.
%   drinkLabel : label of each set (1 = drinking, 0 = non-drinking)
%   trialSetRange    : {[firstTrial, lastTrial]} of each set
%   blockStart  : index of the first trial of each set
n = numel(drinkbehav);
pos = ones(1,n);          % position of each trial inside its set
for i = 2:n
    if drinkbehav(i) == drinkbehav(i-1) && pos(i-1) < maxLen
        pos(i) = pos(i-1) + 1;
    end
end
blockStart = find(pos == 1);
blockEnd = [blockStart(2:end)-1, n];
drinkLabel = double(drinkbehav(blockStart)' == 1);
trialSetRange = arrayfun(@(s,e) [s,e], blockStart, blockEnd, 'UniformOutput', false);
end
