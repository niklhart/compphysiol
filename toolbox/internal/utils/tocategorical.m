function C = tocategorical(C)
% TOCATEGORICAL Convert object to categorical type
%   OUT = TOCATEGORICAL(IN) converts input IN to a categorical array OUT.
%   Input IN may be categorical, logical, numeric, char, cellstr or string.
%   
%   Function TOCATEGORICAL is almost identical to function categorical
%   except that it also supports character arrays.

    if ischar(C)
        C = cellstr(C);
    end
    C = categorical(C);

end