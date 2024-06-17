classdef (Abstract) Dosing
    %DOSING Interface class for dosing schedules

    methods (Abstract)

        out = combine(obj1,obj2)
        cpd = compounds(obj)
        typ = dosingTypes(obj)
        out = filterDosing(obj,cpd,type)
        str = summary(obj)
        disp(obj)

    end

    methods

        function out = plus(obj1,obj2)
            %PLUS Add two dosing schedules

            if strcmp(class(obj1), class(obj2))
                out = combine(obj1, obj2);
            elseif isa(obj1, 'EmptyDosing')
                out = obj2;
            elseif isa(obj2, 'EmptyDosing')
                out = obj1;
            else
                out = combine(ComplexDosing(obj1), ComplexDosing(obj2));
            end
            
        end
        
    end

end