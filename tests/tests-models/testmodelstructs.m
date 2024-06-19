% test if applying rhsfun to the initial condition completes without errors
% and yields the correct units.

t0 = 0*u.h;

%% empirical1CMT_allometric

phys = Physiology('human35m');
dos  = Bolus('Warfarin',t0,10*u.mg,'iv');
drug = loaddrugdata(compounds(dos));
par  = parameters(...
            'V',          1*u.L, ...
            'CL',         1*u.L/u.h, ...
            'lambda_po',  1/u.h, ...
            'F',          1);
opt  = struct('targetBW',80*u.kg);

model = empirical1CMT_allometric;

check_initcon(model,phys,drug,par,opt);

%% empirical1CMT_PLASMA_macroConstants_linearCL

phys = Physiology();
dos  = Bolus('Warfarin',t0,10*u.mg,'iv');
drug = loaddrugdata(compounds(dos));
par  = parameters(...
            'V',          1*u.L, ...
            'CL',         1*u.L/u.h, ...
            'lambda_po',  1/u.h, ...
            'F',          1);
opt  = [];

model = empirical1CMT_PLASMA_macroConstants_linearCL;

check_initcon(model,phys,drug,par,opt);

%% empirical2CMT_PLASMA_macroConstants_linearCL

phys = Physiology();
dos  = Bolus('Warfarin',t0,10*u.mg,'iv');
drug = loaddrugdata(compounds(dos));
par  = parameters(...
            'V1',          1*u.L, ...
            'V2',          1*u.L, ...
            'CL',         1*u.L/u.h, ...
            'Q',         1*u.L/u.h, ...
            'lambda_po',  1/u.h, ...
            'F',          1);
opt  = [];

model = empirical2CMT_PLASMA_macroConstants_linearCL;

check_initcon(model,phys,drug,par,opt);

%% sMD_PBPK_12CMT_permeabilityLimited

phys = Physiology('human35m');
dos  = Bolus('Lidocaine',t0,10*u.mg,'iv');
drug = loaddrugdata(compounds(dos),'species',getvalue(phys,'species'));

par  = [];
opt  = struct('tissuePartitioning',@rodgersrowland);

model = sMD_PBPK_12CMT_permeabilityLimited;

check_initcon(model,phys,drug,par,opt);

%% sMD_PBPK_12CMT_wellstirred

phys = Physiology('human35m');
dos  = Bolus('Warfarin',t0,10*u.mg,'iv');
drug = loaddrugdata(compounds(dos),'species',getvalue(phys,'species'));
par  = [];
opt  = struct('tissuePartitioning',@rodgersrowland);

model = sMD_PBPK_12CMT_wellstirred;

check_initcon(model,phys,drug,par,opt);


%% Model check as a local function

function check_initcon(model, phys, drug, par, opt)

    t0 = 0*u.h;
    setup = model.initfun(phys, drug, par, opt);
    X0  = setup.X0;
    dX0dt = model.rhsfun(t0, X0, setup);

    compatible(dX0dt, X0/t0)

end


