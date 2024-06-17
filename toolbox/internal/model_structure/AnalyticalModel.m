classdef AnalyticalModel < Model
    %ANALYTICALMODEL Class for models specified via analytical solutions
    %   Detailed explanation goes here

    properties
        solfun
    end

    methods

        function model = AnalyticalModel(initfun, solfun)
        %ANALYTICALMODEL Constructor for AnalyticalModel class
            %   M = ANALYTICALMODEL() initializes an empty AnalyticalModel 
            %   object.
            %   M = ANALYTICALMODEL(INITFUN,SOLFUN), called with two
            %   function handles INITFUN and SOLFUN, assigns these
            %   input functions to the initfun and solfun properties.
            %
            %   See also Model, OdeModel
            if nargin > 0
                model.initfun = initfun;
                model.solfun = solfun;
            end

        end

        function observation = simulate(model, dosing, sampling)

            observation = model.solfun(model.setup, dosing, sampling);

        end

        function set.solfun(model, f)
            checknarg(f, 3, 1)
            model.solfun = f;
        end

    end

end