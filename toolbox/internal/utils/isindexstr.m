%ISINDEXSTR True if input is an index structure.
%   TF = ISINDEXSTR(I) returns true if input I is a (possibly nested)
%   struct containing, at its N leaves, the integers 1:N.
%
%
%   Examples:
%
%   I1 = struct('a',1,'b',2);
%   I2 = struct('a',1,'b',3);
%   I3 = struct('c',I2,'d',2);
%   I4 = struct('c',I2,'d',[2 4]);
%   I5 = struct('c','foo','d',1);
%
%   isindexstr(I1)    % --> true
%   isindexstr(I2)    % --> false
%   isindexstr(I3)    % --> true
%   isindexstr(I4)    % --> true
%   isindexstr(I5)    % --> false

function tf = isindexstr(I)

    if isstruct(I)
        try 
            v = flatten_struct(I);
            tf = isequal(sort(v),1:numel(v));
        catch 
            tf = false;
        end
    else
        tf = false;
    end

end