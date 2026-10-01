function slopeBars(slopes, colors, ylab, pValues)
% Bar plot of the fitted slopes (WA, PA, WQ, PQ) with the ANCOVA p-values.
figure;
b = bar(slopes, 'BarWidth',0.4);
b.FaceColor = 'flat';
b.CData = colors;
xticks(1:4);
xticklabels({'WA','PA','WQ','PQ'});
ylabel(ylab);
sigstar({[1 2], [3 4]}, pValues);
end
