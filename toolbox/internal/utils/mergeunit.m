%MERGEUNIT Merge units into a table column
%   T = MERGEUNIT(T,'COL') combines column T.COL with the unit column
%   T.('[COL]'), if available, and returns the combined column as a 
%   DimVar or HDV C. If '[COL]' is not defined, T.COL is simply converted  
%   to numeric format.
%
%   C = MERGEUNIT(T,'COL',FORCENUMERIC), with a Boolean FORCENUMERIC allows  
%   to specify if cellstr column T.('[COL]') should be converted to numeric 
%   type or left as cellstr (units are than merged via concatenation). 
%   Default is 'true'.
%
%   C = MERGEUNIT(T, COLS) or C = MERGEUNIT(T, COLS, FORCENUMERIC), with a 
%   cellstr COLS, is equivalent to iterating over the entries in COLS.


function T = mergeunit(T,cols,forceNumeric)
   
    cols = cellstr(cols);

    % default value for input #3
    if nargin < 3
        forceNumeric = true;
    end

    for i = 1:numel(cols)
        col = cols{i};
        assert(istablecol(T,col), 'Undefined table column "%s".',col)
    
        C = T.(col);
        if forceNumeric
            C = tounit(C);
        end

        ucol = ['[' col ']'];
        if istablecol(T,ucol)
            Cu = T.(ucol);
            if forceNumeric             
                assert(isa(C,'double'), ...
                    'Units defined simultaneously in columns "%s" and "%s".',col,ucol)

                % merge columns as numeric 
                Cu = tounit(Cu);
                C = C .* Cu;
            else  
                if isa(C,'double')
                    C = num2str(C);
                else
                    C = cellfun(@num2str,C,'UniformOutput',false);
                end
                % merge columns as char 
                C = strcat(C,Cu);
            end
            T.(ucol) = [];
        end

        T.(col) = C;
    end

end
