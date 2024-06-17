%MAB_PBPK_11CMT_EXTRAVASLIM_INT 11cmt extravasation-limited mAb PBPK model
%    This function specifies a simplfied PBPK model for mAb with
%    extravasation-limited tissue distribution and no target, parameterized
%    in terms of interstitial volume rather than tissue volume. In the
%    default setting, clearance only occurs from plasma.
%
%    Model parameters:
%    - CLpla (Volume/Time)
%         Total plasma clearance (resulting from elimination from plasma
%         and optionally other clearing tissues)
%    - Etis  (unitless)
%         Tissue extraction ratios which will be used for any clearing 
%         tissue. See model option 'clearingTissues' for further details.
%
%    Mandatory model options:
%    - antibodyBiodistributionCoefficients:
%         a function handle (a method to to predict antibody 
%         biodistribution coefficients).
%   
%    Optional model options:
%    - clearingTissues:     
%         Cellstr of tissues from which clearance is modelled (a subset of
%         {'lun','adi','hea','kid','mus','bon','ski','gut','spl','liv'}, 
%         default: {}). If parameter Etis is non-zero and clearingTissues
%         is empty, a warning is produced since Etis will not be used.
%    - FcRnKnockout:
%         true or false (default: false). If set to true, CLpla.pla is
%         increased.

% ========================================================================%
% General structure
% ========================================================================%
function model = mAb_PBPK_11CMT_extravasLim_int()

    model = OdeModel;
    model.initfun = @initfun;
    model.rhsfun  = @rhsfun;
    model.obsfun  = @obsfun;
    model.name    = mfilename;

end

