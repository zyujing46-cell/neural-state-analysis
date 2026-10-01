function [drinkbehav, sortOrder] = drinkingLabels(trialTimes, approach)
% Trial labels in chronological order: 1 = drinking, 2 = non-drinking
% (CS+ trials, approach = 1 / 0), 0 = other (CS-) trials.
[~, sortOrder] = sort(trialTimes);
approachSorted = approach(sortOrder,1,1);
drinkbehav = zeros(length(trialTimes),1);
drinkbehav(approachSorted==0) = 2;
drinkbehav(approachSorted==1) = 1;
end
