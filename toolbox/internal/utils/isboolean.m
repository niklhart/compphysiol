%ISBOOLEAN Test for boolean type (scalar true or false)
function TF = isboolean(x)
    TF = islogical(x) && isscalar(x);
end
