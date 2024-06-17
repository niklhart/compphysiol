function callif(bool, func, varargin)
%CALLIF Call function with no outputs if a condition is met
%   CALLIF(BOOL, FUNC, ...) calls FUNC(...) if BOOL is true and does
%   nothing otherwise. Function FUNC is called without any output arguments. 
%   This is most useful for functions that do error checking or producing a 
%   side effect such as printing to the console or plotting.

    if bool
        func(varargin{:});
    end

end