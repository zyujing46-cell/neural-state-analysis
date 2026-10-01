function nullVsModelViolin(nullCorr, modelCorr, colors, modelName)
% Violin plot of null vs. model correlations with a one-sided t-test.
n = numel(modelCorr);
figure;
violinplot([nullCorr(:), modelCorr(:)], [ones(n,1), 2*ones(n,1)], 'ViolinColor',colors, ...
    'MarkerSize',100, 'MedianMarkerSize',140, 'Width',0.4);
set(gca,'XTickLabel',{'Null Model', modelName});
title('Comparisons Across All Conditions and Strains')
ylabel('Correlation with Seeking Intensity');
[~, p] = ttest2(modelCorr, nullCorr, 'Tail','right');
sigstar({[1 2]}, p);
end
