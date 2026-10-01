function [rm, dfcVec] = slidingWindowRecurrence(firingRate, windowLength, step)
% Recurrence matrix between sliding windows of dynamic functional
% connectivity (dFC), without weighting.
%   firingRate   : neurons x time points
%   windowLength : window length (time points)
%   step         : step between windows (time points)
%   rm           : windows x windows recurrence matrix (correlation of dfcVec)
%   dfcVec       : neuron pairs x windows, lower triangle of each window's FC
[nNeurons, nPoints] = size(firingRate);
nWindows = length(1:step:(nPoints - windowLength + 1));
dfcVec = zeros(nNeurons*(nNeurons-1)/2, nWindows);
mask = logical(tril(ones(nNeurons) - eye(nNeurons)));

for i = 1:nWindows
    first = step*(i-1) + 1;
    segment = firingRate(:, first:(first + windowLength - 1));
    fc = corr(segment');
    fc(isnan(fc)) = 0;
    dfcVec(:,i) = fc(mask);
end
rm = corr(dfcVec);
end
