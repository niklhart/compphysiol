classdef (InferiorClasses = {?matlab.graphics.axis.Axes}) DimVar < ContainerDisplay
% See also u.

% Copyright (c) 2012-2017, Sky Sartorius. Modified 2019-now, Niklas Hartung
properties (Access = protected)
    exponents
    value
end
properties (Access = protected)
    customDisplay
end

%% Methods the HDV class needs for interconversion between the two classes
methods (Access = {?HDV})
    function expo = getexponents(obj)
        expo = obj.exponents;
    end
    function val = getvalue(obj)
        val = obj.value;
    end
    function cdisp = getcustomdisplay(obj)
        cdisp = obj.customDisplay;
    end
end
   
%% Main DimVar methods
methods
    function v = scd(v,val,flag)
        % SCD  Set custom display units on a per-variable basis. 
        %   v = SCD(v,str) uses str as the preferred custom display unit for v.
        %   str must be a valid field of u or be evaluable by str2u and be
        %   compatible with v.
        %
        %   v = SCD(v) with only one input returns v with custom display units
        %   cleared. Custom display units are also cleared by most operations
        %   that change the units.
        %
        %   v = SCD(v,str,'no-check') omits the unit check and is only
        %   intended for internal use.
        %   
        %   See also str2u, displayUnits.
        
        if nargin == 1 || isempty(val)
            v.customDisplay = '';
        else
            if nargin == 2 || ~strcmp(flag,'no-check')
                typecheck(v, val)
            end
            v.customDisplay = val;
        end
    end
        
    %% Core methods (not overloads).
    % Constructor:
    function v = DimVar(expos,val)
        % See also u.
        v.exponents = expos;
        v.value = val;
    end
    
    function v = clearcanceledunits(v)
        % If all DimVar unit exponents are zero, return normal (double)
        % variable. Exponent tolerance is to fifth decimal.
        
        if ~any(round(1e5*v.exponents)) % Seems to be faster than round(x,5).
            v = v.value;
        else
            v.customDisplay = '';
            % The customDisplay property is invalid after e.g. a multiply or
            % divide operation, so clean it up from the new variable to prevent
            % any undesirable side effects later.
        end
    end
    
    function compatible(varargin)
        % compatible(v1, v2, ...) throws an error unless all inputs are DimVar
        % with the same units.
        %
        %   If throwing an error is not desired, use iscompatible.
        %
        %   See also u, iscompatible.
        
        if ~all(cellfun(@(x) isa(x,'DimVar'), varargin))
            ME = MException('DimVar:incompatibleUnits',...
                'Incompatible units. All inputs must be DimVar.');
            throwAsCaller(ME);            
        end
        
        vararginExpos = cellfun(@(x) x.exponents, varargin,'UniformOutput',false);
        if ~isequal(vararginExpos{:})
            ME = MException('DimVar:incompatibleUnits',...
                ['Incompatible units. Cannot perform operation on '...
                'variables with different units.']);
            throwAsCaller(ME);
        end
        
    end
    
    function tf = iscompatible(varargin) 
    % Returns true if all inputs are DimVars with the same units.
    % 
    %   See also u, DimVar/compatible.

        if nargin <= 1   %early return: nothing to check.
            tf = true;
            return
        end

        isDimVar = cellfun(@(x) isa(x,'DimVar'), varargin);

        if all(isDimVar) 
            vararginExpos = cellfun(@(x) x.exponents, varargin, 'UniformOutput', false);
            tf = isequal(vararginExpos{:});
        else
            tf = false;
        end

    end
    
    
    %% Concatenation.
    function v = cat(dim,varargin)
        
        args = varargin(~cellfun('isempty',varargin));
        
        isDimVar = cellfun(@(x) isa(x,'DimVar'), args);
        isDouble = cellfun(@(x) isa(x,'double'), args);
 
        if ~all(isDimVar | isDouble) %produce an informative error message
            classes = cellfun(@class, args,'UniformOutput',false);
            wrong = strjoin(setdiff(classes, {'DimVar','double'}), ',');
            ME = MException('DimVar:incompatibleUnits',...
                ['Incompatible units. All inputs must be DimVar or '...
                 'double, but found class(es) %s.'], wrong);
            throwAsCaller(ME);
        end
                
        argExpos = repmat({zeros(1,9)}, size(args));
        argExpos(isDimVar) = cellfun(@(x) x.exponents, args(isDimVar), 'UniformOutput', false);

        if isscalar(args) || isequal(argExpos{:}) % => make a DimVar (all args are DimVar)
            v = args{1};
            argVals = cellfun(@(x) x.value, args, 'UniformOutput', false);
            v.value = cat(dim, argVals{:});            
        else                    % => make an HDV array
            hdvs = cellfun(@HDV, args, 'UniformOutput', false); 
            v    = cat(dim, hdvs{:});            
        end        
        
    end
    
    function vOut = horzcat(varargin)
        vOut = cat(2,varargin{:});
    end
    function vOut = vertcat(varargin)
        vOut = cat(1,varargin{:});
    end
    
    %% Validation functions (mustBe__).
    function mustBeGreaterThan(v1,v2)
        compatible(v1,v2);
        mustBeGreaterThan(v1.value,v2.value);
    end
    function mustBeGreaterThanOrEqual(v1,v2)
        compatible(v1,v2);
        mustBeGreaterThanOrEqual(v1.value,v2.value);
    end
    function mustBeLessThan(v1,v2)
        compatible(v1,v2);
        mustBeLessThan(v1.value,v2.value);
    end
    function mustBeLessThanOrEqual(v1,v2)
        compatible(v1,v2);
        mustBeLessThanOrEqual(v1.value,v2.value);
    end
    function mustBeNegative(v);     mustBeNegative(v.value);    end
    function mustBeNonnegative(v);  mustBeNonnegative(v.value); end
    function mustBeNonpositive(v);  mustBeNonpositive(v.value); end
    function mustBeNonzero(v);      mustBeNonzero(v.value);     end
    function mustBePositive(v);     mustBePositive(v.value);    end
    
    %% is__ functions.
    function result = isempty(v);   result = isempty(v.value);      end
    function result = isfinite(v);  result = isfinite(v.value);     end
    function result = isinf(v);     result = isinf(v.value);        end
    function result = isnan(v);     result = isnan(v.value);        end
    function result = isnumeric(v); result = isnumeric(v.value);    end
    function result = isreal(v);    result = isreal(v.value);       end
    
    %% Logical operators (>, <, ==, ~, etc.).
    function result = eq(v1,v2)
        compatible(v1,v2);
        result = v1.value == v2.value;
    end
    function result = ge(v1,v2)
        compatible(v1,v2);
        result = v1.value >= v2.value;
    end
    function result = gt(v1,v2)
        compatible(v1,v2);
        result = v1.value > v2.value;
    end
    function result = le(v1,v2)
        compatible(v1,v2);
        result = v1.value <= v2.value;
    end
    function result = lt(v1,v2)
        compatible(v1,v2);
        result = v1.value < v2.value;
    end
    function result = ne(v1,v2)
        compatible(v1,v2);
        result = v1.value ~= v2.value;
    end
    function result = not(v)
        result = ~v.value;
    end
    
    %% Class conversions.
    function result = double(v)
        % DimVar.double(V)  Returns value property (not diplayingvalue) of V.
        %
        % See also u2num, displayingvalue, displayparser.
        result = v.value;
    end
    function result = logical(v)
        result = logical(v.value);
    end
    function s = string(v)
        %STRING Convert DimVar to string array
        %   STR = STRING(V) converts DimVar array V to string array STR.

        s = string(cellfun(@num2str,num2cell(v),'UniformOutput',false));
    end

    function c = categorical(v)        
        valSet = unique(v.value(:));
        catNames = arrayfun(@num2str,valSet*unitsOf(v),'UniformOutput',false);
        c = categorical(v.value,valSet,catNames);
    end
    
    %% Interpolation

    function Vq = interp1(X,V,Xq,varargin)
        compatible(X,Xq)
        Vq = interp1(double(X), double(V), double(Xq), varargin{:});
        if isa(V,'DimVar')
            Vq = DimVar(V.exponents, Vq);
        end
    end

    %% Simple functions that return DimVar.
    function v = abs(v);            v.value = abs(v.value);                 end
    function v = circshift(v,varargin)
        v.value = circshift(v.value,varargin{:});
    end
    function v = conj(v);           v.value = conj(v.value);                end
    function v = ctranspose(v);     v.value = v.value';                     end
    function v = cumsum(v,varargin);v.value = cumsum(v.value,varargin{:});  end
    function v = diag(v,varargin);  v.value = diag(v.value,varargin{:});    end
    function v = diff(v,varargin)
        %DIFF Difference and approximate derivative for DimVar class
        v.value = diff(v.value,varargin{:});    
    end
    function v = full(v);           v.value = full(v.value);                end
    function v = imag(v);           v.value = imag(v.value);                end
    function v = mean(v,varargin);  v.value = mean(v.value,varargin{:});    end
    function v = median(v,varargin);v.value = median(v.value,varargin{:});  end
    function v = norm(v,varargin);  v.value = norm(v.value,varargin{:});    end
    function v = permute(v,varargin);v.value = permute(v.value,varargin{:});end
    function v = real(v);           v.value = real(v.value);                end
    function v = reshape(v,varargin);v.value = reshape(v.value,varargin{:});end
    function [v,I] = sort(v,varargin)
        [v.value, I] = sort(v.value,varargin{:});
    end
    function v = std(v,varargin);   v.value = std(v.value,varargin{:});     end
    function v = subsref(v,varargin); v.value = subsref(v.value,varargin{:}); end   
    function v = sum(v,varargin)   
        v.value = sum(v.value,varargin{:});     
    end
    function v = trace(v);          v.value = trace(v.value);               end
    function v = transpose(v);      v.value = v.value.';                    end
    function v = uminus(v);         v.value = -v.value;                     end
    function v = uplus(v);                                                  end
    
    %% Functions that require compatibility check.
    function out = atan2(v1,v2)
        compatible(v1,v2);
        out = atan2(v1.value, v2.value);
    end
    function v1 = hypot(v1,v2)
        compatible(v1,v2);
        v1.value = hypot(v1.value,v2.value);
    end
    function v1 = minus(v1,v2)
        compatible(v1,v2);
        v1.value = v1.value - v2.value;
    end
    function v1 = plus(v1,v2)
        compatible(v1,v2);
        v1.value = v1.value + v2.value;
    end
    function bins = discretize(v, edges, varargin)
        compatible(v, edges)
        bins = discretize(double(v),double(edges),varargin{:});
    end


    
    %% Other simple functions.
    function n = length(v);     n = length(v.value);    end
    function n = ndims(v);      n = ndims(v.value);     end
    function n = nnz(v);        n = nnz(v.value);       end
    function n = numel(v);      n = numel(v.value);     end
    function out = sign(v);     out = sign(v.value);    end
    function varargout = size(x,varargin)
        [varargout{1:nargout}] = size(x.value,varargin{:});
    end
    function out = issorted(v,varargin)
        out = issorted(v.value,varargin{:});
    end
    
    %% Plot-like functions.
    function varargout = contour(varargin)
        [varargout{1:nargout}] = plotfunctionwrapper('contour',varargin{:});
    end
    function varargout = contour3(varargin)
        [varargout{1:nargout}] = plotfunctionwrapper('contour3',varargin{:});
    end
    function varargout = contourf(varargin)
        [varargout{1:nargout}] = plotfunctionwrapper('contourf',varargin{:});
    end
    function varargout = contourc(varargin)
        [varargout{1:nargout}] = plotfunctionwrapper('contourc',varargin{:});
    end
    function varargout = fill(varargin)
        [varargout{1:nargout}] = plotfunctionwrapper2('fill',varargin{:});
    end
    function varargout = fill3(varargin)
        [varargout{1:nargout}] = plotfunctionwrapper('fill3',varargin{:});
    end
    function varargout = hist(varargin)
        [varargout{1:nargout}] = plotfunctionwrapper('hist',varargin{:});
    end
    function varargout = histcounts(varargin)
        [varargout{1:nargout}] = plotfunctionwrapper('histcounts',varargin{:});
    end
     function varargout = histcounts2(varargin)
        [varargout{1:nargout}] = plotfunctionwrapper('histcounts2',varargin{:});
    end
    function varargout = histogram(varargin)
        [varargout{1:nargout}] = plotfunctionwrapper('histogram',varargin{:});
    end
    function varargout = histogram2(varargin)
        [varargout{1:nargout}] = plotfunctionwrapper('histogram2',varargin{:});
    end
    function varargout = line(varargin)
        [varargout{1:nargout}] = plotfunctionwrapper('line',varargin{:});
    end
    function varargout = loglog(varargin)
        [varargout{1:nargout}] = plotfunctionwrapper2('loglog',varargin{:});
    end
    function varargout = patch(varargin)
        [varargout{1:nargout}] = plotfunctionwrapper('patch',varargin{:});
    end
    function varargout = plot(varargin)
        [varargout{1:nargout}] = plotfunctionwrapper2('plot',varargin{:});
    end
    function varargout = plot3(varargin)
        [varargout{1:nargout}] = plotfunctionwrapper('plot3',varargin{:});
    end
    function varargout = surf(varargin)
        [varargout{1:nargout}] = plotfunctionwrapper('surf',varargin{:});
    end
    function varargout = semilogx(varargin)
        [varargout{1:nargout}] = plotfunctionwrapper2('semilogx',varargin{:});
    end
    function varargout = semilogy(varargin)
        [varargout{1:nargout}] = plotfunctionwrapper2('semilogy',varargin{:});
    end
    function varargout = surface(varargin)
        [varargout{1:nargout}] = plotfunctionwrapper('surface',varargin{:});
    end
    function varargout = text(varargin)
        [varargout{1:nargout}] = plotfunctionwrapper('text',varargin{:});
    end

    %% Other functions
    function varargout = unique(v,varargin)
        %UNIQUE Set unique for DimVar class. 
        [varargout{1:nargout}] = unique(v.value,varargin{:});
        varargout{1} = DimVar(v.exponents,varargout{1});
        varargout{1} = scd(varargout{1},v.customDisplay);
    end
    function y = prctile(x, varargin)
        %PRCTILE Percentiles of a DimVar sample.
        cd = getcustomdisplay(x);
        y = prctile(double(x), varargin{:})*unitsOf(x);
        y = scd(y, cd);
    end

end
end