classdef (Abstract, HandleCompatible) CompactColumnDisplay
    %COMPACTCOLUMNDISPLAY Display methods for list-like classes
    %   
    %   The abstract COMPACTCOLUMNDISPLAY class is used as a common 
    %   interface to display column vectors of objects for several classes
    %   which can be compactly represented a string. Both display at the 
    %   console (compact form) and display within tables (full form) are 
    %   handled by this class. 
    %
    %   Each concrete subclass of COMPACTCOLUMNDISPLAY must define the
    %   obj2str() method, which encodes a scalar object as a string.
    %   
    %   Currently, classes Ref, Observable and Physiology make use of this 
    %   interface.
    %   
    %   See also Ref, Observable, Physiology.

    methods (Abstract)
        str = obj2str(obj, context)
    end

    methods

        function disp(obj, maxprint)
            %DISP Display a CompactColumnDisplay object
            
            if nargin == 1
                maxprint = 10;
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
            %CHAR Convert a CompactColumnDisplay column vector to char.
            
            assert(iscolumn(obj), 'Only column vectors can be converted to char.')
            tmp = cell(size(obj));
            for i = 1:numel(obj)
                tmp{i} = obj2str(obj(i),'table');
            end
            out = char(tmp);
        end


        % hacking function 'tabular/disp' for CompactColumnDisplay objects 
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