% Testing observables for the 1-CMT model

%% Amount per Volume observable in 1-CMT model - FAILS

%TODO: implement this observable, test not working yet
indv = Individual(1,'Virtual');

obs = Observable('SimplePK','pla','total','Amount/Volume');

%indv.physiology = Physiology('human35m'); 
indv.dosing     = Oral('Warfarin', 0*u.h, 15*u.mg);
indv.sampling   = Sampling([0 36]*u.h, obs); 
indv.model      = empirical1CMT_PLASMA_macroConstants_linearCL;
indv.model.par  = parameters(...
    'V',          10*u.L, ...
    'CL',         0.2*u.L/u.h, ...
    'lambda_po',  1/(0.385*u.h), ...
    'F',          1);

initialize(indv);
simulate(indv);

assert(~isempty(indv.observation))


