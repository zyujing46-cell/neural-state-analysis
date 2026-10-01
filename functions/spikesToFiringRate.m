function [firingRate, kernel] = spikesToFiringRate(spikeTimes, binSize, sigma)
% Bin spike trains and smooth them with a Gaussian kernel.
%   spikeTimes : cell array, spike times (s) of each neuron
%   binSize    : bin size (s)
%   sigma      : the kernel SD is (mean inter-spike interval of the neuron) / sigma
%   firingRate : neurons x bins, smoothed spike count per bin
%   kernel     : Gaussian kernel of the last neuron
nNeurons = size(spikeTimes, 1);

% Length of the recording and mean inter-spike interval of each neuron
lastSpike = 0;
meanIsi = zeros(1, nNeurons);
for i = 1:nNeurons
    lastSpike = max(lastSpike, max(spikeTimes{i}));
    meanIsi(i) = mean(diff(spikeTimes{i}), 'omitnan');
end
nBins = floor(lastSpike/binSize);

spikeCount = zeros(nNeurons, nBins);
firingRate = nan(nNeurons, nBins);
for i = 1:nNeurons
    for b = 1:nBins
        spikeCount(i,b) = histcounts(spikeTimes{i}, [(b-1)*binSize, b*binSize]);
    end
    kernelSd = meanIsi(i)/sigma;
    kernelWidth = 1./binSize;
    kernel = fspecial('gaussian', kernelWidth, kernelSd);
    kernel = kernel./binSize;
    firingRate(i,:) = conv2(spikeCount(i,:), kernel, 'same');
end
end
