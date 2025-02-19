%ODEUNITS Unit-compatible ODE solver suite
%   This is the main function for solving ODEs with unit handling; rather
%   than calling it directly, use the following interface functions:
%
%   See also odeu45, odeu15s

function varargout = odeunits(solver, rhsu, tspanu, y0u, modelu, varargin)
    % for transparency, (functions operating on) variables with units
    % finish in 'u' (rhsu, tspanu, y0u, modelu), whereas (functions 
    % operating on) unitless variables (doubles) finish in 'd' (rhsd, 
    % tspand, y0d, modeld). Doubles converted from DimVar correspond to the
    % values in internal DimVar units.

    solver = str2func(validatestring(solver, {'ode45', 'ode15s'}));
    
    assert(isa(rhsu,'function_handle'), ... && nargin(rhsu) == 3, ... %TODO find syntax that works for .m and mex files
        '"rhsu" must be a function handle with three arguments.')
    nargoutchk(2,Inf)

    check = getoptcompphysiol('OdeUnitCheck');
    
    y0u = y0u(:);
    [tunits, tdispunit] = unitsOf(tspanu);
    y0units             = unitsOf(y0u);
        
    if ~strcmp(check,'never')
        dydtunits           = unitsOf(rhsu(tspanu(1),y0u, modelu));
        
        compatible(unitsOf(y0units./tunits), dydtunits)
    end    
    
    tspand = double(tspanu);
    y0d = double(y0u);
    
    switch check
        case {'never','once'}
            modeld = recapply(@removeunits,modelu);
            rhsd = @(t,y) rhsu(t,y,modeld);
        case 'always'
            rhsd = @rhswrapper;            
    end

    argout = cell(nargout-2,1);
    [t, y, argout{:}] = solver(rhsd, tspand, y0d, varargin{:});
    
    varargout = cell(nargout,1);
    varargout{1} = scd(t * tunits, tdispunit);    
    varargout{2} = y .* (y0units');
    varargout(3:nargout) = argout;
    
    function ddt_yd = rhswrapper(td, yd)
        dyu = rhsu(td.*tunits, yd.*y0units, modelu);
        compatible(dydtunits, dyu)
        ddt_yd = double(dyu);
    end

end
