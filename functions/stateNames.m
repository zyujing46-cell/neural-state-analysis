function names = stateNames(drinkLabel)
% 's' for drinking/seeking trial sets, 'ns' otherwise.
names = repmat({'ns'}, size(drinkLabel));
names(drinkLabel==1) = {'s'};
end
