%GETUNITSTR Get char representation of input's unit
%   STR = GETUNITSTR(VAR), with DimVar VAR, returns the display unit of VAR
%   as a character array. If VAR is double, STR = 'unitless' is returned.
%   In any other case, an error is thrown.

function str = getunitstr(var)
    switch class(var)
        case 'DimVar'
            [~,~,str] = displayparser(var);
        case 'double'
            str = 'unitless';
        otherwise
            error('Incompatible units in data.')
    end
end