classdef Physiology < DB & CompactColumnDisplay
    %PHYSIOLOGY A handle class for storing physiological information.
    %   For the definition of Physiology objects, see functions Covariates,
    %   Physiology/Physiology, and physiological scaling functions.
    %   
    %   For customization of the Physiology class (i.e., to add new 
    %   physiological parameters), physiologytemplate must be expanded. 
    %
    %   To query a physiology object, use function Physiology/getvalue.
    %
    %   For the functions used during construction of the physiological
    %   database, see functions '*record' (advanced).
    %
    %   See also Physiology/Physiology (constructor), Covariates,
    %   physiologytemplate, Physiology/getvalue, Physiology/addrecord, 
    %   Physiology/clonerecord, Physiology/aliasrecord, 
    %   Physiology/updaterecord, Physiology/deleterecord, 
    %   Physiology/hasrecord
    
    properties
        name
        alias
    end
    
    properties (SetAccess = protected)
        units
        pertissue
    end
    
    properties(Constant = true, Access = protected)
        tmp = evalfhopt('PhysiologyTemplate');
    end
    
    methods
        function obj = Physiology(refid)
            %PHYSIOLOGY Constructor of class 'Physiology'.
            %   PHYSIOLOGY() creates an empty physiology object
            %   PHYSIOLOGY(REFID) creates a physiology object from a
            %       reference individual with identifier REFID. The list of valid 
            %       identifiers can be obtained via function referenceid().
            %   
            if nargin == 1
                obj = referenceid(refid);
            else
                pertissue = [obj.tmp{:,3}];

                dbtmp  = cell(numel(pertissue),1);
                dbtmp(pertissue) = {emptydbtable('Tissue')};
                dbtmp(~pertissue) = {emptydbtable()};

                obj.db = cell2struct(dbtmp, obj.tmp(:,1));

                obj.pertissue = cell2struct(obj.tmp(:,3),obj.tmp(:,1));
                obj.units = cell2struct(obj.tmp(:,2), obj.tmp(:,1));
                obj.name = '';            
            end
        end
        
        function set.name(obj, nm)
            assert(ischar(nm), ...
                'compphysiol:Physiology:setname:charInputExpected', ...
                'Input must be char.')
            obj.name = nm;
        end
        
        function addrecord(obj, nm, varargin)
            %ADDRECORD Add a record to the physiological database
            %   Every record must provide the correct number of categories
            %   required for parameter NM. In addition, a value (with 
            %   compatible unit), source and/or assumption must be
            %   provided.
            
            assert(isfield(obj(1).db, nm), ...
                'compphysiol:Physiology:addrecord:parameterNotFound', ...
                ['Parameter type ''' nm ''' not in physiology database.'])
            
            colnames = obj(1).db.(nm).Properties.VariableNames;
            ncol = length(colnames);
            narginchk(ncol,Inf)
            iVal = find(strcmp(colnames,'Value'));

            % parameters lacking any assumption / source will be flagged
            % with assumption "derived"
            if length(varargin) == ncol-2
                varargin = {varargin{1:iVal}, 'derived', ''};
                narginchk(ncol,ncol)
            else
                narginchk(ncol+2, ncol+2) %1(obj) + 1(nm) + length(varargin)
            end
            

            assert(~isempty(varargin{end}) || ~isempty(varargin{end-1}), ...
                'Must provide source and/or assumption')

            typecheck(varargin{iVal}, obj(1).units.(nm))
            if ~strcmp(obj(1).units.(nm), 'char')
                varargin{iVal} = tounit(varargin{iVal});
            end            
            % to be able to call the faster table() instead of cell2table()
            % for creation of one-row tables, we need to put character
            % arrays into cells
            ichar = find(cellfun(@(x) ischar(x) || isempty(x),varargin));
            for i=1:numel(ichar)
                varargin{ichar(i)} = varargin(ichar(i));
            end
                        
            switch numel(varargin{iVal})

                case 1               % same input for each element in Physiology array            

                    toadd = table(varargin{:}, 'VariableNames', colnames);

                    for i = 1:numel(obj)                                  
                        obj(i).db.(nm) = vertcat(obj(i).db.(nm), toadd);
                    end

                case numel(obj)      % one input per element in Physiology array
                    
                    for i = 1:numel(obj)                
                        args_i = varargin;
                        args_i{iVal} = varargin{iVal}(i);
                        obj(i).db.(nm) = vertcat(obj(i).db.(nm), ...
                            table(args_i{:}, 'VariableNames', colnames));
                    end
                    
                otherwise
                    error('Number of values not matching the size of the Physiology array')
           
            end
        end
               
        function rec = getrecord(obj, nm, varargin)
        %GETRECORD Get a record from the physiological database
        %   There are two ways to call GETRECORD, depending on whether the
        %   queried parameter is scalar (e.g.: BW, hct) or a per-tissue 
        %   parameter (e.g.: Q, OWtis).
        %   
        %   GETRECORD(OBJ,NM) accesses the Physiology object (array) OBJ to
        %   retrieve a scalar parameter NM. 
        %
        %   GETRECORD(OBJ,NM,TIS) queries OBJ for a per-tissue parameter NM
        %   and returns the output corresponding to tissue TIS. 
        %
        %   See also physiologytemplate, Physiology/getvalue
        
            assert(isfield(obj(1).db, nm), ...
                'compphysiol:Physiology:getrecord:parameterNotFound', ...
                ['Parameter type ''' nm ''' not in database.'])
                
            if isscalar(obj)
                tab = subset(obj.db.(nm), varargin{:});
                if height(tab) == 0
                    if isempty(varargin) % tissue-independent parameter
                        error('compphysiol:Physiology:getrecord:noEntriesFound1', ...
                            ['No record for parameter type "' nm '" in database "' obj.name '".'])
                    else                 % tissue-dependent parameter
                        error('compphysiol:Physiology:getrecord:noEntriesFound2', ...
                            ['No record "' varargin{1} '" of parameter type "' nm '" in database "' obj.name '".'])
                    end
                elseif height(tab) > 1
                    if isempty(varargin) % tissue-independent parameter
                        error('compphysiol:Physiology:getrecord:multipleEntries1', ...
                            ['Several matching records for parameter type "' nm '" in database "' obj.name '".'])
                    else                 % tissue-dependent parameter
                        error('compphysiol:Physiology:getrecord:multipleEntries2', ...
                            ['Several matching records "' varargin{1} '" of parameter type "' nm '" in database "' obj.name '".'])
                    end
                end
                rec = tab{:,'Value'};
            else
                rec = arrayfun(@(o) getrecord(o,nm,varargin{:}), obj);
            end                    
        end
        
        function tf = hasrecord(obj, nm, varargin)
        %HASRECORD True if matches a record in the physiological database

            assert(isfield(obj(1).db, nm), ...
                'compphysiol:Physiology:hasrecord:parameterNotFound', ...
                ['Parameter type ''' nm ''' not in database.'])

            if isscalar(obj)
%                tf = logical(height(subset(obj.db.(nm), varargin{:})));
                tf = ~isempty(subset(obj.db.(nm), varargin{:}));
            else
                tf = arrayfun(@(o) hasrecord(o, nm, varargin{:}), obj);
            end
        end
        
        
        function aliasrecord(obj, nm, source, alias)
        %ALIASRECORD Create a copy of a record with a different name
        %   ALIASRECORD(OBJ, NM, SOURCE, ALIAS), with Physiology object
        %   (array) OBJ, a parameter NM of the physiological database, and 
        %   char SOURCE and ALIAS, copies record SOURCE of parameter NM into
        %   record ALIAS of parameter NM. The function is shorthand for 
        %
        %   TMP = GETRECORD(OBJ, NM, SOURCE);
        %   ADDRECORD(OBJ, NM, ALIAS, TMP)
        %
        %   which in addition documents the dependency in the source column
        %   of record ALIAS.
        %
        
            assert(isa(obj,'Physiology'), 'Input #1 must be a Physiology object.')
            assert(ischar(nm) && ischar(source) && ischar(alias), ...
                'compphysiol:Physiology:aliasrecord:mustBeChar', ...
                'Inputs #2-#4 must be a char.')
            assert(obj(1).pertissue.(nm), ...
                'compphysiol:Physiology:aliasrecord:mustBePerTissueParameter', ...
                'Input #2 must be a per-tissue parameter.')
            
            if isscalar(obj)
                [~,irec] = ismember(source,obj.db.(nm).Tissue);
                if ~irec
                   error('compphysiol:Physiology:aliasrecord:noEntriesFound', ...
                       ['No record "' source '" of parameter type "' nm '" in database "' obj.name '".'])
                end
                val = obj.db.(nm).Value(irec);
                src = [obj.db.(nm).Source{irec} ' (identical to ' source ')'];
                asm = obj.db.(nm).Assumption{irec};
                addrecord(obj,nm,alias,val,src,asm)
            else
                arrayfun(@(o) aliasrecord(o,nm,source,alias), obj)
            end
        end
        
        function updaterecord(obj, nm, varargin)
        %UPDATERECORD Update an existing record
        %   UPDATERECORD(OBJ, NM, NEWVAL), with Physiology object
        %   (array) OBJ, a tissue-independent parameter NM of the species
        %   database, and a valid value NEWVAL replaces the existing record
        %   in the database, which would be obtained by GETRECORD(OBJ, NM),
        %   by NEWVAL.
        %   
        %   UPDATERECORD(OBJ, NM, TIS, NEWVAL), with Physiology object
        %   (array) OBJ, a tissue-dependent parameter NM of the species
        %   database, a char TIS (a tissue) and a valid value NEWVAL 
        %   replaces the existing record in the database, which would be 
        %   obtained by GETRECORD(OBJ, NM, TIS), by NEWVAL.        
        
            assert(isa(obj,'Physiology'), 'Input #1 must be a Physiology object.')
            assert(ischar(nm), ...
                'compphysiol:Physiology:updaterecord:valueMustBeChar', ...
                'Input #2 must be char.')
            
            if isscalar(obj)
                
                if obj(1).pertissue.(nm)  % expect varargin of length 2
                    narginchk(4,4)
                    
                    tis = cellstr(varargin{1});
                    dbtis = obj.db.(nm).Tissue;

                    if isempty(obj.db.(nm))
                        liVarargin = false(size(tis));
                        locTissue = zeros(size(tis));
                    else
                        [liVarargin,locTissue] = ismember(tis, dbtis);
                    end

                    if ~all(liVarargin)
                        missing = setdiff(tis, obj.db.(nm).Tissue);
                        error('compphysiol:Physiology:updaterecord:noEntriesFound', ...
                            ['No record(s) "' strjoin(missing,',') '" of parameter type "' nm '" in database "' obj.name '".'])
                    end                    
                    val = varargin{2};
                else                      % expect varargin of length 1
                    narginchk(3,3)
                    locTissue = 1;
                    val = varargin{1};
                end
                typecheck(val, obj.units.(nm))
                if strcmp(obj.units.(nm),'char')
                    val = cellstr(val);
                else
                    val = tounit(val);
                end
                obj.db.(nm).Value(locTissue) = val;
                
            else
                arrayfun(@(o) updaterecord(o, nm, varargin{:}), obj)
            end
        end
                
        function deleterecord(obj, nm, varargin)
            
            assert(isfield(obj(1).db, nm), ...
                'compphysiol:Physiology:deleterecord:parameterNotFound', ...
                ['Parameter type ''' nm ''' not in database.'])
            
            if isscalar(obj)
                obj.db.(nm) = setdiff(obj.db.(nm), subset(obj.db.(nm), varargin{:}));
            else
                arrayfun(@(o) deleterecord(o, nm, varargin{:}), obj)
            end
            
        end
        
        
        function checkintegrity(obj)
        % CHECKINTEGRITY checks whether the database is correctly set up.

            % Row duplicate (rdupl) check: are there redundant entries for 
            % any parameter?
            rdupl = false;
            parnames = fieldnames(obj(1).db)';
            commoncols = emptydbtable();
            commoncols = commoncols.Properties.VariableNames;
            for i=1:numel(obj)
                for nm = parnames
                    tab_i_nm = obj(i).db.(nm{1});
                    categ_nm = setdiff(tab_i_nm.Properties.VariableNames, ...
                                       commoncols);
                    if isempty(categ_nm)
                        if height(tab_i_nm) > 1
                            rdupl = true;
                            break
                        end
                    else
                        subtab_i_nm = unique(tab_i_nm(:,categ_nm));                    
                        if height(subtab_i_nm) < height(tab_i_nm) 
                            rdupl = true;
                            break
                        end
                    end
                end
                if rdupl
                    break
                end
            end
        
            assert(~rdupl, ...
                ['Physiological database integrity violated. There are duplicate ' ...
                 'entries.'])
             
            % Handle duplicate (hdupl) check: do all handles refer to
            % different underlying objects?
            hdupl = false;
            for i = 1:numel(obj)
                for j = i+1:numel(obj)
                    if obj(i) == obj(j)
                        hdupl = true;
                        break
                    end
                end
                if hdupl
                    break
                end
            end
            
            assert(~hdupl, ...
                ['Physiological database integrity violated. Some handles refer ' ...
                 'to the same underlying object.'])
            
        end

        function str = obj2str(obj, context)
            switch context
                case {'array','table'}
                   nm = fieldnames(obj.db);
                   exclude = structfun(@(x)x,obj.pertissue) | structfun(@isempty,obj.db);
                   nm = nm(~exclude);
                   cl = cellfun(@(x)num2str(getvalue(obj,x),'%.2f'),nm,'UniformOutput',false);
                   nmax = 6;
                   if numel(cl) > nmax
                       cl{nmax} = [cl{nmax} '...'];
                       cl(nmax+1:end) = [];
                   end
                   str = strjoin(cl,'\t');
                otherwise
                    error('compphysiol:Physiology:obj2str:unknownContext', ...
                        'Function not defined for context "%s"',context)
            end

       end

       function disp(obj)
            if isscalar(obj)
                link = helpPopupStr('Physiology');
                if all(structfun(@isempty,obj.db))
                    fprintf('\tEmpty %s object.\n\n',link)
                else
                    nm = obj.name;
                    if isempty(nm)
                        nm = 'unnamed';
                    end
                    fprintf('\t%s object (%s) with parameters:\n\n',link,nm)
                    dispdbcontent(obj)
                end 
            else
                disp@CompactColumnDisplay(obj)
            end
        end

    end

end
