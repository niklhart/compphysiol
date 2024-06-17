%UPDATE Update model parameter struct
%   NEWPAR = UPDATE(OLDPAR, NM1, VAL1, NM2, VAL2, ...) takes parameter
%       struct OLDPAR and attaches name-value pairs NM1, VAL1, ... to it.
%       If any name NM already exists as a parameter in OLDPAR, there are 
%       two possible cases:
%       1) if the corresponding value VAL is nonempty, the parameter NM in
%          OLDPAR is updated to VAL.
%       2) if the corresponding value VAL is empty, parameter NM is deleted
%          from OLDPAR.


function par = update(par, varargin)

    newnames = varargin(1:2:end);
    newvalues = varargin(2:2:end); % empty value == deletion of parameter

    % check input argument format
    assert(isparstruct(par), ...
        'Input #1 must be a parameter struct, as created by function "parameters".')
    assert(iscellstr(newnames), ...
        'Imput arguments with even number must be char (parameter names)')
    assert(numel(newnames) == numel(newvalues), 'Missing value for a name.')
    assert(all(cellfun(@(x) isempty(x) || (isnumeric(x) && isscalar(x)), newvalues)), ...
        'Values must be empty or numeric scalars.')

    % format ok, now update the parameter struct
    for i = 1:2:numel(varargin)
        nm  = newnames{i};
        val = newvalues{i};
        if isempty(val)
            if isfield(par, nm) 
                par = rmfield(par, nm);            
            else
                error(['Failed to delete parameter "' nm '" because it is undefined.']) 
            end
        else
            par.(nm) = val;
        end
    end    
end

function TF = isparstruct(par)
    TF = isstruct(par) && all(structfun(@(x) isnumeric(x) && isscalar(x), par));
end