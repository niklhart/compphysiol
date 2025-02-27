% test model lumping function

%% Empty or atomic partitioning should leave the model unchanged

tis = {'pla','liv','mus'};
obs = Observable('SimplePK',tis,'','');
m = test_3cmt_model();
l1 = lump_model(m, {});
l2 = lump_model(m, arrayfun(@(x){x}, tis));

indv = Individual(3,'Virtual');

indv(1).dosing     = Bolus('test',0*u.h,1*u.mg,'iv');
indv(1).sampling   = Sampling((0:24)*u.h, obs);
indv(1).model      = m;

indv(2) = clone(indv(1));
indv(2).model      = l1;

indv(3) = clone(indv(1));
indv(3).model      = l2;

initialize(indv)
simulate(indv)

% observations of all three models
A_full  = indv(1).observation.record.Value;
A_lump1 = indv(2).observation.record.Value;
A_lump2 = indv(3).observation.record.Value;

% compute relative errors
relErr1 = abs((A_full - A_lump1) ./ A_full);
relErr2 = abs((A_full - A_lump2) ./ A_full);

% small numerical tolerance
assert(all(relErr1 < 1e-14))
assert(all(relErr2 < 1e-14))


%% Lumping peripheral compartments in 3CMT test model should be exact 

tis = {'pla','liv','mus'};
obs = Observable('SimplePK',tis,'','');
m = test_3cmt_model();
l = lump_model(m, {{'liv','mus'}});

indv = Individual(2,'Virtual');

indv(1).dosing     = EmptyDosing();
indv(1).sampling   = Sampling((0:24)*u.h, obs);
indv(1).model      = m;

indv(2) = clone(indv(1));
indv(2).model      = l;

initialize(indv)
simulate(indv)

% observations of all three models
A_full = indv(1).observation.record.Value;
A_lump = indv(2).observation.record.Value;

% compute relative errors
relErr = abs((A_full - A_lump) ./ A_full);

% small numerical tolerance
assert(all(relErr < 1e-7))


%% Lumping of 12CMT well-stirred model

obs = PBPKobservables();
m = sMD_PBPK_12CMT_wellstirred();
l = lump_model(m, {{'art','lun','ven'}});

indv = Individual(2,'Virtual');

indv(1).dosing     = Bolus('Warfarin',0*u.h,1*u.mg,'iv');
indv(1).drugdata   = loaddrugdata('Warfarin','species','human');
indv(1).physiology = Physiology('human35m');
indv(1).sampling   = Sampling((0:24)*u.h, obs);
indv(1).model      = m;
indv(1).model.options.tissuePartitioning = @rodgersrowland;

indv(2) = clone(indv(1));
indv(2).model      = l;
indv(2).model.options.tissuePartitioning = @rodgersrowland;

initialize(indv)
simulate(indv)

% observations of all three models
A_full = indv(1).observation.record.Value;
A_lump = indv(2).observation.record.Value;

% compute relative errors
relErr = abs((A_full - A_lump) ./ A_full);

% small numerical tolerance
assert(all(relErr(12:end) < 1e-4))

%% Lumping of 12-CMT permeability-limited model

organs = {'adi','bon','gut','hea','kid','liv','lun','mus','ski','spl'};

obs = [Observable('PBPK',organs,'cel','total','Mass/Volume');
       Observable('PBPK',organs,'exc','total','Mass/Volume');
       Observable('PBPK','ven','exc','total','Mass/Volume')];

m = sMD_PBPK_12CMT_permeabilityLimited();
l = lump_model(m, {{'art','lun-exc','ven'}});

indv = Individual(2,'Virtual');

indv(1).dosing     = Bolus('Warfarin', 0*u.h, 60*u.mg, 'iv'); 
indv(1).drugdata   = loaddrugdata('Warfarin','species','human');
indv(1).physiology = Physiology('human35m');
indv(1).sampling   = Sampling((0:24)*u.h, obs);
indv(1).model      = m;
indv(1).model.options.tissuePartitioning = @rodgersrowland;
P = predict_perm(indv(1).drugdata,'cellular');
addrecord(indv(1).drugdata,'cellPerm','human',P,[],'Predicted by PK-Sim formula');


indv(2) = clone(indv(1));
indv(2).model = l;
indv(2).model.options.tissuePartitioning = @rodgersrowland;

initialize(indv);
simulate(indv);

% observations of all three models
A_full = indv(1).observation.record.Value;
A_lump = indv(2).observation.record.Value;

% compute relative errors
relErr = abs((A_full - A_lump) ./ A_full);

% small numerical tolerance
assert(all(relErr(22:end) < 1e-3))

