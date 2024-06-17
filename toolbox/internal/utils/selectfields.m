function out = selectfields(in, fields)
%SELECTFIELDS Select multiple fields from a struct (array) 

    assert(isstruct(in), 'Input #1 must be struct.')   

    fields = cellstr(fields);
    missing = ~isfield(in,fields);
    if any(missing)
        error(['Undefined fields requested:' strjoin(fields(missing),',')]); 
    end
    
    % remove fields not needed
    out = rmfield(in, setdiff(fieldnames(in), fields)); 

end