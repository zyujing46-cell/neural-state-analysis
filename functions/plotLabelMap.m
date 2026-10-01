function plotLabelMap(M, ttl)
% Session x trial-set label map: white = 0, black = 1, gray = no data.
figure('Units','normalized','Position',[0.35 0.35 0.35 0.7]);
h = imagesc(M);
colormap([1 1 1; 0 0 0]);
set(gca,'Color',[0.6 0.6 0.6]);
h.AlphaData = ~isnan(M);
h.AlphaDataMapping = 'none';
axis tight
xlabel('Trial Set');
ylabel('Session');
title(ttl);
end
