%DETACHUNIT Detach unit from a DimVar
%   XD = DETACHUNIT(XU, UNIT), with DimVar XU and character array UNIT
%   convertible to class DimVar, returns a double XD containing the 
%   numeric value of XU in units UNIT.
%
%   [XD, UX] = DETACHUNIT(XU, UNIT) in addition returns UNIT as a DimVar
%   UX, i.e. such that XD * UX = XU holds.

function [xd, ux] = detachunit(xu, unit)

    xd = displayingvalue(scd(xu, unit));
    if nargout == 2
        ux = xu ./ xd; 
    end
end