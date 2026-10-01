function pairedGroupViolin(v1, v2, groupIdx, colors, ttl, ylab, names, yl)
% Violin plot of two per-session measures side by side for each group:
% categories 2g-1 (v1) and 2g (v2) for group g = WA, WQ, PA, PQ.
n = numel(v1);
values = [v1(:); v2(:)];
category = zeros(size(values));
for g = 1:numel(groupIdx)
    category(groupIdx{g})   = 2*g-1;
    category(groupIdx{g}+n) = 2*g;
end
figure;
violinplot(values, category, 'ViolinColor',colors, 'MarkerSize',100, 'MedianMarkerSize',140);
set(gca,'XTick',[1.6,3.6,5.6,7.7],'XTickLabel',{'WA','WQ','PA','PQ'});
if ~isempty(yl)
    ylim(yl);
end
title(ttl);
ylabel(ylab);
legend([{''}, names(1), repmat({''},1,7), names(2)]);
end
