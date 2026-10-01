function M = vec2sym(v)
% Symmetric matrix with unit diagonal from its upper-triangle vector.
n = (1 + sqrt(1 + 8*numel(v))) / 2;
M = zeros(n);
M(triu(true(n),1)) = v;
M = M + M' + eye(n);
end
