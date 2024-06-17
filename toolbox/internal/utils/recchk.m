 
function recchk(o, prevStr, f)

    if isstruct(o)
        if isscalar(o)
            fld = fieldnames(o);     
            for i = 1:numel(fld)
                recchk(o.(fld{i}), [prevStr '.' fld{i}], f);
            end
        elseif ~isempty(o)
            arrayfun(@(i) recchk(o(i), [prevStr '(' num2str(i) ')'], f), 1:numel(o))            
        end
    elseif iscell(o)
        for i = 1:numel(o)
            recchk(o{i}, [prevStr '{' num2str(i) '}'], f);
        end
    elseif istable(o)
        col = o.Properties.VariableNames;
        for i = 1:width(o)
            recchk(o{:,i}, [prevStr '.' col{i}], f);
        end
    else
        f(o, prevStr);
    end  

end