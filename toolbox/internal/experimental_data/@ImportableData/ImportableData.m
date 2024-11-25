classdef ImportableData < handle & matlab.mixin.Copyable % & CompactTabularDisplay
    %IMPORTABLEDATA A class for specifying the import of experimental data.
    %   The ImportableData class is used to specify the import of
    %   experimental data into an Individual object in a stepwize
    %   manner.
    %
    %   See also ImportableData/ImportableData (constructor),
    %   ImportableData/maprow, ImportableData/mapall, 
    %   ImportableData/setattrcol, ImportableData/import, Individual

    properties (SetObservable)
        table table
    end
    properties (SetAccess = private)
        file
        folder
        info
        attributes = table({},[],{},[],'VariableNames',{'list','index','pattern','scope'})
        usermaps = struct('type',{},'label',{},'categ',{},'attr',{})
    end
    properties (Dependent)
        mappings
        name
    end

    methods
        %% Constructor
        function obj = ImportableData(filename, varargin)
            %IMPORTABLEDATA Create an ImportableData object
            %   OBJ = ImportableData(FILENAME) creates an object OBJ of
            %   class ImportableData from a valid data file named FILENAME,
            %   which can either be a relative path with respect to the
            %   main toolbox folder or an absolute path.
            %   
            %   OBJ can then be manipulated using ImportableData methods,
            %   in particular mappings. EXPID = import(OBJ) finishes the
            %   data import.
            %
            %   OBJ = ImportableData(FILENAME, ...) allows to specify any
            %   input argument allowed in function readtable() to customize
            %   the creation of the ImportableData object. 
            %
            %   Examples:
            %   
            %   % With defaults
            %   file = 'data/Theophylline.csv';
            %   data = ImportableData(file)
            %   
            %   See also ImportableData/import, readtable, pathPBPKtoolbox,
            %   ImportableData/maprow, ImportableData/flagcov,
            %   ImportableData/setattr.

            % standardize filename (extension, folder)
            [folder,filename,ext] = fileparts(filename);
            if isempty(ext)
                ext = '.csv';
            end
            filename = [filename ext];


            % relative path to toolbox folder or absolute path?
            tbx_folder = 'toolbox';
            if isfile(fullfile(tbx_folder,folder,filename)) % relative path
                folder = fullfile(tbx_folder, folder);
            end
            assert(isfile(fullfile(folder,filename)), ...   % absolute path
                'Couldn''t find data file "%s".',filename)

            % before reading in the data table, turn off the modified
            % varnames warning, since we explicitly want to use this syntax
            % for unit headers. Afterwards, it it turned on safely again
            % using onCleanup.
            warnid = 'MATLAB:table:ModifiedAndSavedVarnames';
            prev = warning('off',warnid);            
            c = onCleanup(@()warning(prev.state,warnid));

            % read in the data table from '<data>.csv'
            obj.table  = readtable(fullfile(folder, filename), varargin{:});
            obj.file   = filename;
            obj.folder = folder;
            
            % check for the optional file '<data>_Info.txt'
            infoname = replace(filename,'.csv','_Info.txt');
            if isfile(fullfile(folder,infoname))
                obj.info = infoname;
            end

            % add a listener for changes in the table
            addlistener(obj,'table','PostSet',@obj.updateattrindex);

            % Process units encoded in the header (format 'ColName [ColUnit]')
            process_header_units(obj)
            
            % add keywords to the attributes list
            keywords = {'Name';'ID'};
            for i = 1:numel(keywords)
                obj.updateattrrow(keywords{i});
            end
        end

        %% Get-functions for dependent properties
        function nm   = get.name(obj)
            nm = struct;
            [lia, locb] = ismember('Name',obj.attributes.list);
            idx = obj.attributes.index(locb);
            nm.found = lia & ~isnan(idx);
            if nm.found
                nm.col  = categorical(obj.table.(idx));
                nm.freq = countcats(nm.col);
                nm.set  = categories(nm.col);
            end
        end

        function maps = get.mappings(obj)

            maps = obj.usermaps;

            for i = 1:numel(maps)

                categ = maps(i).categ;
                map_attr = {maps(i).attr.name};

                valid_attr = expectattr(categ);

                % process attributes associated to data columns
                isValid  = ismember(obj.attributes.list, valid_attr);
                isGlobal = obj.attributes.scope == 0;
                glb_attr = obj.attributes.list(isValid & isGlobal);
    
                % explicit attribute definitions in a mapping take priority
                % over global column attributes in case of conflicts
                glb_attr = setdiff(glb_attr,map_attr);
    
                % all checks passed, create the column attributes struct
                attrstruct_glb = struct(...
                    'name',     glb_attr,...
                    'value',    [],...
                    'incolumn', true);
   
                % append column attributes to mapping attributes
                maps(i).attr = vertcat(maps(i).attr(:), attrstruct_glb(:));

            end

        end

        %% Methods for interactive use
        function disp(obj)
            %DISP Display an ImportableData object

            link = helpPopupStr('ImportableData');
            fprintf('\t%s object:\n\n',link)        
            fprintf('File: %s\n\n', obj.file)
            if ~isempty(obj.info)
                fprintf('Supplementary information: %s\n\n', obj.info)
            end
            tab = obj.table;
            tab.Properties.UserData.VariableSubtitles = update_column_attributes(obj);
            disptable(tab,10)
            fprintf('Mappings:\n\n')
            dispmappings(obj)

        end

        function details(obj)
            %DETAILS Detailed display of an ImportableData object

            link = helpPopupStr('ImportableData');
            fprintf('\t%s object:\n\n',link)        
            fprintf('File: %s\n\n', obj.file)
            if ~isempty(obj.info)
                fprintf('Supplementary information: %s\n\n', obj.info)
            end
            disptable(obj.table)
            fprintf('Mappings:\n\n')
            out = tablesplit(obj);

            for i = 1:numel(out)
                fprintf('%s\n\n',out(i).type)
                disptable(out(i).tab,4)
            end

        end

        function obj = maprow(obj, label, categ, varargin)
        %MAPROW Map a set of data rows to an event category
        %   MAPROW(OBJ, LABEL, CATEG) maps all rows in the dataset of
        %   ImportableData object OBJ with Name matching LABEL to the event
        %   category CATEG. 
        % 
        %   The 'Name' column must be identified before using MAPROW (which
        %   is tried automatically at construction of OBJ)
        %
        %   MAPROW(OBJ, LABEL, CATEG, ATTR1, VAL1, ATTR2, VAL2,...)
        %   additionally specifies attribute-value pairs for the mapping.
        %   
        %   See also ImportableData/ImportableData, ImportableData/mapall,
        %   expectattr. 

            nm = obj.name;
            assert(nm.found, 'Set the "Name" column before mapping dataset rows.')
            label = validatestring(label, nm.set);        
            obj = map(obj, 'row', label, categ, varargin{:});

        end

        function obj = mapall(obj, label, categ, varargin)
        %MAPALL Map all data rows to an event category
        %   MAPALL(OBJ, LABEL, CATEG) maps all rows in the dataset of
        %   ImportableData object OBJ to the event category CATEG. Input
        %   LABEL is used as an identifier for this mapping.
        %   
        %   MAPALL(OBJ, LABEL, CATEG, ATTR1, VAL1, ATTR2, VAL2,...)
        %   additionally specifies attribute-value pairs for the mapping.
        %   
        %   This function call is similar in spirit to 
        %   
        %       setattr(OBJ, 'Name', ['=' LABEL])
        %       maprow(OBJ, LABEL, CATEG, ...)
        %   
        %   but differs in the following ways:
        %   - it does not create an additional data column
        %   - multiple MAPALL statements can be combined
        %
        %   See also ImportableData/ImportableData, ImportableData/maprow,
        %   ImportableData/setattr.
    
            obj = map(obj, 'all', label, categ, varargin{:});

        end

        function obj = flagcov(obj, label, varargin)
        %FLAGCOV Flag a covariate column in the dataset
        %   FLAGCOV(OBJ, LABEL, COV) declares data column LABEL as
        %   containing the value for the covariate named COV.
        %
        %   FLAGCOV(OBJ, LABEL) uses the default COV=LABEL, i.e. the
        %   data column already has the correct name.
        %
        %   FLAGCOV(..., '[LABEL]', UNIT) declares unit UNIT for the 
        %   covariate, to be used if data column LABEL contains unitless
        %   value for a dimensioned covariate.
        %

            narginchk(2,5)
    
            % process the defaults
            switch nargin
                case {2,4}
                    cov = label;
                    msg = 'No covariate name provided, assuming same as label, "%s".';
                    warning(msg, label)
                case 3
                    cov = varargin{1};
                    varargin = {};
                case 5
                    cov = varargin{1};
                    varargin = varargin(2:3);
                    assert(strcmp(varargin{1},'[Value]'))
            end

            label = validatestring(label, obj.table.Properties.VariableNames);
            obj   = mapall(obj, label, 'Covariate', 'Name', ['=' cov], 'Value', label, varargin{:});
        end

        function obj = setattr(obj,attr,target)
        %SETATTR Set an attribute to a value or column.
        %   SETATTR(OBJ,ATTR,TARGET), binds attribute ATTR to data column 
        %   or explicit value TARGET in the global attributes list.
        %
        %   SETATTR(OBJ,ATTR,[]) removes attribute ATTR from the global
        %   attributes list.
        %
        %   See also ImportableData/processattrval

            assert(ischar(attr), 'Input "attr" must be char.')

            % early return for target []
            if isempty(target)
                obj.updateattrrow(attr,[]);
                return
            end

            [target, iscol] = processattrval(obj, target);
            if iscol
                % 'target' is a data column
                obj = setattrcol(obj,attr,target);
            else 
                % 'target' is a value for a new column
                obj = setattrval(obj,attr,target);
            end
        end

    end


    methods (Access = private)

        %% Callback methods
        function updateattrindex(obj,~,~)
            %UPDATEATTRINDEX Internal function for updating the index 
            %   column of the attributes property. UPDATEATTRINDEX is used
            %   as a callback to any change in the table property.

            % retrieve all active attributes & their search patterns
            lst = obj.attributes.list;
            pat  = obj.attributes.pattern;
            
            % match the patterns
            for i = 1:numel(lst)
                obj.attributes.index(i) = obj.locatecolumn(pat{i});
            end
            
        end

        %% Main mapping function

        function obj = map(obj, type, label, categ, varargin)
            %MAP Map a set of data rows or a column to an event category
            %   MAP(OBJ, TYPE, LABEL, CATEG) maps all rows (for TYPE='row') in the dataset of
            %   ImportableData object OBJ with Name matching LABEL to the event
            %   category CATEG. 
            % 
            %   The 'Name' column must be identified before using MAPROW (which
            %   is tried automatically at construction of OBJ)
            %
            %   MAP(OBJ, TYPE, LABEL, CATEG, ATTR1, VAL1, ATTR2, VAL2,...)
            %   additionally specifies attribute-value pairs for the mapping.
            %   
            %   See also ImportableData/ImportableData, expectattr,
            %   ImportableData/maprow, ImportableData/mapall.
        
            % Validate CATEG
            knownCategs = {'Covariate','Record','Bolus dosing','Infusion dosing','Oral dosing'};
            categ = validatestring(categ, knownCategs);

            % New or redefined mapping?
            mapIndex = subsasgnidx(label, {obj.mappings.label});

            % Attribute-value pairs in VARARGIN 
            map_attr = varargin(1:2:end);
            map_val  = varargin(2:2:end);

            % Scope of the mapping category and attribute validity check
            [valid_attr, mandatory_attr] = expectattr(categ);
            isValid = ismember(map_attr, valid_attr);
            if ~all(isValid)
                msg = 'Invalid attribute(s) "%s" for category "%s" will be ignored.';
                warning(msg, strjoin(map_attr(~isValid),','), categ)
                map_attr = map_attr(isValid);
                map_val  = map_val(isValid);
            end

            % process the name-value pairs (=attributes) in VARARGIN    
            [map_val, inCol] = processattrval(obj,map_val);

            attrstruct_map = struct(...
                'name',     map_attr,...
                'value',    map_val,...
                'incolumn', num2cell(inCol));

            % column attributes are updated in the attributes list, with a
            % local scope
            col_attr = map_attr(inCol);
            col_val  = map_val(inCol);            
            for i = 1:numel(col_attr)
                obj.updateattrrow(col_attr{i},col_val{i},mapIndex);
            end
            
            % mandatory attributes not defined in the mapping are appended
            % to the global attributes list and searched for in the data
            % columns
            global_attr = obj.attributes.list(obj.attributes.scope == 0);
            new_attr = setdiff(mandatory_attr, global_attr);
            new_attr = setdiff(new_attr, map_attr);
            for i = 1:numel(new_attr)
                obj.updateattrrow(new_attr{i});
            end

            % checks and updates finished, assign to OBJ
            obj.usermaps(mapIndex) = struct(...
                'type',    type, ...
                'label',   label, ...
                'categ',   categ, ...
                'attr',    attrstruct_map);

