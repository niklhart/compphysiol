classdef Individual < matlab.mixin.Copyable & ColumnClass
    %INDIVIDUAL Class for holding virtual individuals or experimental data 
    %
    %   The following modelling methods are available:
    %   - Individual/simulate
    %   - Individual/plot
    %   - Individual/initialize
    %   - Individual/estimate
    %   - Individual/observe
    %   
    %   See also Individual/Individual (syntax of constructor)

    %% Properties
    properties
        % for experimental data and virtual individuals
        type
        name
        dosing = EmptyDosing;
        drugdata = DrugData;
        physiology = Physiology;
        observation                 % Record object
        
        % only for virtual individuals
        sampling
        model      % set during 'initialize', except for fields 'fun','par','options'
        estim      % set during 'estimate', except for fields 'data','parinit','options'

    end

    properties (Dependent = true, Access = private)
        pdrugdata
    end
    
    %% Methods
    methods
        
        %% Constructor 
        function obj = Individual(type,n)
        %INDIVIDUAL Construct an object of class Invididual.
        %   OBJ = INDIVIDUAL(TYPE), with TYPE 'Experimental data' or 
        %       'Virtual individual' (with partial string matching), creates
        %       a scalar object of class Individual of the respective type.
        %   OBJ = INDIVIDUAL(TYPE, N), with TYPE as above and an integer N, 
        %       creates a length N array of Individual objects, each of the
        %       respective TYPE.
        %
        %   Examples:
        %   
        %   obj  = Individual('Virtual');
        %   obj2 = Individual('Virtual',5);        
            
            arguments
                type char {mustBeMember(type,{'Virtual','Experimental',''})} = []
                n (1,1) double {mustBeInteger,mustBePositive} = 1
            end            

            if nargin > 0
                obj(n,1) = Individual();
                [obj.type] = deal(type);
            end
        end
        
        %% Set methods
        function set.type(obj, type)
            obj.type = validatestring(type, {'Experimental data','Virtual individual'});
        end

        function set.name(obj, name)
            obj.name = num2str(name);
        end
        
        function set.dosing(obj,dos)
            assert(isscalar(obj), 'Properties can only be set for a scalar Individual object.')
            assert(isempty(dos) || isa(dos,'Dosing'), 'Property "dosing" must be a Dosing object.') 
            obj.dosing = dos;
        end
        
        function out = get.drugdata(obj)
            assert(isscalar(obj), 'Property can only be retrieved for a scalar Individual object.')
            if getoptcompphysiol('AutoAssignDrugData') && isempty(obj.drugdata)
                out = obj.pdrugdata;
                phys = obj.physiology;
                if getoptcompphysiol('AutoFilterDrugData') && hasuniquerecord(phys,'species')
                    filtervariants(out, 'species', getvalue(phys,'species'));
                end
            else
                if getoptcompphysiol('AutoFilterDrugData')
                    msg = ['Option "AutoFilterDrugData" only takes effect'...
                           'when "AutoAssignDrugData" is true.'];
                    warning(msg)
                end
                out = obj.drugdata;
            end
        end
        
        function set.drugdata(obj, drugdata)
            assert(isscalar(obj), ...
                'Properties can only be set for a scalar Individual object.')
            assert(isempty(drugdata) || isa(drugdata,'DrugData'), ...
                'compphysiol:Individual:setdrugdata:wrongObjType', ...
                'Property "drugdata" must be a DrugData object.') 
            obj.drugdata = drugdata;            
        end
        
        function out = get.pdrugdata(obj)
            assert(isscalar(obj), 'Property can only be retrieved for a scalar Individual object.')
            cpd = compounds(obj.dosing);
            out = loaddrugdata(cpd);
        end
      
        function set.physiology(obj,phys)
            assert(isscalar(obj), 'Properties can only be set for a scalar Individual object.')
            assert(isempty(phys) || isa(phys,'Physiology'), ...
                'compphysiol:Individual:setphysiology:wrongObjType', ...
                'Property "physiology" must be a Physiology object.') 
            obj.physiology = phys;
        end
        
        function set.sampling(obj,smpl)
            assert(isscalar(obj), 'Properties can only be set for a scalar Individual object.')
            assert(isempty(smpl) || isa(smpl,'SamplingRange') || isa(smpl,'SamplingSchedule'), ...
                'compphysiol:Individual:setsampling:wrongObjType', ...
                'Property "sampling" must be a SamplingRange or SamplingSchedule object.') 
            obj.sampling = smpl;
        end
        function set.observation(obj,obs)
            assert(isscalar(obj), 'Properties can only be set for a scalar Individual object.')
            assert(isempty(obs) || isa(obs,'Record'), ...
                'compphysiol:Individual:setobservation:wrongObjType', ...
                'Property "observation" must be a Record object.') 
            obj.observation = obs;
        end
        function set.model(obj, model)
            if isempty(model)
                obj.model = [];
            else
                assert(isa(model,'Model'), ...
                    'compphysiol:Individual:setmodel:wrongObjType', ...
                    'Property "model" must be a Model object.')
                obj.model = copy(model);
            end
        end
        
        %% Cloning Individual objects
        function out = clone(obj)
            %CLONE Create a deep copy of an Individual object

            assert(isscalar(obj), 'Only scalar Individual objects can be cloned.')
            out = copy(obj);

            % the following code should be stored as read-only in some
            % global place, rather than in this function.
            allProperties = properties(obj);
            isHandleProperty = cellfun(@(x) isa(obj.(x), 'handle'), allProperties);
            handleProperties = allProperties(isHandleProperty);
            for i = 1:numel(handleProperties)
                prop = handleProperties{i};
                [out.(prop)] = copy(obj.(prop));
            end
        end
        
        %% Conversion methods

        function out = exp2sim(obj)
            %EXP2SIM Convert experimental data to virtual individual
            %   OUT = EXP2SIM(OBJ) converts Individual array OBJ consisting
            %   of experimental data into an Individual array OUT of
            %   virtual individuals. Common properties are re-used, and the
            %   sampling schedule is extracted from the observation record.
            %   This functionality is used within estimation functions to
            %   define a simulation matching the conditions of the
            %   experimental data.
            %
            %   See also Individual, sim2exp.

            assert(all(isexpid(obj),'all'), ...
                'compphysiol:Individual:exp2sim:needExperimentalData', ...
                'Input array must contain experimental data only.')
            
            out = clone(obj);
            for i = 1:numel(out)
                out(i).sampling = schedule(out(i).observation);
            end            
            [out.type] = deal('Virtual individual');            
        end
        

        function obj = sim2exp(obj)
            %SIM2EXP Convert virtual individual (predictions) to experimental data
            %   OUT = SIM2EXP(OBJ) converts Individual array OBJ consisting
            %   of simulated virtual individuals into an Individual array 
            %   OUT of experimental data. This functionality is useful to
            %   estimate model parameters based on model predictions, e.g.
            %   in a simulation study.
            %
            %   See also Individual, exp2sim.

              
            assert(all(issimid(obj),'all'), ...
                'compphysiol:Individual:sim2exp:needVirtualIndividual', ...
                'Input array must contain virtual individuals only.')
            checkSimulated(obj)
            
            for i = 1:numel(obj)
                if isempty(obj(i).observation)
                    assert(~isempty(obj(i).sampling.schedule), 'Sampling schedule must be defined')
                    obj(i).observation = observe(obj(i));
                end
            end             
            [obj.type]     = deal('Experimental data');    
            [obj.sampling] = deal([]);    
            [obj.model]    = deal([]);    
            
        end
            
        
        %% Object display
        function disp(obj,N)
            %DISP Display an Individual object
            %   DISP(OBJ) displays the content of an Individual object OBJ. To
            %   see the underlying structure of OBJ, use builtin('disp',OBJ).
            
            lnk   = helpPopupStr('Individual');
            
            if isscalar(obj)
                str = struct;
                str.type = obj.type;
                str.name = obj.name;
                str.dosing     = summary(obj.dosing);
                str.physiology = summary(obj.physiology);        

                % display model-related information for virtual individuals
                if issimid(obj)
                    if isa(obj.model,'Model')
                        if issimulated(obj)
                            status = 'simulated';
                        elseif isinitialized(obj)
                            status = 'initialized';
                        else
                            status = 'uninitialized';
                        end
                        str.model = [obj.model.name ' (' status ')'];
                    end
                    if ~isempty(obj.sampling)                    
                        str.sampling = summary(obj.sampling);                        
                    end
                    if ~isempty(obj.drugdata)
                        str.drugdata = summary(obj.drugdata);        
                    end
