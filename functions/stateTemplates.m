function [sTmpl, nsTmpl] = stateTemplates(dfcVec, intensity, threshold)
% Mean dFC vector of seeking (intensity > threshold) and non-seeking sets.
isSeek = intensity > threshold;
sTmpl  = mean(dfcVec(:, isSeek), 2);
nsTmpl = mean(dfcVec(:,~isSeek), 2);
end
