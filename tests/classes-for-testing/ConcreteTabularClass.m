classdef ConcreteTabularClass < TabularClass
    %CONCRETETABULARCLASS Dummy class to test the abstract TabularClass

    methods
        
        function obj = ConcreteTabularClass(tab)
            %CONCRETETABULARCLASS Construct an instance of this class
            if nargin > 0
                obj.table = tab;
            else
                obj.table = table();
            end
        end

    end

    methods (Static)
        function obj = empty()
            obj = ConcreteTabularClass();
        end
    end

end