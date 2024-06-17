function str = display_dosing(dosing)
%DISPLAY_DOSING Write Dosing object into concise character array.

props = properties(dosing);
hasprop = ~cellfun(@(x) isempty(dosing.(x)),props);

    switch nnz(hasprop)
        case 0
            str = 'empty';
            return
        case 1
            prop  = props{hasprop};
            dprop = dosing.(prop);
            if height(dprop) <= 3 
                attr = cellfun(@num2str,table2cell(dosing.(prop)),'UniformOutput',false);
                str = [prop ':' strjoin(attr,'-')];
                return
            end
    end
    % more than 2 dosing events of same type or different dosing types
    prop = props(hasprop);
    ndos = cellfun(@(x) height(dosing.(x)),prop);
    str = strjoin(strcat(arrayfun(@num2str,ndos,'UniformOutput',false),{' '},prop),',');

end

