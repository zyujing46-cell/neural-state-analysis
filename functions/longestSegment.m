function [startIdx, runLen] = longestSegment(x, target)
% longestSegment - Find the longest continuous segment of 0s or 1s in a binary array
% 
% Usage:
%   [startIdx, runLen] = longestSegment(x, target)
%
% Inputs:
%   x       - A binary vector (row or column) containing only 0s and 1s
%   target  - The value to search for (0 or 1)
%
% Outputs:
%   startIdx - The starting index of the longest continuous segment of 'target'
%              Returns [] if no such segment is found
%   runLen   - The length of that segment
%              Returns 0 if no such segment is found

    % Ensure input is a column vector
    x = x(:);                      
    
    % Logical vector: 1 where x equals the target, 0 otherwise
    z = (x == target);              
    
    % Handle case where no element matches the target
    if ~any(z)
        startIdx = [];
        runLen = 0;
        return;
    end

    % Compute transitions (difference between consecutive elements)
    % Adding zeros at both ends makes it easier to detect edges
    dz = diff([0; z; 0]);           
    
    % Start indices: where the segment begins (0 -> 1 transition)
    starts = find(dz == 1);          
    
    % End indices: where the segment ends (1 -> 0 transition)
    ends   = find(dz == -1) - 1;     
    
    % Compute the length of each continuous segment
    lens   = ends - starts + 1;      
    
    % Find the longest segment (if multiple, return the first)
    [runLen, idx] = max(lens);       
    startIdx = starts(idx);
end
