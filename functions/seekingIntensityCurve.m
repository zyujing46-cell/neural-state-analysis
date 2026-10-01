function siCurve = seekingIntensityCurve(drinkTime)
% Seeking-intensity model: drinking time per CS+ trial convolved with a
% canonical HRF (see canonicalHrf).
%   drinkTime : drinking time of each CS+ trial (vector)
%   siCurve   : seeking intensity of each trial
% The HRF is sampled at x = 1.5, 2.5, ..., i.e. shifted 0.5 trial earlier.
x = 1.5:1:100.5;
hrf = canonicalHrf(x);
siCurve = conv(drinkTime, hrf);
siCurve = siCurve(5:5+length(drinkTime));
end
