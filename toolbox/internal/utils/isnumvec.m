function TF = isnumvec(x)
%ISNUMVEC True for numeric (row or column) vectors. 
    TF = isnumeric(x) && isvector(x);
end

