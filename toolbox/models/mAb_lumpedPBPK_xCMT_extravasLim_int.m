%MAB_LUMPEDPBPK_XCMT_EXTRAVASLIM_INT Extravasation-limited lumped mAb PBPK
%    This function specifies a lumped PBPK model for mAb (monoclonal anti-
%    bodies) with extravasation-limited tissue distribution and hepatic 
%    clearance
%   
%    To execute this model, the following options must be defined:
%    - antibodyBiodistributionCoefficients:     
%         a function handle (a method to to predict antibody 
%         biodistribution coefficients).
%    - lumpingScheme       a cell array of cellstr, which constitutes a
%                          partition of the 11 physiological compartments.

function model = mAb_lumpedPBPK_xCMT_extravasLim_int()

    model = OdeModel;
    model.initfun = @initfun;
    model.rhsfun  = @rhsfun;
    model.obsfun  = @obsfun;
    model.name    = mfilename;

end

function model = initfun(phys, drug, ~, options)
        
    assert(isscalar(drug), 'Model not defined for multiple drugs.')
    assert(strcmp(drug.class,'mAb'), ['Model not defined for drug class "' drug.class '".'])
    
    % indexing
    tissues = {'lun','adi','hea','kid','mus','bon','ski','gut','spl','liv','pla'};
    [queryphys, querydrug, I] = loaddatabases(phys, drug, tissues);
    
    ncomp = numel(tissues);

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
                    CLpla.pla      = 8.732e-8 * u.L/u.min - E.tis(I.spl)*Q.lymph(I.spl)*(1-sigma.vas(I.spl));

                otherwise
                    error(['Unknown clearance scenario "' num2str(clearanceScenario) '".'])
            end
        otherwise
            error('No clearance scenario specified for rat.')
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
    Leff.lymph = (1-sigma.vas) .* Q.lymph;  % TODO check with Wilhelm: use it below or delete it here?

    % compute ABCs, eK and K with respect to interstitial volume based on 
    % volume scaling factors

    SF.int2tis = fintVtis;
    SF.tis2int = 1 ./ SF.int2tis;

    ABC.int = SF.tis2int .* ABC.tis;
    eK.int  = SF.tis2int .* eK.tis;
    K.int   = SF.tis2int .* K.tis;

    E.int        = E.tis; % note: scaling factors cancel out!
    CLint.int    = Q.lymph./K.int.*E.int./(1-E.int);
    
    %%% -----------------------------------------------------------------------
    %%% Determine lumped PBPK model parameter values based on the above 
    %%% parameter values of the detailed PBPK model
    %%%
    %%% -----------------------------------------------------------------------


    %%% -----------------------------------------------------------------------
    %%% Define indexing of lumped PBPK model

    % transform lumping cell array with organ names into cell array with 
    % corresponding index numbers

    lumping = getfrom(options, 'lumpingScheme');

    assert(issetequal([lumping{:}], tissues), ...
        'Organs listed in options.lumpingScheme do not match the detailed PBPK model to be lumped!')

    nlump = numel(lumping);

    Il = struct;
    Il.cmt = cell(nlump,1);
    for n = 1:nlump
        for k = 1:numel(lumping{n})
            Il.cmt{n}(k) = I.(lumping{n}{k});
        end
    end

    % groupings (of lumped compartments)
    Ilg = struct;

    % lumped compartments containing ven, liv and kid 
    Ilg.cen = find(cellfun(@(x) ismember('pla', x), lumping),1);
    Ilg.liv = find(cellfun(@(x) ismember('liv', x), lumping),1);
    Ilg.kid = find(cellfun(@(x) ismember('kid', x), lumping),1);

    % other groupings 
    Ilg.alltis = 1:nlump;
    Ilg.allExCen = setdiff(Ilg.alltis, Ilg.cen);

    % dosing and metabolism indexing     NH: GItract (po) in future version
    %Il = addcmtidx(Il,'GItract','IVbag','IVrate','metab'); 
    Il.IVbag = max(Ilg.alltis) + 1;
    Il.IVrate  = max(Il.IVbag) + 1;
    Il.metab   = max(Il.IVrate) + 1;    

    %%% -----------------------------------------------------------------------
    %%% Define lumped PBPK model parameters 

    V.lump  = unan(nlump,1); 
    Q.lump  = unan(nlump,1);
    sigma.lump = unan(nlump,1);
    E.lump = unan(nlump,1);
    CLint.lump = unan(nlump,1);
    CLpla.lump = unan(nlump,1);
    eK.lump = unan(nlump,1);
    K.lump = unan(nlump,1);
    
    for n = Ilg.allExCen
        ind = Il.cmt{n};
        V.lump(n)     = sum(V.int(ind)); 
        Q.lump(n)     = sum(Q.lymph(ind));
        sigma.lump(n) = 1 - sum( Q.lymph(ind) .* (1-sigma.vas(ind)) ) / Q.lump(n);
        eK.lump(n)    = sum( V.int(ind).*eK.int(ind).*(1-sigma.vas(ind)) ) / ...
                            ( V.lump(n) .* (1-sigma.lump(n)) );
        E.lump(n)     = 1/(Q.lump(n) * (1-sigma.lump(n))) * ...
                            sum( Q.lymph(ind) .* (1-sigma.vas(ind)) .* E.int(ind) );
        K.lump(n)     = eK.lump(n) / (1 - E.lump(n));
        CLint.lump(n) = Q.lump(n)/K.lump(n)*E.lump(n)/(1-E.lump(n));
        CLpla.lump(n) = sum( CLpla.tis(ind) );
    end
    
    % special treatment of lumped cmt including former plasma cmt
    cenExPla = setdiff(Il.cmt{Ilg.cen},I.pla);
    V.lump(Ilg.cen)     = sum(V.int(cenExPla)) + V.pla;
    Q.lump(Ilg.cen)     = sum(Q.lump(Ilg.allExCen));
    sigma.lump(Ilg.cen) = 1 - sum( Q.lump(Ilg.allExCen).*(1-sigma.lump(Ilg.allExCen)) )/Q.lump(Ilg.cen);
    if nlump == 1
        sigma.lump(Ilg.cen) = 0; %TODO check with Wilhelm
    end
    eK.lump(Ilg.cen)    = (sum( V.int(cenExPla).*(1-sigma.vas(cenExPla)).*eK.int(cenExPla) ) ...
                             + V.pla ) / (V.lump(Ilg.cen).*(1-sigma.lump(Ilg.cen)));
    E.lump(Ilg.cen)     = 1 / ( Q.lump(Ilg.cen)*(1-sigma.lump(Ilg.cen)) ) * ...
                            sum( Q.lymph(cenExPla).*(1-sigma.vas(cenExPla)).*E.int(cenExPla) );
    K.lump(Ilg.cen)     = eK.lump(Ilg.cen)/(1-E.lump(Ilg.cen));
    CLpla.lump(Ilg.cen) = sum( CLpla.tis(cenExPla) ) + CLpla.pla;
    
    ABC.lump = eK.lump .* (1-sigma.lump);
    
    % Definition of dosing target struct
    Id = struct;

    Id.bolus.iv.cmt     = Ilg.cen;
    Id.bolus.iv.scaling = V.lump(Ilg.cen);

    Id.infusion.iv.bag  = Il.IVbag;
    Id.infusion.iv.rate = Il.IVrate;

