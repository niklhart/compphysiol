%CUMTRAPZ Cumulative trapezoidal numerical integration for DimVar class.
%   I = CUMTRAPZ(V1,V2) has the same syntax as the builtin cumtrapz for the 
%   double class, but V1, V2 or both can be DimVar.
%
%   The call CUMTRAPZ(V1) with DimVar V1 is not allowed since the default 
%   spacing would be unit-dependent and therefore not uniquely defined.
%
%   I = CUMTRAPZ(V1,V2,...) can be used as for the builtin cumtrapz.
%
%   See also DimVar/trapz, cumtrapz


function vOut = cumtrapz(v1,v2,varargin)


if ~isa(v2,'DimVar') % v1 is the DimVar.
    vOut = v1;
    vOut.value = cumtrapz(v1.value,v2,varargin{:});


elseif ~isa(v1,'DimVar') % v2 is the DimVar.
    vOut = v2;
    vOut.value = cumtrapz(v1,v2.value,varargin{:});

else % BOTH v1 and v2 are DimVars.
    vOut = v1;
    vOut.value = cumtrapz(v1.value,v2.value,varargin{:});
    vOut.exponents = v1.exponents + v2.exponents;
    
    vOut = clearcanceledunits(vOut);
end