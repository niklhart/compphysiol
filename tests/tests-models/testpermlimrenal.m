% Test implementation of permeability limited model with renal CL against 
% permeability-limited model

%% Test limit case (GFR == 0)

% TODO: I'll have to check what is the issue here. It might be that the CL
% model is not correct yet...!?

% define observables
organs = {'adi','bon','gut','hea','kid','liv','lun','mus','ski','spl'};
obs = Observable('PBPK',organs,'tot','total','Mass/Volume');

% define individuals
indv = Individual(2,'Virtual');

refphys  = Physiology('human35m');
addrecord(refphys,'GFR',0*u.L/u.h)

drug = loaddrugdata('Lidocaine','species','human');
updaterecord(drug, 'cellPerm','human', u.cm/u.h); 
addrecord(drug, 'Freabs', 'human',0)

% define sampling (S), dosing (D), physiology (P), model (M)
indv(1).name        = 'With renal CL (GFR = 0)';
indv(1).physiology  = refphys; 
indv(1).dosing      = Infusion('Lidocaine', 0*u.h, 60*u.mg, 1*u.h, 'iv'); 
indv(1).sampling    = Sampling((0:0.1:10)*u.h, obs);
indv(1).model       = sMD_PBPK_12CMT_permLim_renalCL; 
indv(1).model.options.tissuePartitioning = @rodgersrowland;
indv(1).drugdata    = drug;

indv(2)             = clone(indv(1));
indv(2).name        = 'Model without renal CL';
indv(2).model       = sMD_PBPK_12CMT_permeabilityLimited; 
indv(2).model.options.tissuePartitioning = @rodgersrowland;

initialize(indv);
simulate(indv);

C_renal = indv(1).observation.record.Value;
C_permlim  = indv(2).observation.record.Value;

relErr = abs((C_renal - C_permlim) ./ C_permlim);

% don't test at initial condition, where relErr is NaN
assert(all(relErr((length(organs)+1):end) < 1e-12))

