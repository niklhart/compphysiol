%DO_CALL Call a function with a cell array (rather than list) of arguments
%   DO_CALL(F,C), with a function handle F and a cell array C, is 
%   equivalent to F(C{:})
function varargout = do_call(f,c)
    assert(isa(f,'function_handle'), 'Input #1 must be a function handle.')
    assert(iscell(c), 'Input #2 must be a cell array.')
    [varargout{1:nargout}] = f(c{:});
end
