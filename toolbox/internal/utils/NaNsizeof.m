%NANSIZEOF Create a vector of NaNs from template
%   Y = NANSIZEOF(X) is a replacement for Y = NaN(size(X)) correctly 
%   handling the case where X has units.
%
%   See also zerosizeof

function y = NaNsizeof(x)
    if isnumeric(x)
        y = NaN*x;    % works for double, DimVar, HDV
    else
        y = NaN(size(x)); 
    end
end