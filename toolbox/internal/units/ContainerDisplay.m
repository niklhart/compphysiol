classdef (Abstract) ContainerDisplay < matlab.mixin.CustomCompactDisplayProvider
    %CONTAINERDISPLAY Mixin class for display in structs, tables and cells.
    %   Inheriting from class CONTAINERDISPLAY provides custom object 
    %   display in structs, tables and cells for any class defining a 
    %   string method. Currently, DimVar and HDV make use of this class.
    
    methods (Abstract)
        str = string(obj)
    end

    methods
        function rep = compactRepresentationForSingleLine(obj, displayConfiguration, ~)
            % Fit as many array elements in the available space as possible

            if isrow(obj)
                n = numel(obj);
                switch n
                    case {0,1,2,3}
                        rep = fullDataRepresentation(obj, displayConfiguration);
                    otherwise
                        obj1 = subsref(obj,struct('type','()','subs',{{1}}));
                        ann = ['1x' num2str(n) ' ' class(obj)];
                        rep = partialDataRepresentation(obj, displayConfiguration, string(obj1), Annotation = ann);
                end
            else
                rep = matlab.display.DimensionsAndClassNameRepresentation(obj,displayConfiguration);
            end
        end
    
        function rep = compactRepresentationForColumn(obj,displayConfiguration,~)
            % Fit all array elements in the available space, or else use
            % the array dimensions and class name
            rep = fullDataRepresentation(obj,displayConfiguration);
        end
    end

end