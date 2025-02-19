classdef Observable < CompactColumnDisplay
    %OBS A class for storing observables
    %
    %   See also Observable/Observable (syntax of constructor)

    properties
        type
        attr = struct
    end
    
    methods
        function obj = Observable(type,varargin)
        %OBSERVABLE Construct an Observable object
            %   OBJ = OBSERVABLE(TYPE,ATTR1,ATTR2,...) constructs an 
            %   Observable object OBS of type TYPE (character array) and
            %   with attributes ATTR1,ATTR2,... (character arrays or 
            %   cellstr). The required attributes for a particular TYPE are
            %   defined in the observable template.
            %
            %   Specifying any attribute as cellstr results in OBJ being
            %   an array of Observable objects rather than a scalar one,
            %   with the cellstr attribute being expanded automatically.
            %   At most one attribute can be specified as cellstr.
            %   
            %   Examples:
            %
            %   o1 = Observable('SimplePK','pla','total','Mass/Volume')
            %   o2 = Observable('PBPK',{'adi','mus'},'tis','total','Mass/Volume')
            %
            %   See also obstemplate, PBPKobservables
            
            switch nargin
                case 0
                    % pass (required for allocation of Observable arrays)
                case 1
                    assert(istable(type), 'For a single-input call, input must be a table.')
                    
                    tab = type;
                    assert(istablecol(tab,'Type'), 'Observable type missing.')
                    
                    [grp, id] = findgroups(tab.Type);
            
                    obscl = arrayfun(@(x) renderObservable(x, tab), ...
                                        1:numel(id), 'UniformOutput', false);
                    obj = vertcat(obscl{:});

                    % same ordering as in table
                    [~,I]  = sort(grp(:));   
                    [~,I2] = sort(I);
                    obj = obj(I2);


                otherwise

                    assert(ischar(type), 'Input #1 must be char for multiple-input calls.')

                    attr = evalfhopt('ObservableTemplate',type);

                    if numel(varargin) ~= size(attr,1)
                        error('Wrong number of attributes for observable type "%s" (%d expected, %d provided)', ...
                            type, size(attr,1), numel(varargin))
                    end
                    assert(ischar(type))
                    nattr = cellfun(@(x) ischar(x) + iscell(x)*length(x), varargin);
                    nobs  = max(nattr);
                    if ~all(nattr == 1 | nattr == nobs)
                        msg = ['Observable attributes must be scalar or of equal length, '...
                               'but attributes %s have different lengths.'];
                        error(msg, strjoin(attr(nattr ~= 1),','))
                    end
                    [obj(1:nobs,1).type] = deal(type);

                    args = cellfun(@(x) reptosize(x,nobs), varargin,'UniformOutput',false);
                    args = [args{:}]';
                    for i = 1:nobs
                        structargs = [attr(:,1) args(:,i)]';
                        obj(i).attr = struct(structargs{:});
                    end

            end
            
            % helper function
            function obs = renderObservable(x, tab)
                typ = id{x};
                attrnm = evalfhopt('ObservableTemplate',typ);
                tabx = addtablecols(tab(grp==x,:), attrnm(:,1), 'char');
                attrcl = varfun(@(z)z, tabx(:, attrnm(:,1)), ...
                    'OutputFormat', 'cell');
                obs = Observable(typ, attrcl{:});
            end
            
        end
                
        function out = horzcat(varargin)
            out = vertcat(varargin{:});            
        end
        
        function out = unique(obj)
            
            [itype, types] = findgroups({obj.type});
            include = false(size(obj));
            for i = 1:numel(types)
                istypei = itype == i;
                attri = struct2table([obj(istypei).attr]);
                [~,iA] = unique(attri);
                indtypei = find(istypei);
                include(indtypei(iA)) = true;
            end
            out = obj(include);
        end
        
        function tf = eq(obj1,obj2)      
            %EQ Equal operator for Observable class

            % Note: Working, but very slow...

            convToStr = @(obj) obj2str(obj, 'array'); 

            str1 = arrayfun(convToStr, obj1, 'UniformOutput', false);
            str2 = arrayfun(convToStr, obj2, 'UniformOutput', false);

            tf = strcmp(str1,str2);

        end

        function tf = eq2(obj1,obj2)      
            %EQ Equal operator for Observable class

            % Note: Working, but very slow...
            if isscalar(obj1)
                tf = ismember(obj2,obj1);
            elseif isscalar(obj2)
                tf = ismember(obj1,obj2);
            else  
                assert(numel(obj1)==numel(obj2))
                typ1  = {obj1.type};
                typ2  = {obj1.type};
                types = intersect(typ1,typ2);
                tf = strcmp(typ1,typ2);
                if any(tf)
                    for i = 1:numel(types)
                        % here, similar idea to ismember.
                    end
                end
            end

        end

