% FLATTEN_STRUCT Turn a nested structure into a linear array
%
% Source: https://stackoverflow.com/a/34723841
function C = flatten_struct(A)

    A = struct2cell(A);
    C = [];
    for i=1:numel(A)  
        if(isstruct(A{i}))
            C = [C,flatten_struct(A{i})];
        else
            C = [C,A{i}]; 
        end
    end

end
