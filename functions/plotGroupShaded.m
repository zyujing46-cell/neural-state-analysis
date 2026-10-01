function plotGroupShaded(x, mu, sem, colors, lineWidth)
% New figure with one mean +/- SEM band per group (rows of mu/sem).
figure;
for g = 1:size(mu,1)
    shadedErrorBar(x, mu(g,:), sem(g,:), 'lineProps', {'color',colors(g,:), 'LineWidth',lineWidth}, ...
        'patchSaturation', 0.15);
    hold on;
end
end
