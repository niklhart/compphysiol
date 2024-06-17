function tblout = tblvertcat(varargin)
%TBLVERTCAT Vertically concatenate tables with different variables
%   T = TBLVERTCAT(T1,T2,...) vertically concatenates tables T1, T2, ...
%   into a table T, filling dummy values where necessary. Columns with the
%   same names must have compatible types. Dummy values have the following
%   types:
%
%   Variable type   Dummy variable
%   -----------------------------------
%   numeric         NaN
%   cell(-str)      {''} 
%   string          <missing>
%   categorical     <undefined>
%
%   Examples:
%
%       x = [ 1 ; 2 ; 3 ];
%       y = {'a';'b';'a'};
%       z = categorical(y);
%   
%       % Concatenate two non-empty tables
%       t1 = table(x, y);
%       t2 = table(x, z);
%       tblvertcat(t1, t2)
%
%       % Extra column name from empty table deleted by default
%       tblvertcat(t1, t2([],:)) 
%       
%       % Extra column name inherited from empty table
%       tblvertcat(t1, t2([],:),'includeEmptyTableHeaders')

    [tbl, prop] = parseparams(varargin);

    excludeEmptyTableHeaders = isempty(prop) || ~strcmp(prop{1},'includeEmptyTableHeaders');
    
    %% table properties
    assert(all(cellfun(@istable,tbl)), 'All input arguments must be tables.')

    % early return for 0 or 1 input arguments
    nrowslist = cellfun(@height,tbl);   % number of rows for each table

    if excludeEmptyTableHeaders
        tbl = tbl(nrowslist>0);
        ntbls = nnz(nrowslist);             % number of non-empty tables
        nrowslist = nrowslist(nrowslist>0);
    else
        ntbls = numel(tbl);
    end

    % at most one (non-empty) table --> early return
    switch ntbls
        case 0
            tblout = table();
            return
        case 1
            tblout = tbl{1};
            return
    end
    
    % find union of columns for the remaining tables
    colnamefun = @(t) t.Properties.VariableNames;
    coltypefun = @(t) varfun(@class,t,'OutputFormat','cell');

    colnames = cellfun(colnamefun, tbl, 'UniformOutput', false); 
    coltypes = cellfun(coltypefun, tbl, 'UniformOutput', false);

    allcols = Reduce(@union,colnames{:});  % union of all column names
    
    % check that same column names have compatible formats
    allfmts = cell(size(allcols));
    for icol = 1:numel(allcols)
        fmt = {};
        for itbl = 1:ntbls
            [hascol, colidx] = ismember(allcols{icol}, colnames{itbl});
            if hascol
                fmt = union(fmt, coltypes{itbl}(colidx));
            end
        end        
        if ~isscalar(fmt)
            if all(ismember(fmt,{'double','DimVar','HDV'}))
                % compatible, include double NaN as dummy variables
                fmt = {'double'};   
            else
                % use cell as a container
                fmt = {'cell'};
            end
        end        
        allfmts(icol) = fmt;
    end
    
    % promote all incompatible columns to cell format
    cellcols = allcols(strcmp(allfmts,'cell'));
    for itbl = 1:ntbls
        for icol = 1:numel(cellcols)        
            clcol = cellcols{icol};
            if ismember(clcol, colnames{itbl})
                if isnumeric(tbl{itbl}.(clcol))
                    tbl{itbl}.(clcol) = num2cell(tbl{itbl}.(clcol));
                elseif iscategorical(tbl{itbl}.(clcol))
                    tbl{itbl}.(clcol) = cellstr(tbl{itbl}.(clcol));
                end
            end
        end
    end

    % expand all tables
    for itbl = 1:ntbls
        [missing, iallcols] = setdiff(allcols, colnames{itbl});
        for imis = 1:numel(missing)
            
            fmt = allfmts{iallcols(imis)};
            switch fmt
                case {'double','DimVar','HDV'}
                    dmy = NaN;
                case 'cell'
                    dmy = {''};
                case 'string'
                    dmy = string(NaN); 
                case 'categorical'
                    dmy = categorical(NaN);
                otherwise
                    error('Cannot expand column format "%s".', fmt)
            end
            
            tbl{itbl}.(missing{imis}) = repmat(dmy,nrowslist(itbl),1);
        end
        tbl{itbl} = tbl{itbl}(:, allcols);   % ensure same column order for all tables 
    end

    % concatenate expanded tables
    tblout = vertcat(tbl{:});


end


