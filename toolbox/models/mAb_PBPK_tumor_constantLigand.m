%MAB_PBPK_TUMOR_CONSTANTLIGAND mAb PBPK model with detailed tumor model 
%    This function specifies a simplfied PBPK model for mAb with
%    extravasation-limited tissue distribution, parameterized in terms of 
%    interstitial volume rather than tissue volume. It contains a detailed 
%    tumor distribution model (modelled as cylinder with fixed length and 
%    equal width between layers). The detailed tumor distribution model is 
%    linked to a single-cell-receptor-drug model with natural ligand, which
%    is included at constant ligand concentration. In the default setting, 
%    clearance only occurs from plasma.
%
%    To execute this model, the following options must be defined:
%    - antibodyBiodistributionCoefficients:     
%         a function handle (a method to to predict antibody 
%         biodistribution coefficients).
%    - vTum:
%         weight-normalized tumor burden (a Volume/Mass DimVar)
%   
%   Optional options:
%    - clearanceScenario:     
%         1, 2, 3, or 4. A scenario on how to distribute clearances for
%         different organs (default: 1)
%    - FcRnKnockout:
%         true or false (default: false). If set to true, CLpla.pla is
%         increased.
%    - nLayer:
%         number of layers in the tumor distribution model (default: 4)
%

function model = mAb_PBPK_tumor_constantLigand()

    model = OdeModel;
    model.initfun = @initfun;
    model.rhsfun  = @rhsfun;
    model.obsfun  = @obsfun;
    model.name    = mfilename;

end

function model = initfun(phys, drug, par, options)
    
    % assertions (model validity): 
    assert(isscalar(drug), 'Model not defined for multiple drugs.')    
    assert(strcmp(drug.class,'mAb'), ['Model not defined for drug class "' drug.class '".'])
    
    % indexing
    tissues = {'lun','adi','hea','kid','mus','bon','ski','gut','spl','liv','pla'};%,'tum'};
    [queryphys, querydrug, I] = loaddatabases(phys, drug, tissues);

    ncomp = numel(tissues);
    
    I = addcmtidx(I,'IVbag','IVrate','metab'); %NH implement 'GItract' in future version
    
    Ig = struct;  % groupings
%    Ig.organs      = [I.lun I.adi I.hea I.kid I.mus I.bon I.ski I.gut I.spl I.liv I.tum];
    Ig.organsExTum = [I.lun I.adi I.hea I.kid I.mus I.bon I.ski I.gut I.spl I.liv];
    Ig.visOrg      = [                                          I.gut I.spl I.liv];   % visceral organs
    Ig.nonvisOrg   = [I.lun I.adi I.hea I.kid I.mus I.bon I.ski                  ];   % non-visceral organs
        
    nlayers  = getfrom(options, 'nlayers', 4);
    
    nmax = numel(fieldnames(I));
    I.Cu_int = nmax+1:nmax+nlayers; % free mAb concentration within tumor layers
    nmax = nmax + nlayers;
    I.R = nmax+1:nmax+nlayers;      % free receptor  within tumor layers
    nmax = nmax + nlayers;
    I.Rint = nmax+1:nmax+nlayers;   % internalized receptor  within tumor layers
    nmax = nmax + nlayers;
    I.RC = nmax+1:nmax+nlayers;     % receptor complex  within tumor layers
    nmax = nmax + nlayers;
    I.L = nmax+1:nmax+nlayers;      % natural ligand within tumor layers
    nmax = nmax + nlayers;
    I.RL = nmax+1:nmax+nlayers;     % ligand-receptor complex within tumor layers
    nmax = nmax + nlayers;   % number of ODE variables

    
    % ---------------------------------------------------------------------
    % Define species-specific parameters

    % tissue volumes and interstitial volumes of the different organs 
    V.vas = queryphys('Vvas');
    V.tis = queryphys('Vtis');
    fintVtis = queryphys('fintVtis');
    fintVtis(I.liv) = 6.311934e-02; %estimated in Fuhrmann_consensus PBPK model
    fintVtis(I.spl) = 9.217525e-02; %estimated in Fuhrmann_consensus PBPK model
    V.int = fintVtis .* V.tis;

    % tumor volume parameters
    
    V_tum = getfrom(options,'Vtum') * queryphys('BW');    
    
    fvasVtum = 6*u.percent;     % (Gullino et al. 1965)
    fintVtis = 34*u.percent;    % (Gullino et al. 1965)
    ftisVtum = 1-fvasVtum;
    
