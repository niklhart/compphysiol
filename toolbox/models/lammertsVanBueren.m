%LAMMERTSVANBUEREN Lammerts van Bueren systems biology model
%    Add description
%
%    To execute this model, the following options must be defined:
%   
%       TODO: complete this documentation!      

function model = lammertsVanBueren(phys, dosing, par, options)

    model = initialize(phys, dosing, par, options);
    model.rhsfun  = @rhsfun;
    model.obsfun  = @obsfun;

end

function model = initialize(~, dosing, par, ~)
    
    % assertions (model validity): 
    cpd = compounds(dosing);
    assert(isscalar(cpd), 'Model not defined for multiple drugs.')
    
    % state indexing
    
    I = initcmtidx('pla','int','bnd',...'GItract',
        'IVbag','IVrate','metab');
    
    
    % Definition of dosing target struct
    Id = struct;
    
    Id.bolus.iv.cmt     = I.pla;
    Id.bolus.iv.scaling = 1; %par.Vpla;
    
    Id.infusion.iv.bag  = I.IVbag;
    Id.infusion.iv.rate = I.IVrate;
   
%    Id.oral.cmt         = I.GItract;

    %%% initial condition and units of ODEs

    doseunit = u.ug/u.kg;
    
    X0 = initializeX0(I);
    X0(I.IVrate)  = 0*doseunit / u.min;
    X0(I.pla)     = 0*doseunit;
    X0(I.int)     = 0*doseunit;
    X0(I.bnd)     = 0*doseunit;
%    X0(I.GItract) = 0*doseunit;
    X0(I.IVbag)   = 0*doseunit;
    X0(I.metab)   = 0*doseunit;
            
    % -----------------------------------------------------------------------
    % Assign model parameters 
    model = struct;
    model.indexing.I  = I;
    model.indexing.Id = Id;
    model.par         = par;
    model.X0          = X0;
    
end


%% Right-hand side of ODE model
function dX = rhsfun(t, X, model)

    % initialize output vector
    X = X(:);
    dX = NaNsizeof(X);
    
    % state indexing
    I  = model.indexing.I; 
    
    % variables (always use column vector notation)
    A_pla         = X(I.pla); 
    A_int         = X(I.int);
    A_bnd         = X(I.bnd);
%    A_GItract     = X(I.GItract); 
    infusion_rate = X(I.IVrate);
    
    % parameters
    par      = model.par;

    % derived
    C_int = A_int/par.Vint;

    %%% -----------------------------------------------------------------------
    %%% START OF ODEs

% NH add in future version
%     % GI tract compartment
%     dA_GItract = -par(Ip.lambda_po)*A_GItract;

    % plasma compartment
    dA_pla = ... par(Ip.F) * par(Ip.lambda_po) * A_GItract ... %NH add in future version
              - par.klin * A_pla ...
              - par.kpi * A_pla ...
              + par.kip * A_int ...
              + infusion_rate;

    % interstitial compartment
    dA_int = + par.kpi * A_pla ...
              - par.kip * A_int ...
              - par.kb * (par.Bmax*C_int/(par.KM+C_int) - A_bnd);

    % receptor compartment
    dA_bnd = - par.kdeg * A_bnd ...
              + par.kb * (par.Bmax*C_int/(par.KM+C_int) - A_bnd);
          
    % drug amount in IVbag for infusion
    dA_IVbag = -infusion_rate;

    % drug amount metabolized or excreted
    dA_metab = par.klin * A_pla;

    %%% END OF ODEs
    %%% -----------------------------------------------------------------------

    % output vector (always in column vector notation)
    dX(I.pla)  = dA_pla;
    dX(I.int)  = dA_int;
    dX(I.bnd)  = dA_bnd;

%    dX(I.GItract) = dA_GItract;
    dX(I.metab)   = dA_metab;
    dX(I.IVbag)   = dA_IVbag;
    dX(I.IVrate)  = 0 * unitsOf(X(I.IVrate) / t);

end


%% Observation function
function yobs = obsfun(output, model, type)
    
    I  = model.indexing.I;

    switch type
        case 'Cpla'
            yobs = output.X(:,I.pla)./model.par.Vpla;
        case 'Cint'
            yobs = output.X(:,I.int)./model.par.Vint;
        case 'Cbnd'
            yobs = output.X(:,I.bnd)./model.par.Vint;
        case 'massBalance'
            yobs = output.X(:,I.pla) ...
                   + output.X(:,I.int) ...
                   + output.X(:,I.bnd) ...
                   ... + output.X(:,I.GItract) ...
                   + output.X(:,I.IVbag) ...
                   + output.X(:,I.metab);            
        otherwise
            yobs = [];
    end
end

