function hrf = canonicalHrf(t)
% Canonical haemodynamic response function (difference of two gamma
% functions), normalised to a peak of 1.
%   t   : time points (in trials)
%   hrf : HRF value at each time point
peakShape      = 6;    % shape of the first gamma function (peak)
peakScale      = 1;    % scale of the first gamma function
undershootShape = 12;  % shape of the second gamma function (undershoot)
undershootScale = 1;   % scale of the second gamma function
undershootRatio = 0.35; % weight of the undershoot

hrf = gammaPdf(t, peakShape, peakScale) - undershootRatio * gammaPdf(t, undershootShape, undershootScale);
hrf = hrf / max(hrf);
end

function y = gammaPdf(x, shape, scale)
% Probability density function of a gamma distribution.
y = (x.^(shape-1) .* exp(-x./scale)) ./ (gamma(shape) * scale^shape);
end
