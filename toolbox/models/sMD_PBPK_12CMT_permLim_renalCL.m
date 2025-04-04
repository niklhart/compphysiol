%SMD_PBPK_12CMT_PERMLIM_RENALCL Perm.-lim. 12cmt-PBPK model with renal CL.
%   This function specifies a 12 cmt PBPK model for sMD (small molecule 
%   drugs) with permeability-limited tissue distribution and hepatic and
%   renal clearance.
%   
%   Model parameters to be specified:
%       P          Permeability (a scalar DimVar with unit type Velocity,
%                  i.e., Length/Time)
%   
%   Mandatory model options (no default):
%   - tissuePartitioning     a function handle (a tissue partitioning 
%                            prediction method)
%
%    Model options with a default:
%    - useEmpiricalAbsorptionModel  a Boolean specifying if a first-order
%                                   absorption compartment should be used 
%                                   (default: false)
%    - Vmax                         an Amount/Time type DimVar (maximum 
%                                   secretory clearance, default: 0 mol/h)
%    - Km                           an Amount/Volume type DimVar
%                                   (concentration of half-maximal
%                                   secretory clearance, default: 0 mol/L)

% ========================================================================%
% General structure
% ========================================================================%
function model = sMD_PBPK_12CMT_permLim_renalCL()

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
%INITFUN Initialization of 12 CMT perm.-lim. model with renal CL

    % assertions (model validity): 
    assert(isscalar(drug), 'Model not defined for multiple drugs.')
    assert(strcmp(drug.class,'sMD'), ['Model not defined for drug class "' drug.class '".'])
    
    % indexing
    organs = {'lun','adi','hea','kid','mus','bon','ski','gut','spl','liv'};
    tissues = [organs,{'art','ven'}];
    [queryphys, querydrug, I] = loaddatabases(phys, drug, tissues);

    I = addcmtidx(I,'GItract','IVbag','IVrate','metab'); 
    
    Ig = struct;  % groupings
    Ig.organs    = [I.lun I.adi I.hea I.kid I.mus I.bon I.ski I.gut I.spl I.liv];
    Ig.artInflow = [      I.adi I.hea I.kid I.mus I.bon I.ski I.gut I.spl      ];
    Ig.intoVen   = [      I.adi I.hea I.kid I.mus I.bon I.ski             I.liv];
    Ig.intoLiv   = [                                          I.gut I.spl      ];
        
    Ig.exc = [I.lun I.adi I.hea I.kid I.mus I.bon I.ski I.gut I.spl I.liv];
    Ig.cel = Ig.exc + numel(fieldnames(I));
    
    % ---------------------------------------------------------------------
    % Define species-specific parameters

    % vascular, tissue and total tissue volumes of the different organs 
    V.vas = queryphys('Vvas');
    V.tis = queryphys('Vtis');
    
    % cellular subspace volume
    fcelVtis = queryphys('fcelVtis');
    V.cel = fcelVtis .* V.tis;

    % determine (arterial/venous) blood volume not related to any organ
    V.blo = queryphys('Vtbl') - sum(V.vas(Ig.organs));

    V.art = queryphys('fartVtbl') * V.blo;
    V.ven = queryphys('fvenVtbl') * V.blo;

    % volumes for blood compartments, for consistency
    V.vas([I.art I.ven]) = [V.art V.ven];
    V.tis([I.art I.ven]) = 0*u.L;
    V.cel([I.art I.ven]) = 0*u.L;  
    
    % derived volumes (Vtot = Vas+Vint+Vcel, Vexc = Vvas+Vint)
    V.tot = V.vas + V.tis;
    V.int = V.tis - V.cel;
    V.exc = V.vas + V.int;

    % blood flows (ensure closed circulatory system!)
    Q.blo = queryphys('Qblo');
    Q.co  = sum(Q.blo(Ig.intoVen)); % updated cardiac output
    Q.blo([I.ven I.lun I.art]) = Q.co;

    % hematocrit
    hct = queryphys('hct');
    
    % renal CL model
    GFR    = queryphys('GFR');
    if ~hasrecord(drug,'Freabs')
        warning(['Drug parameter "Freabs" not defined for compound "%s",' ...
                 ' assuming full reabsorption.'], drug.name)
        Freabs = 1;
    else
        Freabs = querydrug('Freabs');
    end

    % Optional Michaelis-Menten parameters for tubular secretion
    Vmax = getfrom(options,'Vmax',0*u.mol/u.h);
    Km   = getfrom(options,'Km',  eps(1)*u.mol/u.L);
    
    % Definition of dosing target struct
    Id = struct;
    
    Id.Bolus.iv.cmt     = I.ven;
    Id.Bolus.iv.scaling = 1;
    
    Id.Infusion.iv.bag  = I.IVbag;
    Id.Infusion.iv.rate = I.IVrate;

    Id.Oral.cmt         = I.GItract;
        
    %%% -------------------------------------------------------------------
    %%% Define drug-specific parameters

    MW = querydrug('MW');

    tissuepartitioning = getfrom(options, 'tissuePartitioning');

    [K, f] = tissuepartitioning(phys, drug, tissues);
    

    % set fu to 1 for cel/int in blood cmt, for consistency
    fu = f.u;
    fu.int([I.art I.ven]) = 1;
    fu.cel([I.art I.ven]) = 1;

    fn = f.n;
    
    % total tissue-to-blood partition coefficients
    BP  = querydrug('BP');
    fuP = querydrug('fuP');
    fuB = fuP/BP;
    K.tis = K.tis_up * fuB;
    
    K.tot      = ( V.vas + V.tis.*K.tis ) ./ V.tot;

    % Currently, K.tis_up(I.ven) = Cblo/Cup, which is conflicting with 
    % K.tis(I.ven) = Ctis(ven)/Cblo = NaN. Hence, K.tis_up shouldn't be 
    % used until rodgersrowland() is adapted consistently.
    K = rmfield(K,'tis_up');
    
    
    % determine vas:(vas+int) and uint:(vas+int) partition coefficients 
    % based on the assumption that Cu_pla = Cu_int
    K_u_exc  = 1 ./ ( V.vas(Ig.organs)./V.exc(Ig.organs) * BP/fuP + V.int(Ig.organs)./V.exc(Ig.organs) ./fu.int(Ig.organs) );
    
    % unbound interstitial-to-(vas+int) partition coefficient
    K.int_exc     = K_u_exc./fu.int(Ig.organs);

    % vascular-to-(vas+int) partition coefficient
    K.vas_exc     = K_u_exc * BP/fuP;  
    
    % Equations for surface are extracted from MoBi in PKSim.
    % - VrefRat values are reasonably close to Vtot of the rat physiology 
    %   currently used in the toolbox, except that:
    %       * adi and bon values fit much better when interchanged
    %       * kid value is 3.5 fold larger in PK-Sim
    %       * gut value is 3 fold larger in PK-Sim
    %       * spl value is 2 fold larger in PK-Sim
    % - SArefRat values are completely different from any physiological 
    %   surface area, they are probably rather effective SA values already
    %   accounting for differences in physiology, uptake mechanisms, etc.

    VrefRat = NaNsizeof(V.tot);     SArefRat = NaNsizeof(V.tot);

    VrefRat(I.lun) =  2.2  *u.mL;   SArefRat(I.lun) = 0.096 *u.m^2;
    VrefRat(I.adi) = 14.2  *u.mL;   SArefRat(I.adi) = 5     *u.m^2;
