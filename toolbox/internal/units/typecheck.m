function typecheck(val, type, form)
%TYPECHECK(VAL,TYPE) Throw a formatted error if VAL is no TYPE DimVar 
%   VAL may be a numeric variable, a string convertible to DimVar type,
%   or a DimVar. TYPE can be one of the following:
%   - one of the supported unit types defined in function istype(), 
%   - 'unitless' or 'numeric' (VAL is expected to be a numeric variable)
%   - a DimVar or a string convertible to DimVar type.
%   - 'char', in which case VAL is assumed to represent a categorial
%     quantity. Other than VAL being in char format, no further checking is
%     done in this case (in particular, the optional 3rd argument has no 
%     effect).
%   
%   TYPECHECK(VAL,TYPE,'scalar') additionally checks if VAL is scalar.
%   TYPECHECK(VAL,TYPE,'nonvector') is similar to the above, but also
%       accepts an empty value.

    formcheck = @(x) true;
    if nargin == 3 && isword(form)
        switch form
            case 'scalar'
                formcheck = @(x) isscalar(x);
            case 'nonvector'
                form = 'scalar or empty';
                formcheck = @(x) isscalar(x) || isempty(x);
        end
    end
    
    % early return for categorical type
    if strcmp(type,'char')
        if ~ischar(val)
            throwAsCaller(MException('compphysiol:typecheck:nonChar',...
                'Argument must be char.'));
        end
        return
    end
    
    % process numerical type
    try
        val = tounit(val);
    catch 
        throwAsCaller(MException('compphysiol:typecheck:noDimVar',...
            'Cannot convert argument to class "DimVar"'));
    end
    
    % early return for double type
    if isa(type,'double')
        if ~isa(val,'double')
            throwAsCaller(MException('compphysiol:typecheck:noDouble',...
                'Input has class "%s", but expected "double".',class(val)));
        end
        return
    end

    % continue processing numeric type
    if isa(val,'DimVar')
        [~, ~, vstr] = displayparser(val);
    else
        vstr = class(val);
    end
    
    if ischar(type) % might be a DimVar string (e.g. 'km'), or a unit type (e.g. 'Length')
        if istype(val, type)
            if ~formcheck(val)
                throwAsCaller(MException('compphysiol:typecheck:nonScalar',...
                        'Argument must be %s.',form));
            end
            return
        else
            try
                type = str2u(type);  % if this works, it was a DimVar string.
                                           % 2-arg call avoids infinite
                                           % scd <-> str2u loop
            catch
                throwAsCaller(MException('compphysiol:typecheck:incompatibleUnits',...
                    'Unit "%s" is incompatible with unit type "%s".', vstr, type));
            end
        end
    elseif iscellstr(type) %#ok<ISCLSTR>
        if any(cellfun(@(t) istype(val, t), type))
            if ~formcheck(val)
                throwAsCaller(MException('compphysiol:typecheck:nonScalar',...
                        'Argument must be %s.',form));
            end
            return
        else
            throwAsCaller(MException('compphysiol:typecheck:incompatibleUnits',...
                'Unit "%s" is incompatible with unit type(s): "%s"', vstr, strjoin(type,', ')));
        end
    end
    
    if isa(type, 'DimVar') || isa(type,'double')
        if ~iscompatible(val, type)
            [~, ~, tstr] = displayparser(type);
            throwAsCaller(MException('compphysiol:typecheck:incompatibleUnits',...
                'Unit "%s" is incompatible with unit "%s".', vstr, tstr));
        end
    else
        throwAsCaller(MException('compphysiol:typecheck:invalidType',...
            'Argument "type" must be a DimVar, a character array, or a string.'));
    end
    
    if ~formcheck(val)
        throwAsCaller(MException('compphysiol:typecheck:nonScalar',...
                'Argument must be %s.',form));
    end
end