% ========================================================================%
% Initialization of model
% ========================================================================%
function setup = initfun(phys, drug, par, options)
    
    % assertions (model validity):     
    assert(isscalar(drug), 'Model not defined for multiple drugs.')
    assert(strcmp(drug.class,'mAb'), ['Model not defined for drug class "' drug.class '".'])
    
    % indexing
    tissues = {'lun','adi','hea','kid','mus','bon','ski','gut','spl','liv','pla'};
    [queryphys, querydrug, I] = loaddatabases(phys, drug, tissues);

    ncomp = numel(tissues);
    
    I = addcmtidx(I,'IVbag','IVrate','metab');
    
    Ig = struct;  % groupings
    Ig.organs    = [I.lun I.adi I.hea I.kid I.mus I.bon I.ski I.gut I.spl I.liv];
    Ig.visOrg    = [                                          I.gut I.spl I.liv];   % visceral organs
    Ig.nonvisOrg = [I.lun I.adi I.hea I.kid I.mus I.bon I.ski                  ];   % non-visceral organs
        
    % ---------------------------------------------------------------------
    % Define species-specific parameters

    % tissue volumes and interstitial volumes of the different organs 
    V.vas = queryphys('Vvas');
    V.tis = queryphys('Vtis');
    fintVtis = queryphys('fintVtis');
    V.int = fintVtis .* V.tis;

    % determine (arterial/venous) blood volume not related to any organ
    hct = queryphys('hct');
    V.pla = (1 - hct) * queryphys('Vtbl');
    
    % blood flows (ensure closed circulatory system!)
    Q.blo = queryphys('Qblo');
    Q.blo(I.lun) = queryphys('co');
    
    % peripheral plasma flows
    Q.pla = (1-hct) * Q.blo;

    % lymph flow as fraction of peripheral plasma and blood flow
    fLymph = nan(size(Q.pla));
    fLymph(Ig.visOrg)    = 0.02;
    fLymph(Ig.nonvisOrg) = 0.04;

    Q.lymph = fLymph.*Q.pla;
    Q.lymph(I.pla) = sum(Q.lymph(Ig.organs));
    
    % Definition of dosing target struct
    Id = struct;
    
    Id.Bolus.iv.cmt     = I.pla;
    Id.Bolus.iv.scaling = V.pla;
    
    Id.Infusion.iv.bag  = I.IVbag;
    Id.Infusion.iv.rate = I.IVrate;
        
    %%% -------------------------------------------------------------------
    %%% Define drug-specific parameters

    MW = querydrug('MW');
    
    % define vascular reflection coefficients
    sigma.vas = nan(size(V.vas));
    sigma.vas([I.liv I.spl I.gut])       = 0.95;  % values for Brown mouse and other species
    sigma.vas([I.hea I.ski I.kid I.lun]) = 0.975;
    sigma.vas([I.mus I.adi I.bon])       = 0.99;

    ABCfun  = getfrom(options, 'antibodyBiodistributionCoefficients');
    ABC = struct;
    ABC.tis = ABCfun(phys, drug, tissues);
    
    % define elimination-corrected tissue partition coefficients
    eK.tis  = ABC.tis ./ (1-sigma.vas);

    % blood-to-plasma ratio
    BP = querydrug('BP');

    %%% initialize tissue-specific extraction ratio
    E.tis = zeros(ncomp,1);

    % different clearance scenarios
    clearingTissues = getfrom(options, 'clearingTissues', {});

    assert(all(ismember(clearingTissues, setdiff(tissues,'pla'))), ...
        'Model option "clearingTissue" contains invalid tissues.')
    if isempty(clearingTissues) && par.Etis ~= 0
        warning(['If no clearing tissue is specified, the tissue '...
                 'extraction parameter will not be used.'])
    end    
    
    for i = 1:numel(clearingTissues)
        E.tis(I.(clearingTissues{i})) = par.Etis;
    end    

    % determine plasma clearance corresponding to the different intrinsic
    % tissue clearances and plasma
    CLpla.tis = E.tis .* Q.lymph .* (1-sigma.vas);
    CLpla.pla = par.CLpla - sum(CLpla.tis(Ig.organs));
    
    % partition coefficients
    K.tis = eK.tis ./ (1-E.tis);

    % define intrinsic tissue clearance
    CLint.tis = Q.lymph ./ K.tis .* E.tis ./ (1-E.tis);

    % account for FcRn status
    FcRnKnockout = getfrom(options, 'FcRnKnockout', false);

    if FcRnKnockout 
        assert(isempty(clearingTissues), 'Knock-out case has been implemented for plasma clearance only.')
        CLpla.pla = 23 * CLpla.pla; 
    end

    % effective lymph flow
    Leff.lymph = (1-sigma.vas) .* Q.lymph;

    % compute ABCs, eK and K with respect to interstitial volume based on 
    % volume scaling factors

    SF.int2tis = fintVtis;
    SF.tis2int = 1 ./ SF.int2tis;

    ABC.int = SF.tis2int .* ABC.tis;
    eK.int  = SF.tis2int .* eK.tis;
    K.int   = SF.tis2int .* K.tis;

    E.int        = E.tis; % note: scaling factors cancel out!
    CLint.int    = Q.lymph./K.int.*E.int./(1-E.int);

    
    %%% initial condition and units of ODEs

    doseunit = u.ug;
    
    X0 = initializeX0(I);
    X0([I.pla Ig.organs]) = 0*doseunit / u.L;
    X0(I.IVbag)   = 0*doseunit;
    X0(I.IVrate)  = 0*doseunit / u.min;
    X0(I.metab)   = 0*doseunit;
            
    % -----------------------------------------------------------------------
    % Assign model parameters 
    setup = struct;
    setup.indexing.I  = I;
    setup.indexing.Ig = Ig;
    setup.indexing.Id = Id;
    setup.V           = V;
    setup.Q           = Q;
    setup.K           = K;
    setup.E           = E;
    setup.eK          = eK;
    setup.BP          = BP;
    setup.fLymph      = fLymph;
    setup.sigma       = sigma;
    setup.CLint       = CLint;
    setup.CLpla       = CLpla;
    setup.ABC         = ABC;
    setup.L           = Leff;
    setup.SF          = SF;
    setup.MW          = MW;
    setup.hct         = hct;
    setup.par         = par;
    setup.X0          = X0;
    
end


% ========================================================================%
% ODE system of the model
% ========================================================================%
function dX = rhsfun(t, X, model) % t will be used for infusion rate

    % initialize output vector
    X = X(:);
    dX = NaNsizeof(X);
    
    % model and indexing
    I = model.indexing.I; 
    Ig = model.indexing.Ig;
    
    % variables (always use column vector notation)
    C_pla = X(I.pla); 
    C_int = X(Ig.organs); 
    
    %%% tissue volumes, blood flows, endosomal clearance etc.
    V_pla    = model.V.pla;
    V_int    = model.V.int;
    Q        = model.Q.lymph;

    K        = model.K.int;
    sigma    = model.sigma.vas;
    CLint    = model.CLint.int;
    CLpla    = model.CLpla.pla;

    % infusion
    infusion_rate = X(I.IVrate);

    %%% -----------------------------------------------------------------------
    %%% START OF ODEs

    % interstitial spaces
    org = Ig.organs;
    VdC_int = Q(org).*( (1-sigma(org))*C_pla - C_int./K(org) ) ...
        - CLint(org).*C_int;

    % plasma
    VdC_pla = sum( Q(org).*C_int./K(org) ) ...
        - sum( Q(org).*(1-sigma(org))*C_pla ) - CLpla*C_pla ...
        + infusion_rate;

    % drug amount in IVbag for infusion
    dA_IVbag = -infusion_rate;

    % drug amount metabolized or excreted
    dA_metab = +CLpla*C_pla + sum( CLint(org).*C_int(org) );


    %%% END OF ODEs
    %%% -----------------------------------------------------------------------

    % converting amounts to concentrations
    dC_pla = VdC_pla ./ V_pla;
    dC_int = VdC_int ./ V_int(org);

    % output vector (always in column vector notation)
    dX(I.pla)     = dC_pla;
    dX(Ig.organs) = dC_int;
    dX(I.metab)   = dA_metab;
    dX(I.IVbag)   = dA_IVbag;
    dX(I.IVrate)  = 0 * unitsOf(X(I.IVrate) / t);

