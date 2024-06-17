%EMPIRICAL2CMT_PLASMA_MACROCONSTANTS_LINEARCL 2-cmt empirical PK model
%    This function specifies a 2-cmt empirical PK model. Parameters must be
%    specified at the script level, as shown below.
%
%    To execute this model, the following parameters must be defined:
%   
%    CL         [Mass/Volume]  Clearance (from central compartment)
%    V1         [Volume]       Central volume of distribution
%    Q          [Mass/Volume]  Intercompartmental clearance
%    V2         [Volume]       Peripheral volume of distribution
%    lambda_po  [1/Time]       First-order oral absorption rate constant
%    F          [unitless]     Oral bioavailability     

% ========================================================================%
% General structure
% ========================================================================%
function model = empirical2CMT_PLASMA_macroConstants_linearCL()


    model = OdeModel;
    model.initfun = @initfun;
    model.rhsfun  = @rhsfun; 
    model.obsfun  = @obsfun;
    model.name    = mfilename;
    
end

% ========================================================================%
% Initialization of model
% ========================================================================%
function setup = initfun(~, drug, par, ~)
%INITFUN Initialization of 2-CMT empirical model

    % assertions (model validity): 
    assert(isscalar(drug), 'Model not defined for multiple drugs.')
    
    % state indexing
    
    I = initcmtidx('cen','per','GItract','IVbag','IVrate','metab');

    % Definition of dosing target struct
    Id = struct;
    
    Id.bolus.iv.cmt     = I.cen;
    Id.bolus.iv.scaling = par.V1;
    
    Id.infusion.iv.bag  = I.IVbag;
    Id.infusion.iv.rate = I.IVrate;
   
    Id.oral.cmt         = I.GItract;

    %%% initial condition and units of ODEs

    doseunit = u.ug;
    
    X0 = initializeX0(I);
    X0([I.cen I.per]) = scd(0*doseunit / u.L,'ug/L');
    X0(I.GItract) = 0*doseunit;
    X0(I.IVbag)   = 0*doseunit;
    X0(I.IVrate)  = 0*doseunit / u.min;
    X0(I.metab)   = 0*doseunit;
            
    % -----------------------------------------------------------------------
    % Assign model parameters 
    setup = struct;
    setup.indexing.I  = I;
    setup.indexing.Id = Id;
    setup.par         = par;
    setup.X0          = X0;
    
end


% ========================================================================%
% ODE system of the model
% ========================================================================%
function dX = rhsfun(t, X, setup) % t will be used for infusion rate
%RHSFUN ODE system of 2-CMT empirical PK model

    % initialize output vector
    X = X(:);
    dX = NaNsizeof(X);
    
    % state indexing
    I = setup.indexing.I; 
    
    % variables (always use column vector notation)
    C_cen         = X(I.cen); 
    C_per         = X(I.per); 
    A_GItract     = X(I.GItract); 
    infusion_rate = X(I.IVrate);
    
    % parameters
    par = setup.par;

    %%% -----------------------------------------------------------------------
    %%% START OF ODEs

    % GI tract compartment
    dA_GItract = -par.lambda_po*A_GItract;

    % central compartment
    VdC_cen = par.F * par.lambda_po * A_GItract ...
              - par.CL * C_cen ...
              + par.Q * (C_per - C_cen) ...
              + infusion_rate;

    % peripheral compartment
    VdC_per =  par.Q * (C_cen - C_per);

    % drug amount in IVbag for infusion
    dA_IVbag = -infusion_rate;

    % drug amount metabolized or excreted
    dA_metab = par.CL * C_cen;

    %%% END OF ODEs
    %%% -----------------------------------------------------------------------

    % converting amounts to concentrations
    dC_cen = VdC_cen ./ par.V1;
    dC_per = VdC_per ./ par.V2;

    % output vector (always in column vector notation)
    dX(I.cen)     = dC_cen;
    dX(I.per)     = dC_per;
    dX(I.GItract) = dA_GItract;
    dX(I.metab)   = dA_metab;
    dX(I.IVbag)   = dA_IVbag;
    dX(I.IVrate)  = 0 * unitsOf(X(I.IVrate) / t);

end

% ========================================================================%
% Definition of observable quantities
% ========================================================================%
function yobs = obsfun(output, setup, obs)
%OBSFUN Observables in 1-CMT empirical PK model
%   The following observables are supported:
%     
%   Type 'SimplePK':
%       Site:     'pla'
%       Binding:  'total'
%       UnitType: 'Mass/Volume'
%    
%   Type 'MassBalance':
%       UnitType: 'Mass

    I  = setup.indexing.I;

    yobs = []; % if obs matches a case below, yobs will be overwritten
    
    switch obs.type
        case 'SimplePK'            
            if strcmp(obs.attr.Site, 'pla') && ...
                    strcmp(obs.attr.Binding,'total') && ...
                    strcmp(obs.attr.UnitType,'Mass/Volume')      %Amount/Volume not working yet (MW not needed in general...)
                yobs = output.X(:,I.cen);
            end
                       
        case 'massBalance'
            if strcmp(obs.attr.UnitType,'Mass')                
                yobs = output.X(:,I.cen) .* setup.par.V1 ...
                       + output.X(:,I.per) .* setup.par.V2 ...
                       + output.X(:,I.GItract) ...
                       + output.X(:,I.IVbag) ...
                       + output.X(:,I.metab); 
            end
    end
end