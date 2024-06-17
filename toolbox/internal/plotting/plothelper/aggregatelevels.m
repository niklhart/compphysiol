%AGGREGATELEVELS Aggregate levels of a categorical variable
%   A = AGGREGATELEVELS(V, CLV), with categorical array V and cell array of
%   cellstr CLV, assembles categories in CLV{1}, ... into one. If CLV is
%   cellstr, it is interpreted as {CLV}, i.e., a single aggregate category.
%
%   A = AGGREGATELEVELS(V, SLV), with categorical array V and a struct of
%   cellstr SLV, uses fieldnames of SLV to name the aggregate categories.
%   
%

function V = aggregatelevels(V, lvl)
    
    assert(iscategorical(V),'Input #1 must be a categorical array.')
    
    if isempty(lvl)
        return
    end
    if iscellstr(lvl) %#ok<ISCLSTR>
        lvl = {lvl};
    end
    if isstruct(lvl)
        aggnm = fieldnames(lvl);
        lvl   = struct2cell(lvl);
    else
        aggnm = cellfun(@(c) strjoin(c,'/'),lvl,'UniformOutput',false);
    end
    assert(iscell(lvl) && all(cellfun(@iscellstr,lvl),'all'), ...
            'Input #3 must be cellstr or a cell array of cellstr.')
    assert(all(ismember([lvl{:}],categories(V))), 'Undefined categories found.')

    nagg = numel(lvl);
    for i = 1:nagg
        V = mergecats(V, lvl{i}, aggnm{i});
    end
    
end