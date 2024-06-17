%SIMULATOR Simulation of a (PB)PK model
%   OUTPUT = SIMULATOR(MODEL, TSPAN, DOSING) takes the following input:
%   - a struct MODEL, containing all information needed to solve the ODE
%     (see below)
%   - a time vector TSPAN, specifying simulation timespan (length=2) or
%     exact simulation times (length > 2)
%   - a Dosing object DOSING, from which dosing information is extracted
%   
%   Output is a structure OUTPUT with fields
%       .t     timesteps of the numerical integrator
%       .X     solution of the ODE system approximated by the numerical
%              integrator
%   Both outputs are dimensioned (t in a time unit, X in the same unit as
%   X0). For information about unit consistency by the numerical
%   integrator, see the help for odeu15s.
%   
%   The struct MODEL must have the following reserved fields for SIMULATOR
%   to work:
%   - rhsfun        A function handle rhsfun(t,Y,MODEL), to be used in the
%                   ODE solver
%   - X0            A (dimensioned) vector of initial conditions
%   - indexing.Id   A dosing index struct, with the following syntax:
%                   * bolus dosing: for dosing <site> (e.g., <site>=iv):
%                       - indexing.Id.<site>.cmt: compartment index for
%                         dosing
%                       - indexing.id.<site>.scaling: scaling parameter for
%                         dosing into cmt (1 if cmt represents an amount,
%                         or the compartment volume if cmt represents a
%                         concentration)
%                   * infusion dosing: for dosing <site> (e.g., <site>=iv):
%                       - indexing.Id.<site>.bag: compartment index for
%                         infusion bag (note: the compartment is assumed to
%                         always contain an amount, NOT a concentration)
%                       - indexing.id.<site>.rate: compartment index for
%                         infusion rate (stored as a state of the ODE 
%                         system)
%   Otherwise, any field may be defined to store e.g. physiological / drug-
%   related parameters, any may itself consist of cells/structs, possibly 
%   nested.
%
%   See also odeu15s, Individual/simulate

function output  = simulator(model, tspan, dosing)

    checkmodelstruct(model)
    
    [~,~,tspanunit] = displayparser(tspan);
    
    tspan = tspan(:);
    tfixed = numel(tspan) > 2;    % two modes: collect predictions at all output times or only at specific ones
    
    setup = model.setup;
    
    X0 = reshape(setup.X0, 1,[]); %row vector easier to handle
    rhs = model.rhsfun;
    
    solver = @odeu15s; %or @odeu45;
    
    solver = @(a,b,c,d) odeu15s(a,b,c,d,odeset('AbsTol',1e-13,'RelTol',1e-13));
    
    [tincr, Xincr] = process_dosing(dosing, setup.indexing.Id, X0);
    
    % trim dosing schedule if no corresponding observations are specified
    imax = find(tincr >= max(tspan), 1);
    if ~isempty(imax)
        tincr = tincr(1:imax-1);
        Xincr = Xincr(1:imax-1,:);
    end
    
    % initialize output
    tout = [];
    Xout = [];

    if ~isempty(tincr) && tincr(1) < tspan(1)     % handle early dosing
    
        nprev = sum(tincr < tspan(1));
        for i = 1:nprev-1
            X0 = X0 + Xincr(i,:);        
            tspanprev = [tincr(i) tincr(i+1)];
            [~, X] = solver(rhs, tspanprev, X0, setup);
            X0 = X(end,:);
        end
        X0 = X0 + Xincr(nprev,:);        
        tspanprev = [tincr(nprev) tspan(1)];
        [~, X] = solver(rhs, tspanprev, X0, setup);
        X0 = X(end,:);
        tincr = tincr(nprev+1:end);
        Xincr = [Xincr(nprev+1:end,:)];

    end

    if isempty(tincr)                % handle empty dosing

        [tout, Xout] = solver(rhs, tspan, X0, setup);
        if tfixed
            iout = ismember(tout, tspan);
            tout = tout(iout);
            Xout = Xout(iout,:);        
        end

    elseif tincr(1) > tspan(1)       % handle delayed dosing
    
        tspan1 = [tspan(tspan < tincr(1)); tincr(1)];

        [t, X] = solver(rhs, tspan1, X0, setup);
        if tfixed
            iout = ismember(t(1:end-1), tspan);  %subsref t to avoid counting observations at tincr twice
            tout = [tout; t(iout)];
            Xout = [Xout; X(iout,:)];        
        else
            tout = [tout; t];
            Xout = [Xout; X];
        end
        X0 = X(end,:);
    end

    % handle intermediate dosing intervals
    for i=1:length(tincr)-1
        X0 = X0 + Xincr(i,:);        
        tspani = [tincr(i); tspan(tspan > tincr(i) & tspan < tincr(i+1)); tincr(i+1)];
        [t, X] = solver(rhs, tspani, X0, setup);
        if tfixed
            iout = ismember(t(1:end-1), tspan); 
            tout = [tout; t(iout)];
            Xout = [Xout; X(iout,:)];        
        else
            tout = [tout; t];
            Xout = [Xout; X];
        end
        X0 = X(end,:);
    end
    
    % handle last dosing interval
    if ~isempty(tincr)
        X0 = X0 + Xincr(end,:);        
        tspanend = [tincr(end); tspan(tspan > tincr(end))];
        [t, X] = solver(rhs, tspanend, X0, setup);
        if tfixed
            iout = ismember(t, tspan); 
            tout = [tout; t(iout)];
            Xout = [Xout; X(iout,:)];        
        else
            tout = [tout; t];
            Xout = [Xout; X];
        end
    end
    % assign output    
    output = struct;
    output.t = scd(tout, tspanunit);
    output.X = Xout;
    
end
    
    