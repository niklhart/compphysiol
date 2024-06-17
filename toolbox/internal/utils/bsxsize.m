function s = bsxsize(A,B)
%BSXSIZE Size of binary singleton expansion of arguments.

    s = size(true(size(A)) | true(size(B)));
    
end

