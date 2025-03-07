% test the simulator for different sampling times / schedules

% Allocation
indv      = Individual('Virtual');
indv.name = 'Warfarin 12-CMT';

% Design of simulation
indv.physiology = Physiology('human35m');
indv.dosing     = EmptyDosing();
indv.drugdata   = loaddrugdata('Warfarin','species','human');
indv.sampling   = SamplingSchedule();

% Model specification
indv.model      = sMD_PBPK_12CMT_wellstirred;
indv.model.options.tissuePartitioning = @rodgersrowland;

initialize(indv)

% model struct
model = indv.model;

% dosing
dos_0h  = Oral('Warfarin', 0*u.h, u.mg);
dos_12h = Oral('Warfarin', 12*u.h, u.mg);

% sampling times
samp_0_24 = [0 24]*u.h;
samp_12_24 = [12 24]*u.h;
samp_0_12_24 = [0 12 24]*u.h;
samp_6_12_18 = [6 12 18]*u.h;


%% Test default case (first dosing at start of sampling)

out1 = simulator(model,samp_0_24,dos_0h);
out2 = simulator(model,samp_0_12_24,dos_0h);

assert(numel(out1.t) > 5)
assert(all(out2.t == samp_0_12_24(:)))

%% Test early dosing

out1 = simulator(model,samp_12_24,dos_0h);
out2 = simulator(model,samp_6_12_18,dos_0h);

assert(numel(out1.t) > 5)
assert(all(any(double(out1.X) > 0, 2)))
assert(all(out2.t == samp_6_12_18(:)))

%% Test delayed dosing

out1 = simulator(model,samp_0_24,dos_12h);
out2 = simulator(model,samp_6_12_18,dos_12h);

assert(numel(out1.t) > 5)
assert(all(out2.t == samp_6_12_18(:)))
assert(nnz(out2.X(1,:)) == 0)



