%UPDATE_PARSTRUCT Update values in a parameter struct 
%
%   S = UPDATE_PARSTRUCT(S, PAR, NAMES) updates parameters named NAMES (a 
%       cellstr) in struct S using values PAR (a numeric, possibly 
%       dimensioned, vector of the same length as NAMES). Changes of unit 
%       types within S are not allowed.
%
%   S = UPDATE_PARSTRUCT(S, PAR, NAMES, UNITS) is equivalent to the syntax
%       S = UPDATE_PARSTRUCT(S, PAR.*UNITS, NAMES), except that in addition, 
%       PAR must be double (as returned by function getestimationwrapper())


function S = update_parstruct(S,par,names,units)

    % length and format checks
    assert(isstruct(S))
    assert(isnumvec(par))
    assert(iscellstr(names)) %#ok<ISCLSTR>
    assert(numel(par) == numel(names)) 
    
    if nargin == 4
        assert(isa(par,'double') && isnumvec(units))
        par = par .* units;
    end
    
    for i = 1:numel(names)
        typecheck(S.(names{i}), par(i))
        S.(names{i}) = par(i);
    end
    
end

