classdef OdeModel < Model
    %ODEMODEL Class for models specified via ODEs
    %   Detailed explanation goes here

    properties
        rhsfun
        obsfun
        odestate
    end

    methods

        function model = OdeModel(initfun, rhsfun, obsfun)
            %ODEMODEL Constructor for OdeModel class
            %   M = ODEMODEL() initializes an empty OdeModel object.
            %   M = ODEMODEL(INITFUN,RHSFUN,OBSFUN), called with three
            %   function handles INITFUN, RHSFUN and OBSFUN, assigns these
            %   input functions to the initfun, rhsfun and obsfun
            %   properties.
            %
            %   See also Model, AnalyticalModel
            if nargin > 0
                model.initfun = initfun;
                model.rhsfun  = rhsfun;
                model.obsfun  = obsfun;
            end
        end

        function rec = simulate(model, dosing, sampling)
        %SIMULATE Simulate an ODE model for a specified dosing and sampling
        %   REC = SIMULATE(M, D, S) with an OdeModel M, a Dosing D and a 
        %   Sampling S, solves the ODE model, computes observables and 
        %   returns the results as a Record object REC.

            % Solve ODEs
            % (side effect: save result of ODE solver in odestate property)
            model.odestate = solve_odes(model, dosing, sampling);

            % Compute Observables from ODE output
            rec = observe(model, sampling);

        end

        function set.rhsfun(model, f)
            checknarg(f, 3, 1)
            model.rhsfun = f;
        end

        function set.obsfun(model, f)
            checknarg(f, 3, 1)
            model.obsfun = f;
        end

        function odestate = solve_odes(model, dosing, sampling)
        %SOLVE_ODES Solve an ODE system
        %   OUT = SOLVE_ODES(M, D, S) with an OdeModel M, a Dosing D and a
        %   Sampling S, solves the ODE system and returns a structure OUT,
        %   with fields
        %       .t     timesteps of the numerical integrator (n-by-1)
        %       .X     solution of the ODE system approximated by the 
        %              numerical integrator (n-by-k)

            timespan = sampling.timespan;
            if isempty(timespan)   % -> by schedule
                timespan = unique(sampling.schedule.Time);
            end

            odestate = simulator(model, timespan, dosing);

        end

        function rec = observe(model, sampling)
        %OBSERVE Get observations from an OdeModel object
        %   REC = OBSERVE(M, S), for a scalar OdeModel object M and a
        %   Sampling object S, returns all observations specified by the
        %   sampling schedule as a Record object REC. If S only contains a
        %   sampling timespan, default observables are loaded. If these are
        %   undefined, an error is thrown.

            assert(isscalar(model))
            validateattributes(sampling,'Sampling',{'scalar'})
            assert(~isempty(model.odestate), 'ODEs must be solved first.')

            % first establish observation schedule and observables
            t = model.odestate.t;

            if numel(t) == 2
                warning('Two-timepoint schedules are not handled correctly yet.')
            end

            % if sampling isn't defined as a schedule, convert to it first.
            if isempty(sampling.schedule)
                if ~isempty(sampling.obs)   % sampling window
                    sampling = Sampling(t, sampling.obs);
                else                            % sampling times w/o observable
                    obs = getoptcompphysiol('DefaultObservable');
                    assert(~isempty(obs), ...
                        'For sampling timespans, default observables must be defined.')
                    sampling = Sampling(t, obs);
                end
            end

            % exctract schedule, observables and dimensions
            schedule = sampling.schedule;
            obs      = unique(schedule.Observable);
            nsched   = height(schedule);
            nobs     = numel(obs);
          
            % add predictions to schedule via split-apply-combine
            data = unan(nsched,1);
            keep = false(nsched,1); % filter unsupported observables

            for i = 1:nobs
                typei = obs(i);
                ind_d = ismember(schedule.Observable, typei);
                ind_y = ismember(t, schedule.Time(ind_d));
                yout = model.obsfun(model.odestate, model.setup, typei);
                if ~isempty(yout)
                    data(ind_d) = yout(ind_y);
                    keep(ind_d) = true;
                end
            end            
            rec = [schedule table(data)];

            rec = rec(keep,:);
            
            % return table as Record object
            rec.Properties.VariableNames = {'Time','Observable','Value'};
            rec = Record(rec);

        end

    end
end