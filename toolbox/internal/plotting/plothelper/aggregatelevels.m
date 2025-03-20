%AGGREGATELEVELS Aggregate levels of a categorical variable
%   C = AGGREGATELEVELS(T, GRP), with a table T and a string array or 
%   cellstr GRP containing column names in T, returns a height(T)-by-1 
%   categorical array C that contains aggregate names that can be used as
%   a grouping column.

function C = aggregatelevels(T, grp)
    
    arguments 
        T table
        grp (:,1) string {mustBeTableCols(grp,T)}
    end

    TT = cellfun(@(c) T{:,c}, grp,'UniformOutput',false);
    C = categorical(Reduce(@times,TT{:}));

end

function mustBeTableCols(grp, T)

    assert(all(istablecol(T,grp)),'compphysiol:aggregatelevels:noTableCols',...
        'All grouping variables must be columns of the input table.')

end

