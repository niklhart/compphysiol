% Test implementation of well-stirred model


%% Check positivity of numerical values in setup struct

% define the dose
Dose = 60*u.mg;

obs = PBPKobservables();

indv = Individual('Virtual');
indv.name        = 'Well-stirred';
indv.physiology  = Physiology('human35m'); 
indv.dosing      = Bolus('Lidocaine', 0*u.h, Dose, 'iv'); 
indv.sampling    = Sampling([0 10]*u.h, obs);
indv.model       = sMD_PBPK_12CMT_wellstirred; 
indv.model.options.tissuePartitioning = @rodgersrowland;
indv.drugdata    = loaddrugdata('Lidocaine','species','human');

initialize(indv)

ddb = getoptPBPKtoolbox('DrugDBhandle');
cls = {ddb.class};
cpd = {ddb.name};
cpd = cpd(strcmp(cls,'sMD'));

for i = 1:numel(cpd)
    indv.drugdata    = loaddrugdata(cpd{i},'species','human');
    if hasrecord(indv.drugdata, 'CLint_hep_perOWliv')
        initialize(indv)
        setup = indv.model.setup;
        validateNestedObj(setup, 'mode', 'error','report_nan',false)
    end
end


%% Long-term infusion --> steady-state according to tissue partitioning

% define the dose
Dose = 1*u.g;

% observables
org = {'lun','adi','bra','hea','kid','mus','bon','ski','gut','spl','liv','art','ven'};
obs = PBPKobservables('Site',org);

% define a simulation
indv = Individual('Virtual');
indv.name        = 'Well-stirred';
indv.physiology  = Physiology('human35m'); 
indv.dosing      = Infusion('Lidocaine', 0*u.day, Dose, 10*u.day, 'iv'); 
indv.sampling    = Sampling([0 10]*u.day, obs);
indv.model       = sMD_PBPK_12CMT_wellstirred; 
indv.model.options.tissuePartitioning = @rodgersrowland;
indv.drugdata    = loaddrugdata('Lidocaine','species','human');

initialize(indv);
simulate(indv);

% expected output: plasma concentration remains constant
Cvas = filter(indv.observation, 'Observable',obs(14));

assert(double(Cvas.Value(end)-Cvas.Value(end-1)) < 1e-15)

% expected: concentration ratio close to partition coefficients
Ctot = filter(indv.observation, 'Observable',obs(2:end));
Kref = indv.model.setup.eK.tot;
Kobs = Ctot.Value(Ctot.Time == max(Ctot.Time)) ./ Cvas.Value(end);

assert( all(abs(Kref - Kobs) < 1e-10, 'all') )

%% Organs entirely vascular --> independent of tissue partitioning

% define the dose
Dose = 60*u.mg;

% reference physiology, with modified organ volumes
vasphys = Physiology('human35m');
updaterecord(vasphys,'Vtis',vasphys.db.Vtis.Tissue,0*u.L);
updaterecord(vasphys,'Vtot',vasphys.db.Vvas.Tissue,vasphys.db.Vvas.Value);

% define observables
org = {'adi','bon','gut','hea','kid','liv','lun','mus','ski','spl','art','ven'};
PBPK = @(subspace, unit) Observable('PBPK', org, subspace, 'total', unit);

obsAvas = PBPK('vas','Mass');
obsAtot = PBPK('tot','Mass');
obsAexc = PBPK('exc','Mass');
%obsAtis = PBPK('tis','Mass');
obsAtis = Observable('PBPK', {'adi','bon','gut','hea','kid','liv', ...
    'lun','mus','ski','spl'}, 'tis', 'total', 'Mass');

obsCvas = PBPK('vas','Mass/Volume');
obsCtot = PBPK('tot','Mass/Volume');
obsCexc = PBPK('exc','Mass/Volume');

obs = [obsAvas obsAtot obsAexc obsAtis obsCvas obsCtot obsCexc];

% define simulations
indv = Individual('Virtual');
indv.name        = 'Well-stirred';
indv.physiology  = vasphys; 
indv.dosing      = Bolus('Lidocaine', 0*u.h, Dose, 'iv'); 
indv.sampling    = Sampling([0:0.1:10]*u.h, obs);
indv.model       = sMD_PBPK_12CMT_wellstirred; 
indv.model.options.tissuePartitioning = @rodgersrowland;
indv.drugdata    = loaddrugdata('Lidocaine','species','human');

% check correct handling of partitioning method
initialize(indv);

assert(all(indv.model.setup.K.tot == 1, 'all'))

% check observation function
simulate(indv);

