% Tutorial "Parameter estimation"

%% Load experimental data and visualize the initial guess

% experimental dataset
data = ImportableData('data/Warfarin_Holford1986.csv','Delimiter',',');
data.maprow('Species','Covariate');
data.maprow('Warfarin oral dose','Oral dosing','Compound','Warfarin');
data.maprow('Warfarin plasma concentration','Record','Site','pla');
expid = import(data)

% virtual individual
simid = Individual('Virtual');
simid.name = 'Initial guess';
simid.dosing    = expid.dosing;
simid.drugdata  = loaddrugdata('Warfarin','species','human');
simid.sampling  = Sampling([0 36]*u.h);
simid.model.fun = @empirical1CMT_PLASMA_macroConstants_linearCL;
simid.model.par = parameters(...
    'V',          15*u.L, ...          
    'CL',         0.3*u.L/u.h, ...     
    'lambda_po',  1.5/u.h, ...         
    'F',          1);

[simid.model]       = initialize(simid);
[simid.output]      = simulate(simid);
[simid.observation] = observe(simid);

plot([expid simid],'plasmaConcentration','group_by','Name')

%% Estimation using method 'estimate()'

% virtual individual for specifying the estimation task
estid = Individual('Virtual');

estid.model.fun  = @empirical1CMT_PLASMA_macroConstants_linearCL;

% convert Observable type 'ExpData' to 'SimplePK'
obs  = Observable('SimplePK','pla','total','Mass/Volume');
expid.observation.record.Observable(:) = obs;
estid.estim.data = expid;

estid.estim.parinit = simid.model.setup.par;         % TODO: not ideal that par is shifted one level up during initialization
estid.estim.options = estimset('fixed',{'F'});

estid.estim = estimate(estid);

% plot estimation result
estid.model.par = estid.estim.parestim;
estid.sampling  = simid.sampling;
estid.dosing    = simid.dosing;
estid.name = 'Fitted parameters';

[estid.model]  = initialize(estid);
[estid.output] = simulate(estid);
[estid.observation] = observe(estid);

plot([expid estid simid],'plasmaConcentration')

%% Goodness-of-fit plots

rtab = residuals(estid.model, expid)

% residual plot
figure()
plot(rtab.Time,rtab.Residuals,'+',rtab.Time,0*rtab.Residuals,'--')
title('Residuals')

% obs-vs-pred plot
figure()
plot(rtab.Prediction,rtab.Observation,'+',rtab.Prediction,rtab.Prediction,'--')
title('Obs vs pred')
