% =========================================================================
% exportCsvData.m
% Export data behind figures of Main.m to CSV files in
% 'Decode_Latent_States/exported_data/':
%   1) Fig1IJ.csv
%      - Fig1I: affinity matrix of the example session 11 (AffinityPlot section)
%      - Fig1J: the three values of the first plot of CategorizeNeuralState:
%        mean affinity within module 1, between modules and within module 2
%   2) Fig3E.csv (State–Behavior Mutual Information violin plot)
%      - the three categories of the CategorizeNeuralState violin plot
%        ('State–Behavior Mutual Information'), one row per session:
%        Null, Original Label, Seeking Intensity
%   3) Fig6CD.csv
%      - the two PcaVsReference violin plots, one row per session:
%        correlation of each model with seeking intensity
%        Fig6C: Null Model vs. Reference Model
%        Fig6D: Null Model vs. PCA Model
%        Both plots use the same null model, so the two null columns are
%        identical.
%   4) Fig7ABCFI.csv (SpecificityVsDensity section)
%      - Fig7A, Fig7B, Fig7C: the three violin plots (Drinking Density,
%        Non-drinking Density, Total specificity), one column per group
%        (WA, WQ, PA, PQ), one value per session
%      - Fig7F, Fig7I: the two slope bar plots, fitted slope of total
%        specificity against drinking density ('Slope (Drink-Speci)') and
%        against non-drinking density ('Slope (Nondrink-Speci)') for the
%        groups WA, PA, WQ, PQ (4 values each)
%   5) FigS3.csv (CategorizeNeuralState section)
%      - the two group-level module bar plots: per-session values (73
%        sessions; one with an empty module is dropped) within module 1,
%        between modules and within module 2; the bars show their mean +/- SEM
%        left panel : recurrence modules (RM values, 'Recurrence Values')
%        right panel: affinity modules (AM values, 'Affinity Values')
%   6) FigS5ABCD.csv (RmAmSummary section)
%      - the four state-specificity violin plots, one column per violin
%        (group x state), one value per session:
%        FigS5A: affinity matrix,   drinking / non-drinking labels
%        FigS5B: recurrence matrix, drinking / non-drinking labels
%        FigS5C: affinity matrix,   seeking / non-seeking labels
%        FigS5D: recurrence matrix, seeking / non-seeking labels
%        (seeking = seeking intensity > 3). Empty cells: session without
%        that state (NaN, not shown in the plot) or shorter group.
%   7) FigS6.csv (PcaVsReference section)
%      - the cumulative explained variance plot: per-session cumulative
%        variance (%) explained by the first 1-5 principal components of
%        the affinity matrix (74 sessions); the bars show mean +/- SD
%   8) FigS1.csv (GaussianWidth section; reads GaussianWidthComparison.mat,
%      saved by that section)
%      - lower left  : average smoothness, total variation (TV); per-session
%                      mean over neurons, the bars show the mean over sessions
%      - lower middle: preserved signal details, number of peaks; per-session
%                      mean over neurons, the bars show the mean over sessions
%      - lower right : preferred Gaussian sigma per neuron (number of neurons)
%      for the kernel widths sigma=mean, sigma=mean/4, sigma=mean/8
%
% Needs the processed session files from Main.m (Preprocess ... TrialSetModel).
% The module partitions and the null shuffles are computed exactly as in
% CategorizeNeuralState and PcaVsReference (each starts from rng(1), all
% sessions in order), so the values match those figures.
% =========================================================================

clearvars

%% Paths and session list (same as Main.m)
projectDir = fileparts(fileparts(mfilename('fullpath')));
if ~exist(fullfile(projectDir,'Rodent data set'),'dir')
    projectDir = pwd;
    if ~exist(fullfile(projectDir,'Rodent data set'),'dir')
        projectDir = fileparts(pwd);
    end
end
dataDir      = fullfile(projectDir,'Rodent data set');
rawDir       = fullfile(dataDir,'fullAnalysis/');
processedDir = fullfile(dataDir,'Processed_sessions');
resultDir    = fullfile(dataDir,'Intermediate_results');
exportDir    = fullfile(projectDir,'Decode_Latent_States','exported_data');  % exported data
addpath(fullfile(projectDir,'Decode_Latent_States','functions'));  % helper functions
sessionFiles = dir([rawDir '*_AllData.mat']);
nSessions = size(sessionFiles,1);
processedFile = @(k) fullfile(processedDir, sessionFiles(k).name);
sessName      = @(k) sessionFiles(k).name(1:end-4);
if ~exist(exportDir,'dir')
    mkdir(exportDir);
