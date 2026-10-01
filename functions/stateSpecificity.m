function [sSpec, nsSpec] = stateSpecificity(M, labels)
% Within-state minus between-state mean of M over pairs of trial sets
% (diagonal excluded). labels: 1 = s, 0 or 2 = ns (row vector).
%   sSpec  = mean(s-s pairs)   - mean(s-ns pairs)
%   nsSpec = mean(ns-ns pairs) - mean(s-ns pairs)
labels(labels==0) = 2;
pairType = labels' * labels;              % 1 = s-s, 4 = ns-ns, 2 = s-ns
pairType = pairType - diag(diag(pairType));
between = mean(M(pairType==2));
sSpec  = mean(M(pairType==1)) - between;
nsSpec = mean(M(pairType==4)) - between;
end
