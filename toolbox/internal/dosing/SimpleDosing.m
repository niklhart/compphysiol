classdef SimpleDosing < Dosing
    %SIMPLEDOSING Abstract superclass of different single-type dosing classes
    %   See also ComplexDosing, Dosing.

    properties (Abstract)
        schedule
    end

    methods (Sealed)
        function cpd = compounds(obj)
            %COMPOUNDS Return compounds defined in a SimpleDosing object
            %   CPD = COMPOUNDS(D), with a SimpleDosing object D, returns
            %   the compounds specified in the schedule as a cellstr CPD.
            cpdArr = arrayfun(@(x) x.schedule.Compound, obj, 'UniformOutput', false);
            cpd = unique(Reduce(@union,cpdArr{:}));
        end

        function disp(obj)
            %DISP Display a SimpleDosing object
            fprintf('%s dosing:\n\n', class(obj))
            disp(obj.schedule)
        end

        function str = summary(obj)
            %SUMMARY One-line summary of SimpleDosing objects
            %   STR = SUMMARY(DOS) summarizes SimpleDosing object DOS into
            %   a single cellstr STR.

            str = sprintf('%d %s event(s)', height(obj.schedule), class(obj));
        end

        function cl = dosingTypes(obj)
            %DOSINGTYPES Dosing types contained in SimpleDosing objects
            %   CL = DOSINGTYPES(D), with a SimpleDosing object D, returns
            %   the dosing types specified in the schedule as a cellstr CL.

            cl = {class(obj)};
        end

        function out = filterDosing(obj, cpd, typ)
            %FILTERDOSING Extract dosing of specific compound(s) / type(s)
            %   OUT = FILTERDOSING(D, CPD, TYP), with a SimpleDosing object 
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
            if ismember(class(obj), typ)
                cpdMatchRow = ismember(obj.schedule.Compound,cpd);
                if any(cpdMatchRow)
                    out = obj;
                    out.schedule = obj.schedule(cpdMatchRow,:);
                else
                    out = EmptyDosing();
                end
            else
                out = EmptyDosing();
            end
        end        

    end

end