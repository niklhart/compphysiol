function [X,Y] = bsx(A,B)
%BSX Binary singleton expansion (for operations without automatic bsx)

    mask = true(size(A)) | true(size(B));
    idx_A = mask .* reshape(1:numel(A), size(A));
    idx_B = mask .* reshape(1:numel(B), size(B));
    X = A(idx_A);
    Y = B(idx_B);
end