%    Id.oral.cmt         = Il.GItract;


    % initial condition and units of ODE
    
    doseunit = u.ug;

    X0 = unan(nlump+3,1);
    X0(Ilg.alltis) = 0*doseunit / u.L;
    X0(Il.IVbag)   = 0*doseunit;
    X0(Il.IVrate)  = 0*doseunit / u.min;
    X0(Il.metab)   = 0*doseunit;

    % ---------------------------------------------------------------------
    % Assign model parameters 
    
    model = struct;
    model.indexing.I   = I;
    model.indexing.Ig  = Ig;
    model.indexing.Il  = Il;
    model.indexing.Ilg = Ilg;
    model.indexing.Id  = Id;
    model.V            = V;
    model.Q            = Q;
    model.K            = K;
    model.E            = E;
    model.eK           = eK;
    model.fLymph       = fLymph;
    model.sigma        = sigma;
    model.CLint        = CLint;
    model.CLpla        = CLpla;
    model.BP           = BP;
    model.lumping      = lumping;
    model.X0           = X0;    

    model.ABC    = ABC;
%    model.L      = Leff;
    model.SF     = SF;
    
end


%% Right-hand side of ODE model
function dX = rhsfun(t, X, model) % t will be used for infusion rate

    % initialize output vector
    X = X(:);
    dX = NaNsizeof(X);
    
    % model and indexing
    Il = model.indexing.Il; 
    Ilg = model.indexing.Ilg;
    
    % variables (always use column vector notation)
    C_lump = X(Ilg.alltis); 
    infusion_rate = X(Il.IVrate);

    %%% tissue volumes, blood flows, extraction ratios, clearance etc.
    V     = model.V.lump;
    Q     = model.Q.lump; 

    K     = model.K.lump;
    sigma = model.sigma.lump;
    eK    = model.eK.lump;
    CLint = model.CLint.lump;
    CLpla = model.CLpla.lump;

    %%% -----------------------------------------------------------------------
    %%% START OF ODEs
    %%%
    
    % abbreviations
    cen = Ilg.cen;        
    cmt = Ilg.allExCen;
    
    VdC_lump = NaNsizeof(C_lump);

    C_pla = C_lump(cen)/( (1-sigma(cen))*eK(cen) );


    if ~isempty(cmt) % more than 1 lumped cmt

        % all compartment except the central

        VdC_lump(cmt) = Q(cmt).*( (1-sigma(cmt)).*C_pla - C_lump(cmt)./K(cmt) ) ...
                       -CLint(cmt).*C_lump(cmt);

        % central compartment             
        VdC_lump(cen) = sum( Q(cmt).*C_lump(cmt)./K(cmt) ) ...
                       -sum( Q(cmt).*(1-sigma(cmt)).*C_pla )...
                       -CLpla(cen)*C_pla + infusion_rate; 

    else  % exactly 1 lumped cmt

        %%% central compartment
        VdC_lump(cen)  = -CLpla(cen)*C_pla + infusion_rate;

    end

    %%% drug amount in IVbag for infusion
    dA_IVbag = -infusion_rate;

    %%% metabolized and excreted compound (mass)
    dA_metab = sum( CLint(cmt).*C_lump(cmt) ) + CLpla(cen)*C_pla; 

    %%%
    %%% END OF ODEs 
    %%% -------------------------------------------------------------------

    %%% converting amounts to concentrations
    dC_lump = VdC_lump ./ V;

    %%% output vector (always in column vector notation)
    dX(Ilg.alltis) = dC_lump;
    dX(Il.IVbag)   = dA_IVbag;
    dX(Il.metab)   = dA_metab;
    dX(Il.IVrate)  = 0 * unitsOf(X(Il.IVrate) / t);
    