%    VrefRat(I.bra) =  1.671*u.mL;   SArefRat(I.bra) = 0.0006*u.m^2;
    VrefRat(I.hea) =  1.2  *u.mL;   SArefRat(I.hea) = 7.54  *u.m^2;
    VrefRat(I.kid) =  7    *u.mL;   SArefRat(I.kid) = 1000  *u.m^2;
    VrefRat(I.mus) =110.1  *u.mL;   SArefRat(I.mus) = 7.54  *u.m^2;
    VrefRat(I.bon) = 28.2  *u.mL;   SArefRat(I.bon) =10     *u.m^2;
    VrefRat(I.ski) = 43.4  *u.mL;   SArefRat(I.ski) = 0.12  *u.m^2;
    VrefRat(I.gut) = 22.2  *u.mL;   SArefRat(I.gut) = 2000  *u.m^2;  % sum of large+small intestine
    VrefRat(I.spl) =  1.3  *u.mL;   SArefRat(I.spl) = 1000  *u.m^2;
    VrefRat(I.liv) = 10    *u.mL;   SArefRat(I.liv) =82     *u.m^2;

    SA = (V.tot./VrefRat).^0.75 .* SArefRat;
    
    %%% TODO: trying to understand the above values, to be removed later
    V_single_cell  = 1e-12*u.L;                                 % human hepatocyte volume 
    SA_single_cell = 4*pi * ( V_single_cell * 3/(4*pi) )^(2/3); % spherical geometry assumed    
    N_cells        = V.cel / V_single_cell;
    SA_naive       = N_cells * SA_single_cell;
    % --> SA_naive yields very different orders of magnitude for SA than 
    %     the PK-Sim method; the two methods yield completely uncorrelated
    %     values.

    % Permeability  (e.g. from Caco2 or PAMPA assay)
    P  = querydrug('cellPerm');

    % Permeability-surface-area product (PS) 
    PS = P * SA; 
    
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    
    % define hepatic clearance with respect to cel tissue concentration by
    % relating CLint to the cellular organ weight
    CLuint = querydrug('CLint_hep_perOWliv') * queryphys('OWtis','liv');
    CLucel = PS(I.liv)*fn.cel(I.liv)*CLuint/(PS(I.liv)*fn.int(I.liv)-CLuint);

    %%% additional partition coefficients (book notation)
    K.exc = V.vas ./ V.exc + V.int ./ V.exc .* fuB ./ fu.int;
    K.cel = fn.pla * fuB ./ (fn.cel .* fu.cel);

    %%% elimination corrected partition coefficients (book notation)
    eK = struct;
    eK.exc = K.exc;
    eK.cel = K.cel;
    eK.cel(I.liv) = PS(I.liv) * fn.pla * fuB / (PS(I.liv)*fn.cel(I.liv) + CLucel * fu.cel(I.liv));
