%ADDTABLECOLS Add empty columns to a table
%   TAB = ADDTABLECOLS(TAB, COLNM, FRMT) adds columns COLNM (char/cellstr) 
%   to table TAB. The table format is specified via FRMT (char/cellstr,
%   same size as COLNM), which can be 'char' or 'double'

function tab = addtablecols(tab, colnm, frmt)

assert(istable(tab), ...
    'compphysiol:Utils:addtablecols:wrongInputType', ...
    'Input #1 must be a table.')

n = height(tab);

colnm = cellstr(colnm);
frmt  = cellstr(frmt);
[colnm, frmt] = uniformize_size(colnm,frmt);

% TODO: can this assertion ever fail after running uniformize_size
% function?
assert(all(size(colnm) == size(frmt)), ...
    'compphysiol:Utils:addtablecols:wrongInputSizes', ...
    'Inputs #2 and #3 must have same size.')

tabnm = tab.Properties.VariableNames;

for i = 1:numel(colnm)
    col = colnm{i};
    % if column is already defined, do nothing
    if ~ismember(col,tabnm)
        switch frmt{i}
            case 'char'
                tab.(col) = repmat({''},n,1);
            case 'double'
                tab.(col) = nan(3,1);
            otherwise 
                error('compphysiol:Utils:addtablecols:wrongColumnType', ...
                    'Invalid format "%s".', ...
                    frmt{i})
        end
    end
end

