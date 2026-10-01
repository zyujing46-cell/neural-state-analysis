function slopes = scatterWithFits(x, y, markerArgs, lineColors, fitX, fitY)
% New figure: scatter two groups (x{g}, y{g}) and overlay a linear fit
% (fitlm, drawn on [0, 1]) for each. The fits use fitX/fitY when given.
if nargin < 5
    fitX = x;
    fitY = y;
end
figure;
for g = 1:2
    scatter(x{g}, y{g}, 300, markerArgs{g}{:});
    hold on;
end
xFit = linspace(0,1,100)';
slopes = zeros(1,2);
for g = 1:2
    lm = fitlm(fitX{g}, fitY{g});
    slopes(g) = lm.Coefficients.Estimate(2);
    plot(xFit, predict(lm, xFit), '-', 'Color',lineColors(g,:), 'LineWidth',6);
end
xlim([0 1]);
end
