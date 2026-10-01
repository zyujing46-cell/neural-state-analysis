% =========================================================================
% Main.m
% Recurrence-matrix (RM) / affinity-matrix (AM) analysis of rodent spike
% data during alcohol (A) and quinine-adulterated alcohol (Q) sessions, in
% Wistar (W) and alcohol-preferring P rats.
%
% The script is organised as independent sections, each switched on/off by
% a field of the `flag` struct below. Paths are resolved from the location of
% this file, so it can be run from any folder. All data (processed sessions,
% cross-session results) are saved under 'Rodent data set/';
% figures are saved under 'Decode_Latent_States/plots/'.
% Most sections read the raw session files in 'Rodent data set/fullAnalysis/'
% and the derived variables (firingRate, rmTrialSet, amTrialSet, drinkLabel,
% seekIntensity, ...) that earlier sections append to
% 'Rodent data set/Processed_sessions/'. Cross-session results
% (session labels, refModelCorr, ...) are saved to
% 'Rodent data set/Intermediate_results/'.
%
% Data dependencies between sections (sections are ordered so that, starting
% from only 'Rodent data set/fullAnalysis/', switching every flag on
% regenerates everything in one run):
%   SessionLabels -> Preprocess (firingRate, creates the processed files)
%   -> DrinkTime (drinkTime) -> Recurrence (rmSliding, dfcVecSliding)
%   -> TrialSetModel (trialSetRange, rmTrialSet, amTrialSet, dfcVec,
%      drinkLabel, seekIntensity; RefModelCorr.mat)
%   -> CategorizeNeuralState (moduleLabel, seekLabel)
%   All later sections only read these; PcaVsReference also reads RefModelCorr.mat,
%   and LabelMapPlot reads moduleLabel / seekLabel.
%
% Terminology
%   trial set        : run of <= 3 consecutive CS+ trials with the same label
%   drinkLabel      : trial-set label, 1 = drinking, 0 = non-drinking
%   seeking intensity: peak of the HRF-smoothed drinking time in a trial set
%                      (seekIntensity)
%   groups           : WA = Wistar+Alcohol, WQ = Wistar+Quinine,
%                      PA = P rat+Alcohol,  PQ = P rat+Quinine
%
% Helper functions are in the 'functions' folder (one file per function),
% which is added to the MATLAB path below.
% =========================================================================

close all
clearvars
clc

%% Section flags (1 = run the section, 0 = skip it)
% Flags are listed in the same order as the sections run (top to bottom).
% Starting from only the fullAnalysis folder, all flags can be switched on
% in a single run.
% ---- Core pipeline (saves data to Rodent data set; run these first, in this order) ----
flag.SessionLabels          = 0; % Rebuild per-session strain / condition labels in file order
flag.Preprocess             = 0; % Bin spike trains and smooth them with a Gaussian kernel
flag.DrinkTime              = 0; % Drinking time per trial
flag.Recurrence             = 0; % Sliding-window recurrence matrix
flag.TrialSetModel          = 0; % Trial-set RM, AM and seeking-intensity model (+ summary figure)
flag.CategorizeNeuralState  = 0; % MI between latent neural states (AM modules) and the seeking-intensity (SI) model

% ---- Analyses of the trial-set model ----
flag.RmAmSummary            = 0; % Violin plots + ANOVA of RM/AM state specificity
flag.StateTimeCourse        = 0; % Seeking-state distribution over time

% ---- Method figures (RM and AM) ----
flag.NeuronActivityPlot     = 0; % Example neuron firing rates
flag.DfcMatrixPlot          = 0; % Example dFC matrices
flag.DfcVectorPlot          = 0; % Example dFC vectors
flag.RecurrenceSlidingPlot  = 0; % Sliding-window RM with drinking strip
flag.RecurrenceTrialPlot    = 0; % Trial-set RM with drinking strip
flag.AffinityPlot           = 0; % AM with module / drinking strips

% ---- Behavior figures ----
flag.BehaviorPlot           = 0; % Behavior method plots
flag.CumSipperTime          = 0; % Accumulated time at the sipper
flag.LabelMapPlot           = 0; % Visualise trial-set labels across sessions

% ---- Main figures ----
flag.ReferenceModel         = 0; % Seeking affinity vs. seeking intensity (sessions 11, 42)
flag.MainFigureAll          = 0; % Main 2x2 figure for every session
flag.PcaVsReference         = 0; % PCA model vs. reference model
flag.SpecificityVsDensity   = 0; % State specificity vs. behavior density

% ---- Supplementary analyses ----
flag.GaussianWidth          = 1; % Gaussian filter width comparison
flag.RecurrenceWindowLength = 0; % Recurrence matrices with different window lengths
flag.ModelFactors           = 0; % Reference-model correlation vs. peak seeking intensity / number of neurons

%% Paths and session list
% Project_1 is the parent of the folder containing this file. When the file
% path is unavailable (e.g. running a single section), fall back to the
% current folder or its parent.
projectDir = fileparts(fileparts(mfilename('fullpath')));
if ~exist(fullfile(projectDir,'Rodent data set'),'dir')
    projectDir = pwd;
    if ~exist(fullfile(projectDir,'Rodent data set'),'dir')
        projectDir = fileparts(pwd);
    end
end
if ~exist(fullfile(projectDir,'Rodent data set'),'dir')
    error('Cannot find the ''Rodent data set'' folder; run Main.m from Project_1 or Decode_Latent_States.');
end
dataDir      = fullfile(projectDir,'Rodent data set');
rawDir       = fullfile(dataDir,'fullAnalysis/');
processedDir = fullfile(dataDir,'Processed_sessions');
resultDir    = fullfile(dataDir,'Intermediate_results'); % cross-session results for plots / later analysis
plotDir      = fullfile(projectDir,'Decode_Latent_States','plots');
addpath(fullfile(projectDir,'Decode_Latent_States','functions'));  % helper functions
if ~exist(processedDir,'dir')
    mkdir(processedDir);
end
if ~exist(resultDir,'dir')
    mkdir(resultDir);
end

% Session files only; auxiliary files (2CAP_SpikeTrains, dataSetVarsForML)
% do not match this pattern
sessionFiles = dir([rawDir '*_AllData.mat']);
nSessions = size(sessionFiles,1);

rawFile       = @(k) [rawDir sessionFiles(k).name];                % raw session data
processedFile = @(k) fullfile(processedDir, sessionFiles(k).name); % derived variables
sessName      = @(k) sessionFiles(k).name(1:end-4);               % file name without .mat

%% Default figure fonts
set(0,'DefaultAxesFontName','Times New Roman');
set(0,'DefaultTextFontName','Times New Roman');
setFontSize(40);

