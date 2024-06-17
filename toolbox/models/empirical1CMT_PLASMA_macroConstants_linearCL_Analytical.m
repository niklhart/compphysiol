%EMPIRICAL1CMT_PLASMA_MACROCONSTANTS_LINEARCL 1-cmt empirical PK model
%    This function specifies a 1-cmt empirical PK model. Parameters must be
%    specified at the script level, as shown below.
%
%    To execute this model, the following parameters must be defined:
%   
%    CL         [Mass/Volume]  Clearance (from central compartment)
%    V          [Volume]       Volume of distribution (central compartment)
%    lambda_po  [1/Time]       First-order oral absorption rate constant
%    F          [unitless]     Oral bioavailability     

% ========================================================================%
% General structure
% ========================================================================%
function model = empirical1CMT_PLASMA_macroConstants_linearCL_Analytical()

    % Analytical model definition requires initialization and solution 
    % functions. See below for their definition.
    
    model = AnalyticalModel;

    model.initfun = @initfun;
    model.solfun  = @solfun;
    
    model.name = mfilename;
    
end

% ========================================================================%
% Initialization of model
% ========================================================================%
function setup = initfun(~, drug, par, ~)
%INITFUN Initialization of 1-CMT empirical model

    % assertions (model validity): 
    assert(isempty(drug) || isscalar(drug), 'Model not defined for multiple drugs.')
    
    % state indexing
    I = initcmtidx('cen','GItract','IVbag','IVrate','metab');

    % Definition of dosing target struct
    Id = struct;
    
    Id.bolus.iv.cmt     = I.cen;
    Id.bolus.iv.scaling = par.V;
    
    Id.oral.cmt         = I.GItract;

    %%% initial condition and units of ODEs

    doseunit = u.ug;
    
    X0 = initializeX0(I);
    X0(I.cen)     = scd(0*doseunit / u.L,'ug/L');
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
% Analytical solution of the model
% ========================================================================%
function rec = solfun(setup, dosing, sampling)
%SOLFUN Solution function of 1-CMT empirical PK model


    % check that dosing is as expected
    dosTypes = dosingTypes(dosing);
    assert(all(ismember(dosTypes,{'Bolus','Oral'})), 'Only bolus and oral dosing allowed.')
    assert(issetequal(dosTypes,'Bolus'), 'Only bolus dosing allowed (TODO: generalize to oral dosing).')

    % check that sampling is as expected 
    schedule = sampling.schedule;
    CplaObs = Observable('SimplePK','pla','total','Mass/Volume');
    assert(all(schedule.Observable == CplaObs), 'Only plasma concentration observable allowed.')


    % allocate result
    Value = unan(height(schedule),1);

    % observation times
    tObs = schedule.Time;    

    % process bolus dosing
    bolDos = filterDosing(dosing, [], 'Bolus');
    assert(all(strcmp(bolDos.schedule.Target,{'iv'})), ...
        'Bolus dosing target must be "iv".')
    tBolus = bolDos.schedule.Time;
    yBolus = bolDos.schedule.Dose;

    % model parameters
    CL  = setup.par.CL;
    V   = setup.par.V;
    kel = CL/V;
    
    % no drug before first dosing
    Atrough = 0*unitsOf(yBolus);

    % before first dosing cycle
    if any(tObs < min(tBolus))
        Value(tObs < min(tBolus)) = 0*unitsOf(yBolus)/u.L;
    end

    % dosing cycles 1 through n-1
    for i = 1:(numel(tBolus)-1)
        Apeak = Atrough + yBolus(i);
        iscycle_i = tObs >= tBolus(i) & tObs < tBolus(i+1);
        Value(iscycle_i) = Apeak * exp(-kel * (tObs(iscycle_i) - tBolus(i))) / V;
        Atrough = Apeak * exp(-kel * (tBolus(i+1) - tBolus(i)));
    end

    % last dosing cycle
    Apeak = Atrough + yBolus(end);
    isLastCycle = tObs >= tBolus(end);
    Value(isLastCycle) = Apeak * exp(-kel * (tObs(isLastCycle) - tBolus(end))) / V;

    % return a Record object
    rec = Record([schedule table(Value)]);

end

