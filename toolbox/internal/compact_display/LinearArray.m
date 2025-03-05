classdef (Abstract, HandleCompatible) LinearArray
    %LINEARARRAY Abstract linear array class
    %   Inheriting from this class overwrites all reshaping and 
    %   concatenation operators to always return a column vector.

    methods
        % uniformize concatenation
        function out = horzcat(varargin)
            out = vertcat(varargin{:});            
        end
        function out = cat(~, varargin)
            out = vertcat(varargin{:});
        end

        % cancel effects of reshaping operators
        function obj = transpose(obj);   end
        function obj = ctranspose(obj);  end
        function obj = permute(obj,~);  end
        function obj = reshape(obj,varargin);  end

        % repeat all/single elements
        function out = repmat(obj,varargin)
            dims = [varargin{:}];
            if length(dims) == 1 || any(dims(2:end) ~= 1)
                msg = 'When calling "repmat" on a LinearArray object, the dimensions must be N-by-1.';
                error('compphysiol:LinearArray:repmat',msg)
            end
            out = matlab.internal.builtinhelper.repmat(obj,dims);
        end
        function out = repelem(obj,N)
            out = matlab.internal.builtinhelper.repelem(obj,N,1);
        end

    end
end
