% Test implementation of permeability limited model against well-stirred
% model (limit case of large permeability)

%% Test limit case (cellPerm --> Inf)

% define observables
organs = {'adi','bon','bra','gut','hea','kid','liv','lun','mus','ski','spl'};
obs = Observable('PBPK',organs,'tot','total','Mass/Volume');

% define individuals
indv = Individual('Virtual',2);

refphys  = Physiology('human35m');

% define sampling (S), dosing (D), physiology (P), model (M)
indv(1).name        = 'Permeability limited';
indv(1).physiology  = refphys; 
indv(1).dosing      = Infusion('Lidocaine', 0*u.h, 60*u.mg, 1*u.h, 'iv'); 
indv(1).sampling    = Sampling((0:0.1:10)*u.h, obs);
indv(1).model       = sMD_PBPK_12CMT_permeabilityLimited; 
indv(1).model.options.tissuePartitioning = @rodgersrowland;
indv(1).drugdata    = loaddrugdata('Lidocaine','species','human');
updaterecord(indv(1).drugdata, 'cellPerm','human', u.km/u.sec); % extremely large permeability (permeability-limited model should equal well-stirred model)

indv(2)             = clone(indv(1));
indv(2).name        = 'Well-stirred';
indv(2).model       = sMD_PBPK_12CMT_wellstirred; 
indv(2).model.options.tissuePartitioning = @rodgersrowland;
%indv(2).drugdata    = loaddrugdata('Lidocaine','species','human');

initialize(indv);
simulate(indv);

C_permlim = indv(1).observation.Value;
C_wellst  = indv(2).observation.Value;

relErr = abs((C_permlim - C_wellst) ./ C_wellst);

% don't test at initial condition, where relErr is NaN
assert(all(relErr((length(organs)+1):end) < 1e-6))


%% Long-term infusion --> steady-state according to tissue partitioning

% define the dose
Dose = 1*u.g;

% observables
org = {'lun','adi','hea','kid','mus','bon','ski','gut','spl','liv'};
excObs = Observable('PBPK',org,'exc','total','Mass/Volume');
celObs = Observable('PBPK',org,'cel','total','Mass/Volume');
plaObs = Observable('PBPK','ven','vas','total','Mass/Volume');
allObs = [excObs celObs plaObs];

% define a simulation
indv = Individual('Virtual');
indv.name        = 'Well-stirred';
indv.physiology  = Physiology('human35m'); 
indv.dosing      = Infusion('Lidocaine', 0*u.day, Dose, 10*u.day, 'iv'); 
indv.sampling    = Sampling([0 9 10]*u.day, allObs);
indv.model       = sMD_PBPK_12CMT_permeabilityLimited; 
indv.model.options.tissuePartitioning = @rodgersrowland;
indv.drugdata    = loaddrugdata('Lidocaine','species','human');
updaterecord(indv(1).drugdata, 'cellPerm','human', u.m/u.sec); % extremely large permeability (permeability-limited model should equal well-stirred model)

initialize(indv);
simulate(indv);

% expected output: plasma concentration remains constant
Cvas = filter(indv.observation, 'Observable',plaObs);

assert(double(Cvas.Value(end)-Cvas.Value(end-1)) < 1e-15)

% expected: concentration ratio close to elimination-corrected partition coefficients
Cexc = filter(indv.observation, 'Observable', excObs);
Ccel = filter(indv.observation, 'Observable', celObs);
Kexc_ref = indv.model.setup.eK.exc(1:10);
Kcel_ref = indv.model.setup.eK.cel(1:10);
Kexc_obs = Cexc.Value(Cexc.Time == max(Cexc.Time)) ./ Cvas.Value(end);
Kcel_obs = Ccel.Value(Ccel.Time == max(Ccel.Time)) ./ Cvas.Value(end);

assert( all(abs(Kexc_ref - Kexc_obs) < 1e-10, 'all') )
assert( all(abs(Kcel_ref - Kcel_obs) < 1e-10, 'all') )


