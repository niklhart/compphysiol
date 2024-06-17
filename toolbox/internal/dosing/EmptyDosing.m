classdef EmptyDosing < Dosing
    %EMPTYDOSING Class for empty dosing schedules (serving as placeholders)
    %   See also Bolus, Oral, Infusion, ComplexDosing.
    
    methods
        function obj = EmptyDosing()
            %EMPTYDOSING Constructor for EmptyDosing class
        end

        function cpd = compounds(~)
            %COMPOUNDS Compounds of an EmptyDosing object (always {})
            cpd = {};
        end

        function obj = combine(obj, ~)
            %COMBINE Combine two EmptyDosing objects
        end

        function disp(~)
            %DISP Display an EmptyDosing object
            link = helpPopupStr('EmptyDosing');
            fprintf('\t %s object.\n\n',link)
        end

        function str = summary(~)
            %SUMMARY Summarize an EmptyDosing object
            str = '0 dosing events';
        end

        function cl = dosingTypes(~)
            %DOSINGTYPES Dosing types contained in EmptyDosing objects
            %   CL = DOSINGTYPES(D), with an EmptyDosing object D, returns
            %   an empty cellstr CL.

            cl = {};
        end

        function obj = filterDosing(obj, ~, ~)
            %FILTERDOSING Extract dosing of specific compound(s) / type(s)
            %   OUT = FILTERDOSING(D, CPD, TYPE), with EmptyDosing object 
            %   D, always return an EmptyDosing object OUT, regardless of 
            %   CPD and TYPE.
        end
    end
end