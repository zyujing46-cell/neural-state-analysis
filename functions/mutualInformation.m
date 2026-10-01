function mi = mutualInformation(x, y)
% Mutual information (bits) between two label vectors.
x = grp2idx(x);
y = grp2idx(y);
pXY = accumarray([x(:), y(:)], 1);
pXY = pXY / sum(pXY(:));
pX = sum(pXY, 2);
pY = sum(pXY, 1);
[PY, PX] = meshgrid(pY, pX);
pIndep = PX .* PY;
nz = pXY > 0;
mi = sum(pXY(nz) .* log2(pXY(nz) ./ pIndep(nz)));
end