%    eK.cel(I.kid) = [] % TODO!
    eK.tot = V.exc ./ V.tot .* eK.exc + V.cel ./ V.tot .* eK.cel;

    %%% fraction excreted in feces and metabolized in the gut
    E.gut = querydrug('Egut');
    E.feces = querydrug('Efeces');

    %%% first order po absorption rate constant, if relevant
    if hasrecord(drug,'lambda_po') || getfrom(options,'useEmpiricalAbsorptionModel',false)
        lambda_po = querydrug('lambda_po'); 
    else
        lambda_po = 0/u.h;
    end
    
    %%% Some additional informative parameter values
    %%%
    %%% BW  = sum of organ weights considered in the model
    %%% co  = cardiac output corresponding to the organs in the model
    %%% Vss = volume of distribution at steady state
    
    OWtis = queryphys('OWtis');
    add.BW      = sum( OWtis(Ig.organs) ) + queryphys('OWtbl'); 
    add.Vtotal  = sum( V.tis(Ig.organs) ) + queryphys('Vtbl'); 
    
    %%% initial condition and units of ODEs

    doseunit = u.ug;
    
    % initial conditions
    X0 = unan(numel(fieldnames(I))+numel(Ig.cel), 1);
    X0([I.art I.ven Ig.exc Ig.cel]) = 0*doseunit;
    X0(I.GItract) = 0 * doseunit;
    X0(I.IVbag)   = 0 * doseunit;
    X0(I.IVrate)  = 0 * doseunit / u.min;
    X0(I.metab)   = 0 * doseunit;
            
    % -----------------------------------------------------------------------
    % Assign model parameters 
    setup = struct;
    setup.indexing.I  = I;
    setup.indexing.Ig = Ig;
    setup.indexing.Id = Id;
    setup.V           = V;
    setup.Q           = Q;
    setup.K           = K;
    setup.CLucel      = CLucel;
    setup.E           = E;
    setup.eK          = eK;
    setup.lambda_po   = lambda_po;
    setup.add         = add;
    setup.BP          = BP;
    setup.X0          = X0;
    setup.fu          = fu;
    setup.fuP         = fuP;
    setup.fn          = fn;
    setup.PS          = PS;
    setup.MW          = MW;
    setup.hct         = hct;
    setup.GFR         = GFR;
    setup.Freabs      = Freabs;
    setup.Vmax        = Vmax;
    setup.Km          = Km;

    % to be used by lump_model 
    setup.cmt     = [strcat(organs,'-exc') setdiff(fieldnames(I),organs,'stable')' strcat(organs,'-cel')];
    setup.physIdx = [Ig.exc I.art I.ven Ig.cel];
    setup.VK      = [V.exc; V.cel(Ig.organs)] .* [eK.exc; eK.cel(Ig.organs)];     
end


% ========================================================================%
% ODE system of the model
% ========================================================================%
function dX = rhsfun(t, X, setup) % t will be used for infusion rate
%RHSFUN ODE system of 12 CMT perm.-lim. model with renal CL

    % initialize output vector
    X = X(:);
    dX = NaNsizeof(X);
    
    % model and indexing
    I = setup.indexing.I; 
    Ig = setup.indexing.Ig;

    % variables (always use column vector notation)
    A_exc = X(Ig.exc);
    A_cel = X(Ig.cel);
    A_art = X(I.art); 
    A_ven = X(I.ven);

    A_GItract = X(I.GItract);

    % tissue volumes, blood flows, extraction ratios, clearance etc.
    V     = setup.V;
    Q     = setup.Q; 
    Q_hepart = Q.blo(I.liv) - sum(Q.blo(Ig.intoLiv)); % hepatic artery blood flow

    % converting amounts to concentrations
    C_exc = A_exc ./ V.exc(Ig.organs); 
    C_cel = A_cel ./ V.cel(Ig.organs);
    C_art = A_art / V.art; 
    C_ven = A_ven / V.ven;

    % fu, fn 
    fu    = setup.fu;
    fn    = setup.fn;
    fuint = fu.int(Ig.organs);
    fucel = fu.cel(Ig.organs);
    fnint = fn.int(Ig.organs);
    fncel = fn.cel(Ig.organs);

    % permeability-surface area product
    PS    = setup.PS;
     
    % Renal CL
    GFR   = setup.GFR;
    Freabs= setup.Freabs;
    Vmax  = setup.Vmax;
    Km    = setup.Km;
    MW    = setup.MW;

    % secretory CL (Michaelis-Menten model)
    CLsec = sum(Vmax*MW./(Km*MW + C_art));
    
    % partitioning, hepatic CL, extraction
    K      = setup.K;
    CLucel = setup.CLucel;
    E      = setup.E;

    % infusion
    infusion_rate = X(I.IVrate);

    % po administration
    lambda_po = setup.lambda_po; 

    % venous concentration leaving tissue
    C_vbl = C_exc.*K.vas_exc(Ig.organs);

    % inflowing concentration into liver and vein
    C_in_liv = ( sum( Q.blo(Ig.intoLiv).*C_vbl(Ig.intoLiv) ) + Q_hepart*C_art ) / Q.blo(I.liv);
    C_in_ven = sum( Q.blo(Ig.intoVen).*C_vbl(Ig.intoVen) ) / Q.co;

    % derive unbound neutral concentrations
    C_int    = K.int_exc .* C_exc;

    Cun_int  = fnint .* fuint .* C_int; %TODO: rename to Cun_exc?
    Cun_cel  = fncel .* fucel .* C_cel;
    
    % ---------------------------------------------------------------------
    % START OF ODEs
    
    % initialisation for exc and cel
    dA_exc = NaNsizeof(A_exc);
    dA_cel = NaNsizeof(A_cel); 
    
    lun = I.lun; 
    liv = I.liv;
    kid = I.kid;

    % lung
    dA_exc(lun) = Q.co*( C_ven - C_vbl(lun) ) - PS(lun)*( Cun_int(lun) - Cun_cel(lun) );
    dA_cel(lun) = PS(lun)*( Cun_int(lun) - Cun_cel(lun) );
    
    % artery (remains the same)
    dA_art = Q.co*(C_vbl(lun) - C_art);

    % all tissues that are directly supplied by the artery 
    orgA = Ig.artInflow; 
  
    dA_exc(orgA)  = Q.blo(orgA).*( C_art - C_vbl(orgA) ) - PS(orgA).*( Cun_int(orgA) - Cun_cel(orgA) );
    dA_cel(orgA) = PS(orgA).*( Cun_int(orgA) - Cun_cel(orgA) );
    
    
    % liver
    dA_exc(liv)  = Q.blo(liv)*(C_in_liv - C_vbl(liv)) - PS(liv)*( Cun_int(liv) - Cun_cel(liv) ) ...
               + (1-E.gut)*(1-E.feces)*lambda_po*A_GItract;
    dA_cel(liv) = PS(liv)*( Cun_int(liv) - Cun_cel(liv) ) ... 
               - CLucel*fucel(liv)*C_cel(liv);
    
    % kidney
    dA_exc(kid)  = Q.blo(kid)*(C_art - C_vbl(kid)) - PS(kid)*( Cun_int(kid) - Cun_cel(kid) ) ...
                - (GFR*setup.fuP/setup.BP + CLsec)*(1-Freabs)*C_art;
    dA_cel(kid) = PS(kid)*( Cun_int(kid) - Cun_cel(kid) );

    % vein
    dA_ven = Q.co*(C_in_ven - C_ven) + infusion_rate;

    % drug amount in GItract for absorption
    dA_GItract = -lambda_po*A_GItract;

    % drug amount in IVbag for infusion
    dA_IVbag   = -infusion_rate;

    % drug amount metabolized or excreted
    dA_metab   = +CLucel*fucel(liv)*C_cel(liv) ...
        + (1-(1-E.gut)*(1-E.feces))*lambda_po*A_GItract ...
        + (GFR*setup.fuP/setup.BP + CLsec)*(1-Freabs)*C_art;

    
    % END OF ODEs 
    % -----------------------------------------------------------------------

    % output vector (always in column vector notation)
    dX(Ig.exc)    = dA_exc;
    dX(Ig.cel)    = dA_cel;
    dX(I.art)     = dA_art;
    dX(I.ven)     = dA_ven;
    dX(I.GItract) = dA_GItract;
    dX(I.metab)   = dA_metab;
    dX(I.IVbag)   = dA_IVbag;
    dX(I.IVrate)  = 0 * unitsOf(X(I.IVrate) / t);

end


% ========================================================================%
% Definition of observable quantities
% ========================================================================%
function yobs = obsfun(output, setup, obs)
%OBSFUN Observables in 12 CMT perm.-lim. model with renal CL
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
%       UnitType: 'Mass','Amount'

    I  = setup.indexing.I;
    Ig = setup.indexing.Ig;

    modelorgans = {'adi','bon','gut','hea','kid','liv','lun','mus','ski','spl'};
    
    yobs = []; % if obs matches a case below, yobs will be overwritten
    
    switch obs.type
        case 'PBPK'      % Site, Subspace, Binding, Unit

            site = obs.attr.Site;

            % retrieve exc and cel concentrations
            if ismember(site, modelorgans) % 2 subcompartments in PL model
                
                Vcel = setup.V.cel(I.(site));
                Vexc = setup.V.tis(I.(site)) + setup.V.vas(I.(site)) - Vcel;
                
                Cexc = output.X(:,Ig.exc(I.(site))) / Vexc; % currently: extracellular subspace, bound+unbound, Mass/Volume units                
                Ccel = output.X(:,Ig.cel(I.(site))) / Vcel; % currently:      cellular subspace, bound+unbound, Mass/Volume units                
                
            elseif ismember(site, {'art','ven'}) % not subcompartmentalized in PL model
                
                Vexc = setup.V.tis(I.(site)) + setup.V.vas(I.(site)) - setup.V.cel(I.(site));
                                
                Cexc = output.X(:,I.(site)) / Vexc; % currently: extracellular subspace, bound+unbound, Mass/Volume units                
                Ccel = 0*Cexc;                      % for consistency with subsequent code                
                
            else
                return
            end

            % Unbound fractions (at the most refined level)
            fuery = setup.fu.ery;
            fupla = setup.fu.pla;
            fuint = setup.fu.int(I.(site));
            fucel = setup.fu.cel(I.(site));

            % Abbreviations
            hct = setup.hct;
            BP  = setup.BP;
            fuB = fupla / BP;
            
            % Sub-compartmentalized volumes (at the most refined level)
            Vcel  = setup.V.cel(I.(site));
            Vint  = setup.V.tis(I.(site)) - Vcel;
            Very  = hct * setup.V.vas(I.(site));
            Vpla  = setup.V.vas(I.(site)) - Very;
 
            % fractional volumes
            Vvas = Very + Vpla;
            Vexc = Vvas + Vint;
            fintVexc = Vint / Vexc;
            fvasVexc = Vvas / Vexc;

            % Partition coefficients relating exc to ery-pla-int spaces
            Kvas_exc = 1/(fintVexc*fuB/fuint+fvasVexc);

            Kery_vas = (1 - (1-hct)/BP)/hct;
            Kpla_vas = 1/BP;
            Kint_vas = fuB/fuint;

            Kpla_exc = Kpla_vas * Kvas_exc;
            Kery_exc = Kery_vas * Kvas_exc;          
            Kint_exc = Kint_vas * Kvas_exc;

            % Concentrations in ery-pla-int spaces (Ccel already defined)
            Cint = Kint_exc * Cexc;
            Cery = Kery_exc * Cexc;
            Cpla = Kpla_exc * Cexc;

            % Subspace
            spc = obs.attr.Subspace;
            switch spc
                case 'ery' %erythrocytes                   
                    Vsub  = Very; 
                    Csub  = Cery;
                    fusub = fuery;
                case 'pla' %plasma
                    Vsub  = Vpla;
                    Csub  = Cpla;
                    fusub = fupla;
                case 'int' %interstitial
                    Vsub  = Vint;
                    Csub  = Cint;
                    fusub = fuint;
                case 'cel' %cellular
                    Vsub  = Vcel;
                    Csub  = Ccel;
                    fusub = fucel;
                case 'vas' % vascular
                    Vsub  = [Very  Vpla ];
                    Csub  = [Cery  Cpla ];
                    fusub = [fuery fupla];
                case 'tis' %tissue
                    Vsub  = [Vint  Vcel];
                    Csub  = [Cint  Ccel];
                    fusub = [fuint fucel];
                case 'exc' %extracellular
                    Vsub  = [Very  Vpla  Vint ];
                    Csub  = [Cery  Cpla  Cint ];
                    fusub = [fuery fupla fuint];                    
                case 'tot' %total
                    Vsub  = [Very  Vpla  Vint  Vcel];
                    Csub  = [Cery  Cpla  Cint  Ccel];
                    fusub = [fuery fupla fuint fucel];
                otherwise 
                    return
            end
            Asub = Vsub .* Csub;     % sub-compartmentalized amount (bound+unbound, Mass units) 

            % Binding
            switch obs.attr.Binding
                case 'total'
                    Aspc = sum(Asub, 2);          % sum over sub(-cmts)
                case 'unbound'
                    Aspc = sum(Asub .* fusub, 2); % sum over unbound in sub
                otherwise 
                    return
            end
            % Aspc: amount in subspace (binding included, Mass units)

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
                Vven = setup.V.ven;
                ytmp = output.X(:,I.ven) / (Vven * setup.BP); % bound+unbound, Mass/Volume units
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



