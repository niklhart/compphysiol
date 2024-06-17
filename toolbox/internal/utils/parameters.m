function par = parameters(varargin)
%PARAMETERS Convert name-value pairs into parameter struct
%   PAR = PARAMETERS(NAME1,VALUE1,NAME2,VALUE2,...) is essentially
%   identical to PAR = struct(NAME1,VALUE1,NAME2,VALUE2,...), but in
%   addition it checks that VALUE1,VALUE2,... are numeric scalars.

    values = varargin(2:2:end);
    
    assert(all(cellfun(@(x) isnumeric(x) && isscalar(x), values)), ...
        'All values must be numeric scalars.')
 
    par = struct(varargin{:});
 
end