recAvas = filter(indv.observation,'Observable',obsAvas);
recAtot = filter(indv.observation,'Observable',obsAtot);
recAexc = filter(indv.observation,'Observable',obsAexc);
recAtis = filter(indv.observation,'Observable',obsAtis);

assert(isequal(recAvas.Value, recAtot.Value, recAexc.Value))
assert(all(recAtis.Value == 0*u.kg))

recCvas = filter(indv.observation,'Observable',obsCvas);
recCtot = filter(indv.observation,'Observable',obsCtot);
recCexc = filter(indv.observation,'Observable',obsCexc);

assert(isequal(recCvas.Value, recCtot.Value, recCexc.Value))

%% Analytical solution of **linear** case (bolus dosing)

% define the dose
Dose = 60*u.mg;

obs = PBPKobservables(); % unused

indv = Individual('Virtual');
indv.name        = 'Well-stirred';
indv.physiology  = Physiology('human35m'); 
indv.dosing      = Bolus('Lidocaine', 0*u.h, Dose, 'iv'); 
indv.sampling    = Sampling((0:0.1:10)*u.h, obs);
indv.model       = sMD_PBPK_12CMT_wellstirred; 
indv.model.options.tissuePartitioning = @rodgersrowland;
indv.drugdata    = loaddrugdata('Lidocaine','species','human');

% numerical solution
initialize(indv);
simulate(indv);

% analytical solution (using eigenvalues)
setup = indv.model.setup;
idx   = setup.indexing;
X0    = setup.X0(1:12); % 10 organs + art + ven
X0(idx.Id.Bolus.iv.cmt) = Dose/idx.Id.Bolus.iv.scaling;

X = solve_linode(setup.V.tot, setup.Q.blo, setup.K.tot, X0, idx, setup.CLuint.hep*setup.fuB);

numtimes = double(unique(indv.sampling.schedule.Time));
Xtref = arrayfun(X, numtimes, 'UniformOutput', false);

Xtref = [Xtref{:}]';

% comparison in double format
Xtnum = double(indv.model.odestate.X(:,1:12));  % 10 organs + art + ven

absErr = abs(Xtnum - Xtref);
relErr = abs((Xtnum - Xtref)./(Xtref+eps(1))); 

assert(all(absErr < 1e-10, 'all'))
assert(all(relErr(2:end,:) < 1e-6, 'all'))          % pb. with zero initial values


%%

% helper function to analytically solve a linear ODE using matrix
% exponentials
function X = solve_linode(V, Q, K, X0, indexing, CLhep)
    
    % all inputs must have the same length
    assert(isequal(numel(V),numel(Q),numel(K),numel(X0)))
    n = numel(V);

    % groupings
    I  = indexing.I;
    Ig = indexing.Ig;

    % here we work in double format -- easy to recover DimVar afterwards
    X0d = double(X0(:));
    Vd  = double(V(:));
    Qd  = double(Q(:));
    CLd = double(CLhep);
    
    % assemble RHS matrix
    A = zeros(n);

    % lun ODE
    A(I.lun,I.ven) = +Qd(I.lun)/Vd(I.ven);
    A(I.lun,I.lun) = -Qd(I.lun)/(Vd(I.lun)*K(I.lun));

    % art ODE
    A(I.art,I.lun) = +Qd(I.art)/(Vd(I.lun)*K(I.lun));
    A(I.art,I.art) = -Qd(I.art)/Vd(I.art);

    % 9 org ODEs (adi, bon, bra, hea, gut, kid, mus, ski, spl)
    linI_artInflow = sub2ind([n n],Ig.artInflow,Ig.artInflow);
    A(Ig.artInflow,I.art) = Qd(Ig.artInflow)./Vd(I.art);
    A(linI_artInflow)     = -Qd(Ig.artInflow)./(Vd(Ig.artInflow).*K(Ig.artInflow));

    % liv ODE
    Q_hepart = Qd(I.liv) - sum(Qd([Ig.intoLiv]));
    A(I.liv,Ig.intoLiv) = Qd(Ig.intoLiv)./(Vd(Ig.intoLiv).*K(Ig.intoLiv));
    A(I.liv,I.art)      = Q_hepart/Vd(I.art);
    A(I.liv,I.liv)      = -(Qd(I.liv)+CLd)/(Vd(I.liv)*K(I.liv));

    % ven ODE
    A(I.ven,Ig.intoVen) = Qd(Ig.intoVen)./(Vd(Ig.intoVen).*K(Ig.intoVen));
    A(I.ven,I.ven)      = -Qd(I.ven)/Vd(I.ven);

    % eigendecomposition
    [eigV,eigD] = eig(A,'vector');

    alpha = eigV\X0d;
    X = @(t) real(eigV*(alpha.*exp(eigD*t)));

end




