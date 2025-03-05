classdef (Abstract, HandleCompatible) TabularClass <  ...
        matlab.mixin.indexing.RedefinesParen & matlab.mixin.indexing.RedefinesDot
    %TABULARCLASS Mixin class for table-like classes
    %   For classes containing tabular information, inheriting from class 
    %   TABULARCLASS has the following effects:
    %   
    %   - access to method 'disptable' to compactly display the tabular
    %   content,
    %   - linear array indexing into the tabular content,
    %   - redefining concatenation operators to concatenate the tabular 
    %     content
    %
    %   Currently, this interface is used by class Record.
    %
    %   See also Record.
    
    properties (Access = protected)
        table
    end

    methods 
        
        function out = variableNames(obj)
            out = obj.table.Properties.VariableNames;
        end

        function out = cat(~, varargin)
        %CAT Concatenate TabularClass objects
        %   TabularClass objects are concatenated by appending the table
        %   properties. The objects inheriting from TabularClass must all
        %   have the same class.
        %
            classes = cellfun(@class,varargin,'UniformOutput',false);
            assert(isequal(classes{:}), ...
                'TabularClass objects can only be concatenated with objects of the same class.')
            tabs = cellfun(@(x) x.table, varargin,'UniformOutput',false);
            out = varargin{1};
            out.table = vertcat(tabs{:});
        end

        function varargout = size(obj)
        %SIZE Size of a TabularClass object
        %   The size of a TabularClass object is N-by-1, with N the height 
        %   of its table property.
            
            nargoutchk(0,2)
            sz = [height(obj.table) 1];
            if nargout < 2
                varargout{1} = sz;                    
            else
                varargout{1} = sz(1);                    
                varargout{2} = sz(2);                    
            end
        end

        function disp(obj, maxprint)
        %DISP Display a TabularClass object
        %   DISP(OBJ) displays a TabularClass object OBJ compactly.
        %   DISP(OBJ, MAXPRINT) displays the first MAXPRINT rows of the
        %   table property, defaulting to 10.

            arguments
                obj TabularClass
                maxprint (1,1) double = 10
            end

            link = helpPopupStr(class(obj));
            if isempty(obj)
                fprintf('\tEmpty %s object.\n\n',link)
            else
                fprintf('\t%s object:\n\n',link)
                disptable(obj,maxprint)
            end
        end

    end

    methods (Access=protected)
        function disptable(obj,maxprint)
            %DISPTABLE Display table in short format

            tab = obj.table;
            nrow = height(tab);

            if nrow <= maxprint

                str = table2char(tab);               
                rows = num2str((1:nrow)');

            else
                iprnt = [1:maxprint nrow]';

                str = table2char(tab(iprnt,:));
                str(end-1,:) = ' ';

                rows = num2str(iprnt);
                rows(maxprint,:) = '.';
            end
            ntotrow = size(str,1);
            nbdyrow = size(rows,1);
            nhdrrow = ntotrow - nbdyrow;
            nrnmcol = size(rows,2);
            hrws = vertcat(repmat(' ',[nhdrrow nrnmcol]), rows);
            spc  = repmat(' ',ntotrow,3);

            disp([hrws spc str])
            if nrow > maxprint
                fprintf('\n(type disp(obj, Inf) to see all entries)\n')
            end
            fprintf('\n')

        end

        % indexing operations into table property
    
        function varargout = parenReference(obj, indexOp)

            idx = indexOp(1).Indices;
            if ~all(strcmp(idx(2:end),{':'}))
                msg = [ 'Only linear indices and matrix indices of the' ...
                        ' form (idx,:) are supported by TabularClass.'];
                error('compphysiol:TabularClass:parenReference:invalidUse', msg)
            end
            obj.table = obj.table(idx{1},:);    % indexing into rows
            if isscalar(indexOp)
                varargout{1} = obj;
                return;                
            end
            if istablecol(obj.table, indexOp(2).Name)                
                [varargout{1:nargout}] = obj.table.(indexOp(2:end));
            else % assume it is a method
                [varargout{1:nargout}] = obj.(indexOp(2:end));
            end

        end

        function obj = parenAssign(obj,indexOp,val)
            % Ensure object instance is the first argument of call.
            if isempty(obj)
                obj = val;
            end
            assert(isscalar(indexOp) && isscalar(indexOp.Indices), ...
                'Indexing operation needs to be scalar.')
            assert(strcmp(class(obj),class(val)), ...
                'Subassignment into TabularClass objects is only possible for objects of the same class');
            obj.table(indexOp.Indices{1},:) = val.table;
        end

        function n = parenListLength(obj,indexOp,ctx)
            if numel(indexOp) <= 2
                n = 1;
                return;
            end
            containedObj = obj.(indexOp(1:2));
            n = listLength(containedObj,indexOp(3:end),ctx);
        end

        function obj = parenDelete(obj,indexOp)
            assert(isscalar(indexOp) && isscalar(indexOp.Indices), ...
                'Indexing operation needs to be scalar.')
            obj.table(indexOp.Indices{1},:) = [];
        end

        function varargout = dotReference(obj,indexOp)
            %DOTASSIGN Subsref into table column or dot method call

            nm = indexOp(1).Name;
            if istablecol(obj.table, nm)                
                [varargout{1:nargout}] = obj.table.(indexOp);
            elseif ismethod(obj, nm)
                [varargout{1:nargout}] = builtin('dotReference',obj,indexOp);
            else
                error('compphysiol:TabularClass:dotReference:unknownName', ...
                    '"%s" is not a table column or method of class %s.', nm, class(obj))
            end

        end

        function obj = dotAssign(obj,indexOp,varargin)
            %DOTASSIGN Subassignment into table column
            [obj.table.(indexOp)] = varargin{:};
        end

        function n = dotListLength(obj,indexOp,indexContext)
            n = listLength(obj.table,indexOp,indexContext);
        end

    end

end