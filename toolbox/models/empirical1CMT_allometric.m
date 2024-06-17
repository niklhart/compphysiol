%empirical1CMT_allometric Allometrical scaling in empirical 1cmt model
%    This function specifies an empirical 1CMT model using allometrical 
%    scaling for model parameters.
%
%    Model parameters are specified for the a reference individual 
%    (input argument 'phys') and scaled to a target body weight:
%       CL          Clearance (from central compartment)
%       V           Volume of distribution (central compartment)
%       lambda_po   First-order oral absorption rate constant
%       F           Oral bioavailability
%
%    To execute this model, the following options must be defined:
%    - targetBW      a Mass-type DimVar: the body weight to which
%                    to scale allometrically.
%         

function model = empirical1CMT_allometric()

    model = OdeModel;
    model.initfun = @initfun;
    model.rhsfun  = @rhsfun; 
    model.obsfun  = @obsfun;
    model.name    = mfilename;

end

function setup = initfun(phys, drug, par, options)
    
    % assertions (model validity): 
    assert(isempty(drug) || isscalar(drug), 'Model not defined for multiple drugs.')
    
    % state indexing
    queryphys = loaddatabases(phys);
    I = initcmtidx('ctr','GItract','IVbag','IVrate','metab');
    
    % Definition of dosing target struct
    Id = struct;
    
    Id.bolus.iv.cmt     = I.ctr;
    Id.bolus.iv.scaling = par.V;
    
    Id.infusion.iv.bag  = I.IVbag;
    Id.infusion.iv.rate = I.IVrate;
   
    Id.oral.cmt         = I.GItract;

    
    % allometric scaling of parameters
    BW_ref = queryphys('BW');
    BW_targ  = getfrom(options, 'targetBW');
    
    SV = BW_targ/BW_ref;
    SQ = (BW_targ/BW_ref)^0.75;

    par.V  = SV * par.V;
    par.CL = SQ * par.CL;    
    

    %%% initial condition and units of ODEs

    doseunit = u.ug;
    
    X0 = initializeX0(I);
    X0(I.ctr)     = 0*doseunit / u.L;
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


%% Right-hand side of ODE model
function dX = rhsfun(t, X, setup) % t will be used for infusion rate

    % initialize output vector
    X = X(:);
    dX = NaNsizeof(X);
    
    % state and parameter indexing
    I = setup.indexing.I; 
    
    % variables (always use column vector notation)
    C_ctr         = X(I.ctr); 
    A_GItract     = X(I.GItract); 
    infusion_rate = X(I.IVrate);
    
    % parameters
    par      = setup.par;

    %%% -----------------------------------------------------------------------
    %%% START OF ODEs

    % GI tract compartment
    dA_GItract = -par.lambda_po*A_GItract;

    % central compartment
    VdC_ctr = par.F * par.lambda_po * A_GItract ...
              - par.CL * C_ctr ...
              + infusion_rate;

    % drug amount in IVbag for infusion
    dA_IVbag = -infusion_rate;

    % drug amount metabolized or excreted
    dA_metab = par.CL * C_ctr;

    %%% END OF ODEs
    %%% -----------------------------------------------------------------------

    % converting amounts to concentrations
    dC_ctr = VdC_ctr ./ par.V;

    % output vector (always in column vector notation)
    dX(I.ctr)     = dC_ctr;
    dX(I.GItract) = dA_GItract;
    dX(I.metab)   = dA_metab;
    dX(I.IVbag)   = dA_IVbag;
    dX(I.IVrate)  = 0 * unitsOf(X(I.IVrate) / t);

end

% ========================================================================%
% Definition of observable quantities
% ========================================================================%
function yobs = obsfun(output, setup, obs)
%OBSFUN Observables in allometrically scaled 1-CMT PK model
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
                    strcmp(obs.attr.UnitType,'Mass/Volume')      %TODO: Amount/Volume not working yet (MW not needed in general...)
                yobs = output.X(:,I.cen);
            end
                       
        case 'massBalance'
            if strcmp(obs.attr.UnitType,'Mass')                
                yobs = output.X(:,I.cen) .* setup.par.V ...
                       + output.X(:,I.GItract) ...
                       + output.X(:,I.IVbag) ...
                       + output.X(:,I.metab); 
            end
    end
end