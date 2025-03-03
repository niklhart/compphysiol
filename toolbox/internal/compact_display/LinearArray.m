classdef (Abstract) LinearArray < handle
    %LINEARARRAY Abstract linear array class
    %   Inheriting from this class overwrites all reshaping and 
    %   concatenation operators to always return a column vector.

    methods
        % concatenate
        function out = horzcat(varargin)
            out = vertcat(varargin{:});            
        end

        % reshape
        function obj = transpose(obj);   end
        function obj = ctranspose(obj);  end
        function obj = permute(obj,~);  end
        function obj = reshape(obj,varargin);  end

        % repeat elements
        function varargout = repmat(~,varargin) %#ok<STOUT>
            error('Function "repmat" not applicable to LinearArray objects.')
        end
        function out = repelem(obj,N)
            out = matlab.internal.builtinhelper.repelem(obj,N,1);
        end

    end
end
