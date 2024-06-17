function checkmodelstruct(model)
%CHECKMODELSTRUCT Error for invalid model structs.
%   ISMODELSTRUCT(MODEL) throws an informative error if struct MODEL  
%   does not comply with the format required for simulator(). This does not
%   guarantee that MODEL is error-free, but it will allow simulator() to
%   pass the respective parts of MODEL on to other functions.
%
%   See also simulator

    assert(all(isfield(model.setup,{'indexing','X0'})), ...
        'Setup struct must have mandatory fields "indexing" and "X0".')
    assert(isfield(model.setup.indexing,'Id'), ...
        'Indexing struct must have a subfield "Id".')
    assert(isnumvec(model.setup.X0), ...
        'Field "X0" must be a (possibly dimensioned) numeric vector.')
    
end

