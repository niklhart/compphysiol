%SMD_PBPK_12CMT_WELLSTIRRED Well-stirred model with new CL module
%    This function specifies a 12 cmt PBPK model for sMD (small molecule 
%    drugs) with well-stirred tissue distribution and hepatic clearance.
%
%    This is the model which is shown in the slides of the PharMetrX A2
%    module 2024.
%   
%    To execute this model, the following options must be defined:
%    - tissuePartitioning     
%           a function handle (a tissue partitioning prediction method)
%    - forceEmpiricalAbsorptionModel  
%           a Boolean; if true, throws an error if DrugData-parameter 
%           'lambda_po' is undefined (default: false)

% ========================================================================%
% General structure
% ========================================================================%
function model = sMD_PBPK_12CMT_wellstirred()

    % an ODE model definition requires three parts: 
    % initialization, ODEs and output. See below for their definition
    
    model = OdeModel;
    
    model.initfun = @initfun;
    model.rhsfun  = @rhsfun;
    model.obsfun  = @obsfun;
    model.name    = mfilename;
    
end

% ========================================================================%
% Initialization of model
% ========================================================================%
function setup = initfun(phys, drug, ~, options)
%INITFUN Initialization of 12 CMT well-stirred model

    % assertions (model validity):     
    assert(isscalar(drug), 'Model not defined for multiple drugs.')
    assert(strcmp(drug.class,'sMD'), ['Model not defined for drug class "' drug.class '".'])
    
    % indexing
    tissues = {'lun','adi','hea','kid','mus','bon','ski','gut','spl','liv','art','ven'};
    [queryphys, querydrug, I] = loaddatabases(phys, drug, tissues);

    I = addcmtidx(I,'GItract','IVbag','IVrate','metab'); 
    
    Ig = struct;  % groupings
    Ig.organs    = [I.lun I.adi I.hea I.kid I.mus I.bon I.ski I.gut I.spl I.liv];
    Ig.artInflow = [      I.adi I.hea I.kid I.mus I.bon I.ski I.gut I.spl      ];
    Ig.intoVen   = [      I.adi I.hea I.kid I.mus I.bon I.ski             I.liv];
    Ig.intoLiv   = [                                          I.gut I.spl      ];
        
    % ---------------------------------------------------------------------
    % Define species-specific parameters

    % vascular and tissue volumes of the different organs 
    V.vas = queryphys('Vvas');
    V.tis = queryphys('Vtis');
    
    % cellular volume (for potential use in obsfun)
    V.cel = queryphys('fcelVtis') .* V.tis;
    
    % determine (arterial/venous) blood volume not related to any organ
    V.blo = queryphys('Vtbl') - sum(V.vas(Ig.organs));

    V.art = queryphys('fartVtbl') * V.blo;
    V.ven = queryphys('fvenVtbl') * V.blo;
    
    % volumes for blood compartments, for consistency
    V.vas([I.art I.ven]) = [V.art V.ven];
    V.tis([I.art I.ven]) = 0*u.L;
    V.cel([I.art I.ven]) = 0*u.L;  

    % derived volumes (total tissue volumes of all organs + blood)
    V.tot = V.vas + V.tis;    
    
    % blood flows (ensure closed circulatory system!)
    Q.blo = queryphys('Qblo');
    Q.co  = sum(Q.blo(Ig.intoVen)); % updated cardiac output
    Q.blo([I.ven I.lun I.art]) = Q.co;

    % hematocrit
    hct = queryphys('hct');
    
    % Definition of dosing target struct
    Id = struct;
    
    Id.Bolus.iv.cmt     = I.ven;
    Id.Bolus.iv.scaling = 1;       % to be removed later
    
    Id.Infusion.iv.bag  = I.IVbag;
    Id.Infusion.iv.rate = I.IVrate;

    Id.Oral.cmt         = I.GItract;
        
    % -------------------------------------------------------------------
    % Define drug-specific parameters

    MW = querydrug('MW');
    
    tissuepartitioning = getfrom(options, 'tissuePartitioning');
    [K, f] = tissuepartitioning(phys, drug, tissues);
    
    % set fu to 1 for cel/int in blood cmt, for consistency
    fu = f.u;
    fu.int([I.art I.ven]) = 1;
    fu.cel([I.art I.ven]) = 1;

    % set fn to 1 for cel/int in blood cmt, for consistency
    fn = f.n;
    fn.int([I.art I.ven]) = 1;
    fn.cel([I.art I.ven]) = 1;
    
    % total tissue-to-blood partition coefficients
    BP = querydrug('BP');
    fuB = querydrug('fuP')/BP;
    K.tis = K.tis_up * fuB;     
    
    K.tot      = ( V.vas + V.tis.*K.tis ) ./ V.tot;

    % set (e)K.tis to NaN for blood cmt (for consistency; tissue conc = NaN)
    K.tis([I.art I.ven])  = NaN;  

    % Currently, K.tis_up(I.ven) = Cblo/Cup, which is conflicting with 
    % K.tis(I.ven) = Ctis(ven)/Cblo = NaN. Hence, K.tis_up shouldn't be 
    % used until rodgersrowland() is adapted consistently.
    K = rmfield(K,'tis_up');
    
    % hepatic intrinsic clearance and extraction ratio based on well-stirred 
    % tissue model
    CLuint.hep   = querydrug('CLint_hep_perOWliv') * queryphys('OWtis','liv');

    E.hep       = ( CLuint.hep*fuB ) / ( Q.blo(I.liv)+CLuint.hep*fuB );

    % elimination corrected partition coefficients
    eK.tot        = K.tot;                  % all except for liver
    eK.tot(I.liv) = (1-E.hep)*K.tot(I.liv);

    % fraction excreted in feces and metabolized in the gut
    E.gut = querydrug('Egut');
    E.feces = querydrug('Efeces');

    % first order po absorption rate constant, if relevant
    if  hasrecord(drug,'lambda_po') || getfrom(options,'forceEmpiricalAbsorptionModel',false)
        lambda_po = querydrug('lambda_po'); 
    else
        lambda_po = 0/u.h;
    end
    
    % Some additional informative parameter values
    %
    % BW  = sum of organ weights considered in the model
    % co  = cardiac output corresponding to the organs in the model
    % Vss = volume of distribution at steady state
    
    OWtis = queryphys('OWtis');
    add.BW      = sum( OWtis(Ig.organs) ) + queryphys('OWtbl'); 
    add.Vtotal  = sum( V.tis(Ig.organs) ) + queryphys('Vtbl'); 
    add.Vss.blo = V.blo + sum( eK.tot(Ig.organs).*V.tot(Ig.organs) ); 
    add.Vss.pla = add.Vss.blo * BP;
    add.CLblood.hep  = E.hep * Q.blo(I.liv);

    % initial condition and units of ODEs

    doseunit = u.ug;
    
    X0 = initializeX0(I);
    X0([I.art I.ven Ig.organs I.GItract I.IVbag I.metab]) = 0 * doseunit;
    X0(I.IVrate)  = 0 * doseunit / u.min;
            
    % -----------------------------------------------------------------------
    % Assign model parameters 
    setup = struct;
    setup.indexing.I  = I;
    setup.indexing.Ig = Ig;
    setup.indexing.Id = Id;
    setup.V           = V;
    setup.Q           = Q;
    setup.K           = K;
    setup.fu          = fu;
    setup.fn          = fn;
    setup.CLuint      = CLuint;
    setup.E           = E;
    setup.eK          = eK;
    setup.lambda_po   = lambda_po;
    setup.add         = add;
    setup.BP          = BP;
    setup.MW          = MW;
    setup.hct         = hct;
    setup.fuB         = fuB;
    setup.X0          = X0;
    
    % to be picked up by lump_model 
    setup.cmt         = fieldnames(I);
    [~,setup.physIdx] = ismember(tissues, fieldnames(I));
    setup.VK          = V.tot .* eK.tot;      
