function mustBeTimeVariable(var)

    if ~istype(var,'Time')
        eid = 'mustBeTimeVariable:notTimeVariable';
        msg = 'Input must be a time variable.';
        error(eid,msg)
    end
end