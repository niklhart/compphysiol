classdef (Abstract) DB < matlab.mixin.Copyable & ColumnClass ...
        & matlab.mixin.indexing.RedefinesBrace

    %DB Superclass of Physiology and DrugData
    %   This class implements common methods of the two database formats.
    %   
    %   See also Physiology, DrugData

    properties
        name char {mustBeTextScalar}
    end
    properties (SetAccess = protected)
        db
    end

    methods (Access = protected)
        function out = braceReference(obj, indexOp)
            assert(isscalar(indexOp), 'DB:braceReference:nonscalarIndexOp', ...
                'Brace referencing of DB objects cannot be combined with other indexing operations.')
            str = cellstr(indexOp.Indices);
            valid = {obj.name};
            assert(numel(valid) == numel(obj), 'DB:braceReference:unnamedObj', ...
                'Brace referencing of DB objects requires all objects to be named.')
            str = cellfun(@(x) validatestring(x, valid, 'DB:braceReference', ...
                                                ['name of ' class(obj) ' object']), ...
                        str, 'UniformOutput', false);
            out = obj(ismember(valid,str));
        end

        function obj = braceAssign(~, ~, ~) %#ok<STOUT>
            error('compphysiol:DB:braceAssign', ...
                  'Brace assignment of DB objects is not possible.')
        end

        function n = braceListLength(~, ~, ~)
            n = 1;
        end
    end


    methods

        % function n = numArgumentsFromSubscript(A, S, indexingContext)
        %     switch S(1).type
        %         case '{}'
        %             n = 1;
        %         case {'()','.'}
        %             n = builtin('numArgumentsFromSubscript',A,S,indexingContext);
        %     end
        % end
        
        % function varargout = subsref(A,S)
        %     nargout = numArgumentsFromSubscript(A,S,matlab.mixin.util.IndexingContext.Statement);
        %     switch S(1).type
        %         case '{}'                    
        %             subs = S(1).subs;
        %             if iscellstr(subs)%#ok<ISCLSTR>
        %                 [lia, locb] = ismember(subs, {A.name});
        %                 if ~all(lia(:)) %unmatched compound
        %                     unmatched = subs(~lia);
        %                     error('compphysiol:DB:subsref:noEntryFound',['No entry/entries named "' strjoin(unmatched,',') '" in the database.'])
        %                 end
        %                 varargout{1} = A(locb);
        %                 if numel(S) > 1  
        %                     nargout = numArgumentsFromSubscript(varargout{1},S(2:end),matlab.mixin.util.IndexingContext.Statement);
        %                     [varargout{1:nargout}] = builtin('subsref', varargout{1}, S(2:end));
        %                 end
        %             else
        %                 [varargout{1:nargout}] = builtin('subsref', A, S);
        %             end
        %         case {'()','.'}
        %             [varargout{1:nargout}] = builtin('subsref', A, S);
        %     end
        % end

        % Accessing database values

        function val = getvalue(obj, nm, varargin, options)
        %GETVALUE Get a value from a database
        %   VAL = GETVALUE(OBJ,NM,CAT1,...,CATN) accesses the DB object
        %   OBJ to retrieve a parameter of type NM, which must be 
        %   uniquely defined by the N categories CAT1, ..., CATN.
        %
        %   VAL = GETVALUE(____, Default = D) sets VAL = D (rather than 
        %   producing an error) in case no match is found in the database.
        %
        %   Either OBJ or a single category CAT can be an array rather than
        %   scalar. If OBJ is an array, VAL has the same size as OBJ. If
        %   CAT is an array, VAL has the same size as CAT. Both OBJ and a
        %   category CAT being non-scalar results in an error. 
        %
        %   GETVALUE(OBJ) returns the content of a scalar DB object as a 
        %   struct.

            arguments 
                obj
                nm = ''
            end
            arguments (Repeating)
                varargin
            end
            arguments
                options.Default
            end

            % syntax getvalue(obj) --> early return
            if nargin == 1
                assert(isscalar(obj), 'compphysiol:DB:getvalue:nonscalarSingleInput' ,'Cannot use single-input call for a non-scalar object.')
                val = obj.db;
                return
            end

            isobjarr = ~isscalar(obj);
            isproparr  = cellfun(@iscellstr, varargin);
            
            % recursive call in case of non-scalar OBJ
            if isobjarr
                assert(~any(isproparr,'all'), 'compphysiol:DB:getvalue:objarrayAndCellstrArgs', ...
                    'If OBJ is an array, all categories must be scalar.')
                if ischar(getvalue(obj(1), nm, varargin{:}))
                    val = arrayfun(@(x) {getvalue(x, nm, varargin{:})}, obj);
                else
                    val = arrayfun(@(x) getvalue(x, nm, varargin{:}), obj);
                end

                return
            end
            
            % scalar OBJ 
            nm = validatestring(nm, fieldnames(obj.db));
                
            switch sum(isproparr)
                case 0
                    varargin = cellstr(varargin);
                    tab = subset(obj.db.(nm), varargin{:});
                    parnm = strjoin([cellstr(nm) varargin],'/');
                    val = dbmatch(obj, tab, parnm, options);
                    
                    if ~isempty(tab.Assumption)
                        cls = class(obj);
                        collect_assumptions({[cls ':' nm ':' strjoin(varargin,'-') ':' tab.Assumption{1}]});
                    end
                    if iscellstr(val) && isscalar(val) %#ok<ISCLSTR>
                        val = val{1};
                    end
                case 1                    
                    val = arrayfun(@(i) helper(obj, nm, varargin, isproparr, i), ...
                        reshape(1:numel(varargin{isproparr}),size(varargin{isproparr})));
                otherwise 
                    error('compphysiol:DB:getvalue:multipleCellstrArgs','At most one category can be cellstr.')
            end

            function val = helper(obj, nm, categ, icellstr, ival)
                categ{icellstr} = categ{icellstr}{ival};                
                val = getvalue(obj, nm, categ{:});
            end
            
        end
        
        function clonerecord(target, nm, source)
        %CLONERECORD Copy a record from one database object to another
        %   CLONERECORD(TARGET, NM, SOURCE), with DB object (array)
        %   TARGET, a parameter NM of the physiological database, and another
        %   (scalar) DB object SOURCE copies all records on
        %   parameter NM from SOURCE to TARGET. 
            assert(isequal(class(target),class(source)), ...
                'Inputs #1 and #3 must have the same class.');
            assert(ischar(nm) && isfield(target(1).db, nm), ['Parameter type ''' nm ''' not in database.'])
            assert(isscalar(source), 'Input #3 (source) must be scalar.')
            
            str = ['Value assumed identical as in ' source.name];
            srctab = source.db.(nm);
            h = height(srctab);
            assum = repmat({str}, [h 1]);
            ref   = repmat({''}, [h 1]);
            for i=1:numel(target)
                target(i).db.(nm) = srctab;
                target(i).db.(nm).Assumption = assum;
                target(i).db.(nm).Source = ref;
            end
            
        end

        function tf = hasuniquerecord(obj,nm,varargin)

            nm  = validatestring(nm, fieldnames(obj.db));
            if any(cellfun(@iscellstr, varargin))
                error('All categories must be scalar.')
            end

            tf = false(size(obj));
            for i = 1:numel(obj)
                tabi = subset(obj(i).db.(nm), varargin{:});
                tf(i)  = isrow(tabi);
            end
        end
        
        % Display of DB objects

        function str = summary(obj)
           %SUMMARY Summary of a DB object 
           n   = sum(~structfun(@isempty,obj.db));
           str = [num2str(n) ' parameters defined'];
        end

        function str = definedParams(obj)
            %DEFINEDPARAMS Obtain list of parameters defined in database
            hasValue = structfun(@(x) ~isempty(x), obj.db);
            fld = fieldnames(obj.db);
            str = fld(hasValue);
        end

    end

    methods (Access = protected)

        function dispdbcontent(obj)
            %DISPDBCONTENT Display the database content in a DB object
            
            if isscalar(obj)
                for fld = fieldnames(obj.db)'
                    tab = obj.db.(fld{1});
                    if ~isempty(tab)
                        subtab = tab(:,setdiff(tab.Properties.VariableNames,{'Source','Assumption'}));
                        if height(subtab) == 1
                            strat = setdiff(subtab.Properties.VariableNames,{'Value','Conditions'});
                            val = subtab.Value;
                            if iscellstr(val) %#ok<ISCLSTR> 
                                val = val{1};
                            end
                            if isempty(strat)
                                fprintf('%s: %s\n', fld{1}, num2str(val))
                            elseif isscalar(strat)
                                fprintf('%s: %s (%s)\n', fld{1}, num2str(val), subtab.(strat{1}){1})
                            else
                                error('Multiple stratifying columns not implemented yet.')
                            end
                        else
                            fprintf('%s: [%i values]\n', fld{1}, height(subtab))
                        end
                    end
                end                
            end
                        
        end
    
    end

    methods (Access = private)

        function out = dbmatch(obj,tab,parnm,options)

            arguments
                obj
                tab table
                parnm
                options
            end

            nmatch = height(tab);

            if nmatch ~= 1
                
                if isempty(obj.name)
                    dbnm = '';
                else
                    dbnm = [' "' obj.name '"'];
                end
                if nmatch == 0
                    if isfield(options,'Default')
                        out = options.Default;
                        return
                    end
                    mident = 'compphysiol:DB:noDbMatch';
                    mstart = 'No matches';
                else % nmatch > 1
                    mident = 'compphysiol:DB:multiDbMatch';
                    mstart = 'Several matches';

                end
                ME = MException(mident, ...
                    [mstart ' for parameter "%s" found in %s object%s.'],...
                    parnm, class(obj), dbnm);
                throwAsCaller(ME);
            end

            out = tab{:,'Value'};

        end
    end
end

