function tf = isequaltol(A, B, tol)
%ISEQUALTOL Variant of isequal function with tolerance (default: 1e-6)
%   ISEQUALTOL(A,B,TOL) recursively checks objects A and B for equality
%   of non-numeric parts and equality up to tolerance TOL for numeric parts.
%
%   Examples:
%       isequaltol(5,5.2,Tol=0.1)
%       isequaltol(5,5.2,Tol=0.3)
%
    arguments 
        A
        B
        tol (1,1) double = 1e-6
    end

    tf = isequal(class(A),class(B)) && isequal(size(A),size(B));

    % early return for class or size mismatch
    if ~tf
        return
    end

    switch class(A)
        case 'double'
            
            tf = all(abs(A-B) < tol, 'all');

        case 'struct'

            tf = issetequal(fieldnames(A),fieldnames(B));
            j  = 1;
            fld = fieldnames(A);
            nfld = length(fld);
            while tf && j <= numel(A)
                i  = 1;
                while tf && i <= nfld
                    tf = isequaltol(A(j).(fld{i}),B(j).(fld{i}),tol);
                    i = i+1;
                end
                j = j+1;
            end

        case 'table'

            tf = isequal(A.Properties,B.Properties);
            i  = 1;
            while tf && i <= width(A)
                tf = isequaltol(A.(i),B.(i),tol);
                i = i+1;
            end

        case 'cell'

            tf = true;
            i  = 1;
            while tf && i <= numel(A)
                tf = isequaltol(A{i},B{i},tol);
                i = i+1;
            end

        case {'char','string'}     % no tolerance on text classes
            tf = isequal(A, B);
    end
end