%         function tf = eq(obj1,obj2)      
%             %EQ Equal operator for Observable class
% 
%             % TODO: this is quite fast, but only correct if either 
%                     obj1 or obj2 are scalar!!
%             tf = ismember(obj1,obj2) & ismember(obj2,obj1);
% 
%         end

        function tf = ne(obj1,obj2)
            %NE Not equal operator for Observable class

            tf = ~eq(obj1,obj2);
        end

        function tf = ismember(obj1, obj2)
            assert(isa(obj1,'Observable') && isa(obj2,'Observable'), ...
                'Both input arguments must have class "Observable".')
            
            tf = false(size(obj1));
            if isempty(tf)
                return
            end
            [itype, types] = findgroups({obj1.type});

            for i = 1:numel(types)
                istype1i = itype == i;
                istype2i = strcmp({obj2.type}, types{i});
                
                if any(istype2i)
                    % tables of attributes for type #i
                    attr1i   = struct2table([obj1(istype1i).attr],'AsArray',true); 
                    attr2i   = struct2table([obj2(istype2i).attr],'AsArray',true);

                    % use method 'table/ismember' for row-wise comparison
                    is1in2   = ismember(attr1i, attr2i);

                    % numeric outer indexing for nested indexing
                    indtypei = find(istype1i);
                    tf(indtypei(is1in2)) = true;
                end
            end
            
        end
        
        function str = obj2str(obj, context)  
            %OBJ2STR Represent scalar Observable object as string
            %   STR = OBJ2STR(OBJ,CONTEXT) turns the scalar Observable
            %   object OBJ into a character array STR. CONTEXT may be 
            %   
            %    - 'scalar' or 'array': attribute names and values are
            %      displayed
            %    - 'table': only attribute values are displayed.
            %   
            %   See also CompactColumnDisplay

            assert(isscalar(obj))
            
            attrib = fieldnames(obj.attr);
            values = struct2cell(obj.attr);

            isdefined = ~cellfun(@isempty,values);
            switch context
                case {'scalar','array'}
                    attrstr = strcat(attrib(isdefined),':',values(isdefined));
                    str = [obj.type '|' strjoin(attrstr,',')];
                case 'table'
                    str = [obj.type '|' strjoin(values(isdefined),'-')];
                otherwise
                    error('Function not defined for context "%s"',context)
            end
        end

         
        function tab = expand(obj)
            %EXPAND Expand an Observable object into a table
            %   TAB = EXPAND(OBJ) returns a table TAB containing one column
            %   per attribute of observables in OBJ, ordered in the same
            %   way as the Observable object OBJ.
            
            if isempty(obj)
                tab = table([],'VariableNames',{'Type'});
                return
            end
            
            [grp, id] = findgroups({obj.type});
            
            tabcl = arrayfun(@type2table, ...
                                1:numel(id), 'UniformOutput', false);
            tab = tblvertcat(tabcl{:});
            
            % same ordering as in Observable object
            [~,sr]  = sort(grp);
            [~,sr2] = sort(sr);
            tab = tab(sr2, :);

            function tab = type2table(i)
                tab = struct2table([obj(grp == i).attr],'AsArray',true);
                Type = repmat(id(i),height(tab),1);
                tab = addvars(tab,Type,'Before',1);
            end
        end    

    end
end