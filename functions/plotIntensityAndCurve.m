function [h1, h2, h4] = plotIntensityAndCurve(drinkLabel, intensity, curve, color, marker, markerSize, curveLabel)
% Right axis: seeking intensity of each trial set. Left axis: a curve over
% trial sets (dashed line + markers), e.g. the seeking affinity or PC1.
x = 1:numel(drinkLabel);
yyaxis right;
set(gca,'YColor','k');
[h1, h2] = plotDrinkMarkers(x, intensity, drinkLabel==1, markerSize);
ylabel('Seeking Intensity');
yyaxis left;
set(gca,'YColor',color);
plot(x, curve, '--', 'LineWidth',3, 'Color',color);
hold on;
h4 = plot(x, curve, marker, 'MarkerFaceColor',color, 'MarkerEdgeColor',color, 'MarkerSize',markerSize);
axis square;
xlabel('Trial Number');
ylabel(curveLabel);
end
