%ISTABLECOL True if column is in table
%   TF = ISTABLECOL(T, COL), with table T and char COL, is true if COL is a
%   column of T and false otherwise.

function tf = istablecol(T, col)
    assert(istable(T), 'Input #1 must be a table.')
    
    tf = ismember(col, T.Properties.VariableNames);
end

