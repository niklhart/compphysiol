%ODEU15S Unit-compatible ODE15S solver (for stiff systems)
%   [T, Y] = ODEU15S(RHS, TSPAN, Y0, MODEL) numerically solves the ODE 
%       Y'(t) = RHS(t,Y; MODEL)
%       Y(0)  = Y0 
%   where arguments TSPAN, Y0, MODEL are allowed to contain units. 
%   ODEU15S is a wrapper for the Matlab builtin ode15s solver that 
%   automatically checks if units are handled consistently. A global option
%   'OdeCheckUnit' allows to switch between two types of behaviour:
%   - 'once'     checks that no unit-incompatible operations are performed
%                in RHS(TSPAN(1), Y0, MODEL) and that the resulting units 
%                are consistent with the units of TSPAN and Y0.
%   - 'always'   checks that no unit-incompatible operations are performed
%                in RHS(t, Y(t), MODEL) at any evaluation, and that the 
%                resulting units are consistent with the units of TSPAN and
%                Y0.

function varargout = odeu15s(varargin)

    [varargout{1:nargout}] = odeunits('ode15s', varargin{:});

end
