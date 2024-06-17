classdef ComplexDosing < Dosing
    %COMPLEXDOSING Class for storing mixed dosing schedules 
    %   Dosing schedules comprising, for example, both bolus and oral
    %   routes are stored in class COMPLEXDOSING.
    %   
    %   See also SimpleDosing, Dosing.

    properties
        simpleDosingList
    end

    methods
        function obj = ComplexDosing(varargin)
            %COMPLEXDOSING Construct a ComplexDosing object
            %   DOS = COMPLEXDOSING(DOS1,DOS2,...) with SimpleDosing
            %   objects DOS1,DOS2,... as inputs (possibly different
            %   subclasses of SimpleDosing) combines the schedules into a
            %   ComplexDosing object DOS. 
            
            if nargin == 1 && isa(varargin{1},'ComplexDosing')
                obj = varargin{1};
            else
                obj.simpleDosingList = varargin;
                obj = simplify(obj);
            end

        end

        function obj = set.simpleDosingList(obj, val)
            assert(iscell(val) && all(cellfun(@(x) isa(x,'SimpleDosing'), val)), ...
                'All input arguments must be of type "SimpleDosing".')

            obj.simpleDosingList = val;
        end

        function cpd = compounds(obj)
            %COMPOUNDS Compounds contained in ComplexDosing objects
            %   CPD = COMPOUNDS(D), with a ComplexDosing object D, returns
            %   the compounds specified in the schedule as a cellstr CPD.
            
            compoundList = cellfun(@compounds,obj.simpleDosingList,'UniformOutput',false);
            cpd = unique(Reduce(@union,compoundList{:}));
        end

        function cl = dosingTypes(obj)
            %DOSINGTYPES Dosing types contained in ComplexDosing objects
            %   CL = DOSINGTYPES(D), with a ComplexDosing object D, returns
            %   the dosing types specified in the schedule as a cellstr CL.

            cl = cellfun(@class,obj.simpleDosingList,'UniformOutput',false);
        end
       
        function out = filterDosing(obj, cpd, typ)
             %FILTERDOSING Extract dosing of specific compound(s) / type(s)
            %   OUT = FILTERDOSING(D, CPD, TYP), with ComplexDosing object 
            %   D, returns a part of the D corresponding to compound(s) CPD
            %   and class(es) TYP. If no match is found, OUT is an
            %   EmptyDosing object.
            %
            %   Arguments CPD and TYP can be [], and then the respective 
            %   filtering by class/type is skipped.

            % pre-processing
            if nargin < 3 || isempty(typ)
                typ = dosingTypes(obj);
            end
            if isempty(cpd)
                cpd = compounds(obj);
            end

            % regular 3-argument call
            isTypeMatch = ismember(dosingTypes(obj), typ);

            filteredDosingList = cellfun(...
                @(x) filterDosing(x, cpd, []), ...
                obj.simpleDosingList(isTypeMatch), ...
                'UniformOutput',false);
            isSimpleDosing = cellfun(@(x) isa(x,'SimpleDosing'), filteredDosingList);
            obj.simpleDosingList = filteredDosingList(isSimpleDosing);

            out = attemptClassSimplification(obj);
        end

        function out = combine(obj1, obj2)
            %COMBINE Combine two ComplexDosing objects
            %   DOS = COMBINE(DOS1,DOS2), with two ComplexDosing objects
            %   DOS1 and DOS2, combines the two schedules into a single
            %   ComplexDosing object DOS.

            out = ComplexDosing();
            out.simpleDosingList = vertcat(obj1.simpleDosingList, obj2.simpleDosingList);
            out = attemptClassSimplification(out);
        end

        function disp(obj)
            %DISP Display a ComplexDosing object

            if isscalar(obj)
                link = helpPopupStr('ComplexDosing');
    
                if isempty(obj.simpleDosingList)
                    fprintf('\tEmpty dosing object.\n\n')
                else
                    fprintf('\t%s object with\n\n',link)
                    for i = 1:numel(obj.simpleDosingList)
                        disp(obj.simpleDosingList{i})
                    end
                end
            else
                builtin('disp',obj)
            end       
        end

        function str = summary(obj)
            %SUMMARY One-line summary of ComplexDosing objects
            %   STR = SUMMARY(DOS) summarizes ComplexDosing object DOS into
            %   a single cellstr STR.

            cl = arrayfun(@summary, obj.simpleDosingList, 'UniformOutput', false);
            str = strjoin(cl,',');
        end

    end

    methods (Access = private)

        function obj = simplify(obj)
            %SIMPLIFY Simplify a ComplexDosing object
            %   OUT = SIMPLIFY(OBJ) combines values in the simpleDosingList
            %   of ComplexDosing object OBJ that have the same value. 
            
            oldSimpleDosingList = obj.simpleDosingList;
            cls = cellfun(@class, oldSimpleDosingList, 'UniformOutput', false);

            % if several entries have the same class, add them together
            ucls = unique(cls);

            newSimpleDosingList = cell(size(ucls));

            for i = 1:numel(ucls)
                icls = ucls{i};
                iTypeSimpleDosing = oldSimpleDosingList(strcmp(cls,icls));
                newSimpleDosingList{i} = Reduce(@plus, iTypeSimpleDosing{:});                
            end

            obj.simpleDosingList = newSimpleDosingList;
        end

        function out = attemptClassSimplification(obj)
            %ATTEMPTCLASSSIMPLIFICATION
            %   Attempt conversion of a ComplexDosing object OBJ to class
            %   SimpleDosing or EmptyDosing. If OBJ only has a single 
            %   dosing type, OUT will be converted to that type. If OBJ has
            %   an empty simpleDosingList attribute, it will be converted
            %   to class EmptyDosing.

            out = simplify(obj);

            switch numel(obj.simpleDosingList)
                case 0
                    out = EmptyDosing;
                case 1
                    out = out.simpleDosingList{1};
            end
        end
    end

end