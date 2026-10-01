function [idx, gamma] = twoModulePartition(A)
% Louvain community detection (community_louvain, 'negative_sym'). The
% resolution gamma is tuned in 0.01 steps from 0.9 until exactly two
% modules are found; gamma < 0 means no two-module split was found.
gamma = 0.9;
idx = community_louvain(A, gamma, [], 'negative_sym');
while max(idx) < 2
    gamma = gamma + 0.01;
    idx = community_louvain(A, gamma, [], 'negative_sym');
end
while max(idx) > 2 && gamma >= 0
    gamma = gamma - 0.01;
    idx = community_louvain(A, gamma, [], 'negative_sym');
end
end
