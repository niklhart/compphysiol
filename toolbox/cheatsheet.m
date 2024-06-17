% Code for the toolbox cheatsheet

%% %% Basics

%% Getting started
initPBPKtoolbox

%% Toolbox help
help scaling_LBW     % function
help Bolus           % class
help Bolus/compounds % method
help sMD_PBPK_12CMT_wellstirred>obsfun % available model predictions

%% %% Working with units
%% Arithmetics

V1 = 10*u.L;
V2 = 20*u.L;
V  = V1+V2   % 30 L

BW = 70*u.kg;
BH = 1.80*u.m;
BMI= BW/BH^2 % ~22 kg/m2

V1 + 5   % Error
log(V1)  % Error

BW + BH  % Error

%% Set custom display

scd(5*u.L,'mL')   % 5000 mL 
scd(5*u.L,'kg')   % Error

%% Arrays

% homogeneous
[V1 V2]
[V1;V2]

% heterogeneous
[BW BH BMI]
[BW;BH;BMI]

%% %% Main components of Individual objects
%% Dosing

% Single dose
d1 = Oral('Drug X', 0*u.h, 5*u.mg)
d2 = Bolus('Drug X', 0*u.h, 5*u.mg, 'iv')
d3 = Infusion('Drug X',0*u.h,5*u.mg,1*u.h,'iv') 

% Multiple dosing
d4 = Oral('Drug X', [0 8 16]*u.h, 5*u.mg)
d5 = Oral('Drug X', [0 8]*u.h, [10 5]*u.mg)

% Complex dosing
d = d1 + d2 + d3

%% Sampling

% Observable
obs = Observable('SimplePK','pla','total','Mass/Volume');

% Sampling schedule s
s1 = Sampling([0 24]*u.h, obs)        % timespan
s2 = Sampling([0 1 2 4 8]*u.h, obs)   % exact timepoints


%% Physiology

% Basic covariates
p1 = Covariates('Species', 'human', ...  
    'BW', 70*u.kg, 'BH', 1.80*u.m, ...
    'age', 35*u.year, 'sex', 'male')
    
% Detailed physiology (reference individual)
p2 = Physiology('human35m')

% Scaling from reference to target individual
p3 = scaling_LBW(p2, p1)

%% Importing experimental data

data = ImportableData('data/Warfarin_Holford1986.csv','Delimiter',',');
data.maprow('Species','Covariate');
data.maprow('Warfarin oral dose','Oral dosing','Compound','Warfarin');
data.maprow('Warfarin plasma concentration','Record','Site','pla');
expid = import(data)
    
%% Simulating a virtual individual

% Allocation
simid      = Individual('Virtual');
simid.name = 'Warfarin 12-CMT';

% Design of simulation
obs = PBPKobservables();
simid.physiology = Physiology('human35m');
simid.dosing     = Oral('Warfarin', 0*u.h, 15*u.mg);
simid.drugdata   = loaddrugdata('Warfarin','species','human');
simid.sampling   = Sampling([0 24]*u.h, obs);

% Model specification
simid.model      = sMD_PBPK_12CMT_wellstirred;
simid.model.options.tissuePartitioning = @rodgersrowland;

% Solving the differential equations
initialize(simid)
simulate(simid)

% Default plots
plot(simid,'yunit','mg/L')

%% Plotting

% Specific default plot (see file plottemplate.m)
plot([expid simid],'plasmaConcentration')

% Customization
plot([expid simid],'plasmaConcentration', ...
    'tunit','min', ...
    'yscalelog',true)

% Low-level plotting
longitudinalplot([expid simid],...
    'Site',     'pla', ...
    'UnitType', 'Mass/Volume', ...
    'group_by', 'Name', ...
    'xlabel',   'Time', ...
    'ylabel',   'Conc.', ...
    'title',    'Plasma concentration')

%% Estimation

% Allocation/model specification
estid = Individual('Virtual');
estid.model = empirical1CMT_PLASMA_macroConstants_linearCL;

% convert Observable type 'ExpData' to 'SimplePK'
obs  = Observable('SimplePK','pla','total','Mass/Volume');
expid.observation.record.Observable(:) = obs;

% Experimental data
estid.estim.data = expid;

% Initial guess and estimation options
estid.estim.parinit = parameters(...
    'V',          15*u.L, ...
    'CL',         0.3*u.L/u.h, ...
    'lambda_po',  1.5/u.h, ...
    'F',          1);
estid.estim.options = estimset('fixed',{'F'});

% Run estimation task
estimate(estid);




