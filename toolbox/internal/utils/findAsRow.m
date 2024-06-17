function I = findAsRow(X, varargin)
%FINDASROW Find indices of nonzero elements and return them as a row vector.
%   Detailed explanation goes here

I = find(X(:),varargin{:})';

end