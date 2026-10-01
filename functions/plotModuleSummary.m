function [pRM12, pRM23] = plotModuleSummary(M, ylab)
% Mean +/- SEM over sessions of [within 1, between, within 2] (columns of M)
% with t-tests of within 1 vs. between and between vs. within 2.
figure;
hatchedBars(mean(M,1), std(M,0,1) / sqrt(size(M,1)));
[~, pRM12] = ttest2(M(:,1), M(:,2));
sigstar({[1,2]}, pRM12);
[~, pRM23] = ttest2(M(:,2), M(:,3));
sigstar({[2,3]}, pRM23);
ylim([0 1]);
ylabel(ylab);
xlim([0.5 3.5]);
axis square;
end
