% Test implementation of permeability limited model against well-stirred
% model (limit case of large permeability)

%% Test limit case (cellPerm --> Inf)

% define observables
organs = {'adi','bon','bra','gut','hea','kid','liv','lun','mus','ski','spl'};
obs = Observable('PBPK',organs,'tot','total','Mass/Volume');

% define individuals
indv = Individual(2,'Virtual');

refphys  = Physiology('human35m');

% define sampling (S), dosing (D), physiology (P), model (M)
indv(1).name        = 'Permeability limited';
indv(1).physiology  = refphys; 
indv(1).dosing      = Infusion('Lidocaine', 0*u.h, 60*u.mg, 1*u.h, 'iv'); 
indv(1).sampling    = Sampling((0:0.1:10)*u.h, obs);
indv(1).model       = sMD_PBPK_12CMT_permeabilityLimited; 
indv(1).model.options.tissuePartitioning = @rodgersrowland;
indv(1).drugdata    = loaddrugdata('Lidocaine','species','human');
addrecord(indv(1).drugdata, 'cellPerm','human', u.km/u.sec); % extremely large permeability (permeability-limited model should equal well-stirred model)

indv(2)             = clone(indv(1));
indv(2).name        = 'Well-stirred';
indv(2).model       = sMD_PBPK_12CMT_wellstirred; 
indv(2).model.options.tissuePartitioning = @rodgersrowland;
%indv(2).drugdata    = loaddrugdata('Lidocaine','species','human');

initialize(indv);
simulate(indv);

C_permlim = indv(1).observation.record.Value;
C_wellst  = indv(2).observation.record.Value;

relErr = abs((C_permlim - C_wellst) ./ C_wellst);

% don't test at initial condition, where relErr is NaN
assert(all(relErr((length(organs)+1):end) < 1e-6))

