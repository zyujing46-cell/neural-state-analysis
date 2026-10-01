function p = slopeComparison(x, y, idxP, idxW)
% ANCOVA (aoctool) of y against x for P vs. W sessions; returns the
% p-value of the slope comparison.
idx = [idxP; idxW];
strain = categorical([repmat({'P'}, numel(idxP), 1); repmat({'W'}, numel(idxW), 1)]);
[~, ~, ~, stats] = aoctool(x(idx), y(idx), strain);
results = multcompare(stats, 0.05, "off", "", "s");
disp(results);
p = results(:,6);
end
