function [h1, h2] = plotDrinkMarkers(x, y, isDrink, markerSize)
% Black squares = drinking, gray circles = non-drinking.
h1 = plot(x(isDrink),  y(isDrink),  'ks', 'MarkerFaceColor',[0 0 0],       'MarkerSize',markerSize);
hold on;
h2 = plot(x(~isDrink), y(~isDrink), 'ko', 'MarkerFaceColor',[0.9 0.9 0.9], 'MarkerSize',markerSize);
end
