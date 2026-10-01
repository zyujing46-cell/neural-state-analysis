function plotLinearFit(x, y, style)
% Scatter plot with a least-squares line; the title shows Pearson's r.
switch style
    case 'gray'
        scatter(x, y, 240, 'MarkerFaceColor','none', 'MarkerEdgeColor',[0.3 0.3 0.3], 'MarkerFaceAlpha',0.8, 'LineWidth',3);
        lineArgs = {'Color',[0.3 0.3 0.3], 'LineWidth',4};
        prefix = 'r = ';
    case 'purple'
        scatter(x, y, 100, 'MarkerFaceColor',[0.6 0.5 0.9], 'MarkerEdgeColor','k', 'MarkerFaceAlpha',0.8);
        lineArgs = {'Color',[0.4 0.2 0.7], 'LineWidth',1.5};
        prefix = 'Linear Analysis,  r = ';
end
hold on;
xfit = linspace(min(x), max(x), 100);
plot(xfit, polyval(polyfit(x, y, 1), xfit), '-', lineArgs{:});
title([prefix num2str(corr(x(:), y(:)), 2)]);
box off;
axis square;
end