end


% ========================================================================%
% ODE system of the model
% ========================================================================%
function dX = rhsfun(t, X, setup) % t will be used for infusion rate
%RHSFUN ODE system of 12 CMT well-stirred model

    % initialize output vector
    X = X(:);
    dX = NaNsizeof(X);
    
    % model and indexing
    I = setup.indexing.I; 
    Ig = setup.indexing.Ig;

    % variables (always use column vector notation)
    A_tot = X(Ig.organs); 
    A_art = X(I.art); 
    A_ven = X(I.ven);
    A_GItract = X(I.GItract);

    % tissue volumes, blood flows, extraction ratios, clearance etc.
    V     = setup.V;
    Q     = setup.Q; 
    Q_hepart = Q.blo(I.liv) - sum(Q.blo(Ig.intoLiv)); % hepatic artery blood flow

    K     = setup.K;
    CLuint = setup.CLuint;
    E     = setup.E;

    fuB   = setup.fuB;
    
    % converting amounts to concentrations
    C_tot = A_tot ./ V.tot(Ig.organs); 
    C_art = A_art / V.art; 
    C_ven = A_ven / V.ven;

    % infusion
    infusion_rate = X(I.IVrate);

    % po administration
    lambda_po = setup.lambda_po; 

    % venous concentration leaving tissue
    C_vbl = C_tot./K.tot(Ig.organs);

    % inflowing concentration into liver and vein
    C_in_liv = ( sum( Q.blo(Ig.intoLiv).*C_vbl(Ig.intoLiv) ) + Q_hepart*C_art ) / Q.blo(I.liv);
    C_in_ven = sum( Q.blo(Ig.intoVen).*C_vbl(Ig.intoVen) ) / Q.co;

    % ---------------------------------------------------------------------
    % START OF ODEs (in mass units)
    
    dA_tot = NaNsizeof(C_tot);  % Different initialization necessary to support computation with/without units
    lun = I.lun; 
    liv = I.liv;

    % lung 
    dA_tot(lun) = Q.co*(C_ven - C_vbl(lun));

    % artery
    dA_art = Q.co*(C_vbl(lun) - C_art);

    % all tissues that are directly supplied by the artery
    orgA = Ig.artInflow; 
    dA_tot(orgA) = Q.blo(orgA).*(C_art - C_vbl(orgA));

    % liver
    dA_tot(liv) = Q.blo(liv)*(C_in_liv - C_vbl(liv)) ...
                    - CLuint.hep*fuB*C_vbl(liv) + (1-E.gut)*(1-E.feces)*lambda_po*A_GItract;
    % vein
    dA_ven = Q.co*(C_in_ven - C_ven) + infusion_rate;

    % drug amount in GItract for absorption
    dA_GItract = -lambda_po*A_GItract;

    % drug amount in IVbag for infusion
    dA_IVbag   = -infusion_rate;

    % Change of infusion rate
    d_IVrate   = 0 * unitsOf(X(I.IVrate) / t);

    % drug amount metabolized or excreted
    dA_metab   = +CLuint.hep*fuB*C_vbl(liv) + (1-(1-E.gut)*(1-E.feces))*lambda_po*A_GItract;

    % END OF ODEs 
    % -----------------------------------------------------------------------

    % output vector (always in column vector notation)
    dX(Ig.organs) = dA_tot;
    dX(I.art)     = dA_art;
    dX(I.ven)     = dA_ven;
    dX(I.GItract) = dA_GItract;
    dX(I.metab)   = dA_metab;
    dX(I.IVbag)   = dA_IVbag;
    dX(I.IVrate)  = d_IVrate;

