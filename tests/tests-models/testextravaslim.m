% Test implementation of extravasation-limited model (for mAbs)


%% Check that any numerical value in the setup struct is positive

indv = Individual('Virtual');
indv.name        = 'Extravasation-limited (check positive)';
indv.physiology  = Physiology('human35m'); 
indv.dosing      = Infusion('mAb7E3', 0*u.h, 210*u.mg, 1*u.h, 'iv');
indv.sampling    = Sampling([0 21]*u.day);
indv.model       = mAb_PBPK_11CMT_extravasLim_int; 
indv.model.options.antibodyBiodistributionCoefficients = @shahbetts;
indv.model.par   = parameters('CLpla', 1.332e-4 * u.L/u.min, ...
                               'Etis', 0);
indv.drugdata    = loaddrugdata('mAb7E3','species','human');

initialize(indv);

validateNestedObj(indv.model.setup, 'mode', 'error','report_nan',false)

%% Long-term infusion --> steady-state according to tissue partitioning

% sites in same ordering as in model
org = {'lun','adi','hea','kid','mus','bon','ski','gut','spl','liv'};
obs = PBPKobservables('Subspace','tis','Site',org);

indv = Individual('Virtual');
indv.name        = 'Extravasation-limited (check long-term infusion)';
indv.physiology  = Physiology('human35m'); 
indv.dosing      = Infusion('mAb7E3', 0*u.day, 1*u.g, 1*u.year, 'iv');
indv.sampling    = Sampling([0 1]*u.year, obs);
indv.model       = mAb_PBPK_11CMT_extravasLim_int; 
indv.model.options.antibodyBiodistributionCoefficients = @shahbetts;
indv.model.par   = parameters('CLpla', 1.332e-4 * u.L/u.min, ...
                              'Etis', 0);
indv.drugdata    = loaddrugdata('mAb7E3','species','human');

initialize(indv);
simulate(indv);

recCpla = filter(indv.observation,'Time',1*u.year,'Observable',obs(1));
recCtis = filter(indv.observation,'Time',1*u.year,'Observable',obs(2:end));

Kref = indv.model.setup.ABC.tis;
Kobs = recCtis.Value ./ recCpla.Value;

assert( all(abs(Kref(1:10) - Kobs) < 1e-6, 'all') )

%% Analytical solution of **linear** case (bolus dosing) - FAILS

warning('Analytical solution of mAb model not implemented yet.')

% define the dose
Dose = 210*u.mg;

org = {'adi','bon','gut','hea','kid','liv','lun','mus','ski','spl','pla'};
obs = Observable('PBPK',org,'tot','total','Mass/Volume');

indv = Individual('Virtual');
indv.name        = 'Extravasation-limited (analytical solution)';
indv.physiology  = Physiology('human35m'); 
indv.dosing      = Bolus('mAb7E3', 0*u.h, Dose, 'iv');
indv.sampling    = Sampling((0:1:21)*u.day, obs);
indv.model       = mAb_PBPK_11CMT_extravasLim_int; 
indv.model.options.antibodyBiodistributionCoefficients = @shahbetts;
indv.model.par   = parameters('CLpla', 1.332e-4 * u.L/u.min, ...
                              'Etis', 0);
indv.drugdata    = loaddrugdata('mAb7E3','species','human');

% numerical solution
initialize(indv);
simulate(indv);

% analytical solution (using eigenvalues)
setup = indv.model.setup;
idx   = setup.indexing;
X0    = setup.X0(1:11); % 10 organs + pla
X0(idx.Id.Bolus.iv.cmt) = Dose/idx.Id.Bolus.iv.scaling;


%TODO: the following is a relict from the sMD model, update it.
% X = solve_linode(setup.V.tot, setup.Q.blo, setup.K.tot, X0, idx, setup.CLuint.hep*setup.fuB);
% 
% Xtref = arrayfun(X, double(indv.sampling.timespan), 'UniformOutput', false);
% 
% Xtref = [Xtref{:}]';
% 
% % comparison in double format
% Xtnum = double(indv.output.X(:,1:11));  % 11 organs + art + ven
% 
% absErr = abs(Xtnum - Xtref);
% relErr = (Xtnum - Xtref)./(Xtref+eps(1)); 
% 
% assert(all(absErr < 1e-10, 'all'))
% assert(all(relErr(2:end,:) < 1e-8, 'all'))          % pb. with zero initial values
% 
% % % graphical comparison (for exploration, commented)
% figure()
% subplot(2,1,1)
% semilogy(Xtnum)
% title('Numerical sol.')
% subplot(2,1,2)
% semilogy(Xtref)
% title('Analytical sol.')
% organs = fieldnames(idx.I);
% legend(organs{1:13})
% linkaxes

%%

% helper function to analytically solve a linear ODE using matrix
% exponentials
%
%   TODO: this function is not finished yet -- I first have to understand
%         the model implementation better.
%
function X = solve_linode(V, Q, K, X0, indexing, CLpla)
    
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
    Ld  = double(L(:));
    CLd = double(CLpla);
    
    % assemble RHS matrix
    A = zeros(n);

    % pla ODE
    A(I.pla,I.pla)     = -(Qd(I.pla) + sum(Ld,'omitnan') + CLd )/Vd(I.pla);
    A(I.pla,Ig.organs) = Qd(I.pla)/(Vd(I.pla)*K(Ig.organs));

    % 10 org ODEs (lun,adi,hea,kid,mus,bon,ski,gut,spl,liv)
    linI_organs = sub2ind([n n],Ig.organs,Ig.organs);
    A(Ig.organs,I.pla) = Qd(Ig.artInflow)./Vd(Ig.artInflow);
    A(linI_organs)     = -Qd(Ig.artInflow)./(Vd(Ig.artInflow).*K(Ig.artInflow));

    % eigendecomposition
    [V,D] = eig(A,'vector');

    alpha = V\X0d;
    X = @(t) real(V*(alpha.*exp(D*t)));

end