%            obj.warnattrdupl([],mapIndex);

        end


        %% Internal functions for manipulation of the attributes property

        function [val, iscol] = processattrval(obj,val)
        %PROCESSATTRVAL Process special syntax for attribute values
        %   [VAL, ISCOL] = PROCESSATTRVAL(OBJ, VAL) processes a cell array
        %   VAL of attribute values and classifies them as either explicit
        %   values or column references, using the following procedure:
        %
        %   - numeric              -->  explicit value
        %   - char starting in '.' -->  column reference, '.' is filtered
        %   - char starting in '=' -->  explicit value, '=' is filtered 
        %   - other char           -->  column reference if matching a data
        %                               column

            % convert char to cellstr
            charInput = ischar(val);
            if charInput
                val = cellstr(val);
            end

            % early return for non-cell VAL
            if ~iscell(val)
                iscol = false(size(val));
                return
            end

            % process VAL
            eqStart  = cellfun(@(v) ischar(v) && startsWith(v,'='), val);
            dotStart = cellfun(@(v) ischar(v) && startsWith(v,'.'), val);
            val(eqStart|dotStart) = extractAfter(val(eqStart|dotStart), 1);
            
            % determine column references (ISCOL)
            colnames = obj.table.Properties.VariableNames;
            hasMatch = cellfun(@(v) ischar(v) && ismember(v,colnames), val);
            iscol = hasMatch & ~eqStart; 

            % check for missing mandatory column references
            missing = val(dotStart & ~hasMatch);
            assert(isempty(missing), 'Attribute(s) not matching any data column: "%s"', ...
                    strjoin(missing,','))

            % if input was char, return output as char, too
            if charInput
                val = val{1};
            end

        end

        function obj = setattrcol(obj, attr, col)
            % SETATTRCOL Assign an attribute to a data column
            %   SETATTRCOL(OBJ, ATTR, COL) assigns a new or an already
            %   assigned attribute ATTR to data column COL.

            colnames = obj.table.Properties.VariableNames;
            col = validatestring(col,colnames);
            obj.updateattrrow(attr,col);
