%SMD_LUMPEDPBPK_XCMT_WELLSTIRRED x-cmt lumped 12cmt well-stirred PBPK model
%    This function specifies a lumped PBPK model for sMD (small molecule 
%    drugs) with well-stirred tissue distribution and hepatic clearance
%   
%    To execute this model, the following options must be defined:
%   
%    - tissuePartitioning     a function handle (a tissue partitioning 
%                             prediction method)
%
%    - lumpingScheme          a cell array of cellstr (a partitioning of
%                             the 12 physiological compartments) 
%   
%    - useEmpiricalAbsorptionModel  a Boolean, should a first-order
%                                   absorption compartment be used 
%                                   (default: true)?
%
%    As an example, lumpingScheme could be
%
%    { {'ven','lun','art','hea','kid','gut','spl','liv','ski'}, ...
%      {'mus','adi','bon'} }

% ========================================================================%
% General structure
% ========================================================================%
function model = sMD_lumpedPBPK_xCMT_wellstirred()

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
%INITFUN Initialize the x-cmt lumped 12cmt well-stirred PBPK model.
    % assertions (model validity): 
    assert(isscalar(drug), 'Model not defined for multiple drugs.')
    assert(strcmp(drug.class,'sMD'), ['Model not defined for drug class "' drug.class '".'])
    
    % indexing
    tissues = {'lun','adi','hea','kid','mus','bon','ski','gut','spl','liv','art','ven'};
    [queryphys, querydrug, I] = loaddatabases(phys, drug, tissues);
    
    Ig = struct;  % groupings
    Ig.organs    = [I.lun I.adi I.hea I.kid I.mus I.bon I.ski I.gut I.spl I.liv];
    Ig.artInflow = [      I.adi I.hea I.kid I.mus I.bon I.ski I.gut I.spl      ];
    Ig.intoVen   = [      I.adi I.hea I.kid I.mus I.bon I.ski             I.liv];
    Ig.intoLiv   = [                                          I.gut I.spl      ];
        
    % -----------------------------------------------------------------------
    % Define species-specific parameters

    % vascular, tissue and total tissue volumes of the different organs 
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
    
    %%% -----------------------------------------------------------------------
    %%% Define drug-specific parameters

    tissuepartitioning = getfrom(options, 'tissuePartitioning');
    [K, f] = tissuepartitioning(phys, drug, tissues);
    
    %%% set fu to 1 for cel/int in blood cmt, for consistency
    fu = f.u;
    fu.int([I.art I.ven]) = 1;
    fu.cel([I.art I.ven]) = 1;
    
    % set fn to 1 for cel/int in blood cmt, for consistency
    fn = f.n;
    fn.int([I.art I.ven]) = 1;
    fn.cel([I.art I.ven]) = 1;

    %%% total tissue-to-blood partition coefficients
    BP = querydrug('BP');
    fuB = querydrug('fuP')/BP;
    K.tis = K.tis_up * fuB;    
    
    K.tot      = ( V.vas + V.tis.*K.tis ) ./ V.tot;

    %%% hepatic intrinsic clearance and extraction ratio based on well-stirred tissue model
    %%%
    CLuint.hep   = querydrug('CLint_hep_perOWliv') * queryphys('OWtis','liv');

    K_liv           = K.tis(I.liv);
    E.hep.tis       = ( CLuint.hep*fuB ) / (Q.blo(I.liv) + CLuint.hep*fuB);

    %%% elimination corrected partition coefficients
    eK.tis      = K.tis; % all except for liver
    eK.tis(I.liv) = (1-E.hep.tis)*K_liv;

    eK.tot = ( V.tis.*eK.tis + V.vas ) ./ V.tot;

    %%% fraction excreted in feces and metabolized in the gut
    E.gut = querydrug('Egut');
    E.feces = querydrug('Efeces');

    %%% (oral) bioavailablility 
    F.bio = (1-E.hep.tis)*(1-E.gut)*(1-E.feces);
    F.gh  = (1-E.gut)*(1-E.feces);

    %%% first order po absorption rate constant, if relevant
    if getfrom(options,'useEmpiricalAbsorptionModel',true)
        lambda_po = querydrug('lambda_po'); 
    else
        lambda_po = 0/u.h;
    end
    
    %%% -----------------------------------------------------------------------
    %%% Determine lumped PBPK model parameter values based on the above 
    %%% parameter values of the detailed PBPK model
    %%%
    %%% -----------------------------------------------------------------------

    %%% To simplified coding of the lumping approach, define total tissue 
    %%% parameters also for ven and art 
    V.tot(I.art) = V.art; 
    V.tot(I.ven) = V.ven;

    K.tot([I.art I.ven])  = 1;
    eK.tot([I.art I.ven]) = 1;

    E.tis = zeros(size(V.tot));
    E.tis(I.liv) = E.hep.tis;


    %%% -----------------------------------------------------------------------
    %%% Define indexing of lumped PBPK model

    % transform lumping cell array with organ names into cell array with 
    % corresponding index numbers

    lumping = getfrom(options, 'lumpingScheme');

    assert(issetequal([lumping{:}], tissues), ...
        'Organs listed in options.lumpingScheme do not match the detailed PBPK model to be lumped!')
    assert(sum(cellfun(@(x) all(ismember({'ven','art','lun'},x)), lumping)) == 1, ...
        'Organs "ven", "art" and "lun" must be lumped into the same compartment.')
    assert(any(cellfun(@(x) issetequal({'liv'},x),lumping)) || ...
                any(cellfun(@(x) all(ismember({'liv','ven'},x)), lumping)), ...
        'Organ "liv" must either be lumped together with "ven" or kept along in a separate compartment.')

    nlump = numel(lumping);

    Il = struct;
    Il.cmt = cell(nlump,1);
    for n = 1:nlump
        for k = 1:numel(lumping{n})
            Il.cmt{n}(k) = I.(lumping{n}{k});
        end
    end

    % groupings (of lumped compartments)
    Ig = struct;

    % lumped compartments containing ven, liv (and kid)
    Ig.cen = find(cellfun(@(x) ismember('ven', x), lumping),1);
    Ig.liv = find(cellfun(@(x) ismember('liv', x), lumping),1);
