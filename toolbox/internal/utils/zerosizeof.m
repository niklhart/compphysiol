%ZEROSIZEOF Create a vector of zeros from template
%   Y = ZEROSIZEOF(X) is a replacement for Y = zeros(size(X)) correctly 
%   handling the case where X has units.
%   
%   See also NaNsizeof

function y = zerosizeof(x)
    if isnumeric(x)
        y = 0*x;      % works for double, DimVar, HDV
    else
        y = zeros(size(x)); 
    end
end