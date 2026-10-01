function [rm, dfcVec] = trialSetRecurrence(firingRate, setStart, trialTimes, binSize)
% Recurrence matrix between trial sets. The dFC of each set is the
% correlation between neurons from the start of its first trial to the
% start of the next set (the last set runs to the end of the recording).
%   firingRate : neurons x bins
%   setStart   : index of the first trial of each set
%   trialTimes : start time (s) of each trial
%   binSize    : bin size (s)
%   rm         : sets x sets recurrence matrix (correlation of dfcVec)
%   dfcVec     : neuron pairs x sets, vectorised dFC of each set
nNeurons = size(firingRate, 1);
nSets = length(setStart);
dfcVec = zeros(nNeurons*(nNeurons-1)/2, nSets);
mask = logical(tril(ones(nNeurons)-eye(nNeurons)));

for i = 1:nSets
    if i == nSets
        windowLength = length(firingRate)*binSize - trialTimes(setStart(i)) - 1;
    else
        windowLength = trialTimes(setStart(i+1)) - trialTimes(setStart(i));
    end
    segment = firingRate(:, ceil(trialTimes(setStart(i))/binSize):floor((trialTimes(setStart(i))+windowLength)/binSize));
    fc = corr(segment');
    dfcVec(:,i) = fc(mask);
end
rm = corr(dfcVec, 'Rows', 'pairwise');
end
