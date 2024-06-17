function tf = iscompatible(varargin) %Modified (c) NH, 2019
% Returns true if all inputs are double or DimVars with compatible units.
%   
%   See also u, compatible, DimVar.compatible, DimVar.iscompatible

    classes = cellfun(@class, varargin, 'UniformOutput', false);

    if all(strcmp(classes, 'double'))
        tf = true;
    elseif all(strcmp(classes, 'DimVar')) 
        vararginExpos = cellfun(@(x) x.exponents, varargin, 'UniformOutput', false);
        tf = isequal(vararginExpos{:});
    else
        tf = false;
    end

end