end

function yobs = obsfun(output, model, type)
    
    I = model.indexing.I;
    Ilg = model.indexing.Ilg;
    Il = model.indexing.Il;
    lumping = model.lumping;
    
    if ismember(type, {'Cadi','Cbon','Cgut','Chea','Ckid', ...
            'Cliv','Clun','Cmus','Cski','Cspl'})
        tis = replace(type,'C','');
        type = 'Ctis';
    end
    
    switch type
        case 'Cpla'
%            yobs = output.X(:,Ilg.cen) / model.ABC.lump(Ilg.cen);% / model.ABC.int(I.pla);            
            yobs = output.X(:,Ilg.cen) / model.ABC.lump(Ilg.cen);% / model.ABC.int(I.pla);            
        case 'Ctis'
            itis = cellfun(@(x) ismember(tis,x), lumping);
 %           yobs = output.X(:,itis) * model.ABC.tis(I.(tis)) / model.ABC.lump(itis); %model.SF.int2tis(I.(tis));            
            yobs = output.X(:,itis) * model.ABC.tis(I.(tis)) / model.ABC.lump(itis); %model.SF.int2tis(I.(tis));            
        case 'massBalance'
            yobs = output.X(:,Ilg.alltis) * model.V.lump ...
                    + output.X(:,Il.IVbag) ...
                    + output.X(:,Il.metab);
            
        otherwise
            yobs = [];
    end
end

