%TABLESPLIT Split ImportableData table by mappings
%   OUT = TABLESPLIT(OBJ) splits the ImportableData object OBJ with N 
%   defined mappings into a N-by-1 struct array OUT of tables with columns
%   equal to the mapped attributes.
%   
%   See also ImportableData, ImportableData/import

function [out,IDs] = tablesplit(obj)

    % ensure that input is left unchanged
    obj = copy(obj);

    % avoid accessing the dependent property 'mappings' multiple times
    mappings = obj.mappings; 
    
    %% consistency checks of '*.csv' and mappings
        
    % Check if mandatory Name column is defined and call it "Name" from now   
    allCols  = obj.table.Properties.VariableNames;
    name = obj.name; % avoid multiple triggers of the get.name function
    if ismember('rows',{mappings.type})
        assert(name.found, 'Mandatory "Name" column missing in dataset "%s".', obj.file)
    end
    
    %% Standardize ID column to handle single/multi ID cases uniformly
    
    idCol = obj.findcol('ID');
    if isnan(idCol)
        assert(~ismember('ID',allCols), ...
            'ID column present, but ID attribute is not set; aborting.')
        obj.setattr('ID',1);
        idCol = obj.findcol('ID');
    end

    obj.table.(idCol) = tocategorical(obj.table.(idCol));   
    IDs = categories(obj.table.(idCol));

    %% Create standardized format for all mappings
    nmap = numel(mappings);
    out(1:nmap) = struct('type',cell(nmap,1),'tab',cell(nmap,1));

    for i = 1:nmap
        map = mappings(i); % current mapping

        % Step 1: filter rows relevant for current name mapping
        switch map.type 
            case 'row'
                lbl = map.label;
                tab = obj.table(name.col == lbl, :);
            case {'column','all'}
                % we consider the entire table for column mappings, but
                % then only the unique combinations will be taken below.
                tab = obj.table;
        end

        % Step 2: create a new table variable-by-variable, using attribute
        % names as column names
        newtab = table();
        newtab.ID = tab.(idCol);

        % iterate over attributes to fill out the table. This is the safest
        % way to rename columns, since two different attributes mapping to 
        % the same column just result in two independent but differently
        % named copies.
        for j = 1:numel(map.attr)
            attr = map.attr(j);
            if attr.incolumn
                idx = findcol(obj,attr.name,i);
                assert(~isnan(idx), 'Attribute "%s" undefined.',attr.name)                
                newtab.(attr.name) = tab.(idx);
            else
                if ischar(attr.value)
                    attr.value = {attr.value};
                end
                newtab.(attr.name) = repmat(attr.value, height(tab), 1);
            end
        end        
        if ismember(map.type,{'column','all'})
            % column mappings currently take the unique set of values
            % defined for each ID.
            newtab = unique(newtab);
        end
        % Final step: assignment
        out(i).type = map.categ;
        out(i).tab  = newtab;
    end
    
end

