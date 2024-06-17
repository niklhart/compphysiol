function disptable(tab, maxprint)
%DISPTABLE Display a table in short format

    if nargin < 2
        maxprint = 10;
    end

    nrow = height(tab);

    if nrow <= maxprint

        str = table2char(tab);               
        rows = num2str((1:nrow)');

    else
        iprnt = [1:maxprint nrow]';

        str = table2char(tab(iprnt,:));
        str(end-1,:) = ' ';

        rows = num2str(iprnt);
        rows(maxprint,:) = '.';
    end
    ntotrow = size(str,1);
    nbdyrow = size(rows,1);
    nhdrrow = ntotrow - nbdyrow;
    nrnmcol = size(rows,2);
    hrws = vertcat(repmat(' ',[nhdrrow nrnmcol]), rows);
    spc  = repmat(' ',ntotrow,3);

    disp([hrws spc str])
    fprintf('\n')
end
