function [Strain, Stim] = groupFactors(groupIdx)
% Between-subject factors for sessions ordered WA, WQ, PA, PQ.
n = cellfun(@numel, groupIdx);
Strain = categorical([repmat({'W'}, n(1)+n(2), 1); repmat({'P'}, n(3)+n(4), 1)]);
Stim   = categorical([repmat({'A'}, n(1), 1); repmat({'Q'}, n(2), 1);
                      repmat({'A'}, n(3), 1); repmat({'Q'}, n(4), 1)]);
end
