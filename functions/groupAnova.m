function tbl = groupAnova(values, groupIdx, factorNames, factorLevels)
% N-way ANOVA with all interactions (anovan; all factors between-subject).
% Factors: Strain (W/P), Stim (A/Q) and optional extra factors.
%   values       : cell array of per-session vectors, one per condition
%   factorNames  : names of the extra factors, e.g. {'State','Measure'}
%   factorLevels : per extra factor, the level of each condition
strainOf = {'W','W','P','P'};
stimOf   = {'A','Q','A','Q'};
Y = [];
labels = repmat({{}}, 1, 2 + numel(factorNames));   % Strain, Stim, extra factors
for g = 1:4
    idx = groupIdx{g};
    n = numel(idx);
    for c = 1:numel(values)
        v = values{c}(:);
        Y = [Y; v(idx)];
        levels = [strainOf(g), stimOf(g), cellfun(@(f) f{c}, factorLevels, 'UniformOutput', false)];
        for f = 1:numel(labels)
            labels{f} = [labels{f}; repmat(levels(f), n, 1)];
        end
    end
end
good = ~isnan(Y);
labels = cellfun(@(l) categorical(l(good)), labels, 'UniformOutput', false);
[~, tbl] = anovan(Y(good), labels, 'model','full', 'varnames', [{'Strain','Stim'}, factorNames]);
end
