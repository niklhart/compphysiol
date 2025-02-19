function tab = filterbylvl(tab, by, lvl)
%FILTERBYLVL Filter a table by (aggregation) levels
%   TAB = FILTERBYLVL(TAB, BY, LVL) filters table TAB according to column 
%       BY, retaining only the levels in aggregation LVL.

    if isempty(lvl)
        return
    end
    
    tab = tab(ismember(tab.(by),levels(lvl)), :);    
    if iscategorical(tab.(by)) || iscellstr(tab.(by))
        tab.(by) = removecats(categorical(tab.(by)));
    end
end


function lvl = levels(aggr)
%LEVELS Aggregation levels
%   LVL = LEVELS(AGGR), with an aggregation AGGR, returns all aggregation
%   levels as a cellstr LVL.

    if iscell(aggr) && ~iscellstr(aggr)
        lvl = [aggr{:}];
    elseif isstruct(aggr)
        lvl = struct2cell(aggr);
        lvl = [lvl{:}];
    elseif iscellstr(aggr)
        lvl = aggr;
    else 
        error('compphysiol:Utils:Filterbylvl:Levels:invalidInputArgument', ...
            'Invalid input argument.')
    end

end

