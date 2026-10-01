function saveFigureFiles(h, folder, name)
% Save a figure as .png and .fig (the folder is created if needed).
if ~exist(folder,'dir')
    mkdir(folder);
end
saveas(h, fullfile(folder, [name '.png']));
savefig(h, fullfile(folder, [name '.fig']));
end
