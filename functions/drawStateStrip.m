function drawStateStrip(values, nCols, stripHeight)
% Draw one block per matrix column above the current image (1 = black,
% 0 = white) and extend the y-limits to show it.
values = values(:)';
if numel(values) ~= nCols
    error('Strip length (%d) must equal the number of matrix columns n (%d).', numel(values), nCols);
end
hold on;
xl = xlim;
yl = ylim;
width = (xl(2) - xl(1)) / nCols;
for i = 1:nCols
    color = [0 0 0];
    if values(i) == 0
        color = [1 1 1];
    end
    rectangle('Position', [xl(1) + (i-1)*width, yl(2), width, stripHeight], ...
        'FaceColor', color, 'EdgeColor', 'none');
end
ylim([yl(1), yl(2) + stripHeight]);
hold off;
end