%                    str.estim    = [];                        
                elseif ~isexpid(obj)
                    builtin('disp',obj);
                    return
                end     
                % display observations
                if ~isempty(obj.observation)                    
                    str.observation = summary(obj.observation);                        
                end  
                fprintf('\t%s object:\n\n',lnk)
                disp(str)       

            else
                if nargin == 1
                    disp@ColumnClass(obj)
                else
                    disp@ColumnClass(obj,N)
                end
            end
            fprintf("Use builtin('disp',OBJ)) to see the underlying structure of the Individual object OBJ\n") 
        end


        function str = obj2str(obj, context)
            switch context
                case {'array','table'}

                    tp = obj.type;
                    if isempty(tp)
                        tp = 'Undefined';
                    end

                    nm = obj.name;
                    if isempty(nm)
                        nm = '';
                    else
                        nm = [' "' nm '"'];
                    end

                    str = [tp nm];

                otherwise
                    error('compphysiol:Individual:obj2str:unknownContext', ...
                        'Function not defined for context "%s"', context)
            end

        end
        
        
        
        %% Script level methods

        function varargout = plot(obj,varargin)
        %PLOT Plot experimental data and simulations
        %   PLOT(OBJ) displays the default plots defined in the plot
        %   template.
        %
        %   PLOT(OBJ, TYPE) displays graphics TYPE, which must also be
        %   defined in the plot template, but not necessarily as a default
        %   plot.
        %
        %   For changing the behaviour of the plot method, define a custom 
        %   version of plottemplate() and activate it using 
        %
        %   setoptcompphysiol('PlotTemplate', @PLOTTEMPL)
        %
        %   where PLOTTEMPL is the name of the custom plot template.
        %      
        %   See also PLOTTEMPLATE, LONGITUDINALPLOT

            checkHandleDuplicates(obj)

            assert(all(isexpid(obj) | issimulated(obj),'all'), ...
                'compphysiol:Individual:plot:missingSimulation', ...
                'Virtual individuals must be simulated prior to plotting.')
        
            h = evalfhopt('PlotTemplate',obj,varargin{:});
            
            switch nargout
                case 1
                    varargout{1} = h;
            end
        end
        
        
        function initialize(obj)
        %INITIALIZE Initialize virtual individuals
        %   INITIALIZE(OBJ) initializes the model setup struct for any 
        %   virtual individual in the array OBJ. To simulate a virtual 
        %   individual, it must be initialized first.
        %
        %   See also Individual/simulate
        
            checkHandleDuplicates(obj)

            is_sim = issimid(obj);
            is_exp = isexpid(obj);
            if ~all(is_sim | is_exp, 'all') 
                msg = ['In each component, Individual type must be either ' ...
                       '"Virtual individual" or "Experimental data".'];
                warning(msg)
            end

            for i = findAsRow(is_sim)
                
                % define a name of individual for error display
                if isempty(obj(i).name)
                    nm = ['Individual ' num2str(i)];
                else
                    nm = ['Individual "' obj(i).name '"'];
                end

                % produce a meaningful error message if anything is missing
                validateattributes(obj(i).model,      'Model',     {},         nm, 'property "model"')
                validateattributes(obj(i).physiology, 'Physiology',{'scalar'}, nm, 'property "physiology"')
                validateattributes(obj(i).dosing,     'Dosing',    {},         nm, 'property "dosing"')
                validateattributes(obj(i).sampling,   {'SamplingRange','SamplingSchedule'},  {},         nm, 'property "sampling"')
                validateattributes(obj(i).drugdata,   'DrugData',  {'scalar'}, nm, 'property "drugdata"')
                                
                % if all checks passed, initialize the model
                obj(i).model.setup = obj(i).model.initfun(...
                    obj(i).physiology, ...
                    obj(i).drugdata, ... 
                    obj(i).model.par, ...
                    obj(i).model.options);  

            end  

            if getoptcompphysiol('ReportToConsole')
                fprintf('%d virtual individuals initialized.\n',sum(is_sim))
            end
        end
        
        
        function simulate(obj)
        %SIMULATE Simulate virtual individuals
        %   SIMULATE(OBJ) simulates the model specified for any virtual
        %   individual in the Individual array OBJ. The model must be 
        %   initialized prior to using SIMULATE.
        %
        %   See also Individual, Individual/initialize

            checkHandleDuplicates(obj)

            is_sim = issimid(obj);
            for i = findAsRow(is_sim)
                checkInitialized(obj(i))
                obj(i).observation = simulate(obj(i).model, obj(i).dosing, obj(i).sampling);
            end        

            if getoptcompphysiol('ReportToConsole')
               fprintf('%d virtual individuals simulated.\n',sum(is_sim))
            end
        end
        
        
        function estimate(obj, varargin)
        %ESTIMATE Estimate model parameters
        %
        %   ESTIMATE(OBJ) performs, for all virtual individuals in the
        %   Individual array OBJ, estimation as specified in OBJ.estim.
        %   
        %   Required fields in OBJ.estim are
        %   
        %       .parinit   A struct of parameters, as created by function
        %                  parameters(), used as an initial guess for the
        %                  estimation procedure.
        %       .data      An array of class Individual containing the 
        %                  experimental data to use for estimation.
        %   
        %   Optional fields in OBJ.estim 
        %   
        %       .options   A struct with one of the following estimation 
        %                  options:
        %                   - 'fixed'  A cellstr of fixed, i.e. non-
        %                              estimated, parameter names.
        %
        %   The input suitable for an estimation task is created by
        %   function getestimationwrapper(). For more control over the 
        %   estimation procedure, this function can also be called
        %   directly.
        %
        %   ESTIMATE(OBJ, 'N1', V1, 'N2', V2, ...) passes the name-value 
        %   pairs 'N1', V1, 'N2', V2, ... on to function optimoptions(). In
        %   this way, the estimation settings can be customized 
        %   
        %	See also Individual/getestimationwrapper, optimoptions.
     
            checkHandleDuplicates(obj)

            oldopt = setoptcompphysiol('ReportToConsole', false);
            cleanup_Reporting = onCleanup(@()setoptcompphysiol(oldopt));

            for i = findAsRow(issimid(obj))
                
                [par, fun, names, units] = getestimationwrapper(obj(i));
                
                opt = optimoptions('fmincon',...
                    'Display','iter',...
                    'Algorithm','sqp',...      % 'interior-point' 'sqp' 'trust-region-reflective' 'active-set'
                    'TypicalX',par, ...
                    'OptimalityTolerance',1e-8, ...
                    'StepTolerance',1e-8, ...
                    'FiniteDifferenceStepSize',1e-1*par, ...
                    'FiniteDifferenceType','central', ...
                    varargin{:});
                
                
                      %fmincon(FUN,  X0,  A,  B,Aeq,Beq,       LB,      UB,NONLCON, OPTIONS)
                popt = fmincon(fun, par, [], [], [], [], par*1e-5, par*1e5,     [], opt);

                % estimation output (TODO: add convergence diagnostics!)
                obj(i).estim.parestim  = update_parstruct(obj(i).estim.parinit,popt,names,units);
            end            

            clearvars cleanup_Reporting

            if getoptcompphysiol('ReportToConsole')
                fprintf('%d estimation task(s) completed.\n',sum(is_sim))
            end
        end
        
        
        function [par, fun, names, units] = getestimationwrapper(obj, units)
        %GETESTIMATIONWRAPPER Make a wrapper for estimation at script level
        %   [PAR, FUN, NAMES, UNITS] = GETESTIMATIONWRAPPER(OBJ) takes a
        %   scalar Individual object OBJ with specified estim property and
        %   returns information required for performing parameter 
        %   estimation with standard tools (i.e., unitless and vectorized 
        %   parameters). The following information is returned:
        %       PAR    A numeric vector of unitless parameters
        %       FUN    An objective function taking a vector of type PAR as
        %              its input
        %       NAMES  A cellstr of parameter names.
        %       UNITS  A vector of units, such that PAR*UNITS restores PAR
        %              in its original form. By default, this is done via
        %              function unitsOf(), which means that PAR is given in
        %              internal units.
        
        %   TODO: also make the following syntax work; in particular, the
        %         question is what format input UNITS should have: the most
        %         natural would be a struct with parameter names and (non-
        %         default) units, but then input UNITS and output UNITS
        %         would have a completely different syntax.
        %
        %   [PAR, FUN, NAMES, UNITS] = GETESTIMATIONWRAPPER(OBJ, UNITS) 
        %   specifies target units UNITS for PAR to be returned in. 
        %       
            assert(nargin == 1, 'Argument "units" not implemented yet; I first have to decide on input syntax!')
        
            assert(isscalar(obj), ...
                'Estimation wrappers can only be obtained for scalar Individual objects.')
        
            if isempty(obj.estim) || ~isfield(obj.estim, 'data')
                error('No estimation information provided.')
            end

            % get estimation options
            if isfield(obj.estim, 'options')
                opt = obj.estim.options;
            else
                opt = estimset();
            end

            % convert parameter format (struct --> vector)
            parstr = obj.estim.parinit;
            obj.model.par = parstr;

            names = fieldnames(parstr);

            iest = ~ismember(names, opt.fixed);
            names = names(iest);

            parvec = struct2cell(parstr);
            parvec = vertcat(parvec{:});

            par = parvec(iest);
            units = unitsOf(par);
            par  = double(par);

            fun = @(p) nll(obj.model, obj.estim.data, p.*units, names);
        end
        
        
        %% Helper functions

        function checkInitialized(obj)
            if ~all(isinitialized(obj),'all')
                msg = 'All elements in Individual array must be initialized.';
                error('compphysiol:Individual:checkInitialized:notInitialized', msg)
            end
        end

        function checkSimulated(obj)
            if ~all(issimulated(obj),'all')
                msg = 'All elements in Individual array must have simulation output.';
                error('compphysiol:Individual:checkSimulated:notSimulated', msg)
            end
        end

        function checkHandleDuplicates(obj)

            uobj = unique(obj);
            if numel(uobj) ~= numel(obj)
                msg = ['Handle duplicates found in Individual array. To copy ' ...
                       'the content of an Individual object OBJ, use ' ...
                       'OBJ2 = clone(OBJ) instead of OBJ2 = OBJ.'];
                error('compphysiol:Individual:checkHandleDuplicates:handleDuplicates', msg)
            end

        end
        
        % function S = individualtype(obj)
        %     %INDIVIDUALTYPE Abbreviated representation of Individual type
        %     %   S = INDIVIDUALTYPE(OBJ) with Individual object OBJ returns 
        %     %   a cellstr of the same size as OBJ with
        %     %   - S{i} = 'E'  if OBJ(i) is experimental data
        %     %   - S{i} = 'V'  if OBJ(i) is a virtual individual
        %     %   - S{i} = ''   if OBJ(i) has no assigned type yet
        % 
        %     S = cell(size(obj));
        %     S(isexpid(obj)) = {'E'};
        %     S(issimid(obj)) = {'V'};
        % 
        %     S(cellfun(@isempty,S)) = {''};
        % end
        
        function tf = issimid(obj) 
            %ISSIMID Check which array entries contain virtual individuals
            %   TF = ISSIMID(OBJ) returns a logical array TF of the same 
            %   size as OBJ, with TF(i) = true if OBJ(i).type is 
            %   'Virtual individual'.
            tf = arrayfun(@(x) strcmp(x.type, 'Virtual individual'), obj);
        end
        function tf = isexpid(obj)            
            %ISEXPID Check which array entries contain experimental data
            %   
            %   TF = ISEXPID(OBJ) returns a logical array TF of the same 
            %   size as OBJ, with TF(i) = true if OBJ(i).type is 
            %   'Experimental data'.
            tf = arrayfun(@(x) strcmp(x.type, 'Experimental data'), obj);
        end
        function tf = isinitialized(obj)
            %ISINITIALIZED Check if virtual individuals are initialized
            %   TF = ISINITIALIZED(OBJ) returns a logical array TF of the 
            %   same size as OBJ, with TF(i) = true if OBJ(i).model.setup 
            %   is assigned, as expected after calling method 'initialize'.
            tf = arrayfun(@(x) isa(x.model,'Model') && ~isempty(x.model.setup), obj);
        end
        function tf = issimulated(obj)
            %ISSIMULATED Check if virtual individuals have been simulated
            %   TF = ISSIMULATED(OBJ) returns a logical array TF of the 
            %   same size as OBJ, with TF(i) = true if OBJ(i).observation  
            %   is assigned.
            tf = arrayfun(@(x) isa(x.model,'Model') && isa(x.observation,'Record'), obj);            
        end
    end
end









