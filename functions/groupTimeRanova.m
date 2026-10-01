function groupTimeRanova(Y, groupIdx, nTime)
% Repeated-measures ANOVA with Time within and Strain x Stim between.
% Y: sessions (ordered WA, WQ, PA, PQ) x time points; the first nTime
% columns are used.
[Strain, Stim] = groupFactors(groupIdx);
withinDesign = table(categorical((1:nTime)'), 'VariableNames', {'Time'});
rm = fitGroupRm(Y, Strain, Stim, withinDesign, nTime);
showRanova(rm, 'Time', 'Time', true);
end