%    V.vas(I.tum) = fvasVtum * V_tum;
%    V.tis(I.tum) = ftisVtum * V_tum;
%    V.int(I.tum) = fintVtis * V.tis(I.tum);
    
    % tumor modelled as cylinder with layers of equal width

    % calculate fixed length l of cylinder from total tumor volume V= pi*r^2*l
    r = 75 * u.um;%Krogh Radius (from Cilliers et al. 2016)
    l = (V_tum/(pi*r^2));

    % calculate average number of capillaries in 0.25 mm2 tumor tissue
    No_cap = 0.25*u.mm^2/(pi*r^2);

    % innermost cylinder contains a thin capillary (fixed radius)
    r_cap = 8*u.um;%capillary radius (from Cilliers et al. 2016)
    SA_cap= 2*pi*r_cap*l;

    % calculate equal width w of the layers
    w = (r-r_cap)/nlayers;

    
    % total volumes of tumor layers, based on cylinder volume equation
    VKtot = pi*l*( (w*(1:nlayers)+r_cap).^2 - (w*(0:nlayers-1)+r_cap).^2 )';
    VKtis = ftisVtum * VKtot;
    VKint = fintVtis * VKtis;
    VKcel = VKtis - VKint;
    
    % surface area of tumor layers based on cylinder lateral surface equation 
    %   SA=2*pi*r*length    (r_cap is added because it was excluded in layer width) 
    SA = 2*pi*(w*(1:nlayers)+r_cap)*l;

    % mAb diffusion coefficient
    D = 1.27e-7*u.cm^2/u.s;     % Schmidt and Wittrup 2009 Mol Cancer Ther Supplemental Data Table S1 

    % mAb permeability coefficient of a typical mAb
    P = 2.82e-7*u.cm/u.s;       % Schmidt and Wittrup 2009 Mol Cancer Ther Supplemental Data Table S3
    
    % exchange between plasma (capillary) and first layer
    PSf(1)=P*2*pi*r_cap*l; %[dm^3/min] %forward PS_pla1
    PSb(1)=P*2*pi*r_cap*l; %[dm^3/min] %backward PS_1pla

    % exchange between tumor layers
    PSf(2:nlayers) = (D*SA(1:nlayers-1))/w; %forward exchange  (PS_12, PS_23, PS_34, PS_45...)
    PSb(2:nlayers) = (D*SA(1:nlayers-1))/w; %backward exchange (PS_21, PS_32, PS_43, PS_54...)

    % volume of a single human tumor cell
    Vsinglecell= 2e-12*u.L; % (assuming a spherical cell shape and a typical radius of 8um in human solid tumors)  
                            % source: Research on the physics of cancer: a Global Perspective (Chapter 6)
    
    % number of cells per each tumor layer (in mol)
    Ncell = VKcel/Vsinglecell/u.NA;
    
    
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
    Q.lymph(I.pla) = sum(Q.lymph(Ig.organsExTum));
    
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
    clearanceScenario = getfrom(options, 'clearanceScenario', 1);

    switch queryphys('species')
        case 'human'
            if clearanceScenario ~= 1
                warning('Only default clearance scenario 1 implemented for humans.')
            end
            CLpla.pla = 1.332e-4 * u.L/u.min;

        case 'mouse'
            switch clearanceScenario
                case 1   % default setting: clearance only from plasma

                    CLpla.pla = 8.732e-8 * u.L/u.min;

                case 2   % clearance from all tissues

                    E.tis(Ig.organs) = 5.268e-03; % all tissues with identical extraction ratio
                    CLpla.pla = 0 * u.L/u.min;

                case 3   % clearance from liver and plasma

                    E.tis(I.liv) = 4.131e-02;
                    CLpla.pla    = 8.732e-8 * u.L/u.min - E.tis(I.liv)*Q.lymph(I.liv)*(1-sigma.vas(I.liv));

                case 4   % clearance from spleen and plasma

                    E.tis(I.spl) = 5.274e-03;
                    CLpla.pla    = 8.732e-8 * u.L/u.min - E.tis(I.spl)*Q.lymph(I.spl)*(1-sigma.vas(I.spl));

                otherwise
                    error(['Unknown clearance scenario "' num2str(clearanceScenario) '".'])
            end
        otherwise
            error('No clearance scenario specified for species other than human/mouse.')
    end

    % determine plasma clearance corresponding to the different intrinsic
    % tissue clearances
    CLpla.tis = E.tis .* Q.lymph .* (1-sigma.vas);

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

    
    %%% initial condition and units of ODEs

    doseunit = u.nmol;

    X0 = unan(nmax,1);

    X0([I.pla Ig.organsExTum]) = 0*doseunit / u.L;
    X0(I.Cu_int)  = 0*doseunit / u.L;
    X0(I.IVbag)   = 0*doseunit;
    X0(I.IVrate)  = 0*doseunit / u.min;
    X0(I.metab)   = 0*doseunit;
            
    [Rintss, Rss, RLss] = getSteadyState(par);
    X0(I.R)    = Rss;
    X0(I.Rint) = Rintss;
    X0(I.RC)   = 0;
    X0(I.L)    = par.Ltum;
    X0(I.RL)   = RLss;
    
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
    
    model.par = par;
    
    model.PSb   = PSb;
    model.PSf   = PSf;
    model.SA    = SA;
    model.Ncell = Ncell;
    model.nlayers = nlayers;
    model.VKint = VKint;
    
    model.X0          = X0;
    
    
    %%% -----------------------------------------------------------------------
