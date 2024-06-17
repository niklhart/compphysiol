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
%    - Bmax (Amount)
%    - Km (Amount/Volume)
%    - kdeg (1/Time)
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
%    - targetExpressingTissues:
%         Cellstr of tissues which express the target (a subset of {'pla',
%         'lun','adi','hea','kid','mus','bon','ski','gut','spl','liv'}, 
%         default: {}). A target binding module (parameters Bmax, Km, kdeg)
%         is used for any target expressing tissue.
%    - FcRnKnockout:
%         true or false (default: false). If set to true, CLpla.pla is
%         increased.


function model = mAb_PBPK_11CMT_extravasLim_int_target()


    error('Implementation ongoing, not for use yet.')

    model = OdeModel;
    model.initfun = @initfun;
    model.rhsfun  = @rhsfun;
    model.obsfun  = @obsfun;
    model.name    = mfilename;

end

function model = initfun(phys, dosing, par, options)
    
    % assertions (model validity): 
    cpd = compounds(dosing);
    ddb = getoptPBPKtoolbox('DrugDBhandle');
    drug = ddb{cpd{:}};
    
    assert(isscalar(drug), 'Model not defined for multiple drugs.')
    assert(strcmp(drug.class,'mAb'), ['Model not defined for drug class "' drug.class '".'])
    
    % indexing
    tissues = {'lun','adi','hea','kid','mus','bon','ski','gut','spl','liv','pla'};
    [queryphys, querydrug, I] = loaddatabases(phys, drug, tissues);

    ncomp = numel(tissues);
    
    I = addcmtidx(I,'IVbag','IVrate','metab'); %NH implement 'GItract' in future version
    
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
    
    Id.bolus.iv.cmt     = I.pla;
    Id.bolus.iv.scaling = V.pla;
    
    Id.infusion.iv.bag  = I.IVbag;
    Id.infusion.iv.rate = I.IVrate;
        
    %%% -------------------------------------------------------------------
    %%% Define drug-specific parameters

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
                 'extraction parameter will be unused.'])
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
        assert(scenario == 1, 'Knock-out case has been implemented only for scenario 1.')
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

    %%% target-related parameters
    targetExpressingTissues = getfrom(options, 'targetExpressingTissues', {});

    assert(all(ismember(targetExpressingTissues, tissues)), ...
        'Model option "targetExpressingTissues" contains invalid tissues.')
    
    Bmax = uzeros(ncomp,1);
    Km   = uzeros(ncomp,1);
    kdeg = uzeros(ncomp,1);
    
    MW = querydrug('MW');
    
    for i = 1:numel(targetExpressingTissues)
        tis = targetExpressingTissues{i};
        Bmax(I.(tis)) = par.Bmax * MW;     
        Km(I.(tis))   = par.Km * MW;       
        kdeg(I.(tis)) = par.kdeg; 
    end  
    
    %%% initial condition and units of ODEs

    doseunit = u.ug;
    
    X0 = initializeX0(I);
    X0([I.pla Ig.organs]) = 0*doseunit / u.L;
    X0(I.IVbag)   = 0*doseunit;
    X0(I.IVrate)  = 0*doseunit / u.min;
    X0(I.metab)   = 0*doseunit;
            
    % -----------------------------------------------------------------------
    % Assign model parameters 
    model = struct;
    model.indexing.I  = I;
    model.indexing.Ig = Ig;
    model.indexing.Id = Id;
    model.V           = V;
    model.Q           = Q;
    model.K           = K;
    model.E           = E;
    model.eK          = eK;
    model.BP          = BP;
    model.fLymph      = fLymph;
    model.sigma       = sigma;
    model.CLint       = CLint;
    model.CLpla       = CLpla;
    model.ABC         = ABC;
    model.L           = Leff;
    model.SF          = SF;
    model.Bmax        = Bmax;
    model.kdeg        = kdeg;
    model.Km          = Km;
    model.X0          = X0;
    
end