%% Session metadata and groups
% sessionType / animalType in 2CAP_SpikeTrains follow the row order of
% dataSetVarsForML (column 6 = data set name), not the order of sessionFiles.
% Sorting the data set names by date gives the sessionFiles order, so the labels
% are reordered the same way and saved as sessionStrain / sessionCondition.
% They are also built automatically when the saved files are missing.
if flag.SessionLabels || ~exist(fullfile(resultDir,'sessionStrain.mat'),'file') ...
        || ~exist(fullfile(resultDir,'sessionCondition.mat'),'file')
    load([rawDir 'dataSetVarsForML.mat'],'dataSetVarsForML');
    load([rawDir '2CAP_SpikeTrains.mat'],'sessionType','animalType');
    dataSetNames = dataSetVarsForML(2:end,6);   % row 1 is the header
    [dataSetNames, order] = sort(dataSetNames);
    fileNames = arrayfun(@(k) sessName(k), (1:nSessions)', 'UniformOutput', false);
    if ~isequal(dataSetNames, strrep(fileNames,'_AllData',''))
        error('Sorted data set names in dataSetVarsForML do not match the session files.');
    end
    sessionStrain    = animalType(order);   sessionStrain    = sessionStrain(:);
    sessionCondition = sessionType(order);  sessionCondition = sessionCondition(:);
    save(fullfile(resultDir,'sessionStrain.mat'),'sessionStrain');
    save(fullfile(resultDir,'sessionCondition.mat'),'sessionCondition');
    clear dataSetVarsForML sessionType animalType dataSetNames order fileNames
end
load(fullfile(resultDir,'sessionStrain.mat'));    % strain of each session ('W' or 'P')
load(fullfile(resultDir,'sessionCondition.mat')); % 'Regular' (A) or 'Regular + Qui' (Q)

isW = strcmp(sessionStrain,'W');
isA = strcmp(sessionCondition,'Regular');
idxWA = find( isW &  isA);
idxWQ = find( isW & ~isA);
idxPA = find(~isW &  isA);
idxPQ = find(~isW & ~isA);
groupIdx    = {idxWA, idxWQ, idxPA, idxPQ};
groupNames  = {'WA','WQ','PA','PQ'};
groupColors = lines(4);   % one color per group (MATLAB default line colors)
groupOrder  = vertcat(groupIdx{:});   % sessions sorted WA, WQ, PA, PQ

%% Preprocess spike data: bin and smooth with a Gaussian kernel
if flag.Preprocess
    binSize = 0.1;     % spike-count bin size in seconds (100 ms)
    for i = 1:nSessions
        load(rawFile(i),'spkData');
        firingRate = spikesToFiringRate(spkData, binSize, 1/8); % kernel std = 1/8
        save(processedFile(i),"firingRate");   % creates the file (overwrites an existing one)
    end
end

%% Drinking time per trial
if flag.DrinkTime
    for i = 1:nSessions
        load(rawFile(i));
        drinkTime = drinkingTime(trialTimes, trialTypes, approach, bodyCoords, boxCoords);
        save(processedFile(i),"drinkTime",'-append');
    end
end

%% Sliding-window recurrence matrices
% Recurrence matrix between sliding-window dFC (dynamic functional
% connectivity) vectors; rmSliding and dfcVecSliding are appended to each
% preprocessed file and a heatmap is saved.
if flag.Recurrence
    windowLength = 500;          % sliding-window length (bins)
    slidingstep = 250; % sliding-window step (bins)
    savepath = fullfile(plotDir,'recurrence_matrix','wl_50s_sl_25s');
    for i = 1:nSessions
        load(processedFile(i));
        [rmSliding,dfcVecSliding] = slidingWindowRecurrence(firingRate,windowLength,slidingstep);
        rmSliding(isnan(rmSliding)) = 0; % windows with undefined correlation -> 0
        save(processedFile(i),"rmSliding","dfcVecSliding",'-append');

        h = figure;
        hm = heatmap(rmSliding);
        colormap jet;
        title(sprintf('%s, %s rat, Recurrence matrix for WL=%d, SL=%d',sessionCondition{i},sessionStrain{i},windowLength,slidingstep));
        hm.XDisplayLabels = nan(size(hm.XDisplayData)); % hide per-window labels
        hm.YDisplayLabels = nan(size(hm.YDisplayData));
        grid off
        saveFigureFiles(h, savepath, sessName(i));
    end
end

%% Trial-set model: recurrence matrix, affinity matrix and seeking intensity
% For each session the CS+ trials are grouped into trial sets (runs of <= 3
% consecutive trials with the same drinking label) and trialSetModel computes:
%   rmTrialSet    : recurrence matrix between the dFC vectors of the trial sets
%   amTrialSet : affinity matrix derived from rmTrialSet
%   seekIntensity  : seeking intensity of each set from the seeking-intensity
%                    model (drinking time per trial convolved with a canonical
%                    HRF, see seekingIntensityCurve); the peak of the model within
%                    the set
% These are appended to the processed session file, and a 2x2 summary figure
% (drinking behavior, RM, seeking affinity, AM) is saved per session.
if flag.TrialSetModel
    binSize = 0.1;     % spike-count bin size in seconds (100 ms)
    refModelCorr = []; % correlation between seeking affinity and seeking intensity
    setFontSize(12);
    savepath = fullfile(plotDir,'TrialSetModel');

    for j = 1:nSessions
        load(rawFile(j));
        load(processedFile(j));
        [drinkbehav, sortOrder] = drinkingLabels(trialTimes, approach);
        S = trialSetModel(firingRate, drinkbehav, trialTimes(sortOrder), drinkTime, binSize);
        save(processedFile(j),'-struct','S','trialSetRange','amTrialSet','rmTrialSet','dfcVec', ...
            'drinkLabel','seekIntensity','-append');

        % Y-axis labels of the RM and AM heatmaps, one per trial set:
        %   s(n,x) : drinking trial set (drinkLabel = 1)
        %            n = number of trials in the set (1-3)
        %            x = total drinking time of the set from the seeking-
        %                intensity model, i.e. siCurve summed over the set's
        %                trials (seekIntensity is the peak, not this sum)
        %   ns(n)  : non-drinking trial set (drinkLabel = 0); n = number of trials
        rowLabels = cell(size(S.drinkLabel));
        for k = 1:numel(S.trialSetRange)
            iv = S.trialSetRange{k};
            if S.drinkLabel(k) == 1
                rowLabels{k} = sprintf('s(%d,%.1f)', diff(iv)+1, sum(S.siCurve(iv(1):iv(2))));
            else
                rowLabels{k} = sprintf('ns(%d)', diff(iv)+1);
            end
        end

        h = figure;
        % (1) Drinking time per trial (right) and seeking intensity curve (left)
        subplot(2,2,1)
        hold on;
        yyaxis right;
        set(gca,'YColor','k');
        [h1,h2] = plotDrinkMarkers(1:numel(S.drinkbehav), S.drinkTime, S.drinkbehav==1, 6);
        ylabel('Drinking Time(s)');
        xlabel('Trial Number');
        set(gca,'Position',[0.07, 0.55, 0.35, 0.35]);
        title('Drinking Behavior');
        yyaxis left;
        set(gca,'YColor',[0, 0.5, 0]);
        ylabel('Seeking Intensity');
        plot(S.siCurve,'Color',[0, 0.5, 0]);
        legend([h1, h2], {'Drinking','Non-drinking'});
        hold off;

        % (2) Recurrence matrix
        subplot(2,2,2)
        hm = heatmap(S.rmTrialSet);
        hm.FontName = 'Times New Roman'; % heatmap ignores the default font settings
        colormap jet;
        hm.XLabel = 'Time-ordered Trial Set dFCs';
        hm.YDisplayLabels = rowLabels;
        title(sprintf('%s, %s rat, Recurrence Matrix',sessionCondition{j},sessionStrain{j}));
        set(gca,'Position',[0.555, 0.55, 0.35, 0.35]);

        % (3) Seeking intensity (right) and the affinity row of the
        %     peak-intensity trial set, i.e. the "seeking affinity" (left)
        subplot(2,2,3)
        yyaxis right;
        set(gca,'YColor','k');
        plotDrinkMarkers(1:numel(S.drinkLabel), S.seekIntensity, S.drinkLabel==1, 6);
        ylabel('Seeking Intensity');
        yyaxis left;
        [~, peak] = max(S.seekIntensity);
        seekAff = S.amTrialSet(peak,:);
        plot(1:length(S.amTrialSet), seekAff);
        r = corr(S.seekIntensity', seekAff', 'type','Pearson');
        refModelCorr = [refModelCorr, r];
        xlabel('Time');
        ylabel('Affinity Values');
        title(sprintf('Affinity and Behavior, r=%.2f', r));
        set(gca,'Position',[0.07, 0.1, 0.35, 0.35]);

        % (4) Affinity matrix
        subplot(2,2,4)
        hm = heatmap(S.amTrialSet);
        hm.FontName = 'Times New Roman';
        colormap jet;
        hm.XLabel = 'Time-ordered Trial Set dFCs';
        hm.YDisplayLabels = rowLabels;
        title('Affinity Matrix');
        set(gcf,'Position',[100, 100, 800, 800]);

        saveFigureFiles(h, savepath, sessName(j));
    end

    save(fullfile(resultDir,'RefModelCorr.mat'),'refModelCorr');
    setFontSize(40);
end

%% Modularity of the affinity matrix and mutual information with behavior
% Splits each affinity matrix into two Louvain modules, compares affinity
% within/between modules, and measures the mutual information (MI) between
% the modules and the behavior labels. Saves moduleLabel and seekLabel.
% Louvain is stochastic, so the RNG is seeded and each session's partition is
% computed once and reused by every analysis below (including the threshold sweep).
if flag.CategorizeNeuralState
    rng(1);
    partitions = cell(1,nSessions);
    for j = 1:nSessions
        load(processedFile(j), 'amTrialSet');
        partitions{j} = twoModulePartition(amTrialSet);
    end

    % ---- Single session (11): affinity within module 1 / between / within module 2 ----
    load(processedFile(11));
    idx = partitions{11};
    blocks = moduleBlocks(amTrialSet, idx);
    figure;
    hatchedBars(cellfun(@(b) mean(b,'all'), blocks), []);
    [~, pExample12] = ttest2(blocks{1}, blocks{2});
    [~, pExample23] = ttest2(blocks{2}, blocks{3});
    ylim([0 1]);
    ylabel('Affinity Values');
    xlim([0.5 3.5]);
    axis square;

    % ---- All sessions: the same three means for AM and RM ----
    [amModuleMeans, rmModuleMeans] = deal(zeros(nSessions,3));
    for j = 1:nSessions
        load(processedFile(j));
        idx = partitions{j};
        amModuleMeans(j,:)      = cellfun(@(b) mean(b,'all'), moduleBlocks(amTrialSet, idx));
        rmModuleMeans(j,:) = cellfun(@(b) mean(b,'all'), moduleBlocks(rmTrialSet, idx));
    end
    % Drop sessions with an empty module
    amModuleMeans(any(isnan(amModuleMeans),2),:) = [];
    rmModuleMeans(any(isnan(rmModuleMeans),2),:) = [];
    plotModuleSummary(amModuleMeans, 'Affinity Values');
    [pRM12, pRM23] = plotModuleSummary(rmModuleMeans, 'Recurrence Values');
    [~, pAMvsRM] = ttest2(rmModuleMeans(:), amModuleMeans(:));

    % ---- MI between modules and drinking / seeking labels ----
    seekThreshold = 3;
    [miDrink, miSeek, miNull] = deal(zeros(1,nSessions));
    nModules = zeros(1,nSessions); % number of modules found
    for j = 1:nSessions
        load(processedFile(j));
        idx = partitions{j};
        moduleLabel = idx';
        moduleLabel(moduleLabel==2) = 0;
        seekLabel = double(seekIntensity > seekThreshold); % 1 = seeking trial set
        save(processedFile(j),"moduleLabel","seekLabel",'-append');

        nModules(j) = max(idx);
        miDrink(j) = mutualInformation(drinkLabel', idx);
        miSeek(j)  = mutualInformation(seekLabel', idx);
        % Null model: mean MI over 50 shuffles of the seeking labels
        nullMI = zeros(1,50);
        for k = 1:50
            nullMI(k) = mutualInformation(seekLabel(randperm(length(seekLabel)))', idx);
        end
        miNull(j) = mean(nullMI);
    end

    figure;
    violinplot([miNull, miDrink, miSeek], repelem(1:3, nSessions), ...
        'ViolinColor', [0.8,0.8,0.8; 0.4,0.4,0.4; 0.1,0.1,0.1]);
    xticks(1:3);
    xticklabels({'Null', 'Original Label', 'Seeking Intensity'});
    title('State–Behavior Mutual Information');
    ylabel('Mutual Information');
    [~, pMiNullVsDrink] = ttest(miNull, miDrink);
    [~, pMiDrinkVsSeek] = ttest(miDrink, miSeek);
    % NOTE: sigstar uses pRM12/pRM23 from the RM bar plot above, not pMiNullVsDrink/pMiDrinkVsSeek computed here
    sigstar({{'Null','Original Label'}, {'Original Label','Seeking Intensity'}}, [pRM12, pRM23]);
    ylim([0 1])

    % ---- Seeking-threshold sweep: mean MI with the seeking labels ----
    thresholds = 0.5:0.5:15.5;
    meanMiSeek = zeros(size(thresholds));
    for t = 1:numel(thresholds)
        for j = 1:nSessions
            load(processedFile(j), 'drinkLabel', 'seekIntensity');
            idx = partitions{j};
            miDrink(j) = mutualInformation(drinkLabel', idx);
            miSeek(j)  = mutualInformation(double(seekIntensity > thresholds(t))', idx);
            miNull(j)  = mutualInformation(randi([1, 2], 1, length(idx))', idx); % random labels
        end
        meanMiSeek(t) = mean(miSeek);
    end

    shades = [0.8,0.8,0.8; 0.5,0.5,0.5; 0.1,0.1,0.1];
    figure;
    plot(thresholds, meanMiSeek, '-o', 'MarkerFaceColor',shades(3,:), 'MarkerSize',9, 'LineWidth',2, 'color',shades(3,:));
    xlabel('Threshold');
    ylabel('Mean Mutual Information');
    axis square;
    ylim([0.01 0.25]);
    hold on;
    % Reference lines (from the last threshold iteration)
    plot(thresholds, mean(miDrink)*ones(size(thresholds)), '-', 'LineWidth',4, 'color',shades(2,:));
    plot(thresholds, mean(miNull)*ones(size(thresholds)),  '-', 'LineWidth',4, 'color',shades(1,:));
    legend('Seeking/Non-seeking','Drinking/Non-drinking','Null Model');
end

%% State specificity of RM/AM: violin plots and ANOVA
% Specificity = mean within-state value (s-s or ns-ns pairs) minus mean
% between-state value (s-ns pairs). Computed with the drinking labels and
% with seeking-intensity labels (seekIntensity > seekThreshold).
if flag.RmAmSummary
    seekThreshold = 3;
    [amSpecDrink, amSpecNonDrink, rmSpecDrink, rmSpecNonDrink, ...
     amSpecSeek, amSpecNonSeek, rmSpecSeek, rmSpecNonSeek] = deal(zeros(nSessions,1));

    for i = 1:nSessions
        load(processedFile(i));
        siLabels = drinkLabel;
        siLabels(seekIntensity >  seekThreshold) = 1;
        siLabels(seekIntensity <= seekThreshold) = 0;

        [amSpecDrink(i),    amSpecNonDrink(i)]    = stateSpecificity(amTrialSet, drinkLabel);
        [rmSpecDrink(i),  rmSpecNonDrink(i)]  = stateSpecificity(rmTrialSet, drinkLabel);
        [amSpecSeek(i), amSpecNonSeek(i)] = stateSpecificity(amTrialSet, siLabels);
        [rmSpecSeek(i), rmSpecNonSeek(i)] = stateSpecificity(rmTrialSet, siLabels);
    end

    grayPairs = repmat([0.1 0.1 0.1; 0.8 0.8 0.8], 4, 1); % dark = s, light = ns
    drinkNames = {'Drinking','Non-drinking'};
    seekNames  = {'Seeking','Non-seeking'};

    % Drinking labels
    pairedGroupViolin(amSpecDrink,   amSpecNonDrink,   groupIdx, grayPairs, 'State Specificity', 'Affinity Values',   drinkNames, [-0.2 0.8]);
    pairedGroupViolin(rmSpecDrink, rmSpecNonDrink, groupIdx, grayPairs, 'State Specificity', 'Recurrence Values', drinkNames, [-0.2 0.8]);
    % ANOVA: Strain x Stim x State (d/nd) x Measure (AM/RM)
    disp(groupAnova({amSpecDrink, amSpecNonDrink, rmSpecDrink, rmSpecNonDrink}, groupIdx, ...
        {'State','Measure'}, {{'d','nd','d','nd'}, {'AM','AM','RECU','RECU'}}));

    % Seeking-intensity labels
    pairedGroupViolin(amSpecSeek,   amSpecNonSeek,   groupIdx, grayPairs, 'State Specificity', 'Affinity Values',   seekNames, [-0.2 0.8]);
    pairedGroupViolin(rmSpecSeek, rmSpecNonSeek, groupIdx, grayPairs, 'State Specificity', 'Recurrence Values', seekNames, [-0.2 0.8]);
    % ANOVA: Strain x Stim x State (s/ns) x Measure (AM/RM)
    disp(groupAnova({amSpecSeek, amSpecNonSeek, rmSpecSeek, rmSpecNonSeek}, groupIdx, ...
        {'State','Measure'}, {{'s','ns','s','ns'}, {'AM','AM','RECU','RECU'}}));

    % ANOVA: drinking vs. seeking labels (Method), separately for AM and RM
    methodLevels = {'(Non)Drink/','(Non)Drink/','(Non)Seek','(Non)Seek'};
    disp(groupAnova({amSpecDrink, amSpecNonDrink, amSpecSeek, amSpecNonSeek}, groupIdx, ...
        {'State','Method'}, {{'s','ns','s','ns'}, methodLevels}));
    disp(groupAnova({rmSpecDrink, rmSpecNonDrink, rmSpecSeek, rmSpecNonSeek}, groupIdx, ...
        {'State','Method'}, {{'s','ns','s','ns'}, methodLevels}));
end

%% Seeking / non-seeking state distribution over time
% Average the trial-set dFC vectors of seeking and non-seeking sets into
% two template states, then correlate every sliding-window dFC with each
% template to follow the states over time.
if flag.StateTimeCourse
    seekThreshold = 3;

    % ---- Example session (18): templates and their time courses ----
    load(processedFile(18));
    [sTmpl, nsTmpl] = stateTemplates(dfcVec, seekIntensity, seekThreshold);
    for tmpl = {sTmpl, nsTmpl}
        C = vec2sym(tmpl{1});
        C = C - diag(diag(C));
        uplim = prctile(C(:),95);
        figure;
        set(gca,'Color','white');
        set(gcf,'Color','white');
        imagesc(C);
        caxis([-uplim, uplim]);
        colormap jet;
        colorbar;
        axis square;
        set(gca,'XTick',[],'YTick',[]);
    end

    figure;
    plot(corr(sTmpl, dfcVecSliding,'Rows','pairwise'), 'Linewidth',2.5,'color',[0.1,0.1,0.1]);
    hold on;
    plot(corr(nsTmpl,dfcVecSliding,'Rows','pairwise'), 'Linewidth',2.5,'color',[0.8,0.8,0.8]);
    legend('Seeking','Non-Seeking');

    % ---- All sessions: correlation time courses (first nWin windows) ----
    nWin = 150;
    [sTimeCourse, nsTimeCourse] = deal(zeros(nSessions, nWin));
    for i = 1:nSessions
        load(processedFile(i));
        [sTmpl, nsTmpl] = stateTemplates(dfcVec, seekIntensity, seekThreshold);
        c = corr(sTmpl,  dfcVecSliding,'Rows','pairwise');  sTimeCourse(i,:)  = c(1:nWin);
        c = corr(nsTmpl, dfcVecSliding,'Rows','pairwise');  nsTimeCourse(i,:) = c(1:nWin);
    end

    % Group mean +/- SEM, smoothed with a 5-point moving average
    % (sessions containing NaN are dropped for the groups marked true)
    [sMu,  sSem]  = groupMeanSEM(sTimeCourse,  groupIdx, [false true  true true], 1);
    [nsMu, nsSem] = groupMeanSEM(nsTimeCourse, groupIdx, [false false true true], 1);
    smooth5 = @(m) movmean(m, 5, 2);

    plotGroupShaded(1:nWin, smooth5(sMu), smooth5(sSem), groupColors, 2.5);
    title('Seeking State Correlation Over Time');
    legend(groupNames);
    xlabel('Time (dFC Number)');
    ylabel('Correlations');
    ylim([0 0.5]);

    plotGroupShaded(1:nWin, smooth5(nsMu), smooth5(nsSem), groupColors, 2.5);
    title('Non-seeking State Correlation Over Time');
    legend(groupNames);
    xlabel('Time (dFC Number)');
    ylabel('Correlations');

    % ---- Repeated-measures ANOVA: State x Time within, Strain x Stim between ----
    Y = [sTimeCourse(groupOrder,:), nsTimeCourse(groupOrder,:)]; % [s(1..nWin), ns(1..nWin)]
    [Strain, Stim] = groupFactors(groupIdx);
    good = all(~isnan(Y), 2);
    if any(~good)
        warning('Dropping %d subjects with NaNs in their s/ns time series.', sum(~good));
        Y = Y(good,:);
        Strain = Strain(good);
        Stim = Stim(good);
    end
    assert(size(Y,1) > 1, 'Need at least 2 subjects after cleaning.');

    withinDesign = table(categorical([repmat({'s'},nWin,1); repmat({'ns'},nWin,1)]), ...
                   categorical([(1:nWin)'; (1:nWin)']), 'VariableNames', {'State','Time'});
    [rm, T] = fitGroupRm(Y, Strain, Stim, withinDesign, 2*nWin);
    showRanova(rm, 'State*Time', 'State*Time', true);

    % Each state separately
    rmModelS  = fitrm(T, sprintf('Var1-Var%d ~ Strain*Stim', nWin), 'WithinDesign', withinDesign(withinDesign.State=="s",:));
    showRanova(rmModelS, 'Time', 'Time, State = s', false);
    rmModelNs = fitrm(T, sprintf('Var%d-Var%d ~ Strain*Stim', nWin+1, 2*nWin), 'WithinDesign', withinDesign(withinDesign.State=="ns",:));
    showRanova(rmModelNs, 'Time', 'Time, State = ns', false);
end

%% Method figure: example neuron firing rates
% Firing rates of 5 random neurons (session 1, bins 5000-5500), stacked vertically
if flag.NeuronActivityPlot
    load(processedFile(1));
    nNeurons = 5;
    neurons = randperm(size(firingRate,1), nNeurons);
    traces = firingRate(neurons, 5000:5500);
    offset = 1.1 * (max(traces(:)) - min(traces(:))); % vertical spacing between traces
    time = (0:500)/10;

    figure;
    set(gca,'Color','white','FontSize',30,'LineWidth',2);
    set(gcf,'Color','white');
    % Style the axis labels (the text is set below; the style is kept)
    xlabel('X-axis','FontSize',25,'FontWeight','bold');
    ylabel('Y-axis','FontSize',25,'FontWeight','bold');
    hold on;
    for k = 1:nNeurons
        plot(time, traces(k,:) + (k-1)*offset, 'Color',[0, 0.5, 0.8], 'LineWidth',3);
    end
    for k = 1:nNeurons
        yline((k-1)*offset, '--k', 'LineWidth',1.5); % baseline of each trace
    end
    xlabel('Time (0.1 Sec)');
    ylabel('Ind. Neuron Firing Rates');
    yticks((0:nNeurons-1) * offset);
    yticklabels(arrayfun(@(k) sprintf(' %d',k), 1:nNeurons, 'UniformOutput',false));
    ylim([-0.3, nNeurons*offset]);
    axis square;
    ax = gca;
    ax.XLabel.Position = ax.XLabel.Position + [0, 4.1, 0];
    hold off;
end

%% dFC matrix examples (first 4 trial-set dFCs of session 8)
if flag.DfcMatrixPlot
    load(processedFile(8));
    for k = 1:4
        figure;
        set(gca,'Color','white');
        set(gcf,'Color','white');
        imagesc(vec2sym(dfcVec(:,k)));
        colormap jet;
        colorbar('southoutside');
        axis square;
        set(gca,'XTick',[],'YTick',[]);
    end
end

%% dFC vector examples (first 30 entries shown as a column image)
if flag.DfcVectorPlot
    load(processedFile(8));
    for k = 1:4
        figure;
        imagesc(dfcVec(1:30,k));
        colormap(jet);
        caxis([-0.2,1]);
        axis image;
        set(gca,'XTick',[],'YTick',[]);
    end
end

%% Sliding-window recurrence matrix with drinking-trial strip (session 61)
if flag.RecurrenceSlidingPlot
    slidingstep = 250; % sliding-window step (bins), as in the recurrence section
    binSize = 0.1;     % spike-count bin size in seconds (100 ms)
    load(processedFile(61));
    load(rawFile(61));
    n = size(rmSliding,2);

    % Windows that contain a drinking trial (window step in seconds =
    % slidingstep*binSize) and the preceding windows (50% overlap)
    win = ceil(trialTimes(approach(:,1,1)==1) / (slidingstep*binSize));
    drinkWindowMask = zeros(size(rmSliding));
    drinkWindowMask(:,win) = 1;
    drinkWindowMask(win,:) = 1;
    win(win==1) = [];
    drinkWindowMask(win-1,:) = 1;
    drinkWindowMask(:,win-1) = 1;

    figure;
    imagesc(rmSliding);
    colormap('jet');
    axis square;
    set(gca,'Color',[0.8, 0.9, 1],'XTick',[],'YTick',[]);
    drawStateStrip(drinkWindowMask(1,:), n, 8);
    colorbar;
end

%% Trial-set recurrence matrix with drinking/non-drinking strip (session 11)
if flag.RecurrenceTrialPlot
    load(processedFile(11));
    figure;
    imagesc(rmTrialSet);
    set(gca,'FontSize',40);
    colormap jet;
    axis square;
    colorbar;
    set(gca,'Color',[0.8, 0.9, 1],'XTick',[],'YTick',[]);
    drawStateStrip(drinkLabel, size(rmTrialSet,2), 1);
    colorbar;
end

%% Affinity matrix examples with module (session 11) and behavior (session 18) strips
if flag.AffinityPlot
    % ---- Session 11: Louvain module strip ----
    load(processedFile(11));
    figure;
    imagesc(amTrialSet);
    set(gca,'FontSize',40);
    colormap jet;
    colorbar;
    axis square;
    set(gca,'Color',[0.8, 0.9, 1],'XTick',[],'YTick',[]);
    idx = twoModulePartition(amTrialSet);
    idx(idx==2) = 0; % module 1 -> black, module 2 -> white
    drawStateStrip(idx, size(rmTrialSet,2), 1);
end

%% Behavior method plots (example session 6 and all sessions)
if flag.BehaviorPlot
    purple = [0.4940, 0.1840, 0.5560];
    load(rawFile(6));
    load(processedFile(6));
    drinkbehav = drinkingLabels(trialTimes, approach);
    keep = drinkbehav > 0;                 % CS+ trials
    drinkbehav = drinkbehav(keep);
    dt = drinkTime(keep);            % drinking time per CS+ trial
    x = 1:numel(dt);
    siCurve = seekingIntensityCurve(dt);       % convolved behavior model

    % (1) Raw drinking time per CS+ trial
    figure;
    set(gca,'YColor','k');
    [h1,h2] = plotDrinkMarkers(x, dt, drinkbehav==1, 20);
    legend([h1, h2], {'Drinking','Non-drinking'});
    ylabel('Drinking time(s)');
    xlabel('Trial Number');
    axis square;
    set(gca,'LineWidth',2.5);

    % (2) Behavior model (right) and trial-set seeking intensity (left),
    %     each trial-set marker placed at the trial where the curve peaks
    figure;
    yyaxis right;
    set(gca,'YColor','k');
    plot(siCurve,'LineWidth',3,'Color',purple);
    hold on;
    set(gca,'LineWidth',2.5);
    yyaxis left;
    set(gca,'YColor',purple);
    peakTrial = zeros(size(trialSetRange));
    for k = 1:numel(trialSetRange)
        iv = trialSetRange{k};
        [~, m] = max(siCurve(iv(1):iv(2)));
        peakTrial(k) = iv(1) + m - 1;
    end
    [h1,h2] = plotDrinkMarkers(peakTrial, seekIntensity, drinkLabel==1, 20);
    legend([h1, h2], {'Drinking','Non-drinking'});
    ylabel('Seeking Intensity (per Trial Set)');
    xlabel('Trial Number');
    axis square;

    % (3) Raw drinking time (left) with the behavior model (right)
    figure;
    yyaxis left;
    set(gca,'YColor','k');
    [h1,h2] = plotDrinkMarkers(x, dt, drinkbehav==1, 20);
    ylabel('Drinking Time(s)');
    xlabel('Trial Number');
    yyaxis right;
    set(gca,'YColor',purple);
    plot(siCurve,'LineWidth',3,'Color',purple);
    legend([h1, h2], {'Drinking','Non-drinking'});
    ylabel('Seeking Intensity (per Trial)');
    axis square;
    set(gca,'LineWidth',2.5);

    % (4) Behavior model of all sessions (sessions x CS+ trials)
    siCurveAll = [];
    for j = 1:nSessions
        load(rawFile(j));
        load(processedFile(j));
        drinkbehav = drinkingLabels(trialTimes, approach);
        siCurveAll = [siCurveAll; seekingIntensityCurve(drinkTime(drinkbehav > 0))];
    end

    % Group mean +/- SEM
    [mu, sem] = groupMeanSEM(siCurveAll, groupIdx, false(1,4), 1);
    plotGroupShaded(1:size(siCurveAll,2), mu, sem, groupColors, 4);
    xlabel('Trial Number');
    ylabel('Seeking Intensity (per Trial)');
    legend(groupNames);
    title('Temporal Dynamics of Seeking Intensity ');

    % Repeated-measures ANOVA: Time within, Strain x Stim between
    % NOTE: number of time points = number of WA sessions, as in the original code
    groupTimeRanova(siCurveAll(groupOrder,:), groupIdx, numel(idxWA));
end

%% Accumulated time at the sipper
% Cumulative drinking time vs. session time, averaged per group, followed by a
% repeated-measures ANOVA of cumulative drinking time vs. trial number.
if flag.CumSipperTime
    % ---- vs. session time (first nFrames video frames) ----
    nFrames = 110000;
    cumDrinkTimeFrame = zeros(nFrames, nSessions);
    for i = 1:nSessions
        load(rawFile(i));
        [~, perFrame] = drinkingTime(trialTimes, trialTypes, approach, bodyCoords, boxCoords);
        c = cumsum(perFrame);
        cumDrinkTimeFrame(:,i) = c(1:nFrames);
    end
    [mu, sem] = groupMeanSEM(cumDrinkTimeFrame', groupIdx, false(1,4), 0);
    plotGroupShaded(bodyCoords{1}(1:nFrames), mu, sem, groupColors, 4);
    xlabel('Time(s)');
    ylabel('Accumulated Time');
    legend(groupNames);
    title('Accumulated Time at the Sipper')

    % ---- Cumulative drinking time per CS+ trial (for the ANOVA) ----
    cumDrinkTimeTrial = [];  % sessions x trials
    for i = 1:nSessions
        load(rawFile(i));
        load(processedFile(i));
        drinkbehav = drinkingLabels(trialTimes, approach);
        cumDrinkTimeTrial = [cumDrinkTimeTrial; cumsum(drinkTime(drinkbehav > 0))];
    end

    % ---- Repeated-measures ANOVA: Time within, Strain x Stim between ----
    % NOTE: the number of time points is taken as the number of WA sessions
    % (kept from the original code); size(cumDrinkTimeTrial,2) is likely intended.
    groupTimeRanova(cumDrinkTimeTrial(groupOrder,:), groupIdx, numel(idxWA));
end

%% Visualise trial-set labels across sessions
if flag.LabelMapPlot
    maxTrialSets = 40; % label matrices are NaN-padded to this many trial sets
    [drinkLabelMap, moduleLabelMap, seekLabelMap] = deal(nan(nSessions,maxTrialSets));
    for i = 1:nSessions
        load(processedFile(i));
        n = length(drinkLabel);
        drinkLabelMap(i,1:n) = drinkLabel; % drinking labels
        moduleLabelMap(i,1:n) = moduleLabel;   % Louvain module labels
        seekLabelMap(i,1:n)  = seekLabel;    % seeking labels (threshold 3)
    end
    setFontSize(25);
    % NOTE: the last two titles appear swapped relative to the data
    % (moduleLabelMap = modules, seekLabelMap = seeking labels).
    plotLabelMap(drinkLabelMap, 'Drinking/Non-drinking');
    plotLabelMap(moduleLabelMap, 'Seeking/Non-seeking(Th=3)');
    plotLabelMap(seekLabelMap,  'State 1/State 2');
    setFontSize(40);
end

%% Reference model: seeking affinity vs. seeking intensity (sessions 11 and 42)
if flag.ReferenceModel
    binSize = 0.1;     % spike-count bin size in seconds (100 ms)
    for j = [11, 42]
        load(rawFile(j));
        load(processedFile(j));
        [drinkbehav, sortOrder] = drinkingLabels(trialTimes, approach);
        S = trialSetModel(firingRate, drinkbehav, trialTimes(sortOrder), drinkTime, binSize);
        [~, peak] = max(S.seekIntensity);
        seekAff = S.amTrialSet(peak,:);

        figure;
        c = lines(6);
        [h1,h2,h4] = plotIntensityAndCurve(S.drinkLabel, S.seekIntensity, seekAff, c(6,:), '^', 20, 'Functional Seeking Affinity');
        title('Affinity and Behavior');
        legend([h1, h2, h4], {'Drinking','Non-drinking','Seeking AM'});

        figure;
        imagesc(S.amTrialSet);
        colormap jet;
        colorbar;
        set(gca,'YTick',1:numel(S.drinkLabel),'YTickLabel',stateNames(S.drinkLabel),'FontSize',25);
        title(sprintf('%s, %s rat, Affinity Matrix',sessionCondition{j},sessionStrain{j}),'FontSize',40);
        axis square;

        figure;
        plotLinearFit(seekAff, S.seekIntensity, 'gray');
        xlabel('Functional Seeking Affinity');
        ylabel('Seeking Intensity');
    end
end

%% Main figure for all sessions
% 2x2 figure per session: seeking affinity, its linear fit, PC1 score of
% the affinity matrix and its linear fit, each against seeking intensity.
if flag.MainFigureAll
    binSize = 0.1;     % spike-count bin size in seconds (100 ms)
    setFontSize(20);
    savepath = fullfile(plotDir,'MainFigureAll');
    for j = 1:nSessions
        load(rawFile(j));
        load(processedFile(j));
        [drinkbehav, sortOrder] = drinkingLabels(trialTimes, approach);
        S = trialSetModel(firingRate, drinkbehav, trialTimes(sortOrder), drinkTime, binSize);
        [~, peak] = max(S.seekIntensity);
        seekAff = S.amTrialSet(peak,:);
        [~, score] = pca(S.amTrialSet);

        h = figure;
        subplot(2,2,1);
        set(gca,'Position',[0.07, 0.6, 0.35, 0.35]);
        plotIntensityAndCurve(S.drinkLabel, S.seekIntensity, seekAff, [0, 0.4470, 0.7410], '^', 10, 'Functional Seeking Affinity');
        title('Affinity and Behavior');

        subplot(2,2,2);
        set(gca,'Position',[0.555, 0.6, 0.35, 0.35]);
        plotLinearFit(seekAff, S.seekIntensity, 'purple');
        xlabel('Functional Seeking Affinity');
        ylabel('Seeking Intensity');

        subplot(2,2,3);
        set(gca,'Position',[0.07, 0.1, 0.35, 0.35]);
        plotIntensityAndCurve(S.drinkLabel, S.seekIntensity, score(:,1), [0.8, 0.2, 0.5], 'h', 10, 'PC1 Score');
        title('PC1 and Behavior');

        subplot(2,2,4);
        set(gca,'Position',[0.555, 0.1, 0.35, 0.35]);
        plotLinearFit(score(:,1), S.seekIntensity, 'purple');
        xlabel('PC1 Score');
        ylabel('Seeking Intensity');

        set(gcf,'Position',[100, 100, 1200, 1200]);
        saveFigureFiles(h, savepath, sessName(j));
    end
    setFontSize(40);
end

%% PCA model vs. reference model
% Correlate PC1 of each affinity matrix with seeking intensity, compare it
% with a shuffled null and with the reference model (refModelCorr.mat).
if flag.PcaVsReference
    rng(1);   % fixed seed so the null model (random shuffles) is reproducible
    load(fullfile(resultDir,'RefModelCorr.mat'));  % reference-model correlations
    nPerm = 300;
    [pcaModelCorr, nullModelCorr] = deal(zeros(1,nSessions));
    explainedAll = zeros(5,nSessions);
    nullCorrPerm = zeros(1,nPerm);
    for j = 1:nSessions
        load(processedFile(j));
        [~, score, ~, ~, explained] = pca(amTrialSet);
        explainedAll(:,j) = explained(1:5); % variance explained by PC1-5
        % PCA sign is arbitrary: use the absolute correlation
        pcaModelCorr(j) = abs(corr(score(:,1), seekIntensity'));
        % Null model: correlation with shuffled seeking intensity; keep one
        % random draw out of nPerm permutations
        for k = 1:nPerm
            nullCorrPerm(k) = corr(score(:,1), seekIntensity(randperm(length(seekIntensity)))');
        end
        nullModelCorr(j) = nullCorrPerm(randi(nPerm));
    end

    % ---- Cumulative variance explained by PC1-PC5 (mean +/- SD) ----
    cumVar = cumsum(explainedAll,1);
    figure;
    b = bar(1:5, mean(cumVar,2), 'FaceColor','w', 'EdgeColor','k', 'BarWidth',0.5, 'LineWidth',2);
    hold on;
    hatchfill2(b, 'single', 'HatchAngle',45, 'HatchSpacing',5, 'HatchColor','k', 'LineWidth',2);
    errorbar(1:5, mean(cumVar,2), std(cumVar,0,2), 'LineStyle','none', 'Color',[0.5 0.5 0.5], ...
        'LineWidth',2, 'Marker','o', 'MarkerSize',6, 'MarkerFaceColor',[0.5 0.5 0.5], 'CapSize',10);
    xticks(1:5);
    xticklabels({'1','2','3','4','5'});
    ylabel('Cumulative Explained Variance (%)');
    title('Cumulative Variance Explained (n = 74)');
    ylim([0 100]);
    grid on;

    % ---- Example sessions (11, 42): PC1 reconstruction and PC1 vs. behavior ----
    c = lines(7);
    for j = [11, 42]
        load(processedFile(j));
        [coeff, score] = pca(amTrialSet);
        figure;
        imagesc(score(:,1).*coeff(:,1)'); % rank-1 reconstruction from PC1
        colormap jet;
        colorbar;
        title('PC1-Reconstructed Matrix')
        axis square;

        if corr(score(:,1), seekIntensity') < 0
            score(:,1) = -score(:,1);
        end
        figure;
        [h1,h2,h4] = plotIntensityAndCurve(drinkLabel, seekIntensity, score(:,1), c(7,:), 'h', 20, 'PC1 Score');
        title('PC1 and Behavior');
        legend([h1, h2, h4], {'Drinking','Non-drinking','PC1'});
    end

    % Linear fit for the last example session
    figure;
    plotLinearFit(score(:,1), seekIntensity, 'gray');
    xlabel('PC1 Score');
    ylabel('Seeking Intensity');

    % ---- PCA model vs. reference model, per session ----
    pcaModelCorr = pcaModelCorr(:);
    refModelCorr = refModelCorr(:);
    figure;
    scatter(pcaModelCorr, refModelCorr, 180, 'o', 'MarkerFaceColor','none', 'MarkerEdgeColor',[0.3 0.3 0.3], 'linewidth',3);
    hold on;
    plot(pcaModelCorr, polyval(polyfit(pcaModelCorr, refModelCorr, 1), pcaModelCorr), 'color',[0.3 0.3 0.3], 'LineWidth',4);
    axis square;
    xlabel('PCA–Behavior Correlation');
    ylabel('Reference–Behavior Correlation');
    title('Model Alignment');

    % ---- Each model vs. the null model ----
    nullVsModelViolin(nullModelCorr, refModelCorr,    [0.7,0.7,0.7; c(6,:)], 'Reference Model');
    nullVsModelViolin(nullModelCorr, pcaModelCorr, [0.7,0.7,0.7; c(7,:)], 'PCA Model');

    % ---- Reference vs. PCA model per group, and 3-way ANOVA ----
    pairedGroupViolin(refModelCorr, pcaModelCorr, groupIdx, repmat(c(6:7,:),4,1), ...
        'Neural-Behavioral Correlation', 'Correlation', {'Reference Model','PCA Model'}, []);
    disp(groupAnova({refModelCorr, pcaModelCorr}, groupIdx, {'Model'}, {{'Ref','PCA'}}));
end

%% State specificity vs. drinking / non-drinking density
if flag.SpecificityVsDensity
    setFontSize(60);
    [drinkDensity, nonDrinkDensity, totalSpecificity] = deal(zeros(1,nSessions));
    for i = 1:nSessions
        load(processedFile(i));
        load(rawFile(i));
        [~, sortOrder] = sort(trialTimes);
        [drinkDensity(i), nonDrinkDensity(i)] = behaviorDensity(drinkTime, approach(sortOrder,1,1));
        [sSpec, nsSpec] = stateSpecificity(amTrialSet, drinkLabel);
        totalSpecificity(i) = sSpec + nsSpec;   % total AM state specificity
    end

    % ---- ANCOVA (aoctool): P vs. W slopes of specificity against density ----
    p1Slope = slopeComparison(drinkDensity,    totalSpecificity, idxPA, idxWA);
    p2Slope = slopeComparison(drinkDensity,    totalSpecificity, idxPQ, idxWQ);
    p3Slope = slopeComparison(nonDrinkDensity, totalSpecificity, idxPA, idxWA);
    p4Slope = slopeComparison(nonDrinkDensity, totalSpecificity, idxPQ, idxWQ);

    % ---- Violin plots and 2-way ANOVAs (Strain x Stim) ----
    groupCat = zeros(1,nSessions);
    for g = 1:4
        groupCat(groupIdx{g}) = g;
    end
    measures = {drinkDensity, 'Drinking Density'; nonDrinkDensity, 'Non-drinking Density'; totalSpecificity, 'Total specificity'};
    for m = 1:3
        figure;
        violinplot(measures{m,1}, groupCat, 'ViolinColor', lines(4), 'MarkerSize', 200);
        xticks(1:4);
        xticklabels(groupNames);
        ylabel(measures{m,2});
    end
    for m = [3 1 2]   % specificity, drinking density, non-drinking density
        disp(groupAnova({measures{m,1}}, groupIdx, {}, {}));
    end

    % ---- Specificity vs. density: per-group linear fits ----
    pairs = {idxWA, idxPA, {'WA','PA'}; idxWQ, idxPQ, {'WQ','PQ'}};
    densities = {drinkDensity, 'Drinking Density'; nonDrinkDensity, 'Non-drinking Density'};

    % One color per group
    slopes = zeros(2,4); % rows: drinking / non-drinking density; columns: WA, PA, WQ, PQ
    % NOTE: as in the original code, the points are always the drinking
    % density of WA/PA; only the fitted lines follow the density/pair.
    pairColors = {groupColors([1 3],:), groupColors([2 4],:)};
    for m = 1:2
        for p = 1:2
            X = densities{m,1};
            pc = pairColors{p};
            markers = {{'MarkerEdgeColor',[0 0 0],'MarkerFaceColor',pc(1,:),'LineWidth',2}, ...
                       {'MarkerEdgeColor',[0 0 0],'MarkerFaceColor',pc(2,:),'LineWidth',2}};
            slopes(m, 2*p-1:2*p) = scatterWithFits( ...
                {drinkDensity(idxWA), drinkDensity(idxPA)}, {totalSpecificity(idxWA), totalSpecificity(idxPA)}, ...
                markers, pc, ...
                {X(pairs{p,1}), X(pairs{p,2})}, {totalSpecificity(pairs{p,1}), totalSpecificity(pairs{p,2})});
            xlabel(densities{m,2});
            ylabel('Total Specificity');
            [~, objh] = legend(pairs{p,3});
            set(findobj(objh,'type','patch'),'MarkerSize',18);
        end
    end
    slopeBars(slopes(1,:), groupColors([1 3 2 4],:), 'Slope (Drink–Speci)',    [p1Slope, p2Slope]);
    slopeBars(slopes(2,:), groupColors([1 3 2 4],:), 'Slope (Nondrink–Speci)', [p3Slope, p4Slope]);

    setFontSize(40);
end

%% Gaussian kernel width comparison for spike smoothing
if flag.GaussianWidth
    binSize = 0.1;     % spike-count bin size in seconds (100 ms)
    sigmaList = [1, 1/4, 1/8];            % kernel std levels: sigma, sigma/4, sigma/8
    sigmaLabels = {'\sigma=mean','\sigma=mean/4','\sigma=mean/8'};
    nSigma = numel(sigmaList);

    % ---- Example neuron (session 2): raw spike counts vs. three kernel widths ----
    load(rawFile(2),'spkData');
    nBins = 0; % time of the last spike across neurons (s)
    for k = 1:size(spkData,1)
        nBins = max(nBins, max(spkData{k}));
    end
    nBins = floor(nBins/binSize); % in bins
    spikeCount = zeros(1,nBins);
    for a = 1:nBins
        spikeCount(a) = histcounts(spkData{1}, [(a-1)*binSize, a*binSize]);
    end
    figure;
    plot(spikeCount(1:500),'linewidth',1.5);
    hold on;
    for si = 1:nSigma
        firingRate = spikesToFiringRate(spkData, binSize, sigmaList(si));
        plot(firingRate(1,1:500),'linewidth',1.5 + 0.5*(si==nSigma));
    end
    legend('Raw Data','sigma=mean','sigma=mean/4','sigma=mean/8','FontSize',20)
    xlabel('Time(0.1s)');
    ylabel('Neuron Firing Rate');
    title('Neuron Firing Rate with Different Gaussian Filters');

    % ---- All sessions: total variation (smoothness) and peak count per neuron ----
    [tvBySigma, peaksBySigma] = deal(cell(1,nSigma));
    for si = 1:nSigma
        [tvPerSession, peaksPerSession] = deal(cell(1,nSessions));
        for i = 1:nSessions
            load(rawFile(i),'spkData');
            firingRate = spikesToFiringRate(spkData, binSize, sigmaList(si));
            tvPerSession{i} = sum(abs(diff(firingRate,1,2)),2);   % total variation per neuron
            peaksPerSession{i} = arrayfun(@(k) numel(findpeaks(firingRate(k,:))), 1:size(spkData,1));
        end
        tvBySigma{si} = tvPerSession;
        peaksBySigma{si} = peaksPerSession;
    end
    save(fullfile(resultDir,'GaussianWidthComparison.mat'),'tvBySigma','peaksBySigma');

    % ---- Best sigma per neuron: lowest (normalized TV + 1 - normalized peaks) ----
    rescale01 = @(v) (v - min(v)) / (max(v) - min(v) + eps);
    scoreAll = [];
    for si = 1:nSigma
        score = [];
        for j = 1:numel(tvBySigma{si})
            score = [score, rescale01(tvBySigma{si}{j})' + (1 - rescale01(peaksBySigma{si}{j}))];
        end
        scoreAll = [scoreAll; score];
    end
    [~, bestSigmaIdx] = min(scoreAll, [], 1);

    figure;
    counts = histcounts(bestSigmaIdx, 0.5:1:(nSigma+0.5));
    bar(categorical(1:nSigma, 1:nSigma, sigmaLabels), counts, 'barwidth',0.5);
    ylabel('Number of Neurons');
    title('Preferred Gaussian Sigma per Neuron');

    % Group-level TV and peaks (mean over sessions of the per-session means)
    semOfSessions = @(c) std(cellfun(@(x) std(x)/sqrt(length(x)), c)) / sqrt(length(c));
    meanTv = cellfun(@(c) mean(cellfun(@mean, c)), tvBySigma);
    semTv  = cellfun(semOfSessions, tvBySigma);
    meanPeak = cellfun(@(c) mean(cellfun(@mean, c)), peaksBySigma);
    semPeak  = cellfun(semOfSessions, peaksBySigma);

    figure;
    subplot(1,2,1);
    bar(meanTv);
    hold on;
    errorbar(1:nSigma, meanTv, semTv, '.k');
    xticklabels(sigmaLabels);
    ylabel('Total Variation');
    title('Average Smoothness (TV)');
    subplot(1,2,2);
    bar(meanPeak);
    hold on;
    errorbar(1:nSigma, meanPeak, semPeak, '.k');
    xticklabels(sigmaLabels);
    ylabel('Number of Peaks');
    title('Preserved Signal Details');
end

%% Recurrence matrices with different window lengths (supplementary S2)
% For each window length, split every session's sliding-window recurrence
% matrix into two Louvain modules and store the module specificity
% (within-module minus between-module recurrence) in specificityAll{w}.
if flag.RecurrenceWindowLength
    windowLengths = 100:200:800;
    specificityAll = cell(1,numel(windowLengths));
    for w = 1:numel(windowLengths)
        wl = windowLengths(w);
        step = wl/2;

        % Example recurrence matrix (session 1)
        load(processedFile(1));
        R = slidingWindowRecurrence(firingRate, wl, step);
        R(isnan(R)) = 0;
        figure;
        imagesc(R);
        colormap jet;
        title(sprintf('WL=%d, SL=%d', wl, step));
        axis square;
        colorbar;

        spec = nan(1,nSessions);
        for i = 1:nSessions
            load(processedFile(i));
            R = slidingWindowRecurrence(firingRate, wl, step);
            [idx, gamma] = twoModulePartition(R);
            if gamma >= 0 % a two-module split was found
                [sSpec, nsSpec] = stateSpecificity(R, idx');
                spec(i) = sSpec + nsSpec;
            end
        end
        specificityAll{w} = spec(~isnan(spec));
    end
end

%% Reference-model correlation vs. peak seeking intensity and number of neurons
% Checks whether the correlation between the seeking affinity and the seeking
% intensity (refModelCorr, from TrialSetModel) depends on how strongly the
% animal drank (peak seeking intensity of the session) or on the number of
% recorded neurons.
if flag.ModelFactors
    load(fullfile(resultDir,'RefModelCorr.mat'));  % refModelCorr, one value per session
    [peakIntensity, nNeurons] = deal(zeros(1,nSessions));
    for i = 1:nSessions
        load(processedFile(i), 'seekIntensity');
        peakIntensity(i) = max(seekIntensity);
        info = whos('-file', processedFile(i), 'firingRate');  % size without loading the data
        nNeurons(i) = info.size(1);
    end

    factors = {peakIntensity, 'Peak Seeking Intensity'; nNeurons, 'Number of Neurons'};
    for k = 1:2
        x = factors{k,1}(:);
        y = refModelCorr(:);
        [r, p] = corr(x, y);   % Pearson
        figure;
        scatter(x, y, 280, 'filled');
        hold on;
        xFit = linspace(min(x), max(x), 100);
        plot(xFit, polyval(polyfit(x, y, 1), xFit), 'k-', 'LineWidth', 4);  % least-squares line
        xlabel(factors{k,2});
        ylabel('Correlation');
        title(sprintf('r = %.2f, p = %.3f', r, p));
        box off;
        axis square;
        fprintf('Reference-model correlation vs. %s: r = %.3f, p = %.3g\n', factors{k,2}, r, p);
    end
end
