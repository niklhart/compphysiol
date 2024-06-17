classdef (InferiorClasses = {?DimVar}) HDV < ContainerDisplay
    %HDV Class for heterogeneous dimensioned variable (short HDV) arrays
    %   The HDV class extends class DimVar to support arrays with
    %   heterogeneous units, for example [u.m u.kg].
    
    properties% (Access = protected)
        value
        exponents
        grouping
        customDisplay
    end
    
    methods
        function obj = HDV(val,expo,grp,cdis)
            %HDV Construct an instance of this class
            switch nargin
                case 1
                    switch class(val)
                        case 'HDV'
                            obj = val;
                        case 'DimVar'
                            obj.value         = getvalue(val);
                            obj.exponents     = getexponents(val);
                            obj.grouping      = ones(size(val));
                            obj.customDisplay = {getcustomdisplay(val)};
                        case 'double'
                            obj = HDV(val,zeros(1,9),ones(size(val)));
                        otherwise 
                            error('Cannot convert object of class "%s" to HDV.',class(val))
                    end
                case 3                    
                    obj.value         = val;
                    obj.exponents     = expo;
                    obj.grouping      = grp;
                    obj.customDisplay = repmat({''},size(expo,1),1);
                case 4
                    obj.value         = val;
                    obj.exponents     = expo;
                    obj.grouping      = grp;
                    obj.customDisplay = cdis;
            end
        end
    end
    
    %% Important internal functions for HDV class
    methods (Access = protected)
                
        function obj = uniquify_exponents(obj)
            [uexpo,iexpo,igrp] = unique(obj.exponents,'rows');
            
            if isscalar(iexpo) % all units are compatible
                if any(round(1e5*uexpo))  % --> DimVar
                    tmp = DimVar(uexpo, obj.value);
                    obj = scd(tmp, obj.customDisplay{iexpo});
                else                      % --> double
                    obj = obj.value;
                end
            else               % some units are still incompatible
                obj.exponents     = uexpo;
                obj.grouping(:)   = igrp(obj.grouping); % replace category labels
                obj.customDisplay = obj.customDisplay(iexpo);
            end                        
        end
        
        function obj = clearcustomdisplay(obj)
            [obj.customDisplay{:}] = deal('');
        end
    end
    
    %% Public methods for HDV class
    methods    
        
        %% Custom display

        function v = scd(v, str)
        % scd  Set custom display units for HDV class
        %   v = scd(v,str) uses str as the preferred custom display unit 
        %   for v. Input str can be char or cellstr, and may redefine some 
        %   or all display units of variable v. 
        %
        %   v = scd(v) with only one input returns v with all custom display 
        %   units cleared. Custom display units are also cleared by most 
        %   operations that change the units.
        %
        %   Examples:
        %
        %       v = [u.m u.kg];
        %       scd(v,'g')
        %   
        %   See also DimVar/scd, str2u.

            if nargin < 2
                v = clearcustomdisplay(v); 
                return
            end

            str = cellstr(str);
            for i = 1:numel(str)
                vdis = str2u(str{i});
                [lia, locb] = ismember(getexponents(vdis),v.exponents,'rows');
                if lia
                    v.customDisplay{locb} = str{i};
                end
            end
          
        end


        %% Concatenation
        function v = cat(dim,varargin)
            %CAT Concatenate HDV arrays
            
            args = varargin(~cellfun('isempty',varargin));
            args = cellfun(@HDV, args, 'UniformOutput', false);    
            
            % separate the three properties 
            avals  = cellfun(@(x) x.value,         args, 'UniformOutput', false);
            aexpos = cellfun(@(x) x.exponents,     args, 'UniformOutput', false);
            agrps  = cellfun(@(x) x.grouping,      args, 'UniformOutput', false);
            acdis  = cellfun(@(x) x.customDisplay, args, 'UniformOutput', false);
            
            % concatenate values and exponents
            Val  = cat(dim, avals{:});
            Expo = vertcat(aexpos{:});
            Cdis = vertcat(acdis{:});
            
            % create a global group numbering (shift later indices)
            ngrp = cellfun(@(x) length(unique(x)), agrps);
            cngrp = [0 cumsum(ngrp(1:end-1))];
            agrps = arrayfun(@(x,y) {x+y{1}}, cngrp, agrps);
            GRP = cat(dim, agrps{:});
            
            v = HDV(Val,Expo,GRP,Cdis);
            v = uniquify_exponents(v);
        end
        function vOut = horzcat(varargin)
            vOut = cat(2,varargin{:});
        end
        function vOut = vertcat(varargin)
            vOut = cat(1,varargin{:});
        end
        
        %% Subsetting / subassignment
        function B = subsref(A, S)
            % SUBSREF Subscripted reference for class HDV.
            switch S(1).type
                case '()'
                    B = A;
                    
                    B.value     = subsref(A.value, S(1));
                    Grp         = subsref(A.grouping, S(1));
                    [Grp(:),ID] = findgroups(Grp(:));
                    B.grouping  = Grp;    
                    
                    B.exponents     = A.exponents(ID,:);
                    B.customDisplay = A.customDisplay(ID);
                    
                    B = uniquify_exponents(B);
                    
                case '{}'
                    error('Brace indexing not supported for class "HDV".')
                case '.'
                    B = builtin('subsref', A, S);
            end
        end
        
        function n = numArgumentsFromSubscript(~,~,indexingContext)
            switch indexingContext
            	case matlab.mixin.util.IndexingContext.Statement
                	n = 1; % nargout for indexed reference used as statement
                case matlab.mixin.util.IndexingContext.Expression
                	n = 1; % nargout for indexed reference used as function argument
            	case matlab.mixin.util.IndexingContext.Assignment
                	n = 1; % nargin for indexed assignment
            end
        end

        function A = subsasgn(A,S,B)
            % SUBSASGN Subscripted assignment for class HDV. 
            %           Cases                   Status    
            %     - A is HDV, B is HDV             OK            
            %     - A is HDV, B is DV              OK       
            %     - A is HDV, B is double          OK
            %     - A is HDV, B is []              OK
            %     - A is DV,  B is HDV             -> DimVar.subsasgn  (TODO) 
            %     - A is double, B is HDV          -> builtin subsasgn (X)
            %     - A is [],  B is HDV             -> builtin subsasgn (X)
            %   (the last three calls seem inconsistent with MATLAB rules
            %   for class precedence, see 
            %   https://de.mathworks.com/matlabcentral/answers/409207-why-does-subsasgn-seem-to-break-precedence-rules-and-how-to-fix-it
            %   https://de.mathworks.com/help/matlab/matlab_oop/class-precedence.html
            %
            %   Further cases to be covered in DimVar.subsasgn:
            %     - A is DV, B is incompatible DV   OK
            %     - A is DV, B is double            OK
            %     - A is double, B is DV  (calls builtin subsasgn, X)
            
            assert(strcmp(S(1).type, '()'), ...
                'Brace/dot subassignment not supported for class "HDV".')
            switch class(A)
                case 'HDV'
                    B = HDV(B);                        
                    A.value = subsasgn(A.value, S, B.value);
                    
                    expo = vertcat(A.exponents, B.exponents);
                    cdis = vertcat(A.customDisplay, B.customDisplay);
                    
                    Grp = subsasgn(A.grouping, S, B.grouping+max(A.grouping,[],'all'));
                    [Grp(:),ID] = findgroups(Grp(:));
                    
                    A.exponents     = expo(ID,:);
                    A.customDisplay = cdis(ID);
                    A.grouping      = Grp;
                    
                    A = uniquify_exponents(A);
                case 'DimVar'  % B is HDV; 
                    % this is only called when using the syntax 
                    % subsasgn(A,S,B) instead of A(I)=B.
                    error('Case "DV(I) = HDV" not implemented yet.')
                case 'double'  % B is HDV
                    % this is only called when using the syntax 
                    % subsasgn(A,S,B) instead of A(I)=B.
                    error('Cases "double(I) = HDV" and "[](I) = HDV" not implemented yet.')                    
                otherwise
                    error("Can't assign an HDV into array of class '%s'.", class(A))
            end
        end
        
        %% Display
        function str = string(obj)
            %STRING Convert HDV to string array
            %   STR = STRING(V) converts HDV array V to string array STR.

            if isempty(obj)
                str = string([]);
                return
            end

            % parse 1-variables in all units, including customDisplay
            expos = obj.exponents;
            S = arrayfun(@displaystr,(1:size(expos,1))', obj.customDisplay);
            
            % multiply value property by displayingvalue, convert to string
            dispfactor = [S.v];
            valstr  = compose("%5.5g",obj.value .* reshape(dispfactor(obj.grouping),size(obj.grouping)));
            valstr  = regexprep(valstr,"-0$","0");
            valstr(ismissing(valstr)) = "NaN"; % un-do conversion to <missing>
            valstr = strtrim(valstr);

            % format unit string 
            unitstr = vertcat(S.str);
            unitstr = reshape(unitstr(obj.grouping), size(obj.grouping));

            % display result
            str = valstr + unitstr;
                
            function res = displaystr(i,cdis)
                expo = expos(i,:);
                if all(expo == 0)
                    res = struct('v',1,'str',"");
                    return
                end
                
                dv = DimVar(expo,1);
                dv = scd(dv,cdis{1});                
                [v,~,ustr] = displayparser(dv);
                res = struct('v',v,'str',string(char(160)) + ustr);
            end

        end

        function disp(obj)
            %DISP Display HDV objects

            % handle empty HDV objects (normally not used) 
            if isempty(obj)
                lnk = '<a href="matlab:helpPopup HDV">HDV</a>';
                fprintf('\tEmpty %s object.\n\n',lnk)
                return
            end

            str_trimmed = string(obj);
            ws = string(char(160)); % significant whitespace

            % split into value and unit
            valstr  = extractBefore(str_trimmed, ws);
            unitstr = extractAfter(str_trimmed,  ws);

            % unitless elements are turned into <missing>, revert this
            isunitless = ~contains(str_trimmed,ws);
            valstr(isunitless)  = str_trimmed(isunitless); 
            unitstr(isunitless) = "";

            str_padded = pad(valstr,'left') + ws + pad(unitstr,'right'); %#ok<NASGU> 
            t = evalc('disp(str_padded)');
            disp(replace(t,'"',''));     %print string without double quotes
            
        end

        function d = displayingvalue(obj)
        %DISPLAYINGVALUE Extract displaying value of HDV variable
        %   D = DISPLAYINGVALUE(V) for HDV V is similar to D = DOUBLE(V), 
        %   but returns D in display units rather than base units. 
        % 
        %   Caution: the HDV class uniformizes consistent units whenever
        %   possible, for example V = [u.m u.L u.km] is the same as 
        %   V = [u.m u.L 1000*u.m]. Therefore, DISPLAYINGVALUE(V) will 
        %   return [1 1 1000] and not [1 1 1].

            s = string(obj);
            spc = char(160);
            withUnits = contains(s, spc);
            s(withUnits) = extractBefore(s(withUnits), spc);
            d = double(s);
        end

        %% is_ functions
        function tf = isnumeric(~); tf = true;               end
        function tf = isnan(obj);   tf = isnan(double(obj)); end
        function tf = isscalar(obj)
            tf = isscalar(obj.value);
        end
        function tf = isempty(obj); tf = isempty(obj.value); end

        %% simple functions that return HDV
        function v = real(v);           v.value = real(v.value);                end
        function v = imag(v);           v.value = imag(v.value);                end

        function obj = unitsOf(obj)
            %TODO: implement the two output case (see DimVar.unitsOf)
            obj.value = ones(size(obj.value));
        end

        %% conversion
        function out = double(obj)
            out = obj.value;
        end

        %% comparison operators
        function tf = eq(v,w)
            compatible(v,w)
            tf = v.value == w.value;
        end
        
        %% compatibility
        function tf = iscompatible(obj1,obj2)
        % Check compatibility of objects

            obj1 = HDV(obj1);
            obj2 = HDV(obj2);

            [grp1,grp2] = bsx(obj1.grouping,obj2.grouping);

            ugrps  = unique([grp1(:) grp2(:)],'rows');
            
            expos1 = obj1.exponents(ugrps(:,1),:);
            expos2 = obj2.exponents(ugrps(:,2),:);
            
            tf = isequal(expos1, expos2);
        end
        
        function compatible(varargin)
            if ~iscompatible(varargin{:})
                ME = MException('HDV:incompatibleUnits',...
                    ['Incompatible units. Cannot perform operation on '...
                    'variables with different units.']);
                throwAsCaller(ME);
            end
        end
        
        %% other simple functions
        function obj = ctranspose(obj)
            obj.value    = obj.value';
            obj.grouping = obj.grouping';
        end
        
        function obj = uplus(obj);    end
        
        function obj = uminus(obj)
            obj.value = -obj.value;
        end
        
        function obj1 = plus(obj1,obj2)
            obj1 = HDV(obj1);
            obj2 = HDV(obj2);            
            compatible(obj1,obj2);            
            obj1.value    = obj1.value + obj2.value;     
            obj1.grouping = obj1.grouping .* ones(size(obj2.grouping)); % bsx
        end 
        
        function obj1 = minus(obj1,obj2)
            obj1 = HDV(obj1);
            obj2 = HDV(obj2);            
            compatible(obj1,obj2);
            obj1.value    = obj1.value - obj2.value;        
            obj1.grouping = obj1.grouping .* ones(size(obj2.grouping)); % bsx

        end
        
        function out = times(obj1,obj2)
                    
            switch class(obj1)
                case 'HDV'
                    if isa(obj2,'HDV')
                        
                        Val = obj1.value .* obj2.value;

                        % create all possible combinations of Expo / Grp
                        n1 = size(obj1.exponents,1);
                        n2 = size(obj2.exponents,1);
                        Expo = kron(ones(n2,1), obj1.exponents) ...
                                + kron(obj2.exponents, ones(n1,1));
                        [grp1,grp2] = bsx(obj1.grouping,obj2.grouping);
                        Grp = sub2ind([n1 n2], grp1, grp2);

                        % drop unused Expos and order Grp accordingly
                        [Grp(:), ID] = findgroups(Grp(:));
                        Expo = Expo(ID,:);
                        
                        % Create an HDV object and simplify
                        out = HDV(Val,Expo,Grp);       % no custom display (now invalid)
                        out = uniquify_exponents(out); % remove redundant exponents
                        
                    else
                        out = times(obj2,obj1);
                        return
                    end
                    
                case 'DimVar' % obj2 is HDV
                    Val  = getvalue(obj1) .* obj2.value;
                    Expo = getexponents(obj1) + obj2.exponents;
                    Grp  = ones(size(Val)) .* obj2.grouping;         % bsx
                    
                    out = HDV(Val,Expo,Grp);      % no custom display (now invalid)

                case 'double' % obj2 is HDV
                    out = obj2;     % maintain exponents and custom display
                    out.value    = obj1 .* obj2.value;
                    out.grouping = ones(size(obj1)) .* out.grouping; % bsx
                    
                    return
                    
                otherwise
                    error(['Input class ' class(obj1) ' incompatible with HDV.'])
            end
            
        end
        
        function out = mrdivide(obj1, obj2)
            assert(isscalar(obj2), 'For HDV A, "A/B" is only defined for scalar B.')
            out = rdivide(obj1,obj2);            
        end

        function out = rdivide(obj1, obj2)
            
            % invert obj2
            switch class(obj2)
                case 'HDV'
                    obj2.value     = 1 ./ obj2.value;
                    obj2.exponents = -obj2.exponents;
                case {'DimVar','double'}
                    obj2 = 1 ./ obj2;  % use rdivide method of the respective class
                otherwise 
                    error(['Cannot divide by object of class ' class(obj2) '.'])
            end
            
            % use times function
            out = times(obj1,obj2);
        end
        
        function obj = sqrt(obj)
            obj.value = sqrt(obj.value);
            obj.exponents = 0.5*obj.exponents;
            obj = clearcustomdisplay(obj);
        end
        
        function out = power(obj,y)
            assert(isa(y,'double') && isscalar(y), ...
                'For Z = X.^Y, Y must be a scalar double.');
            if y == 0
                out = ones(size(obj.value));
                out(isnan(ob.value)) = NaN;
                warning('Exponentiating with 0 removes all units.')
            else
                obj.value     = obj.value.^y;
                obj.exponents = y * obj.exponents;
                out = clearcustomdisplay(obj);
            end
        end
        
        function out = ldivide(obj1, obj2); out = rdivide(obj2,obj1); end
            
        function out = mtimes(obj1, obj2)
            if isscalar(obj1) || isscalar(obj2)
                out = obj1 .* obj2;
            else
                error('Matrix multiplication not defined for class "HDV".')
            end
        end

        %% Array reshaping
        function obj = reshape(obj,varargin)
            obj.value    = reshape(obj.value, varargin{:});
            obj.grouping = reshape(obj.grouping, varargin{:});
        end
        function obj = permute(obj, varargin)
            obj.value    = permute(obj.value, varargin{:});
            obj.grouping = permute(obj.grouping, varargin{:});
        end

        function n = length(v);     n = length(v.value);    end
        function n = ndims(v);      n = ndims(v.value);     end
        function n = nnz(v);        n = nnz(v.value);       end
        function n = numel(v);      n = numel(v.value);     end
        function out = sign(v);     out = sign(v.value);    end
        function varargout = size(x,varargin)
        	[varargout{1:nargout}] = size(x.value,varargin{:});
        end
        
        function obj = sum(obj, dim)
            
            if nargin == 1
                error('One-argument sum not implemented for class HDV.')
            elseif ~isscalar(dim) % recursive call to HDV/sum
                obj = sum(sum(obj,dim(1)),dim(2:end));
                return
            end
            
            % some computational overhead due to the use of diff() and
            % mean(), which are not strictly necessary, but allow for very
            % concise code.
            dgrp = diff(obj.grouping,1,dim);          
            assert(~any(dgrp,'all'),'Incompatible units along dimension %d.',dim)
            
            obj.value    = sum(obj.value, dim);
            obj.grouping = mean(obj.grouping, dim);  % reduces size(OBJ, DIM) to 1             
        end
        
    end
end

