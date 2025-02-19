%LUMP_MODEL Lump a compartmental model
%   L = LUMP_MODEL(M, PARTITIONING), with an OdeModel object M and a cell 
%   array of cellstr PARTITIONING containing names of model compartments,
%   lumps model compartments of M in the same cellstr of PARTITIONING into
%   a single compartment. The resulting lumped model is returned as an 
%   OdeModel object L.
%
%   Model compartments not specified in PARTITIONING will remain in
%   separate compartments. Therefore, LUMP_MODEL(M, {}) is always identical
%   to M.
%
%   Function LUMP_MODEL relies on a few conventions in model M and if these
%   are not fulfilled, an error will be thrown when L is initialized. More 
%   precisely, the setup struct returned by model M must contain the 
%   following fields:
%   
%   - a valid indexing struct setup.indexing.I, which enumerates the entire
%     state vector X, say of length N;
%   - a valid indexing struct setup.indexing.Id, which specifies dosing 
%     compartments (Bolus, Infusion or Oral);
%   - a length N cellstr setup.cmt containing names for all ODE states;
%   - a length M <= N indexing setup.physIdx vector containing indices of
%     of physiological states (between 1 and N);
%   - an M-by-1 numeric vector setup.VK containing normalization values for 
%     the lumping condition for the M physiological compartments. The order
%     is chosen that VK(i) represents compartment cmt(physIdx(i)).
%     These normalization values should be chosen such that A(i)/VK(i) is 
%     approximately equal within the same lumped compartment, or phrased in 
%     concentrations, C(i)/K(i) is approximately constant.
%
%   ATTENTION:
%   Currently, the first-pass effect is not accounted for in LUMP_MODEL.
%   Therefore, if liver is lumped together with the central compartments
%   (artery/lung/vein) and a dose is given orally, the lumped model will
%   overpredict concentrations. As a solution, lump liver into a separate
%   compartment when dosing orally. Generally this will improve the fit
%   significantly, in any case.
%
%   Examples:
%   
%   obs = PBPKobservables();
%   m = sMD_PBPK_12CMT_wellstirred();
%   l = lump_model(m, {{'art','lun','ven'}});
%   
%   indv = Individual(2,'Virtual');
% 
%   indv(1).name       = 'Full model';
%   indv(1).dosing     = Bolus('Warfarin',0*u.h,1*u.mg,'iv');
%   indv(1).drugdata   = loaddrugdata('Warfarin','species','human');
%   indv(1).physiology = Physiology('human35m');
%   indv(1).sampling   = Sampling([0 24]*u.h, obs);
%   indv(1).model      = m;
%   indv(1).model.options.tissuePartitioning = @rodgersrowland;
% 
%   indv(2) = clone(indv(1));
%   indv(2).name       = 'Lumped model';
%   indv(2).model      = l;
%   indv(2).model.options.tissuePartitioning = @rodgersrowland;
% 
%   initialize(indv)
%   simulate(indv)
%   plot(indv)

function lmod = lump_model(mod, partitioning)

    assert(isa(mod,'OdeModel'), 'Input #1 must be an ODE model.')

    % define lumped model
    lmod = OdeModel;

    lmod.initfun = @(varargin) initfun_lumped(varargin{:}, mod.initfun, partitioning);
    lmod.rhsfun  = @(varargin) rhsfun_lumped(varargin{:}, mod.rhsfun);
    lmod.obsfun  = @(varargin) obsfun_lumped(varargin{:}, mod.obsfun);

end

