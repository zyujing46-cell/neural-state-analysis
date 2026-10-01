function [drinkDen, nonDrinkDen] = behaviorDensity(drinkTime, approachBehav)
% Drinking density    : share of the total drinking time spent in the
%                       longest run of drinking trials.
% Non-drinking density: share of the non-drinking time (8 s of sipper
%                       access per trial) spent in the longest run of
%                       non-drinking trials.
csTime = drinkTime(approachBehav==1 | approachBehav==0);   % CS+ trials
isDrink = csTime ~= 0;
totalDrink = sum(drinkTime(approachBehav==1));
[s1, r1] = longestSegment(isDrink, 1);
drinkDen = sum(csTime(s1:s1+r1)) / totalDrink;   % NOTE: range includes one trial after the run
[~, r0] = longestSegment(isDrink, 0);
nonDrinkDen = 8*r0 / (8*sum(~isDrink) + 8*sum(isDrink) - totalDrink);
end
