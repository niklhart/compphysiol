% Tests for empirical1CMT_PLASMA_macroConstants_linearCL
% 
% The computed numerical solution is tested against known analytical 
% solutions

% common part
tmp = Individual('Virtual');

p = parameters(...
    'V',          1*u.L, ...
    'CL',         1*u.L/u.h, ...
    'lambda_po',  2/u.h, ...
    'F',          1);
t = (1:0.1:36)'*u.h;
d = 15*u.mg;

obs = Observable('SimplePK','pla','total','Mass/Volume');

tmp.drugdata   = loaddrugdata('Warfarin');
tmp.sampling   = Sampling(t, obs); 
tmp.model      = empirical1CMT_PLASMA_macroConstants_linearCL;
tmp.model.par  = p;


%% Test empty dosing vs analytical solution

indv = clone(tmp);
indv.dosing = EmptyDosing;

initialize(indv);
simulate(indv);

num = indv.observation.record.Value; % numerical solution

% assertions: 
assert(isequal(size(num),size(t)))  % numerical approx. equal to reference?
assert(istype(num,'Mass/Volume'))   % correct unit type
assert(nnz(num) == 0)               % all-zero solution

%% Test bolus dosing vs analytical solution

indv = clone(tmp);
indv.dosing = Bolus('Warfarin', 0*u.h, d, 'iv');

initialize(indv);
simulate(indv);

num = indv.observation.record.Value; % numerical solution
ref = (d/p.V)*exp(-(p.CL/p.V)*t);    % reference solution

% assertions: numerical approx. equal to reference?
assert(isequal(size(ref),size(num)))

absErr = abs(ref-num);
relErr = absErr ./ ref;

assert(all(relErr < 1e-6 | double(absErr) < 1e-8))   % accounts for ODE solver inaccuracy

%% Test oral dosing vs analytical solution

indv = clone(tmp);
indv.dosing = Oral('Warfarin', 0*u.h, d);

initialize(indv);
simulate(indv);

num = indv.observation.record.Value; % numerical solution

% reference solution (Bateman function)
ka = p.lambda_po;
ke = p.CL / p.V;
ref = (d*ka*p.F/p.V) * (exp(-ke*t) - exp(-ka*t)) / (ka - ke); 

% assertions: numerical approx. equal to reference?
assert(isequal(size(ref),size(num)))

absErr = abs(ref-num);
relErr = absErr ./ ref;

assert(all(relErr<1e-6 | double(absErr) < 1e-8))   % accounts for ODE solver inaccuracy


%% Test infusion dosing vs analytical solution

dur = 2*u.h;

indv = clone(tmp);
indv.dosing = Infusion('Warfarin', 0*u.h, d, dur, 'iv');

initialize(indv);
simulate(indv);

num = indv.observation.record.Value; % numerical solution

% reference solution (synthesis-degradation model)
ke = p.CL / p.V;
r  = d / dur;
Apre  = @(t)  r / ke * (1 - exp(-ke*t));
Adur  = Apre(dur);
Apost = @(t) Adur * exp(-ke*(t-dur));
ref = (Apre(t) .* (t < dur) + Apost(t) .* (t >= dur)) / p.V; 
ref = scd(ref, 'ug/L');

% assertions: numerical approx. equal to reference?
assert(isequal(size(ref),size(num)))

absErr = abs(ref-num);
relErr = absErr ./ ref;

t = indv.observation.record.Time;

assert(all(relErr<1e-6 | double(absErr) < 1e-8))   % accounts for ODE solver inaccuracy
