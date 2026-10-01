function hatchedBars(means, stderr)
% Hatched bar plot of three means (optionally with error bars).
x = 1:numel(means);
b = bar(x, means, 'FaceColor','w', 'EdgeColor','k', 'LineWidth',2);
b.BarWidth = 0.35;
b.CData = repmat([0.8 0.8 0.8], numel(means), 1);
b.FaceAlpha = 0.8;
hatchfill2(b(1), 'single', 'HatchAngle',-45, 'hatchcolor',[0.8 0.8 0.8]);
if ~isempty(stderr)
    hold on;
    errorbar(x, means, stderr, 'k', 'LineStyle','none', 'LineWidth',2, 'CapSize',20);
end
end