%    Ig.kid = find(cellfun(@(x) ismember('kid', x), lumping),1);

    % other groupings 
    Ig.alltis = 1:nlump;
    Ig.allExCen = setdiff(Ig.alltis, Ig.cen);

    % dosing and metabolism indexing
    %Il = addcmtidx(Il,'GItract','IVbag','IVrate','metab'); 
    Il.GItract = max(Ig.alltis) + 1;
    Il.IVbag   = max(Il.GItract) + 1;
    Il.IVrate  = max(Il.IVbag) + 1;
    Il.metab   = max(Il.IVrate) + 1;    

    %%% -----------------------------------------------------------------------
    %%% Define lumped PBPK model parameters 

    V.lump  = unan(nlump,1); 
    Q.lump  = unan(nlump,1);
    CL.lump = unan(nlump,1);
    K.lump  = unan(nlump,1);    % TODO: added, discuss
    eK.lump = unan(nlump,1);

    for n = 1:nlump
        ind = Il.cmt{n};
        V.lump(n)  = sum(V.tot(ind)); 
        Q.lump(n)  = sum(Q.blo(ind));
        CL.lump(n) = sum(Q.blo(ind).* E.tis(ind));
        K.lump(n)  = sum(V.tot(ind).* K.tot(ind))/V.lump(n);
        eK.lump(n) = sum(V.tot(ind).*eK.tot(ind))/V.lump(n);
    end
    Q.lump(Ig.cen) = sum(Q.lump(Ig.allExCen));


    % Definition of dosing target struct
    Id = struct;

    Id.Bolus.iv.cmt     = Ig.cen;
    Id.Bolus.iv.scaling = V.lump(Ig.cen);

    Id.Infusion.iv.bag  = Il.IVbag;
    Id.Infusion.iv.rate = Il.IVrate;

    Id.Oral.cmt         = Il.GItract;

    % initial condition and units of ODE
    doseunit = u.ug;

    X0 = unan(nlump+4,1);
    X0(Ig.alltis) = 0*doseunit / u.L;
    X0(Il.GItract) = 0*doseunit;
    X0(Il.IVbag)   = 0*doseunit;
    X0(Il.IVrate)  = 0*doseunit / u.min;
    X0(Il.metab)   = 0*doseunit;

    % ---------------------------------------------------------------------
    % Assign model parameters 
    
    setup = struct;
    setup.indexing.I  = I;
    setup.indexing.Il = Il;
    setup.indexing.Ig = Ig;
    setup.indexing.Id = Id;
    setup.V           = V;
    setup.Q           = Q;
    setup.K           = K;
    setup.fu          = fu;
    setup.fn          = fn;
    setup.CLuint      = CLuint;
    setup.CL          = CL;
    setup.E           = E;
    setup.F           = F;
    setup.eK          = eK;
    setup.lambda_po   = lambda_po;
    setup.BP          = BP;
    setup.hct         = hct;
    setup.fuB         = fuB;
    setup.lumping     = lumping;
    setup.X0          = X0;
    
end

