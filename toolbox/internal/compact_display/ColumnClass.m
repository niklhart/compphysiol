classdef (Abstract, HandleCompatible) ColumnClass
    %COLUMNCLASS Abstract column-like class
    %   Inheriting from this class overwrites all reshaping and 
    %   concatenation operators to always return a column vector.
    %   In addition, it defines a common interface for display in arrays or
    %   tables. To this end, a concrete subclass must implement an obj2str
    %   method that encodes a scalar object as a string. 
    %   
    %   Currently, the following classes make use of this interface:
    %   
    %   DrugData, Observable, Individual, Physiology, Ref.
    %   
    %   See also DrugData, Observable, Individual, Physiology, Ref.

    methods (Abstract)
        str = obj2str(obj, context)
    end

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

        function disp(obj, maxprint)
            %DISP Display a ColumnClass object
            
            arguments
                obj ColumnClass
                maxprint (1,1) double = 10
            end

            link = helpPopupStr(class(obj));
            if isempty(obj)
                fprintf('\tEmpty %s array.\n\n',link)
            elseif isscalar(obj)
                fprintf('\t%s object:\n\n',link)
                fprintf(['\t' obj2str(obj,'scalar')  '\n\n'])
            elseif iscolumn(obj)
                fprintf('\t%s array:\n\n',link)
                nobj = numel(obj);
                if nobj <= maxprint
                    for i = 1:nobj
                        fprintf([num2str(i) '\t' obj2str(obj(i),'array') '\n'])
                    end
                    fprintf('\n')
                else
                    for i = 1:maxprint-1
                        fprintf([num2str(i) '\t' obj2str(obj(i),'array')  '\n'])
                    end
                    fprintf(['...\n' num2str(nobj) '\t' obj2str(obj(nobj),'array')  '\n'])
                    fprintf('\n(type disp(obj, Inf) to see all entries)\n\n')
                end
            else
                builtin('disp',obj)
            end 

        end

        function out = char(obj)
            %CHAR Convert a ColumnClass vector to char.
            
            tmp = cell(size(obj));
            for i = 1:numel(obj)
                tmp{i} = obj2str(obj(i),'table');
            end
            out = char(tmp);
        end

        % hacking function 'tabular/disp' for ColumnClass objects 
        function out = num2str(obj, varargin)

            ST = dbstack(1,'-completenames');
            if ~isempty(ST) && contains(ST(1).file,['@tabular' filesep 'disp.m'])
                
                ncol = size(obj,1);
                tmp = cell(ncol,1);
                                
                if iscolumn(obj)  
                    for i = 1:numel(obj)
                        tmp{i} = obj2str(obj(i),'table');
                    end
                else
                    dim = size(obj);
                    dim(1) = 1;
                    dimstr = arrayfun(@num2str,dim,'UniformOutput',false);
                    [tmp{:}] = deal(['[' strjoin(dimstr,'x') ' ' class(obj) ']']);
                end
                out = char(tmp{:});
            else
                error('Input to num2str must be numeric.')
            end
        end
        function out = isnumeric(~)
            ST = dbstack(1,'-completenames');
            out = ~isempty(ST) && contains(ST(1).file,['@tabular' filesep 'disp.m']);            
        end    
    end
end