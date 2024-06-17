classdef (Abstract) Model < matlab.mixin.Copyable
    %MODEL Interface class for models
    %   Detailed explanation goes here

    properties    
        par = struct;
        options = struct;
        setup
        initfun
        name
    end

    methods (Abstract)
        observation = simulate(model, dosing, sampling)
    end

    methods
        function set.par(model, p)
            assert(isstruct(p) && all(structfun(@(x) isnumeric(x) && isscalar(x),p)), ...
                'Property "par" invalid.')
            model.par = p;
        end

        function set.options(model, opt)
            assert(isstruct(opt), 'Property "options" must be struct.')
            model.options = opt;
        end

        function set.initfun(model, f)
            checknarg(f, 4, 1)
            model.initfun = f;
        end

    end

end