function setup = initfun_lumped(phys, drug, par, options, initfun_orig, partitioning)

    % include original setup
    setup = struct;
    setup.orig = initfun_orig(phys, drug, par, options);

    % check for mandatory fields in setup.orig and setup.orig.indexing
    if ~all(isfield(setup.orig,{'indexing','X0','VK','cmt','physIdx'})) || ...
            ~isfield(setup.orig.indexing,'Id')
        error('compphysiol:lump_model:initfun_lumped:missingField', ...
            'Mandatory field in setup struct missing in model to be lumped.')
    end

    % lumping-specific setup
    cmt  = setup.orig.cmt(:);
    ncmt = numel(cmt);

    % add indexing struct for lumped CMT
    setup.indexing = struct;
    I = struct;
    I.phys = setup.orig.physIdx;
    I.aux  = setdiff(1:ncmt,I.phys);
    setup.indexing.I = I;

    % check size equality of X0(phys) and VK
    assert(isequal(size(setup.orig.X0(I.phys)),size(setup.orig.VK)), ...
        'compphysiol:lump_model:initfun_lumped:incompatibleSizes', ...
            'Sizes of tissues and VK must agree.')

    % check that indexing struct and X0 are consistent in original model
    assert(isequal(ncmt,numel(setup.orig.X0)), ...
        'compphysiol:lump_model:initfun_lumped:incompatibleSizes2', ...
        'Number of compartment in indexing struct and initial condition must agree.')

    % number of compartments per lumped compartment
    szlump = cellfun('length',partitioning);
    szlump = [szlump ones(1,ncmt-sum(szlump))];
    nlump = numel(szlump);
    lgrp = repelem(1:nlump, szlump)';

    % array permutation into order of lumping scheme
    flatpart = flatten_partitioning(partitioning);
    fullpart = [flatpart; setdiff(cmt,flatpart,'stable')];
    [~,perm] = ismember(cmt, fullpart);

    % check that all compartments to be lumped are physiological ones
    if ~all(ismember(flatpart, cmt(I.phys)))
        error('compphysiol:lump_model:initfun_lumped:unphysiologicalPartitioning', ...
            'Only physiological compartments may be lumped together.')
    end

    % groups in lumping scheme in original order
    grp = lgrp(perm);

    % dosing indexing struct of lumped compartments
    setup.indexing.Id = setup.orig.indexing.Id;
    dtype = fieldnames(setup.indexing.Id);
    if ismember('Bolus',dtype) % target = 'iv' hard-wired for now!
        setup.indexing.Id.Bolus.iv.cmt = grp(setup.orig.indexing.Id.Bolus.iv.cmt);
    end
    if ismember('Oral',dtype)
        setup.indexing.Id.Oral.cmt = grp(setup.orig.indexing.Id.Oral.cmt);
    end
    if ismember('Infusion',dtype) % target = 'iv' hard-wired for now!
        setup.indexing.Id.Infusion.iv.bag  = grp(setup.orig.indexing.Id.Infusion.iv.bag);
        setup.indexing.Id.Infusion.iv.rate = grp(setup.orig.indexing.Id.Infusion.iv.rate);
    end

    % lumping function (volume-weighted average concentrations)
    setup.lump = @(x) splitapply(@sum,x,grp); 
    
    % original and lumped volumes * partition coefficients
    VKphys = setup.orig.VK;
    VKorig = [VKphys; ones(numel(I.aux),1)*u.L];    % adding dummy values for auxiliary CMT
    VKlump = setup.lump(VKorig);
    
    % unlumping function
    setup.unlump = @(x) VKorig .* x(grp) ./ VKlump(grp);

    % initial conditions
    setup.X0 = setup.lump(setup.orig.X0);

end

function dXl = rhsfun_lumped(t, Xl, setup, rhsfun_orig) 

    % expand to the original variables
    X = setup.unlump(Xl);

    % call original ODE model
    dX = rhsfun_orig(t,X,setup.orig);

    % reduce back to the lumped variables
    dXl = setup.lump(dX);
 
end


function yobs = obsfun_lumped(outputl, setup, obs, obsfun_orig)

    % create output in terms of the original variables
    output = struct;
    output.t = outputl.t;
    outXcl = cellfun(@(x) setup.unlump(x')', num2cell(outputl.X,2), 'UniformOutput',false);
    output.X = vertcat(outXcl{:});

    % apply original observation function
    yobs = obsfun_orig(output, setup.orig, obs);

end


%% helper functions

function part = flatten_partitioning(part)
    if ~isempty(part)
        part = reshape([part{:}],[],1);
    end
end

