function tf = istype(v, name)
%ISTYPE Method istype for non-DimVars

    if strcmpi(name, 'unitless')
        name = 'double';
    end
    tf = isa(v, name);
end