end

% ========================================================================%
% Definition of observable quantities
% ========================================================================%
function yobs = obsfun(output, setup, obs)
%OBSFUN Observables in 12 CMT well-stirred model
%   The following observables are supported:
%   
%   Type 'PBPK':
%       Site:     'adi','bon','gut','hea','kid','liv','lun','mus','ski','spl','art','ven'
%       Subspace: 'cel','ery','exc','int','pla','tis','tot','vas'
%       Binding:  'total','unbound'
%       UnitType: 'Mass','Amount','Mass/Volume','Amount/Volume'
%   
%   Type 'SimplePK':
%       Site:     'pla'
%       Binding:  'total','unbound'
%       UnitType: 'Mass/Volume','Amount/Volume'
%   
%   Type 'ArmVein':
%       Subspace: 'ery','pla','vas'
%       Binding:  'total','unbound'
%       UnitType: 'Mass/Volume','Amount/Volume'
%   
%   Type 'NormalizedConc':
%       Site:     'adi','bon','gut','hea','kid','liv','lun','mus','ski','spl','art','ven'
%       Subspace: 'tot'
%    
%   Type 'MassBalance':
%       UnitType: 'Mass','Amount'

    I = setup.indexing.I;

    modelsites = {'adi','bon','gut','hea','kid','liv','lun','mus','ski','spl','art','ven'};
    
    yobs = []; % if obs matches a case below, yobs will be overwritten
    
    switch obs.type
        case 'PBPK'      % Site, Subspace, Binding, Unit
            
            % Site
            site = obs.attr.Site;
            if ismember(site, modelsites)
                % Vascular concentration (Mass/Volume units)
                Cvas = output.X(:,I.(site)) / (setup.V.tot(I.(site)) * setup.K.tot(I.(site)));
            else
                return
            end
            
            % Sub-compartmentalized quantities (at the most refined level)
            Vcel  = setup.V.cel(I.(site));
            Vint  = setup.V.tis(I.(site)) - Vcel;
            Very  = setup.hct * setup.V.vas(I.(site));
            Vpla  = setup.V.vas(I.(site)) - Very;
            
            fuery = setup.fu.ery;
            fupla = setup.fu.pla;
            fuint = setup.fu.int(I.(site));
            fucel = setup.fu.cel(I.(site));
            
            % partition coefficients Csub/Cvas
            Kery  = (1 - (1-setup.hct)/setup.BP)/setup.hct;
            Kpla  = 1/setup.BP;
            Kint  = setup.fuB / fuint;
            Kcel  = setup.fuB / fucel * (setup.fn.pla/setup.fn.cel(I.(site)));            
            
            % Subspace
            spc = obs.attr.Subspace;
            switch spc
                case 'cel' %cellular
                    Vsub     = Vcel;
                    Ksub_vas = Kcel;
                    fusub    = fucel;
                case 'ery' %erythrocytes                   
                    Vsub     = Very; 
                    Ksub_vas = Kery;
                    fusub    = fuery;
                case 'exc' %extracellular
                    Vsub     = [Very  Vpla  Vint ];
                    Ksub_vas = [Kery  Kpla  Kint ];
                    fusub    = [fuery fupla fuint];                    
                case 'int' %interstitial
                    Vsub     = Vint;
                    Ksub_vas = Kint;
                    fusub    = fuint;
                case 'pla' %plasma
                    Vsub     = Vpla;
                    Ksub_vas = Kpla;
                    fusub    = fupla;
                case 'tis' %tissue
                    Vsub     = [Vint  Vcel];
                    Ksub_vas = [Kint  Kcel];
                    fusub    = [fuint fucel];
                case 'tot' %total
                    Vsub     = [Very  Vpla  Vint  Vcel];
                    Ksub_vas = [Kery  Kpla  Kint  Kcel];
                    fusub    = [fuery fupla fuint fucel];
                case 'vas' % vascular
                    Vsub     = [Very  Vpla ];
                    Ksub_vas = [Kery  Kpla ];
                    fusub    = [fuery fupla];
                otherwise 
                    return
            end
            Asub = Vsub .* Ksub_vas .* Cvas;     % sub-compartmentalized amount (bound+unbound, Mass units) 

            % Binding
            switch obs.attr.Binding
                case 'total'
                    Aspc = sum(Asub, 2);          % sum over sub(-cmts)
                case 'unbound'
                    Aspc = sum(Asub .* fusub, 2); % sum over unbound in sub
                otherwise 
                    return
            end
            % Aspc = amount in subspace (binding included, Mass units)

            % Units
            switch obs.attr.UnitType
                case 'Mass'
                    yspc = Aspc;
                case 'Mass/Volume'
                    Vspc = sum(Vsub);
                    yspc = Aspc / Vspc;
                case 'Amount'
                    yspc = Aspc / setup.MW;
                case 'Amount/Volume'
                    Vspc = sum(Vsub);
                    yspc = (Aspc / setup.MW) / Vspc;
                otherwise 
                    return
            end
            
            % all checks passed and all steps processed: return the result
            yobs = yspc;
            
            % raise warning if 'non-physiological' observable is requested
            if ismember(site,{'art','ven'}) && ismember(spc,{'tis','int','cel'})
                msg = 'Non-physiological observable requested (Site=%s, Subspace=%s).';
                warning(msg, site, spc)
            end
                
        case 'SimplePK'  % Site, Binding, Unit
            site = obs.attr.Site;
            if strcmp(site, 'pla')
                ytmp = output.X(:,I.ven) / (setup.V.ven * setup.BP); % bound+unbound, Mass/Volume units
            else
                return
            end
            switch obs.attr.Binding
                case 'total'
                    % do nothing, ytmp already has correct binding type
                case 'unbound'
                    ytmp = ytmp * setup.fu.pla;
                otherwise 
                    return
            end
            switch obs.attr.UnitType 
                case 'Mass/Volume'
                    % do nothing, ytmp already has correct unit type
                case 'Amount/Volume'
                    ytmp = ytmp / setup.MW;
                otherwise 
                    return
            end
            yobs = ytmp;

        case 'ArmVein'

            % Arm vein = mix of adipose, muscle, skin, artery
            amsa = [I.adi I.mus I.ski I.art];

            % Unbound fractions
            fuery = setup.fu.ery;
            fupla = setup.fu.pla;

            % Abbreviations
            hct = setup.hct;
            BP  = setup.BP;

            % Partition coefficients relating exc to vas/ery/pla spaces
            Kvas_tot = 1 ./ setup.K.tot(amsa)';
            Kery_vas = (1 - (1-hct)/BP)/hct;
            Kpla_vas = 1/BP;
            
            % Total and vascular muscle/skin concentrations
            Ctot_amsa = output.X(:,amsa) ./ setup.V.tot(amsa)';               
            Cvas_amsa = Kvas_tot .* Ctot_amsa;

            % Concentrations in vas/ery/pla subspaces of arm vein
            Cvas_arm = 0.075 * Cvas_amsa(:,1) ...    % adi
                         + 0.05 * Cvas_amsa(:,2) ... % mus
                         + 0.775 * Cvas_amsa(:,3) ...% ski
                         + 0.1 * Cvas_amsa(:,4);     % art
            Cery_arm = Kery_vas .* Cvas_arm;
            Cpla_arm = Kpla_vas .* Cvas_arm;
            
            % Subspace
            spc = obs.attr.Subspace;
            switch spc
                case 'ery' %erythrocytes                   
                    Csub  = Cery_arm;
                    fusub = fuery;
                case 'pla' %plasma
                    Csub  = Cpla_arm;
                    fusub = fupla;
                case 'vas' % vascular
                    Csub  = [hct*Cery_arm (1-hct)*Cpla_arm];
                    fusub = [fuery    fupla];
                otherwise 
                    return
            end

            % Binding
            switch obs.attr.Binding
                case 'total'
                    Cspc = sum(Csub, 2);          % sum over sub(-cmts)
                case 'unbound'
                    Cspc = sum(Csub .* fusub, 2); % sum over unbound in sub
                otherwise 
                    return
            end

            % Units
            switch obs.attr.UnitType
                case 'Mass/Volume'
                    yspc = Cspc;
                case 'Amount/Volume'
                    yspc = Cspc / setup.MW;
                otherwise 
                    return
            end
            yobs = yspc;

        case 'NormalizedConc'      % Site, Subspace
            
            % Site
            site = obs.attr.Site;
            if ismember(site, modelsites)
                % Normalized concentration (Mass/Volume units)
                ytmp = output.X(:,I.(site)) / (setup.V.tot(I.(site)) * setup.eK.tot(I.(site)));
            else
                return
            end
            
            if ~strcmp(obs.attr.Subspace,'tot')
                msg = ['In the well-stirred model, normalized concentrations ' ...
                    'can only be calculated for subspace "tot".'];
                warning(msg)
                return
            end

            % all checks passed and all steps processed: return the result
            yobs = ytmp;
 
        case 'MassBalance'
            iIV = I.IVrate;
            ytmp = sum(output.X(:,[1:(iIV-1) (iIV+1):end]),2);
            switch obs.attr.UnitType
                case 'Mass'
                    % do nothing, ytmp already has correct unit type
                case 'Amount'
                    ytmp = ytmp / setup.MW; 
                otherwise
                    return
            end
            yobs = ytmp;
    end
        
end

