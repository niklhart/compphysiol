%KRIPPENDORF_C Krippendorff model "C" for receptor-mediated endocytosis
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


function model = Krippendorff_C(phys, drug, par, options)

    model = initialize(phys, drug, par, options);
    model.rhsfun  = @rhsfun;
    model.obsfun  = @obsfun;

end

function model = initialize(~, drug, par, ~)
    
    % assertions (model validity): 
    assert(isscalar(drug), 'Model not defined for multiple drugs.')

    % state indexing
    
    I = initcmtidx('pla','ex',...'GItract',   % NH add GI tract in future version?
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
    X0(I.ex)     = 0*doseunit / (u.L/u.kg);
%    X0(I.GItract) = 0*doseunit;
    X0(I.IVbag)   = 0*doseunit;
    X0(I.IVrate)  = 0*doseunit / u.min;
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
    C_pla         = X(I.pla); 
    C_ex         = X(I.ex);
%    A_GItract     = X(I.GItract); 
    infusion_rate = X(I.IVrate);
    
    % parameters
    par = model.par;
    
    KM = par.KM; 
    Vi = par.Vint;
    Vp = par.Vpla;
    q12 = par.kpi*Vp;
    q21 = par.kip*Vi;
    Vmax = par.Bmax*par.kdeg;
    CLlin = par.klin*Vp;
    
    
    %%% -----------------------------------------------------------------------
    %%% START OF ODEs

    
%    % GI tract compartment
%    dA_GItract = -par(Ip.lambda_po)*A_GItract;

    % plasma compartment
    VdC_pla = q21*C_ex - q12*C_pla - CLlin*C_pla + infusion_rate;

    % interstitial compartment
    VdC_ex = -(Vmax * C_ex)/(KM+C_ex) - q21*C_ex + q12*C_pla;

    % drug amount in IVbag for infusion
    dA_IVbag = -infusion_rate;

    % drug amount metabolized or excreted
    dA_metab = (Vmax * C_ex)/(KM+C_ex);

    %%% END OF ODEs
    %%% -----------------------------------------------------------------------

    % converting amounts to concentrations
    dC_pla = VdC_pla ./ Vp;
    dC_ex = VdC_ex ./ Vi;

    % output vector (always in column vector notation)
    dX(I.pla)  = dC_pla;
    dX(I.ex) = dC_ex;

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
            yobs = output.X(:,I.pla);
        case 'massBalance'
            yobs = output.X(:,I.pla) .* model.par.Vpla ...
                   + output.X(:,I.ex) .* model.par.Vint ...
                   + output.X(:,I.GItract) ...
                   + output.X(:,I.IVbag) ...
                   + output.X(:,I.metab);            
        otherwise
            yobs = [];
    end
end

