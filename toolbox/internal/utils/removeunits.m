%REMOVEUNITS Remove units from variables, leaving anything else unchanged.
function x = removeunits(x)
    if isa(x,'DimVar') || isa(x,'HDV')
        x = double(x);
    end
end