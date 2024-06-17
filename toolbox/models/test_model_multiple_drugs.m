%TEST_MODEL_MULTIPLE_DRUGS Multi-drug/output model to test toolbox design
%    This function specifies a model for two different drugs, as well as PK
%    and PD outputs. The output returned is only used for testing purposes
%    and has no physiological meaning.

% ========================================================================%
% General structure
% ========================================================================%
function model = test_model_multiple_drugs(~, drug, ~, ~)

    % a model definition requires three parts: 
    % initialization, ODEs and output. See below for their definition
    model = struct;

    model.setup  = initfun([], drug, [], []);
    model.rhsfun = @rhsfun;
    model.obsfun = @obsfun;
    
    model.name = mfilename;
    
end

% ========================================================================%
% Initialization of model
% ========================================================================%
function setup = initfun(~, drug, ~, ~)
%INITFUN Initialization of test model

    % assertions (model validity): 
    assert(numel(drug) == 2, 'Two drugs must be defined for this model.')
    cpds = {drug.name};

    % state indexing
    
    I = struct;
    I.(cpds{1}) = initcmtidx('cen','GItract','IVbag','IVrate','metab');
    I.(cpds{2}) = structfun(@(x) x+5,I.(cpds{1}),'UniformOutput',false); %TODO: eleganter!

    % definition of model parameters -- all are assumed known :-)
    par = parameters(...
        'V', u.L,...
        'CL',u.L/u.h,...
        'lambda_po',1/u.h,...
        'F', 1 ...
    );               
               
    % Definition of dosing target struct
    Id = struct;
    
    for i = 1:2
        Id.(cpds{i}).bolus.iv.cmt     = I.(cpds{i}).cen;
        Id.(cpds{i}).bolus.iv.scaling = par.V;

        Id.(cpds{i}).infusion.iv.bag  = I.(cpds{i}).IVbag;
        Id.(cpds{i}).infusion.iv.rate = I.(cpds{i}).IVrate;

        Id.(cpds{i}).oral.cmt         = I.(cpds{i}).GItract;
    end
        
    %%% initial condition and units of ODEs

    doseunit = u.ug;
    
    X0 = initializeX0(I);
    for i = 1:2
        X0(I.(cpds{i}).cen)     = scd(0*doseunit / u.L,'ug/L');
        X0(I.(cpds{i}).GItract) = 0*doseunit;
        X0(I.(cpds{i}).IVbag)   = 0*doseunit;
        X0(I.(cpds{i}).IVrate)  = 0*doseunit / u.min;
        X0(I.(cpds{i}).metab)   = 0*doseunit;
    end
    % -----------------------------------------------------------------------
    % Assign model parameters 
    setup = struct;
    setup.indexing.I  = I;
    setup.indexing.Id = Id;
    setup.par         = par;
    setup.compounds   = cpds;
    setup.X0          = X0;
    
end


% ========================================================================%
% ODE system of the model
% ========================================================================%
function dX = rhsfun(t, X, setup) % t will be used for infusion rate
%RHSFUN ODE system of two 1-CMT empirical PK models

    % initialize output vector
    X = X(:);
    dX = NaNsizeof(X);
    
    % state indexing
    I = setup.indexing.I; 
    I1 = I.(setup.compounds{1});
    I2 = I.(setup.compounds{2});
    
    % variables (always use column vector notation)
    C_cen1         = X(I1.cen); 
    C_cen2         = X(I2.cen); 
    A_GItract1     = X(I1.GItract); 
    A_GItract2     = X(I2.GItract); 
    infusion_rate1 = X(I1.IVrate);
    infusion_rate2 = X(I2.IVrate);
    
    % parameters
    par = setup.par;

    %%% -----------------------------------------------------------------------
    %%% START OF ODEs

    % GI tract compartments
    dA_GItract1 = -par.lambda_po * A_GItract1;
    dA_GItract2 = -par.lambda_po * A_GItract2;

    % central compartments
    VdC_cen1 = par.F * par.lambda_po * A_GItract1 ...
              - par.CL * C_cen1 ...
              + infusion_rate1;
    VdC_cen2 = par.F * par.lambda_po * A_GItract2 ...
              - par.CL * C_cen2 ...
              + infusion_rate2;

    % drug amounts in IVbags for infusion
    dA_IVbag1 = -infusion_rate1;
    dA_IVbag2 = -infusion_rate2;

    % drug amounts metabolized or excreted
    dA_metab1 = par.CL * C_cen1;
    dA_metab2 = par.CL * C_cen2;

    %%% END OF ODEs
    %%% -----------------------------------------------------------------------

    % converting amounts to concentrations
    dC_cen1 = VdC_cen1 ./ par.V;
    dC_cen2 = VdC_cen2 ./ par.V;

    % output vector (always in column vector notation)
    dX(I1.cen)     = dC_cen1;
    dX(I2.cen)     = dC_cen2;
    dX(I1.GItract) = dA_GItract1;
    dX(I2.GItract) = dA_GItract2;
    dX(I1.metab)   = dA_metab1;
    dX(I2.metab)   = dA_metab2;
    dX(I1.IVbag)   = dA_IVbag1;
    dX(I2.IVbag)   = dA_IVbag2;
    dX(I1.IVrate)  = 0 * unitsOf(X(I1.IVrate) / t);
    dX(I2.IVrate)  = 0 * unitsOf(X(I2.IVrate) / t);

end

% ========================================================================%
% Definition of observable quantities
% ========================================================================%
function yobs = obsfun(output, setup, obs)
%OBSFUN Observables in test model
%   The following observables are supported:
%     
%   Type 'MultiPK':
%       Site:  'pla'
%       Drug:  both defined drugs
%    
%   Type 'PD'
%       (no attributes)

    I  = setup.indexing.I;

    yobs = []; % if obs matches a case below, yobs will be overwritten
    
    switch obs.type
            
        case 'MultiPK'
            if strcmp(obs.attr.Site, 'pla') && ...
                    any(strcmp(obs.attr.Drug, setup.compounds))
                
                % Multi drug implemented as multi-level index structure
                yobs = output.X(:,I.(obs.attr.Drug).cen); 
    
            end
                       
        case 'PD'
            if strcmp(obs.attr.Name, 'ReceptorSaturation')
                cpds = setup.compounds{1};
                Ctot = output.X(:,I.(cpds{1}).cen) + output.X(:,I.(cpds{2}).cen);
                yobs = Ctot ./ (setup.EC50 + Ctot);             
            end
    end
end