%            obj.warnattrdupl(attr);

        end

        function obj = setattrval(obj, attr, val)
            % SETATTRVAL Assign a value for an attribute
            %   SETATTRVAL(OBJ, ATTR, VAL) assigns value VAL and attribute
            %   ATTR to data column ATTR. Attribute ATTR cannot be already
            %   bound to another column.

            bound_attr = obj.attributes.list(~isnan(obj.attributes.index));
            assert(~ismember(attr,bound_attr), ...
                'Attribute "%s" already bound to a data column.', attr)
            if ischar(val)
                val = cellstr(val);
            end
            assert(isscalar(val), 'Input "val" must be scalar.')
            obj.table.(attr) = repmat(val, height(obj.table),1);
            obj = setattrcol(obj, attr, attr);
        end

        function updateattrrow(obj,attr,pat,scope)
            %UPDATEATTRROW Internal function for modifying, adding or 
            %   deleting a row in the attributes property, called from 
            %   within 'setattr' and 'maprow'.
            %
            %   UPDATEATTRROW(OBJ, ATTR, PAT, SCOPE) updates the attributes
            %   property for attribute ATTR and scope SCOPE (0 for global
            %   scope or a positive integer for a single-mapping scope) 
            %   with matching pattern PAT.
            %   
            %   UPDATEATTRROW(OBJ, ATTR, PAT) uses SCOPE = 0, i.e. a 
            %   global scope.
            %
            %   UPDATEATTRROW(OBJ, ATTR) uses PAT = ATTR as a matching
            %   pattern and SCOPE = 0.

            % default scope is global, if missing.
            if nargin < 4
                scope = 0;
            end

            % default pattern, if missing: from attrmpatemplate() or =attr. 
            if nargin < 3
                def = attrmaptemplate;
                [hasdef, locdef] = ismember(attr,def(:,1));
                if hasdef
                    pat = def{locdef,2};
                else
                    pat = attr;
                end
            end

            % determine list and scope matches
            list_match  = strcmp(attr, obj.attributes.list);
            scope_match = scope == obj.attributes.scope;

            % find row index of list & scope match
            iattr = find(list_match & scope_match,1);
            nattr = height(obj.attributes);
            if isempty(iattr)
                iattr = nattr+1;
            end

            % delete attribute or add/modify attribute?
            if isempty(pat)
                assert(iattr <= nattr, 'Cannot delete unassigned attribute "%s".', attr)
                obj.attributes(iattr,:) = [];
            else
                icol = obj.locatecolumn(pat);
                obj.attributes(iattr,:) = {attr, icol, {pat}, scope};
            end            

        end

        %% Internal functions related to column indices

        function icol = locatecolumn(obj, pat)
        % LOCATECOLUMN Locate a data column matching a pattern 
        % ICOL = LOCATECOLUMN(OBJ, PAT), with a character array PAT, 
        % computes the index ICOL of the first column starting in PAT,
        % using a case-insensitive search.
        %
        % ICOL = LOCATECOLUMN(OBJ, PATS), with a cellstr PATS, checks one 
        % element of PATS after each other and stops as soon as any column
        % matches the current element of PATS.
        %
        % If no match is found, ICOL is NaN.
        
            colnames = obj.table.Properties.VariableNames;
            pat = cellstr(pat);
            for i = 1:numel(pat)
                idx = startsWith(colnames,pat{i},'IgnoreCase',true);
                if any(idx)
                    break
                end
            end
            icol = find(idx,1);
            if isempty(icol)
                icol = NaN;
            end

        end

        function idx = findcol(obj, attr, i)
            %FINDCOL Find column index to which an attribute is mapped
            %   IDX = FINDCOL(OBJ, ATTR) retrieves the column index IDX 
            %   corresponding to attribute ATTR.
            %
            %   IDX = FINDCOL(OBJ, ATTR, I) retrieves the column index IDX 
            %   for the I-th mapping.

            list_match = strcmp(attr, obj.attributes.list);
            if nargin < 3
                i = 0;
            end 
            scope_match = i == obj.attributes.scope;
            % local scope if defined, else global scope
            if i > 0 && ~any(list_match & scope_match)
              scope_match = obj.attributes.scope == 0;
            end
            idx = obj.attributes.index(list_match & scope_match);

        end

        %% Internal functions related to display

        function dispmappings(obj)

            % Mapping information
            maps = obj.mappings; 
            nMaps = numel(maps);
            mapLabels = {maps.label};        

            % Process row names (requires Name column to be defined)
            nm = obj.name;
            if nm.found 
                RowNameSet = nm.set;
                fRowName   = nm.freq;    
            else
                RowNameSet = {};
                fRowName   = [];
                if nMaps == 0
                    fprintf('"Name" attribute not assigned to any data column yet.\n\n')
                    return
                end
            end

            % name set, counts & mapping status; same ordering as mappings
            NameSet = union(mapLabels(:),RowNameSet,'stable');
            nNames   = numel(NameSet);
            
            [isRow,locR] = ismember(NameSet,RowNameSet);
            fName = height(obj.table)*ones(size(NameSet));
            fName(isRow) = fRowName(locR(isRow));

            isMapped = ismember(NameSet,mapLabels);

            % Initialize a cell array C for display on the console
            C = cell(nNames,6);
            iIdx    = 1;
            iOrnt   = iIdx+1;
            iSize   = iOrnt+1;
            iName   = iSize+1;
            iMapped = iName+1;
            iMapinfo= iMapped+1;

            % Index
            C(isMapped,iIdx)  = strcat(num2str((1:numel(maps))'),{' '});
            C(~isMapped,iIdx)  = {''};

            % Orientation
            iRow = ismember(NameSet,RowNameSet);
            iCol = ~iRow;
            C(iRow,iOrnt) = {'- '};
            C(iCol,iOrnt) = {'| '};

            % Size and name of events to be mapped
            C(:,iSize) = strcat({'['}, cellstr(num2str(fName)), {'x] '}); 
            C(:,iName) = NameSet;
           
            % Find "columnless" attributes in the list, which are displayed
            % in a special way if relevant for a mapping (see loop below)
            columnless_attr = obj.attributes.list(isnan(obj.attributes.index));

            % Deal with unmapped names first
            C(~isMapped,iMapped)  = mapsymbols('unmapped');
            C(~isMapped,iMapinfo) = {'(unmapped)'};

            % Assign mapping information in human-readable form
            for i = 1:nMaps
                map = maps(i);
                iC = strcmp(mapLabels{i}, NameSet);

                % Flag value/missing/local attributes, then collapse all 
                % attributes used in the current mapping into a str
                attr = {map.attr.name};
                vals = {map.attr.value};
                incol = [map.attr.incolumn];                
                isval = ~incol;
                islcl = incol & ~cellfun(@isempty,vals);
                ismis = incol & ismember(attr,columnless_attr);
                attr(isval) = strcat(attr(isval),'=',cellfun(@num2str,vals(isval),'UniformOutput',false));
                attr(islcl) = strcat(attr(islcl),num2str(i));
                attr(ismis) = strcat('!', attr(ismis));
                attrStr = strjoin(attr,',');
                
                % Assign into cell array C
                if any(ismis)
                    C(iC,iMapped) = mapsymbols('missing');
                else
                    C(iC,iMapped) = mapsymbols('complete');
                end
                C{iC,iMapinfo} = sprintf('%s(%s)', map.categ, attrStr);
            end

            % Reshape cell array matrix into a character array
            ncols = size(C,2);
            Ccols = cell(1,ncols);
            for i = 1:ncols
                Ccols{i} = char(C(:,i));
            end
            disp([Ccols{:}])
 
        end

        %% Check attribute consistency
% 
%         function warnattrdupl(obj,glb_attr,imaps)
%             %WARNATTRDUPL Warn about (local/global) attribute duplicates 
% 
%             % set defaults for 'glb_attr' and 'imap' arguments
%             maps = obj.mappings;
%             if nargin < 2 || isempty(glb_attr)
%                 attribs = obj.attributes;
%                 glb_attr = attribs.list(~isnan(attribs.index) & attribs.scope == 0);
%             end
%             if nargin < 3 || isempty(imaps)
%                 imaps = 1:numel(maps);
%             end
% 
%             % loop over maps
%             for i = imaps
% 
%                 map_attr = {maps(i).attr.name};
%                 val_attr = map_attr(~[maps(i).attr.incolumn]);
% 
%                 % explicit attribute definitions in a mapping take priority
%                 % over global column attributes in case of conflicts
%                 redefined_attr = intersect(val_attr,glb_attr);
%                 if ~isempty(redefined_attr)
%                     msg = ['Attribute(s) "%s" specified in a mapping and defined globally. '...
%                            'In this case, attributes are taken from the mapping.'];
%                     warning(msg, strjoin(redefined_attr,','))
%                 end
%    
%             end
% 
%         end

        %% Other internal functions 

        function colattrib = update_column_attributes(obj)
            % UPDATE_COLUMN_ATTRIBUTES Synchronize variable subtitles after
            % a change in 'OBJ.attributes'.

            attrib = obj.attributes;
            ncol = width(obj.table);
            colattrib = cell(1,ncol);
            scopedisp = arrayfun(@num2str,attrib.scope,'UniformOutput',false);
            scopedisp(attrib.scope == 0) = {[]};
            for i = 1:ncol
                iattr = attrib.index == i;
                colattrib{i} = strcat(attrib.list(iattr), scopedisp(iattr));
            end
        end

        function process_header_units(obj)
            %PROCESS_HEADER_UNITS Process units encoded in the header
            %   PROCESS_HEADER_UNITS(OBJ) picks up any column specified as
            %       'ColName [ColUnit]', turns it into a DimVar with unit 
            %       [ColUnit] and renames the column as 'ColName'.

            fileHeaders = obj.table.Properties.VariableDescriptions;
            if ~isempty(fileHeaders) 
                for i = 1:width(obj.table)
                    parsedHeader = strip(strsplit(fileHeaders{i}, {'[',']'}));
                    if ~isscalar(parsedHeader)
                        header  = parsedHeader{1};
                        unitstr = parsedHeader{2};
                        if ~isnumeric(obj.table.(i))
                            error('Dataset column "%s" using a unit header must be numeric, but has class "%s".', ...
                                fileHeaders{i},class(obj.table.(i)))
                        end
                        obj.table.Properties.VariableNames{i} = header;
                        obj.table.(header) = obj.table.(header) * str2u(unitstr);
                    end
                end
                obj.table.Properties.VariableDescriptions = {};
            end
            
        end

    end

end