%%% Calculate pre-treatment steady state values
%%%
    function [Rintss, Rss, RLss] = getSteadyState(par)
        
        ksynR   = par.ksynR;
        kdegR   = par.kdegR;  
        krecyRi = par.krecyRi;    
        kdegRi  = par.kdegRi;    
        kdegRL  = par.kdegRL;
        koffL   = par.koffL;
        konL    = par.konL;
        L       = par.Ltum;
        
        Rintss = (kdegR*ksynR*(kdegRL + koffL))/(kdegR*kdegRL*kdegRi + kdegR*kdegRi*koffL + L*kdegRL*kdegRi*konL + L*kdegRL*konL*krecyRi);
        Rss    = (kdegRL*kdegRi*ksynR + kdegRi*koffL*ksynR + kdegRL*krecyRi*ksynR + koffL*krecyRi*ksynR)/(kdegR*kdegRL*kdegRi + kdegR*kdegRi*koffL + L*kdegRL*kdegRi*konL + L*kdegRL*konL*krecyRi);
        RLss   = (ksynR*(L*kdegRi*konL + L*konL*krecyRi))/(kdegR*kdegRL*kdegRi + kdegR*kdegRi*koffL + L*kdegRL*kdegRi*konL + L*kdegRL*konL*krecyRi);
    end

    
end


%% Right-hand side of ODE model
function dX = rhsfun(t, X, model) % t will be used for infusion rate

    % initialize output vector
    X = X(:);
    dX = NaNsizeof(X);
    
    % model and indexing
    I = model.indexing.I; 
    Ig = model.indexing.Ig;
    
    % parameters
    par = model.par;
    
    % variables (always use column vector notation)
    C_pla = X(I.pla); 
    C_int = X(Ig.organsExTum); 
    
    Cu_int = X(I.Cu_int);
    R      = X(I.R);
    Rint   = X(I.Rint);
    RC     = X(I.RC);
    RL     = X(I.RL);
    L      = X(I.L);
    
    %%% tissue volumes, blood flows, endosomal clearance etc.
    V_pla    = model.V.pla;
    V_int    = model.V.int;
    VK_int   = model.VKint;
    Q        = model.Q.lymph;

    K        = model.K.int;
    sigma    = model.sigma.vas;
    CLint    = model.CLint.int;
    CLpla    = model.CLpla.pla;

    PSb      = model.PSb;
    PSf      = model.PSf;
    Ncell    = model.Ncell;
    
    nlayers  = model.nlayers;
    
    koffC = par.KD * par.konC;
    
    % infusion
    infusion_rate = X(I.IVrate);

    %%% -----------------------------------------------------------------------
    %%% START OF ODEs

