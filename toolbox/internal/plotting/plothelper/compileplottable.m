%COMPILEPLOTTABLE Create a table which can be used for plotting functions
%   TAB = COMPILEPLOTTABLE(INDV) takes an Individual array INDV and
%   compiles observations, type, and name into a single table TAB suitable
%   for plotting.
%   
%   TAB = COMPILEPLOTTABLE(INDV, OBSARGS) additionally filters by
%   Observable attributes such as 'Site', specified as a struct with the
%   attribute names as fieldnames and the retained values as cellstr.
%
%   TAB = COMPILEPLOTTABLE(INDV, []) is equivalent to the one-argument
%   call.

function tab = compileplottable(individual, obsargs)

    checkSimulated(individual);

    nid = numel(individual);
    tabs = cell(nid,1);
    for i = 1:nid
        
        tabs{i} = expand(individual(i).observation); % Record object --> table
        
        reservedCols = {'ID','Name','IdType','Observable'};
        assert(~any(ismember(reservedCols,tabs{i}.Properties.VariableNames)), ...
            'Individual %d uses reserved column name for observation attribute.',i) 
        tabs{i}.ID     = repmat(i,[height(tabs{i}) 1]);                     % adding ID column
        
        if isempty(individual(i).name)
            namei = defaultname(individual(i));
        else
            namei = individual(i).name;
        end
        tabs{i}.Name   = repmat({namei},[height(tabs{i}) 1]);  % adding name column
        
        tabs{i}.IdType = repmat({individual(i).type}, [height(tabs{i}) 1]); % ExpId or SimId?

        obs_i = individual(i).observation.Observable;
        tabs{i}.Observable = arrayfun(@(x) obj2str(x,'table'),obs_i,'UniformOutput',false);
    end
    
    tab = tblvertcat(tabs{:}); % collapse per-ID tables into a single table.
    
    % early return for empty table, because the commands below will fail
    % if isempty(tab)
    %     return
    % end

    % filter by Observable attributes
    if nargin == 2 && ~isempty(obsargs)
        obsargfields = fieldnames(obsargs);
        for i = 1:numel(obsargfields)
            fld = obsargfields{i};
            obsargs_i = obsargs.(fld);
            if ~isempty(obsargs_i) && istablecol(tab,fld)
                tab = tab(ismember(tab.(fld),obsargs_i),:);
            end
        end
    end
    % convert columns to categorical type -> comparison with '=='
    attrCols = setdiff(tab.Properties.VariableNames, ...
        {'Time','ID','Name','IdType','Value'});
    tab.ID     = categorical(tab.ID);           
    tab.Name   = categorical(tab.Name);         
    tab.IdType = categorical(tab.IdType, {'Experimental data','Virtual individual'});        
    
    for i = 1:numel(attrCols)
        tab.(attrCols{i}) = categorical(tab.(attrCols{i}));
    end

    % remove missing values in Time / Value column
    tab = rmmissing(tab,'DataVariables',{'Time','Value'});   
 
end
