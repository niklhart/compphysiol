% solutions to all tutorials, in alphabetical order

%% Accessing physiology and drug databases

adult = Physiology('human35m'); % or human35f
child = Physiology('human5u');  % or other ages
rat   = Physiology('rat475');
mouse = Physiology('mouse40');

tissues = {'adi' 'bon' 'bra' 'gut' 'hea' 'kid' 'liv' 'lun' 'mus' 'ski' 'spl'};

OWtis_adult = getvalue(adult, 'OWtis', tissues);
OWtot_adult = sum(OWtis_adult) + getvalue(adult, 'OWtbl');
ratio_adult = OWtot_adult / getvalue(adult, 'BW')

OWtis_child = getvalue(child, 'OWtis', tissues);
OWtot_child = sum(OWtis_child) + getvalue(child, 'OWtbl');
ratio_child = OWtot_child / getvalue(child, 'BW')

OWtis_rat = getvalue(rat, 'OWtis', tissues);
OWtot_rat = sum(OWtis_rat) + getvalue(rat, 'OWtbl');
ratio_rat = OWtot_rat / getvalue(rat, 'BW')

OWtis_mouse = getvalue(mouse, 'OWtis', tissues);
OWtot_mouse = sum(OWtis_mouse) + getvalue(mouse, 'OWtbl');
ratio_mouse = OWtot_mouse / getvalue(mouse, 'BW')

% --> least covered in child (~92%), most in rat (~98%)

%% Defining a dosing scheme

dosing_pneumonia = Infusion('Amoxicillin', 0*u.day:8*u.h:2*u.day+16*u.h, 2.2*u.g, 'iv', 'duration', 30*u.min) ...
    + Oral('Clarithromycin', 0*u.day:12*u.h:2*u.day+12*u.h, 500*u.mg) ...
    + Oral('Amoxicillin', 3*u.day:8*u.h:6*u.day+16*u.h, 1000*u.mg)

%% Defining a physiology

rat1 = Covariates('Species','rat','BW',400*u.g,'sex','male','age',70*u.week)

rat2 = Physiology('rat475')

rat3 = scaling_BW(rat2, rat1)

%% Importing experimental data

% dataset from the tutorial
data = ImportableData('data/Warfarin_Holford1986.csv','Delimiter',',');
data.maprow('Species','Covariate');
data.maprow('Warfarin oral dose','Oral dosing','Compound','Warfarin');
data.maprow('Warfarin plasma concentration','Record','Site','pla');
expid = import(data);

% dataset from the exercise
data2 = ImportableData('data/Warfarin_Holford1986_Variante.csv','Delimiter',',');
data2.maprow('Species','Covariate');
data2.maprow('Oral dose','Oral dosing');
data2.maprow('Concentration','Record');
data2.setattr('Site','SITE')
expid2 = import(data2)

% check for equality
isequal(expid,expid2)


%% Plot customizations

% the Individual array from the tutorial
obs = PBPKobservables();

indv = Individual(2,'Virtual');

indv(1).name = 'Lidocaine (oral)';
indv(1).dosing     = Oral('Lidocaine', 0*u.h, 100*u.mg);
indv(1).drugdata   = loaddrugdata('Lidocaine','species','human');
indv(1).physiology = Physiology('human35m');
indv(1).sampling   = Sampling([0 24]*u.h, obs);
indv(1).model      = sMD_PBPK_12CMT_wellstirred;
indv(1).model.options.tissuePartitioning = @rodgersrowland;

indv(2) = clone(indv(1));
indv(2).name = 'Lidocaine (iv infusion)';
indv(2).dosing = Infusion('Lidocaine', 0*u.h, 100*u.mg, 1*u.h, 'iv');

initialize(indv)
simulate(indv)

% exercise solution
longitudinalplot(indv,...
    'Site',      {'pla','liv'}, ...
    'subplot_by','Name', ...
    'group_by',  'Site',...
    'tunit',     'h',...
    'yunit',     'mg/L',...
    'yscalelog', true, ...
    'title',     'Impact of administration route on uptake',...
    'ylabel',    'Concentration')


%% Working with units

2e-15*u.L*u.NA*u.nM

