function mustContainColumns(tab, cols)
%MUSTCONTAINCOLUMNS Validate columns in a table.
%   MUSTCONTAINCOLUMNS(TAB, COLS), with a table TAB and a cellstr COLS,
%   returns an informative error message if any of the columns in COLS are
%   missing in TAB.

    assert(istable(tab),   'Input #1 must be a table.')
    assert(iscellstr(cols),'Input #2 must be a cellstr.') %#ok<ISCLSTR>

    tabcols = tab.Properties.VariableNames;
    if ~all(ismember(cols, tabcols))
        missing = setdiff(cols, tabcols);
        me = MException('compphysiol:missingCol','Mandatory column(s) missing: %s.',strjoin(missing,','));
        throwAsCaller(me)
    end

end

