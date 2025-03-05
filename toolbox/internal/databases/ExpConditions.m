classdef ExpConditions < ColumnClass

    properties
        conditions
    end

    methods
        function obj = ExpConditions(varargin)
        %EXPCONDITIONS Specify experimental conditions
        %   TODO: ADD ERROR CHECKING
        
            if isscalar(varargin)

                if isa(varargin{1},'ExpConditions')
                    obj = varargin{1};
                elseif isempty(varargin{1})
                    obj.conditions = struct();
                else
                    error('Invalid input to ExpConditions.')
                end
            else
                obj.conditions = struct(varargin{:});
            end
        end

        function obj = plus(obj, obj2)
        %PLUS Combine two disjoint sets of experimental conditions.
        %
        % C = PLUS(A, B), or equivalently C = A+B, with disjoint scalar 
        % ExpConditions A,B returns the concatenated ExpConditions object C
        %
        % Examples:
        %
        %   A = ExpConditions('species','human');
        %   B = ExpConditions('hct',0.42);
        %   C = A+B
        %
            assert(isa(obj,'ExpConditions') && isa(obj2,'ExpConditions'))

            common = intersect(fieldnames(obj.conditions), fieldnames(obj2.conditions));
            assert(isempty(common), 'Cannot add overlapping ExpConditions.')

            obj.conditions = mergestructs(obj.conditions, obj2.conditions);

        end

%           Method 'FILTER' is working, but is not needed currently.
%
%         function obj = filter(obj, cond, value)
%         %FILTER Filter an ExpConditions array by value of a condition
%         %   OUT = FILTER(OBJ, COND, VALUE) filters ExpConditions array OBJ,
%         %   keeping only those elements for which condition COND is defined
%         %   and has the value VALUE.
% 
%             assert(ischar(cond)  && ~isempty(cond),  'Input #2 must be a non-empty char.')
%             assert(ischar(value) && ~isempty(value), 'Input #3 must be a non-empty char.')
%             
%             str = getcondition(obj, cond);
%             obj = obj(strcmp(str,value));
%         end


        function out = getcondition(obj, cond)
        %GETCONDITION Access a specific condition of an ExpConditions object
        %   VAL = GETCONDITION(OBJ, COND) returns value VAL of a condition 
        %   COND in the ExpConditions object OBJ. Unspecified conditions 
        %   are represented by []. 
        %   
        %   CLL = GETCONDITION(ARR, COND), with an ExpConditions array ARR,
        %   returns the output as a cell array CLL of the same size as OBJ.

            if isscalar(obj)
                if isfield(obj.conditions,cond)
                    out = obj.conditions.(cond);
                else
                    out = [];
                end
            else
                out = arrayfun(@(x) getcondition(x, cond), obj, 'UniformOutput', false);
            end
        end

        function str = obj2str(obj, context)
        %OBJ2STR Represent scalar ExpConditions object as string
        %   STR = OBJ2STR(OBJ,CONTEXT) turns the scalar ExpConditions 
        %   object OBJ into a character array STR depending on CONTEXT as 
        %   follows:
        %   
        %       'scalar' and 'array' show all experimental conditions
        %       'table' only uses the first two experimental conditions
        %   
        %   See also ColumnClass

            cond = obj.conditions;
            appendStr = '';

            switch context
                case {'scalar','array'}
                    % pass
                case {'table'}
                    % pre-process
                    fld = fieldnames(cond);
                    if numel(fld) > 2
                        for i = 3:numel(fld)
                            cond = rmfield(cond,fld{i});
                            appendStr = '|...';
                        end
                    end
                otherwise
                    error('Function not defined for context "%s"',context)
            end

            fld = fieldnames(cond);
            val = cellfun(@num2str,struct2cell(cond),'UniformOutput',false);
            if ~isempty(cond)
                fld = strcat(fld,{':'});
            end
            str = strcat(fld,val);
            str = [strjoin(str,'|') appendStr];

            % special display for unspecified ExpConditions
            if isempty(str)
                str = '<undefined>';
            end
        end
    end
end