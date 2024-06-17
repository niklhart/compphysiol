classdef (Abstract, HandleCompatible) CompactTabularDisplay
    %COMPACTTABULARDISPLAY Mixin class for compact table display
    %   For classes containing tabular information (possibly together with
    %   other information), inheriting from class COMPACTTABULARDISPLAY
    %   makes method 'disptable' accessible which displays the tabular
    %   content in compact form.

    methods (Abstract = true)
        tab = gettable(obj)
    end

    methods 
        function disptable(obj,maxprint)
            %DISPTABLE Display table in short format

            if nargin == 1
                maxprint = 10;
            end

            tab = gettable(obj);
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

    end
end