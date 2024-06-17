%GETFROM Get a value from an options struct; throws an error if not found.
%   OUT = GETFROM(OPTIONS,WHAT) is designed to be used in models requiring
%   quantities defined on the script level, e.g.
%   - a method to predict tissue partition coefficients (all PBPK models)
%   - a grouping of states in a lumped model
%
%   OUT = GETFROM(OPTIONS,WHAT,DEFAULT) uses the default value DEFAULT if
%   OPTIONS.(WHAT) is undefined.

function out = getfrom(options, what, default)

    assert(isstruct(options), 'Options must be a struct.')
    if ~isfield(options, what) 
        if nargin == 2
            error(['Couldn''t find mandatory model option "' what '".'])
        else
            out = default;
        end
    else
        out = options.(what);
    end
    
end

