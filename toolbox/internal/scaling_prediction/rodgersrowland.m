%RODGERSROWLAND Rodgers and Rowland's tissue partition prediction method
%   K = RODGERSROWLAND(PHYS, DRUG, ORGANS) predicts tissue-to-unbound plasma 
%   partition coefficients using the method described in Rodgers et al.
%   Input PHYS is a Physiology object, DRUG a DrugData object and ORGANS a 
%   cellstr with the compartment names (e.g. {'adi','bon',...}).
%   Output is a struct that can be appended to the initialized model. 
%
%   [K, F] = RODGERSROWLAND(PHYS, DRUG, ORGANS) additionally returns
%   a struct F with fields 
%       .n: fraction neutral ...
%           .pla:  ... in plasma
%           .ery:  ... in erythrocytes
%           .int:  ... in interstitial space (identical to f.n.pla)
%           .cel:  ... in cellular space
%       .u: fraction unbound ...
%           .pla:  ... in plasma
%           .ery:  ... in erythrocytes
%           .int:  ... in interstitial space
%           .cel:  ... in cellular space
%
%   [K, F, FC] = RODGERSROWLAND(PHYS, DRUG, ORGANS) additionally returns
%   fractions partitioning into tissue constituents, summed over organs 
%   and subspaces, as a struct FC with fields
%       .uw: unbound water         (pla + int + cel)
%       .pr: binding proteins      (pla + int)
%       .nl: neutral lipids        (pla + cel)
%       .np: neutral phospholipids (pla + cel)
%       .ap: acidic phospholipids  (cel)
%
%   RODGERSROWLAND(___, N1 = V1, N2 = V2, ...) allows to additionally 
%   specify any of the following optional name-value pairs:
%   
%   - plasmaWaterFraction (default: 0.93)
%       Water subspace fraction of plasma, which was set to 1 in the 
%       original Rodgers et al. publications. 
%   - fupIncludesLipids (default: true)
%       If the experimentally determined fuP values doesn't account for 
%       binding to lipids, this option can be set to false to reflect this 
%       fact when determining binding to plasma proteins. A typical case
%       would be a reported fuP = 1.
%   - treatNegativeBindingAsZero (default: false)
%       Due to inconsistencies in the experimental inputs, the calculated
%       binding constants to proteins or acidic phospholipids can become
%       negative. By default, this will result in an error. In contrast,
%       Rodgers et al. set binding constants to zero in such a case. This
%       behaviour is recovered when setting this option to true.
%   - respectThermodynamics (default: true)
%       This option is passed on to function ionized_fractions() and is
%       provided to reproduce Rodgers et al.'s original results. It is
%       not recommended to change the default value otherwise.
%
%   References: 
%   - Rodgers et al. (2005), DOI: 10.1002/jps.20322
%   - Rodgers/Rowland (2006), DOI: 10.1002/jps.20502
%
%   Example:
%
%       phys = Physiology('human35m');
%       drug = loaddrugdata('Warfarin','species','human');
%       organs = {'adi','bon','gut','hea','kid','liv','lun','mus','ski','spl'};
%
%       K = rodgersrowland(phys,drug,organs);
%
%   See also Physiology, DrugData

function [K, f, fC] = rodgersrowland(phys, drug, organs, options)

arguments
    phys (1,1) Physiology
    drug (1,1) DrugData {mustBeSmallMolecule}
    organs {mustBeText}
    options.plasmaWaterFraction (1,1) double {mustBePositive} = 0.93
    options.fupIncludesLipids (1,1) logical = true
    options.treatNegativeBindingAsZero (1,1) logical = false
    options.respectThermodynamics (1,1) logical = true
end

organs = cellstr(organs);
organs = organs(:);

[queryphys, querydrug, I] = loaddatabases(phys, drug, organs);

% species specific data
hct      = queryphys('hct');  
pH_cel   = queryphys('pH');    

fpwVpla = options.plasmaWaterFraction;

fcelVtis  = queryphys('fcelVtis');
fintVtis  = queryphys('fintVtis');

fcwVtis  = queryphys('fwicVtis');
fiwVtis  = queryphys('fwecVtis');
fnlVtis  = queryphys('fnliVtis');
fnpVtis  = queryphys('fnphVtis');
fapVtis  = queryphys('faphVtis');   

fnlVtis_pla = queryphys('fnliVtis','pla');
fnpVtis_pla = queryphys('fnphVtis','pla');

fcwVtis_ery = queryphys('fwicVtis','ery');
fnlVtis_ery = queryphys('fnliVtis','ery');
fnpVtis_ery = queryphys('fnphVtis','ery');
fapVtis_ery = queryphys('faphVtis','ery');
pH_pla = queryphys('pH','pla');
pH_ery = queryphys('pH','ery');

%%% drug-specific or mixed data

