function am = computeAffinityMatrix(rm, prct)
% Affinity matrix: cosine similarity between the columns of a recurrence
% matrix, each column keeping only values at or above its prct-th
% percentile (prct = 0 keeps all values). The pair's own two entries are
% excluded from each comparison.
%   rm   : N x N recurrence matrix
%   prct : percentile threshold, e.g. 50 keeps the top half of each column
%   am   : N x N affinity matrix (diagonal = 1)
n = size(rm, 1);
mask = true(n, 1);
am = zeros(n, n);
for i = 1:n-1
    colI = rm(:,i);
    if prct ~= 0
        colI(colI < prctile(colI, prct)) = 0;
    end
    mask(i) = false;
    for j = i+1:n
        colJ = rm(:,j);
        if prct ~= 0
            colJ(colJ < prctile(colJ, prct)) = 0;
        end
        mask(j) = false;
        am(i,j) = 1 - pdist2(colI(mask)', colJ(mask)', 'cosine');
        mask(j) = true;
    end
    mask(i) = true;
end
am = am + am';
am(logical(eye(n))) = 1;
end