%    VdC_int = NaNsizeof(C_int);  
    VdCu_int = NaNsizeof(Cu_int); % Different initialization necessary to support computation with/without units 
    
    % interstitial spaces; organs without tumor
    orgExTum = Ig.organsExTum;
    VdC_int = Q(orgExTum).*( (1-sigma(orgExTum))*C_pla - C_int(orgExTum)./K(orgExTum) ) ...
        - CLint(orgExTum).*C_int;

    % plasma
    VdC_pla = sum( Q(orgExTum).*C_int./K(orgExTum) ) ...
        - sum( Q(orgExTum).*(1-sigma(orgExTum))*C_pla ) - CLpla*C_pla ...
        + PSb(1).*Cu_int(1) - PSf(1).*C_pla + infusion_rate;

    % interstitial spaces of tumor layers: free mAb within tumour
    
    if nlayers == 1
        VdCu_int(1) = PSf(1).*C_pla - PSb(1).*Cu_int(1) ...
            + Ncell(1)*(koffC*RC(1) - konC*R(1)*Cu_int(1));
   
    else
        VdCu_int(1) = PSf(1).*C_pla - PSb(1).*Cu_int(1) ...
            - PSf(2).*Cu_int(1) + PSb(2).*Cu_int(2) ...
            + Ncell(1)*(koffC*RC(1) - par.konC*R(1)*Cu_int(1));
        for i=2:nlayers-1
            VdCu_int(i) = PSf(i).*Cu_int(i-1) - PSb(i).*Cu_int(i) ...
                - PSf(i+1).*Cu_int(i) + PSb(i+1).*Cu_int(i+1) ...
                + Ncell(i)*(koffC*RC(i) - par.konC*R(i)*Cu_int(i));
        end
        VdCu_int(nlayers) = PSf(nlayers).*Cu_int(nlayers-1) ...
            - PSb(nlayers).*Cu_int(nlayers) ...
            + Ncell(nlayers)*(koffC*RC(nlayers) - par.konC*R(nlayers)*Cu_int(nlayers));
    end 
    
    % receptor binding in interstitial spaces of tumor layers
    
    % free receptor
    dR    = par.ksynR - par.kdegR*R + par.krecyRi*Rint ...
        - par.konC*R.*Cu_int + koffC*RC - par.konL*L.*R + par.koffL*RL;
    % free internalized receptor
    dRint = par.kdegR*R - par.krecyRi*Rint - par.kdegRi*Rint;
    % receptor drug complex
    dRC   = par.konC*R.*Cu_int - koffC*RC - par.kdegRC*RC;
    % natural ligand
    dL    = par.ksynL - par.kdegL*L; %constant with dLdt=0 because ksynL and kdegL=0
    % ligand-receptor complex
    dRL   = par.konL*L.*R - par.koffL*RL - par.kdegRL*RL;
    
    
    % drug amount in IVbag for infusion
    dA_IVbag = -infusion_rate;

    % drug amount metabolized or excreted
    dA_metab = +CLpla*C_pla ...
        + sum( CLint(orgExTum).*C_int(orgExTum) ) ...
        + sum(par.kdegRC.*RC.*Ncell);


    %%% END OF ODEs
    %%% -----------------------------------------------------------------------

    % converting amounts to concentrations
    dC_pla  = VdC_pla ./ V_pla;
    dC_int  = VdC_int ./ V_int(orgExTum);
    dCu_int = VdCu_int ./ VK_int;
    
    % output vector (always in column vector notation)
    dX(I.pla)     = dC_pla;
    dX(orgExTum)  = dC_int;
    dX(I.Cu_int)  = dCu_int;
    dX(I.R)       = dR;
    dX(I.Rint)    = dRint;
    dX(I.RC)      = dRC;
    dX(I.RL)      = dRL;
    dX(I.L)       = dL;
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
            yobs = output.X(:,Ig.organsExTum) * model.V.int(Ig.organsExTum) ...
                    + output.X(:,I.Cu_int) .* model.VKint ...
                    + output.X(:,I.R) ...
                    + output.X(:,I.RC) ...                    
                    + output.X(:,I.pla) .* model.V.pla ...
                    + output.X(:,I.IVbag) ...
                    + output.X(:,I.metab);
            
        otherwise
            yobs = [];
    end
end