% no acidic/basic pKa values given = drug doesn't have such a pKa
pKa_ani = querydrug('pKa_ani', Default = []);  
pKa_cat  = querydrug('pKa_cat',  Default = []);  

fuP      = querydrug('fuP');         
Kery_up  = querydrug('K_ery_up'); 
logPow   = querydrug('logPow');

% assign logPvow value. Otherwise, estimate logPvow based on logPow 
% according to Poulin & Theil
logPvow = querydrug('logPvow', Default = 1.115*logPow - 1.35);

% fraction neutral due to ionization effects
% (same pH in plasma and extracellular space --> same ionization)
therm = options.respectThermodynamics;
[fnC,   ~,fcatC,fzC]       = ionized_fractions(pH_cel, pKa_ani, pKa_cat, 0, therm);
[fnP,   ~,  ~  ,fzP]       = ionized_fractions(pH_pla, pKa_ani, pKa_cat, 0, therm);
[fn_ery,~,fcat_ery,fz_ery] = ionized_fractions(pH_ery, pKa_ani, pKa_cat, 0, therm);

% Rodgers et al. treat neutral and zwitter ion fraction identically
% (hence, the constant of tautomeric equilibrium doesn't matter)
fnnC    = fnC    + fzC;
fnnP    = fnP    + fzP;
fnn_ery = fn_ery + fz_ery;

% acidic phospholipid concentration (as a mass fraction)
AP     = fapVtis;
AP_ery = fapVtis_ery;

%%% neutral lipids-to-water partition coefficient
%%%
Knl   = 10^logPow * fnnC;
if ismember('adi',organs)
    Knl(I.adi) = 10^logPvow * fnnC(I.adi);
end
Knl_ery = 10^logPow * fnn_ery;
Knl_pla = 10^logPow * fnnP;

%%% approximate neutral phospholipids-to-water partition coefficient
%%%
Knp     = 0.3*Knl     + 0.7 * fnnC;
Knp_ery = 0.3*Knl_ery + 0.7 * fnn_ery;
Knp_pla = 0.3*Knl_pla + 0.7 * fnnP;

% account for lipid binding in fuP if not accounted for in the fuP assay
if ~options.fupIncludesLipids 
    fuP_exp = fuP;
    fuP = 1 / (1/fuP + Knl_pla*fnlVtis_pla + Knp_pla*fnpVtis_pla);
    Kery_up = Kery_up * fuP_exp / fuP;
end

% R&R method distinguishes bases dependent on pKa
RRsubclass = drug.subclass;
if strcmp(RRsubclass,'base')
    if any(pKa_cat > 7)
        RRsubclass = 'mod. to strong base';
    else
        RRsubclass = 'weak base';
    end
end
if strcmp(RRsubclass,'ampholyte')
    if any(pKa_cat > 7)
        RRsubclass = 'zwitter ion type I';
    else
        RRsubclass = 'zwitter ion type II';
    end
end

KA_PR_x_PRtis = NaNsizeof(organs);
switch RRsubclass   
    % Rodgers et al. (2005): substances with at least one basic pKa > 7
    case {'mod. to strong base','diprotic base','zwitter ion type I'} % binding to acidic phospholipids (aph)
        % Association constant to acidic phospholipids
        KA_AP  = (Kery_up*fnn_ery/fnnP - fcwVtis_ery - Knl_ery*fnlVtis_ery...
                         -Knp_ery*fnpVtis_ery) / (AP_ery*fcat_ery);


        % No association to plasma/interstitial binding proteins
        KA_PR_x_PRpla    = 0;
        KA_PR_x_PRtis(:) = 0;
        
        % Compound fuP is ignored, otherwise the RR method is inconsistent 
        fuP = 1./(fpwVpla + Knl_pla*fnlVtis_pla + Knp_pla*fnpVtis_pla);

    % Rodgers/Rowland (2006): substances without any basic pKa > 7
    case {'neutral','acid','weak base','diprotic acid','zwitter ion type II'}

        % tissue-to-plasma protein ratio
        if strcmp(RRsubclass,'neutral')
            PRtis_to_PRpla = queryphys('rtpLip');  % binding to lipoproteins (Lip)
        else
            PRtis_to_PRpla = queryphys('rtpAlb');  % binding to albumin (Alb)
        end
       
        % Association constant to binding proteins x protein concentrations
        KA_PR_x_PRpla = (1/fuP - Knl_pla*fnlVtis_pla - Knp_pla*fnpVtis_pla)/fpwVpla - 1;
        KA_PR_x_PRtis = KA_PR_x_PRpla * PRtis_to_PRpla;

        % No association to acidic phospholipids
        KA_AP  = 0;

        % Compound Kery is ignored, otherwise the method is inconsistent
        Kery_up = (fcwVtis_ery + Knl_ery*fnlVtis_ery + Knp_ery*fnpVtis_ery)*fnnP/fnn_ery;

    otherwise
        error(['Unknown drug subclass "' RRsubclass '".'])
end

if options.treatNegativeBindingAsZero
    KA_AP         = max(KA_AP,0);
    KA_PR_x_PRtis = max(KA_PR_x_PRtis,0);
end

% check for plausibility of estimated KA values
assert(all(KA_AP >= 0), sprintf(...
    ['The relationship defining association to acidic phospholipids,\n\n'...
    'KA_AP  = (Kery_up*fnn_ery/fnnP - fcwVtis_ery - Knl_ery*fnlVtis_ery - Knp_ery*fnpVtis_ery) / (AP_ery*fcatC_ery),\n\n'...    
    'resulted in a negative association constant KA_AP.']))
assert(all(KA_PR_x_PRtis(~isnan(KA_PR_x_PRtis)) >= 0), sprintf(...
    ['The relationship defining association to proteins,\n\n'...
    'KA_PR_x_PRpla = 1/fuP - fpwVpla - Knl_pla*fnlVtis_pla - Knp_pla*fnpVtis_pla,\n\n'...    
    'resulted in a negative association constant KA_PR.']))

% First determine total-to-unbound partition coefficients, i.e., 1/fu
% (for tissue subspaces ery, int and cel)
K.cel_ucel = ( fcwVtis + Knl.*fnlVtis + Knp.*fnpVtis + ...
                  KA_AP*AP.*fcatC ) ./ fcelVtis;

K.ery_uery = fnn_ery/fnnP * Kery_up;
              
K.int_uint = (fiwVtis + KA_PR_x_PRtis) ./ fintVtis;   

% tis = int + cel --> weighted partition coefficients (incl. ionization) 
K.tis_up = fintVtis .* K.int_uint + fnnP./fnnC.*fcelVtis.*K.cel_ucel;

% blood-to-plasma concentration ratio
BP = hct*fuP*Kery_up + (1-hct);

% Add blood-related compartments
if ismember('art', organs)
    K.tis_up(I.art)   = BP/fuP;  % blood-to-unbound plasma partition coefficient
end
if ismember('ven', organs)
    K.tis_up(I.ven)   = BP/fuP;  % blood-to-unbound plasma partition coefficient
end
if ismember('blo', organs)
    K.tis_up(I.blo)   = BP/fuP;  % blood-to-unbound plasma partition coefficient
end
if ismember('pla',organs)
    K.tis_up(I.pla) = 1/fuP;     % plasma-to-unbound plasma partition coefficient
end
if ismember('ery',organs)
    K.tis_up(I.ery) = Kery_up;  % erythrocyte-to-unbound plasma partition coefficient
end

% fractions unbound and fractions neutral
if nargout > 1
    f = struct;
    
    f.u.pla = fuP;
    f.u.ery = 1/K.ery_uery;
    f.u.int = 1./K.int_uint;
    f.u.cel = 1./K.cel_ucel;
    
    f.n.pla = fnnP;
    f.n.ery = fnn_ery;
    f.n.int = repmat(fnnP, size(organs));
    f.n.cel = fnnC;
end

% partitioning into tissue constituents
if nargout > 2
    Vtis = queryphys('Vtis');
    Vtbl = queryphys('Vtbl');
    Very =    hct *Vtbl;
    Vpla = (1-hct)*Vtbl;        
    Vpw  = fpwVpla * Vpla;         
    
    Viw  = Vtis .* fiwVtis;
    Vcw  = Vtis .* fcwVtis;
    Vnl  = Vtis .* fnlVtis;
    Vnp  = Vtis .* fnpVtis;

    Vcw_ery = fcwVtis_ery * Very;
    Vnl_ery = fnlVtis_ery * Very;
    Vnp_ery = fnpVtis_ery * Very;

    Vnl_pla = fnlVtis_pla * Vpla;
    Vnp_pla = fnpVtis_pla * Vpla;

    Kpla_up = 1/fuP;

    denominator = sum(Vtis.*K.tis_up) + Very*Kery_up + Vpla * Kpla_up;

    fC = struct;

    fC.uw = (sum(Viw + Vcw.*fnnP./fnnC) + Vcw_ery*fnnP/fnn_ery + Vpw) / denominator;    
    fC.pr = (KA_PR_x_PRpla*Vpw + sum(KA_PR_x_PRtis.*Vtis) ) / denominator;    
    fC.nl = (Vnl_pla * Knl_pla + fnnP * (sum(Vnl .* Knl ./ fnnC) + Vnl_ery * Knl_ery / fnn_ery)) / denominator;
    fC.np = (Vnp_pla * Knp_pla + fnnP * (sum(Vnp .* Knp ./ fnnC) + Vnp_ery * Knp_ery / fnn_ery)) / denominator;
    fC.ap = KA_AP * fnnP * (sum(Vtis.*AP.*fcatC./fnnC) + Very*AP_ery*fcat_ery/fnn_ery )/ denominator;   
    
end

end