end

%% Module partitions, as in CategorizeNeuralState
rng(1);
partitions = cell(1,nSessions);
for j = 1:nSessions
    load(processedFile(j), 'amTrialSet');
    partitions{j} = twoModulePartition(amTrialSet);
end

%% 1) Affinity matrix and module affinity means of session 11
exampleSession = 11;
load(processedFile(exampleSession), 'amTrialSet');
am = amTrialSet;
moduleMeans = cellfun(@(b) mean(b,'all'), moduleBlocks(am, partitions{exampleSession}));

%   Fig1I,Affinity matrix (<session>)
%   ,TrialSet_1,...,TrialSet_N
%   TrialSet_1,<row 1>
%   ...
%   (blank line)
%   Fig1J,Module affinity means (<session>)
%   Within Module 1,<value>
%   Between Modules,<value>
%   Within Module 2,<value>
moduleNames = {'Within Module 1','Between Modules','Within Module 2'};
csvFile = fullfile(exportDir, 'Fig1IJ.csv');
n = size(am,1);
fid = fopen(csvFile, 'w');
fprintf(fid, 'Fig1I,Affinity matrix (%s)\n', sessName(exampleSession));
fprintf(fid, '%s\n', strjoin([{''}, compose('TrialSet_%d', 1:n)], ','));
for i = 1:n
    fprintf(fid, 'TrialSet_%d%s\n', i, sprintf(',%.10g', am(i,:)));
end
fprintf(fid, '\nFig1J,Module affinity means (%s)\n', sessName(exampleSession));
for k = 1:3
    fprintf(fid, '%s,%.10g\n', moduleNames{k}, moduleMeans(k));
end
fclose(fid);
fprintf('Saved %s\n', csvFile);

