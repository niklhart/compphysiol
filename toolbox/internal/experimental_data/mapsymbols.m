function str = mapsymbols(type)
%MAPSYMBOLS Symbols representing different states of mappings

    lst = struct;
    
    lst.unmapped = {'      '};
    lst.complete = {' ---> '};
    lst.missing  = {' -!-> '};
    
    type = validatestring(type,fieldnames(lst));
    
    str = lst.(type);

end

