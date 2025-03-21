% test compileplottable

indv = Individual('Virtual');
indv.model = test_model();
indv.sampling = Sampling([0 1 2]*u.h, Observable('MultiPK', ...
    {'A','B','A','B'},{'pla','pla','tis','tis'}));
indv.name = 'Ind1';

initialize(indv);
simulate(indv);

%% Correct usage

% no filtering by site
tab1 = compileplottable(indv);
tab2 = compileplottable(indv, []);
assert(isequal(size(tab1), [12 9]))
assert(isequal(tab1,tab2))

% filtering by site
tab3 = compileplottable(indv, struct('Site','pla'));
assert(isequal(size(tab3), [6 9]))

%% Empty Individual

% Using with not initialized individual
indv2 = Individual('Virtual');
assertError(@() compileplottable(indv2), ...
    'compphysiol:Individual:checkSimulatedOrExperimental:notSimOrExp')

%% Individual with empty name
% TODO: switch to test model
Dose = 60*u.mg;

obs = Observable('PBPK', {'ven','mus','ven','mus'}, ...
    {'tot','tot','vas','vas'}, 'total', 'Mass/Volume');

indv = Individual('Virtual');
indv.name        = 'Well-stirred';
indv.physiology  = Physiology('human35m'); 
indv.dosing      = Bolus('Lidocaine', 0*u.h, Dose, 'iv'); 
indv.sampling    = Sampling((0:10)*u.day, obs);
indv.model       = sMD_PBPK_12CMT_wellstirred; 
indv.model.options.tissuePartitioning = @rodgersrowland;
indv.drugdata    = loaddrugdata('Lidocaine','species','human');

initialize(indv);
simulate(indv);

indv.name = '';
tab4 = compileplottable(indv, struct('Site','ven'));
assert(isequal(tab4.Name, repmat({'Lidocaine:human:male:35 year:73 kg'},22,1)))


