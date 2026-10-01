function blocks = moduleBlocks(M, idx)
% Upper-triangle values of M within module 1, between modules 1 and 2,
% and within module 2.
% NOTE: triu is also applied to the (non-square) between-module block,
% as in the original code.
blocks = {M(idx==1,idx==1), M(idx==1,idx==2), M(idx==2,idx==2)};
blocks = cellfun(@(B) B(triu(true(size(B)),1)), blocks, 'UniformOutput', false);
end
