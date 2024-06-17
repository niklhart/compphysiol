%REDUCE Reduce function operator
%   OUT = REDUCE(FUN, ARG1, ..., ARGN) recursively applies binary operator
%   FUN to the arguments
%   For example, REDUCE(@union,{'a','b'},{'c'},{'d','e'}) is equivalent to 
%   union(union({'a','b'},{'c'}),{'d','e'}).

function out = Reduce(fun, varargin)

    switch nargin
        case {0,1}
            error('Reduce must be called with at least two input arguments.')
        case 2
            out = varargin{1};
        case 3
            out = fun(varargin{1:2});
        otherwise
            out = Reduce(fun, fun(varargin{1:2}), varargin{3:end});
    end
end

