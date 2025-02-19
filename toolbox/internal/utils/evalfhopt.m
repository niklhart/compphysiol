function val = evalfhopt(option, varargin)
%EVALFHOPT Query a function handle option and evaluate it
%   Detailed explanation goes here

    arguments
        option char
    end
    arguments (Repeating)
        varargin
    end

    h = getoptcompphysiol(option);
    assert(isa(h,'function_handle'), 'Option must be a function handle.')
    val = h(varargin{:});

end