% ========================================================================%
% ODE system of the model
% ========================================================================%
function dX = rhsfun(t, X, setup) % t will be used for infusion rate
%RHSFUN ODE system of the x-cmt lumped 12cmt well-stirred PBPK model.

    % initialize output vector
    X = X(:);
    dX = NaNsizeof(X);
    
    % model and indexing
    Il = setup.indexing.Il; 
    Ig = setup.indexing.Ig;
    
    % variables (always use column vector notation)
    C_lump = X(Ig.alltis); 
    A_GItract = X(Il.GItract);
    infusion_rate = X(Il.IVrate);

    %%% tissue volumes, blood flows, extraction ratios, clearance etc.
    V  = setup.V.lump;
    Q  = setup.Q.lump; 
    CL = setup.CL.lump;
    eK = setup.eK.lump;
    F  = setup.F;

    %%% po administration
    lambda_po = setup.lambda_po; 

    if Ig.liv == Ig.cen
        F.lump = F.bio;
    else
        F.lump = F.gh;
    end

    %%% -----------------------------------------------------------------------
    %%% START OF ODEs
    %%%
    VdC_lump = NaNsizeof(C_lump);

    if length(Ig.alltis) > 1
        Cin_cen         = sum(Q(Ig.allExCen).*C_lump(Ig.allExCen)./eK(Ig.allExCen)) / Q(Ig.cen);

        VdC_lump(Ig.allExCen) = Q(Ig.allExCen).*(C_lump(Ig.cen)/eK(Ig.cen) ...
                               -C_lump(Ig.allExCen)./eK(Ig.allExCen));
        VdC_lump(Ig.cen)      = Q(Ig.cen)*(Cin_cen - C_lump(Ig.cen)/eK(Ig.cen)) ...
                               -CL(Ig.liv)*C_lump(Ig.liv)/eK(Ig.liv) + infusion_rate; 
    else
        VdC_lump(Ig.cen)      = -CL(Ig.liv)*C_lump(Ig.liv)/eK(Ig.liv) + infusion_rate; 
    end
    VdC_lump(Ig.liv) = VdC_lump(Ig.liv) + F.lump * lambda_po * A_GItract;

    %%% drug amount in GItract for absorption
    dA_GItract = -lambda_po*A_GItract;

    %%% drug amount in IVbag for infusion
    dA_IVbag = -infusion_rate;

    %%% metabolized and excreted compound (mass)
    dA_metab = CL(Ig.liv)*C_lump(Ig.liv)/eK(Ig.liv) + (1-F.lump)*lambda_po*A_GItract; 

    %%%
    %%% END OF ODEs 
    %%% -------------------------------------------------------------------

    %%% converting amounts to concentrations
    dC_lump = VdC_lump ./ V;

    %%% output vector (always in column vector notation)
    dX(Ig.alltis)  = dC_lump;
    dX(Il.GItract) = dA_GItract;
    dX(Il.IVbag)   = dA_IVbag;
    dX(Il.metab)   = dA_metab;
    dX(Il.IVrate)  = 0 * unitsOf(X(Il.IVrate) / t);
    
end

% ========================================================================%
% Definition of observable quantities
% ========================================================================%
function yobs = obsfun(output, setup, obs)
%OBSFUN Observables in x-cmt lumped 12 CMT well-stirred PBPK model
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
%   Type 'MassBalance':
%       UnitType: 'Mass,'Amount'

    I = setup.indexing.I;
    Ig = setup.indexing.Ig;
    Il = setup.indexing.Il;
    lumping = setup.lumping;
    
    nonElim = {'adi','bon','gut','hea','kid','lun','mus','ski','spl','art','ven'};
    
    yobs = []; % if obs matches a case below, yobs will be overwritten
    
    switch obs.type
        case 'PBPK'      % Site, Subspace, Binding, UnitType
            
            % Site
            site = obs.attr.Site;
            if ismember(site, nonElim)
                
                isite = cellfun(@(x) ismember(site,x), lumping);
                Cvas = output.X(:,isite) / setup.eK.lump(isite);  % Vascular concentration (Mass/Volume units)
           
            elseif strcmp(site,'liv')

                isite = cellfun(@(x) ismember(site,x), lumping);
                Cvas = output.X(:,isite) / setup.eK.lump(isite) * (1-setup.E.hep.tis);  % Vascular concentration (Mass/Volume units)

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

            % Unit type
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
                
        case 'SimplePK'  % Site, Binding, UnitType
            site = obs.attr.Site;
            if strcmp(site, 'pla')
                ytmp = output.X(:,Ig.cen) * (setup.eK.tot(I.ven) / setup.eK.lump(Ig.cen)) / setup.BP;% bound+unbound, Mass/Volume units
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

        case 'MassBalance'
            Ig = setup.indexing.Ig;
            ytmp = output.X(:,Ig.alltis) * setup.V.lump ...
                    + output.X(:,Il.IVbag) ...
                    + output.X(:,Il.metab) ...
                    + output.X(:,Il.GItract);
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

