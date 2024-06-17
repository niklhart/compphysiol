%KRIPPENDORF_B Krippendorff model "B" for receptor-mediated endocytosis
%    Add description
%   
%    Reference: 
%       Krippendorff et al, "Nonlinear pharmacokinetics of therapeutic 
%       proteins resulting from receptor mediated endocytosis"
%       Link to publication: doi.org/10.1007/s10928-009-9120-1
%
%    Model parameters:
%       kb     (rate)
%       kpi    (rate)
%       kip    (rate)
%       Vint   (volume per weight) 
%       Vpla   (volume per weight)
%       klin   (rate)
%       kdeg   (rate)
%       KM     (mass per volume?)
%       Bmax   (mass per weight)


function model = Krippendorff_B(phys, drug, par, options)

    model = struct;

    model.setup  = initialize(phys, drug, par, options);
    model.rhsfun = @rhsfun;
    model.obsfun = @obsfun;

    model.name   = mfilename;
end

function setup = initialize(~, drug, par, ~)
    
    % assertions (model validity): 
    assert(isscalar(drug), 'Model not defined for multiple drugs.')
    
    % state indexing
    
    I = initcmtidx('pla','int',...'GItract',   % NH add GI tract in future version?
        'IVbag','IVrate','metab');
    
    
    % Definition of dosing target struct
    Id = struct;
    
    Id.bolus.iv.cmt     = I.pla;
    Id.bolus.iv.scaling = par.Vpla;
    
    Id.infusion.iv.bag  = I.IVbag;
    Id.infusion.iv.rate = I.IVrate;
   
%    Id.oral.cmt         = I.GItract;

    %%% initial condition and units of ODEs

    doseunit = u.ug/u.kg;
    
    X0 = initializeX0(I);
    X0(I.pla)     = 0*doseunit / (u.L/u.kg);
    X0(I.int)     = 0*doseunit / (u.L/u.kg);
%    X0(I.GItract) = 0*doseunit;
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
function dX = rhsfun(t, X, setup)

    % initialize output vector
    X = X(:);
    dX = NaNsizeof(X);
    
    % state indexing
    I  = setup.indexing.I; 
    
    % variables (always use column vector notation)
    C_pla         = X(I.pla); 
    C_int         = X(I.int);
%    A_GItract     = X(I.GItract); 
    infusion_rate = X(I.IVrate);
    
    % parameters
    par = setup.par;
    
    KM    = par.KM; 
    Vi    = par.Vint;
    Vp    = par.Vpla;
    q12   = par.kpi*Vp;
    q21   = par.kip*Vi;
    Bmax  = par.Bmax/Vi;
    CLlin = par.klin*Vp;
    CLrs  = par.kdeg*Vi;

    %%% -----------------------------------------------------------------------
    %%% START OF ODEs

    C_ex = (1/2)*((C_int-Bmax-KM)+sqrt((C_int-Bmax-KM)^2+4*KM*C_int));
    C_rs = C_ex * Bmax /(KM + C_ex);

    
%    % GI tract compartment
%    dA_GItract = -par(Ip.lambda_po)*A_GItract;

    % plasma compartment
    VdC_pla = q21*C_ex - q12*C_pla - CLlin*C_pla + infusion_rate;

    % interstitial compartment
    VdC_int = - CLrs * C_rs - q21*C_ex + q12*C_pla;

    % drug amount in IVbag for infusion
    dA_IVbag = -infusion_rate;

    % drug amount metabolized or excreted
    dA_metab = CLrs * C_rs;

    %%% END OF ODEs
    %%% -----------------------------------------------------------------------

    % converting amounts to concentrations
    dC_pla = VdC_pla ./ Vp;
    dC_int = VdC_int ./ Vi;

    % output vector (always in column vector notation)
    dX(I.pla)  = dC_pla;
    dX(I.int) = dC_int;

%    dX(I.GItract) = dA_GItract;
    dX(I.metab)   = dA_metab;
    dX(I.IVbag)   = dA_IVbag;
    dX(I.IVrate)  = 0 * unitsOf(X(I.IVrate) / t);

    
end

% Old version of obsfun. TODO Delete once scripts are running.
% %% Observation function
% function yobs = obsfun(output, setup, type)
%     
%     I  = setup.indexing.I;
% 
%     switch type
%         case 'Cpla'
%             yobs = output.X(:,I.pla);
%         case 'massBalance'
%             yobs = output.X(:,I.pla) .* setup.par.Vpla ...
%                    + output.X(:,I.int) .* setup.par.Vint ...
%                    + output.X(:,I.GItract) ...
%                    + output.X(:,I.IVbag) ...
%                    + output.X(:,I.metab);            
%         otherwise
%             yobs = [];
%     end
% end
% ========================================================================%
% Definition of observable quantities
% ========================================================================%
function yobs = obsfun(output, setup, obs)
%OBSFUN Observables in Krippendorff model B
%   The following observables are supported:
%     
%   Type 'SimplePK':
%       Site:     'pla'
%       Binding:  'total'
%       UnitType: '1/Volume'
%    
%   Type 'MassBalance':
%       UnitType: 'unitless'

    I  = setup.indexing.I;

    yobs = []; % if obs matches a case below, yobs will be overwritten
    
    switch obs.type
        case 'SimplePK'            
            if strcmp(obs.attr.Site, 'pla') && ...
                    strcmp(obs.attr.Binding,'total') && ...
                    strcmp(obs.attr.UnitType,'1/Volume')      %TODO: Amount/(Volume*Mass) not working yet (MW not needed in general...)
                yobs = output.X(:,I.pla);
            end
                       
        case 'massBalance'
            if strcmp(obs.attr.UnitType,'unitless')                
                yobs = output.X(:,I.pla) .* setup.par.Vpla ...
                   + output.X(:,I.int) .* setup.par.Vint ...
                   + output.X(:,I.GItract) ...
                   + output.X(:,I.IVbag) ...
                   + output.X(:,I.metab);        
            end
    end
end