end

% ========================================================================%
% Definition of observable quantities
% ========================================================================%
function yobs = obsfun(output, model, obs)
%OBSFUN Observables in 11 CMT extravasation-limited model
%   The following observables are supported:
%   
%   Type 'PBPK':
%       Site:     'adi','bon','gut','hea','kid','liv','lun','mus','ski','spl','pla'
%       Subspace: 'int','pla','tis','tot'
%       Binding:  'total'
%       UnitType: 'Mass','Amount','Mass/Volume','Amount/Volume'
%   
%   Type 'SimplePK':
%       Site:     'pla'
%       Binding:  'total'
%       UnitType: 'Mass/Volume','Amount/Volume'
%    
%   Type 'MassBalance':
%       UnitType: 'Mass,'Amount'

    I = model.indexing.I;

    modelsites = {'adi','bon','gut','hea','kid','liv','lun','mus','ski','spl','pla'};
    
    yobs = []; % if obs matches a case below, yobs will be overwritten
    
    switch obs.type
        case 'PBPK'      % Site, Subspace, Binding, UnitType
            
            % Site
            site = obs.attr.Site;
            if strcmp(site,'pla')
                Cpla = output.X(:,I.pla);
                Cint = 0*Cpla;  % model site 'pla' has no interstitial space
            elseif ismember(site, modelsites)
                % Interstitial concentration (Mass/Volume units)
                Cint = output.X(:,I.(site));
                Cpla = 0*Cint;  % model tissues don't have vascular space 
            else
                return
            end
            
            % Subspace
            spc = obs.attr.Subspace;
            switch spc
                case 'pla' %plasma
                    Cspc = Cpla;
                    Vspc = model.V.pla;
                case 'int' %interstitial
                    Cspc = Cint;
                    Vspc = model.V.int(I.(site));
                case 'tis' %tissue
                    Cspc = Cint * model.SF.int2tis(I.(site));
                    Vspc = model.V.tis(I.(site));
                case 'tot' %total
                    Vspc = model.V.tis(I.(site)) + model.V.vas(I.(site));
                    Cspc = Cint * model.V.int(I.(site)) / Vspc;
                otherwise 
                    return
            end
            
            % Binding
            switch obs.attr.Binding
                case 'total'
                    % pass
                otherwise 
                    return
            end

            % Unit types
            switch obs.attr.UnitType
                case 'Mass'
                    yspc = Cspc * Vspc;
                case 'Mass/Volume'
                    yspc = Cspc;
                case 'Amount'
                    yspc = Cspc * Vspc / model.MW;
                case 'Amount/Volume'
                    yspc = Cspc / model.MW;
                otherwise 
                    return
            end
            
            % all checks passed and all steps processed: return the result
            yobs = yspc;
                
        case 'SimplePK'  % Site, Binding, UnitType
            
            site = obs.attr.Site;
            if strcmp(site, 'pla')
                ytmp = output.X(:,I.pla); % bound+unbound, Mass/Volume units
            else
                return
            end
            switch obs.attr.Binding
                case 'total'
                    % pass
                otherwise 
                    return
            end
            switch obs.attr.UnitType 
                case 'Mass/Volume'
                    % do nothing, ytmp already has correct unit type
                case 'Amount/Volume'
                    ytmp = ytmp / model.MW;
                otherwise 
                    return
            end
            yobs = ytmp;

        case 'MassBalance'
            
            Ig = model.indexing.Ig;
            ytmp = output.X(:,Ig.organs) * model.V.int(Ig.organs) ...
                    + output.X(:,I.pla) .* model.V.pla ...
                    + output.X(:,I.IVbag) ...
                    + output.X(:,I.metab);
                
            switch obs.attr.UnitType
                case 'Mass'
                    % do nothing, ytmp already has correct unit type
                case 'Amount'
                    ytmp = ytmp / model.MW; 
                otherwise
                    return
            end
            yobs = ytmp;
    end
        
end