%% Right-hand side of ODE model
function dX = rhsfun(t, X, model) % t will be used for infusion rate

    % initialize output vector
    X = X(:);
    dX = NaNsizeof(X);
    
    % model and indexing
    I = model.indexing.I; 
    Ig = model.indexing.Ig;
    org = Ig.organs;
    pla = I.pla;

    % variables (always use column vector notation)
    C_pla = X(pla); 
    C_int = X(org); 
    
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

    
    %%% free concentration and amount bound to the target or 
    %%% receptor-system (RS) in the interstitial space
    Ceff_int = C_int - (Bmax(org)./V_int(org)) - Km(org);
    Cu_int   = 1/2*( Ceff_int + sqrt( Ceff_int.^2 + 4*Km(org).*C_int ) );
    Atar_int = Bmax(org).*Cu_int./(Km(org)+Cu_int);

    %%% free concentration and amount bound to the target or 
    %%% receptor-system (RS) in plasma
    Ceff_pla      = C_pla -(Bmax(pla)./V_pla) -Km(pla);
    Cu_pla        = 1/2*( Ceff_pla + sqrt( Ceff_pla^2 + 4*Km(pla).*C_pla ) );
    Atar_pla      = Bmax(pla).*Cu_pla./(Km(pla)+Cu_pla);
       

    %%% -----------------------------------------------------------------------
    %%% START OF ODEs

    % interstitial spaces
    VdC_int = Q(org).*( (1-sigma(org))*Cu_pla - Cu_int./K(org) ) ...
        - CLint(org).*Cu_int - kdeg(org).*Atar_int;

    % plasma
    VdC_pla = sum( Q(org).*Cu_int./K(org) ) ...
        - sum( Q(org).*(1-sigma(org))*Cu_pla ) - CLpla*Cu_pla ...
        - kdeg(pla).*Atar_pla ...
        + infusion_rate;

    % drug amount in IVbag for infusion
    dA_IVbag = -infusion_rate;

    % drug amount metabolized or excreted
    dA_metab = CLpla*Cu_pla + kdeg(pla).*Atar_pla ...
               + sum( CLint(org).*Cu_int(org) ) + sum( kdeg(org).*Atar_int );


    %%% END OF ODEs
    %%% -----------------------------------------------------------------------

    % converting amounts to concentrations
    dC_pla = VdC_pla ./ V_pla;
    dC_int = VdC_int ./ V_int(org);

    % output vector (always in column vector notation)
    dX(pla)       = dC_pla;
    dX(org)       = dC_int;
    dX(I.metab)   = dA_metab;
    dX(I.IVbag)   = dA_IVbag;
    dX(I.IVrate)  = 0 * unitsOf(X(I.IVrate) / t);

end

function yobs = obsfun(output, model, type)
    
    I = model.indexing.I;

    switch type
        case 'Cpla'
            yobs = output.X(:,I.pla);            
        case 'Cadi'
            yobs = output.X(:,I.adi) * model.SF.int2tis(I.adi);            
        case 'Cbon'
            yobs = output.X(:,I.bon) * model.SF.int2tis(I.bon);         
        case 'Cgut'
            yobs = output.X(:,I.gut) * model.SF.int2tis(I.gut);            
        case 'Chea'
            yobs = output.X(:,I.hea) * model.SF.int2tis(I.hea);            
        case 'Ckid'
            yobs = output.X(:,I.kid) * model.SF.int2tis(I.kid);            
        case 'Cliv'
            yobs = output.X(:,I.liv) * model.SF.int2tis(I.liv);            
        case 'Clun'
            yobs = output.X(:,I.lun) * model.SF.int2tis(I.lun);            
        case 'Cmus'
            yobs = output.X(:,I.mus) * model.SF.int2tis(I.mus);            
        case 'Cski'
            yobs = output.X(:,I.ski) * model.SF.int2tis(I.ski);            
        case 'Cspl'
            yobs = output.X(:,I.spl) * model.SF.int2tis(I.spl);            
        case 'massBalance'
            Ig = model.indexing.Ig;
            yobs = output.X(:,Ig.organs) * model.V.int(Ig.organs) ...
                    + output.X(:,I.pla) .* model.V.pla ...
                    + output.X(:,I.IVbag) ...
                    + output.X(:,I.metab);
            
        otherwise
            yobs = [];
    end
end

