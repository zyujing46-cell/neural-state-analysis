function [mu, sem] = groupMeanSEM(M, groupIdx, dropNaN, stdFlag)
% Mean and SEM over sessions (rows of M) for each group (rows of mu/sem).
%   dropNaN(g): drop sessions containing NaN; the SEM denominator is then
%               length() of the remaining matrix, otherwise the number of
%               sessions (both as in the original analysis)
%   stdFlag   : 0 = sample std, 1 = population std
for g = 1:numel(groupIdx)
    R = M(groupIdx{g},:);
    if dropNaN(g)
        R = R(~any(isnan(R),2),:);
        n = length(R);   % NOTE: max(size(R)), kept from the original code
    else
        n = numel(groupIdx{g});
    end
    mu(g,:)  = mean(R,1);
    sem(g,:) = std(R,stdFlag,1) / sqrt(n);
end
end
