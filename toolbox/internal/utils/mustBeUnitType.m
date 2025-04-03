function mustBeUnitType(value, type)

    if ~isa(value,'DimVar') || ~istype(value, type)
        eid = 'mustBeUnitType:wrongUnitType';
        msg = 'Input must be a DimVar of type "%s".';
        error(eid, msg, type)
    end

end