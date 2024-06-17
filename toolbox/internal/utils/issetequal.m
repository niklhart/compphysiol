%ISSETEQUAL True for set equality
function TF = issetequal(A,B)
    TF = isempty(setdiff(A,B)) && isempty(setdiff(B,A));

end