%% 2) State-behavior mutual information (violin plot), as in CategorizeNeuralState
seekThreshold = 3;
[miDrink, miSeek, miNull] = deal(zeros(nSessions,1));
for j = 1:nSessions
    load(processedFile(j), 'drinkLabel', 'seekIntensity');
    idx = partitions{j};
    seekLabel = double(seekIntensity > seekThreshold); % 1 = seeking trial set
    miDrink(j) = mutualInformation(drinkLabel', idx);
    miSeek(j)  = mutualInformation(seekLabel', idx);
    % Null model: mean MI over 50 shuffles of the seeking labels
    nullMI = zeros(1,50);
    for k = 1:50
        nullMI(k) = mutualInformation(seekLabel(randperm(length(seekLabel)))', idx);
    end
    miNull(j) = mean(nullMI);
end

% Columns named after the categories of the violin plot
T = table(arrayfun(sessName, (1:nSessions)', 'UniformOutput', false), miNull, miDrink, miSeek, ...
    'VariableNames', {'Session', 'Null', 'Original Label', 'Seeking Intensity'});
csvFile = fullfile(exportDir, 'Fig3E.csv');
writetable(T, csvFile);
fprintf('Saved %s\n', csvFile);

%% 3) Reference / PCA model vs. null model (violin plots), as in PcaVsReference
rng(1);
load(fullfile(resultDir,'RefModelCorr.mat'));  % refModelCorr, from TrialSetModel
nPerm = 300;
[pcaModelCorr, nullModelCorr] = deal(zeros(nSessions,1));
nullCorrPerm = zeros(1,nPerm);
for j = 1:nSessions
    load(processedFile(j), 'amTrialSet', 'seekIntensity');
    [~, score] = pca(amTrialSet);
    % PCA sign is arbitrary: use the absolute correlation
    pcaModelCorr(j) = abs(corr(score(:,1), seekIntensity'));
    % Null model: correlation with shuffled seeking intensity; keep one
    % random draw out of nPerm permutations
    for k = 1:nPerm
        nullCorrPerm(k) = corr(score(:,1), seekIntensity(randperm(length(seekIntensity)))');
    end
    nullModelCorr(j) = nullCorrPerm(randi(nPerm));
end

% Columns named after the violin plot labels
T = table(arrayfun(sessName, (1:nSessions)', 'UniformOutput', false), ...
    nullModelCorr, refModelCorr(:), nullModelCorr, pcaModelCorr, ...
    'VariableNames', {'Session', 'Fig6C Null Model', 'Fig6C Reference Model', ...
                      'Fig6D Null Model', 'Fig6D PCA Model'});
csvFile = fullfile(exportDir, 'Fig6CD.csv');
writetable(T, csvFile);
fprintf('Saved %s\n', csvFile);

%% 4) Specificity vs. density (violin and slope bar plots), as in SpecificityVsDensity
load(fullfile(resultDir,'sessionStrain.mat'));    % strain of each session ('W' or 'P')
load(fullfile(resultDir,'sessionCondition.mat')); % 'Regular' (A) or 'Regular + Qui' (Q)
isW = strcmp(sessionStrain,'W');
isA = strcmp(sessionCondition,'Regular');
idxWA = find( isW &  isA);
idxWQ = find( isW & ~isA);
idxPA = find(~isW &  isA);
idxPQ = find(~isW & ~isA);
groupIdx   = {idxWA, idxWQ, idxPA, idxPQ};
groupNames = {'WA','WQ','PA','PQ'};

[drinkDensity, nonDrinkDensity, totalSpecificity] = deal(zeros(nSessions,1));
for i = 1:nSessions
    load(processedFile(i), 'drinkTime', 'amTrialSet', 'drinkLabel');
    load(fullfile(rawDir, sessionFiles(i).name), 'trialTimes', 'approach');
    [~, sortOrder] = sort(trialTimes);
    [drinkDensity(i), nonDrinkDensity(i)] = behaviorDensity(drinkTime, approach(sortOrder,1,1));
    [sSpec, nsSpec] = stateSpecificity(amTrialSet, drinkLabel);
    totalSpecificity(i) = sSpec + nsSpec;   % total AM state specificity
end

% Fitted slopes (linear fit of total specificity against density, per group)
pairs = {idxWA, idxPA; idxWQ, idxPQ};
densities = {drinkDensity, nonDrinkDensity};
slopeValues = [];
for m = 1:2
    for p = 1:2
        for g = 1:2
            idx = pairs{p,g};
            lm = fitlm(densities{m}(idx), totalSpecificity(idx));
            slopeValues(end+1) = lm.Coefficients.Estimate(2); %#ok<SAGROW>
        end
    end
end

%   Fig7A,Drinking Density          (same layout for Fig7B, Fig7C)
%   WA,WQ,PA,PQ
%   <one session per row; shorter groups end with empty cells>
%   (blank line)
%   Fig7F,Slope (Drink-Speci)        (same layout for Fig7I)
%   WA,PA,WQ,PQ
%   <4 slopes>
violinPanels = {'Fig7A', 'Drinking Density',     drinkDensity;
                'Fig7B', 'Non-drinking Density', nonDrinkDensity;
                'Fig7C', 'Total specificity',    totalSpecificity};
barPanels    = {'Fig7F', 'Slope (Drink-Speci)';
                'Fig7I', 'Slope (Nondrink-Speci)'};
groupSize = cellfun(@numel, groupIdx);
csvFile = fullfile(exportDir, 'Fig7ABCFI.csv');
fid = fopen(csvFile, 'w');
for v = 1:3
    fprintf(fid, '%s,%s\n', violinPanels{v,1}, violinPanels{v,2});
    fprintf(fid, '%s\n', strjoin(groupNames, ','));      % WA,WQ,PA,PQ (violin x-axis order)
    values = violinPanels{v,3};
    for r = 1:max(groupSize)
        cells = repmat({''}, 1, 4);
        for g = 1:4
            if r <= groupSize(g)
                cells{g} = sprintf('%.10g', values(groupIdx{g}(r)));
            end
        end
        fprintf(fid, '%s\n', strjoin(cells, ','));
    end
    fprintf(fid, '\n');
end
for b = 1:2
    fprintf(fid, '%s,%s\n', barPanels{b,1}, barPanels{b,2});
    fprintf(fid, 'WA,PA,WQ,PQ\n');                     % bar x-axis order
    fprintf(fid, '%s\n', strjoin(compose('%.10g', slopeValues(4*b-3:4*b)), ','));
    if b < 2
        fprintf(fid, '\n');
    end
end
fclose(fid);
fprintf('Saved %s\n', csvFile);

%% 5) Group-level module bar plots (FigS3), as in CategorizeNeuralState
% Uses the same module partitions (from the AM) as CategorizeNeuralState.
[amModuleMeans, rmModuleMeans] = deal(zeros(nSessions,3));
for j = 1:nSessions
    load(processedFile(j), 'amTrialSet', 'rmTrialSet');
    idx = partitions{j};
    amModuleMeans(j,:) = cellfun(@(b) mean(b,'all'), moduleBlocks(amTrialSet, idx));
    rmModuleMeans(j,:) = cellfun(@(b) mean(b,'all'), moduleBlocks(rmTrialSet, idx));
end
% Drop sessions with an empty module
amModuleMeans(any(isnan(amModuleMeans),2),:) = [];
rmModuleMeans(any(isnan(rmModuleMeans),2),:) = [];

%   FigS3 left panel,Recurrence modules (...)     (same layout for the right panel)
%   Within Module 1,Between Modules,Within Module 2
%   <one session per row>
panels = {'FigS3 left panel',  'Recurrence modules (Recurrence Values)', rmModuleMeans;
          'FigS3 right panel', 'Affinity modules (Affinity Values)',     amModuleMeans};
csvFile = fullfile(exportDir, 'FigS3.csv');
fid = fopen(csvFile, 'w');
for q = 1:2
    fprintf(fid, '%s,%s\n', panels{q,1}, panels{q,2});
    fprintf(fid, '%s\n', strjoin(moduleNames, ','));
    M = panels{q,3};
    for r = 1:size(M,1)
        fprintf(fid, '%s\n', strjoin(compose('%.10g', M(r,:)), ','));
    end
    if q < 2
        fprintf(fid, '\n');
    end
end
fclose(fid);
fprintf('Saved %s\n', csvFile);

%% 6) State specificity violin plots (FigS5A-D), as in RmAmSummary
seekThreshold = 3;
[amSpecDrink, amSpecNonDrink, rmSpecDrink, rmSpecNonDrink, ...
 amSpecSeek, amSpecNonSeek, rmSpecSeek, rmSpecNonSeek] = deal(zeros(nSessions,1));
for i = 1:nSessions
    load(processedFile(i), 'amTrialSet', 'rmTrialSet', 'drinkLabel', 'seekIntensity');
    siLabels = drinkLabel;
    siLabels(seekIntensity >  seekThreshold) = 1;
    siLabels(seekIntensity <= seekThreshold) = 0;
    [amSpecDrink(i), amSpecNonDrink(i)] = stateSpecificity(amTrialSet, drinkLabel);
    [rmSpecDrink(i), rmSpecNonDrink(i)] = stateSpecificity(rmTrialSet, drinkLabel);
    [amSpecSeek(i),  amSpecNonSeek(i)]  = stateSpecificity(amTrialSet, siLabels);
    [rmSpecSeek(i),  rmSpecNonSeek(i)]  = stateSpecificity(rmTrialSet, siLabels);
end

%   FigS5A,State specificity - Affinity Values (drinking labels)
%   WA Drinking,WA Non-drinking,WQ Drinking,...,PQ Non-drinking
%   <one session per row>
%   (blank line)  ... same for FigS5B, FigS5C, FigS5D
panels = {'FigS5A', 'State specificity - Affinity Values (drinking labels)',   amSpecDrink, amSpecNonDrink, {'Drinking','Non-drinking'};
          'FigS5B', 'State specificity - Recurrence Values (drinking labels)', rmSpecDrink, rmSpecNonDrink, {'Drinking','Non-drinking'};
          'FigS5C', 'State specificity - Affinity Values (seeking labels)',    amSpecSeek,  amSpecNonSeek,  {'Seeking','Non-seeking'};
          'FigS5D', 'State specificity - Recurrence Values (seeking labels)',  rmSpecSeek,  rmSpecNonSeek,  {'Seeking','Non-seeking'}};
csvFile = fullfile(exportDir, 'FigS5ABCD.csv');
fid = fopen(csvFile, 'w');
for q = 1:4
    fprintf(fid, '%s,%s\n', panels{q,1}, panels{q,2});
    % columns in the violin order: per group (WA, WQ, PA, PQ) state 1, then state 2
    header = {};
    cols = {};
    for g = 1:4
        for s = 1:2
            header{end+1} = sprintf('%s %s', groupNames{g}, panels{q,5}{s}); %#ok<SAGROW>
            v = panels{q,2+s};
            cols{end+1} = v(groupIdx{g}); %#ok<SAGROW>
        end
    end
    fprintf(fid, '%s\n', strjoin(header, ','));
    for r = 1:max(cellfun(@numel, cols))
        cells = repmat({''}, 1, 8);
        for c = 1:8
            if r <= numel(cols{c}) && ~isnan(cols{c}(r))
                cells{c} = sprintf('%.10g', cols{c}(r));
            end
        end
        fprintf(fid, '%s\n', strjoin(cells, ','));
    end
    if q < 4
        fprintf(fid, '\n');
    end
end
fclose(fid);
fprintf('Saved %s\n', csvFile);

%% 7) Cumulative explained variance (FigS6), as in PcaVsReference
explainedAll = zeros(5,nSessions);
for j = 1:nSessions
    load(processedFile(j), 'amTrialSet');
    [~, ~, ~, ~, explained] = pca(amTrialSet);
    explainedAll(:,j) = explained(1:5);   % variance explained by PC1-5
end
cumVar = cumsum(explainedAll,1)';         % sessions x 5

%   FigS6,Cumulative explained variance (%) of the affinity matrix
%   PC1,PC1-2,PC1-3,PC1-4,PC1-5
%   <one session per row>
csvFile = fullfile(exportDir, 'FigS6.csv');
fid = fopen(csvFile, 'w');
fprintf(fid, 'FigS6,Cumulative explained variance (%%) of the affinity matrix\n');
fprintf(fid, 'PC1,PC1-2,PC1-3,PC1-4,PC1-5\n');
for r = 1:nSessions
    fprintf(fid, '%s\n', strjoin(compose('%.10g', cumVar(r,:)), ','));
end
fclose(fid);
fprintf('Saved %s\n', csvFile);

%% 8) Gaussian kernel width comparison (FigS1), as in GaussianWidth
load(fullfile(resultDir,'GaussianWidthComparison.mat'));  % tvBySigma, peaksBySigma
sigmaNames = {'sigma=mean','sigma=mean/4','sigma=mean/8'};
nSigma = numel(sigmaNames);

% Best sigma per neuron: lowest (normalized TV + 1 - normalized peaks)
rescale01 = @(v) (v - min(v)) / (max(v) - min(v) + eps);
scoreAll = [];
for si = 1:nSigma
    score = [];
    for j = 1:numel(tvBySigma{si})
        score = [score, rescale01(tvBySigma{si}{j})' + (1 - rescale01(peaksBySigma{si}{j}))]; %#ok<AGROW>
    end
    scoreAll = [scoreAll; score]; %#ok<AGROW>
end
[~, bestSigmaIdx] = min(scoreAll, [], 1);
preferredCounts = histcounts(bestSigmaIdx, 0.5:1:(nSigma+0.5));

% Per-session means over neurons (sessions x sigma)
tvPerSession   = cell2mat(cellfun(@(c) cellfun(@mean, c)', tvBySigma,   'UniformOutput', false));
peakPerSession = cell2mat(cellfun(@(c) cellfun(@mean, c)', peaksBySigma, 'UniformOutput', false));

%   FigS1 lower left,Average smoothness - total variation (...)
%   sigma=mean,sigma=mean/4,sigma=mean/8
%   <one session per row>
%   (blank line)
%   FigS1 lower middle,Preserved signal details - number of peaks (...)
%   <same layout>
%   (blank line)
%   FigS1 lower right,Preferred Gaussian sigma per neuron (number of neurons)
%   sigma=mean,sigma=mean/4,sigma=mean/8
%   <3 counts>
csvFile = fullfile(exportDir, 'FigS1.csv');
fid = fopen(csvFile, 'w');
panels = {'FigS1 lower left',   'Average smoothness - total variation (per-session mean over neurons)', tvPerSession;
          'FigS1 lower middle', 'Preserved signal details - number of peaks (per-session mean over neurons)', peakPerSession};
for q = 1:2
    fprintf(fid, '%s,%s\n', panels{q,1}, panels{q,2});
    fprintf(fid, '%s\n', strjoin(sigmaNames, ','));
    M = panels{q,3};
    for r = 1:size(M,1)
        fprintf(fid, '%s\n', strjoin(compose('%.10g', M(r,:)), ','));
    end
    fprintf(fid, '\n');
end
fprintf(fid, 'FigS1 lower right,Preferred Gaussian sigma per neuron (number of neurons)\n');
fprintf(fid, '%s\n', strjoin(sigmaNames, ','));
fprintf(fid, '%s\n', strjoin(compose('%d', preferredCounts), ','));
fclose(fid);
fprintf('Saved %s\n', csvFile);
