%COMPATIBLE Throws an error unless all inputs have compatible units.
%   This is the version of function DimVar.compatible for unitless 
%   quantities, throwing an error unless all inputs are double.
%   
%   See also u, iscompatible, DimVar.compatible, DimVar.iscompatible

function compatible(varargin)

    if ~all(cellfun(@(x) isa(x,'double'), varargin))
            ME = MException('DimVar:incompatibleUnits',...
                'Incompatible units. All inputs must be DimVar.');
            throwAsCaller(ME);            
    end

end