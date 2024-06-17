%INITIALIZEX0 Initialize dimensioned vector of NaNs from indexing struct
%   X0 = INITIALIZEX0(I), with (indexing) struct I, returns a dimensioned
%   column vector X0 which has as many elements as I has indices. Fields of
%   I can be non-scalar, but the union of all fields must be a contiguous
%   enumeration (from 1 to the number of indices).
   
function X0 = initializeX0(I)

    assert(isstruct(I), 'Input must be struct.')
    
    numindex = flatten_struct(I);

    nX0 = numel(numindex);
    assert(isequal(sort(numindex), 1:nX0), ...
        'Input is not a valid index structure.')
    
    X0 = unan(nX0,1);
    
end

