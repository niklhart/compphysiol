%LUKACOVA Lukacova et al.'s tissue partition prediction method
%   K = LUKACOVA(PHYS, DRUG, ORGANS) predicts tissue-to-unbound plasma 
%   partition coefficients using the method described in Lukacova et al.
%   Input PHYS is a Physiology object, DRUG a DrugData object and ORGANS a 
%   cellstr with the compartment names (e.g. {'adi','bon',...}).
%   Output is a struct that can be appended to the initialized model. 
%
%   [K, F] = LUKACOVA(PHYS, DRUG, ORGANS) additionally returns
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
%   [K, F, FC] = LUKACOVA(PHYS, DRUG, ORGANS) additionally returns
%   fractions partitioning into tissue constituents, summed over organs 
%   and subspaces, as a struct FC with fields
%       .uw: unbound water         (pla + int + cel)
%       .pr: binding proteins      (pla + int)
%       .nl: neutral lipids        (pla + cel)
%       .np: neutral phospholipids (pla + cel)
%       .ap: acidic phospholipids  (cel)
%   
%   Example:
%
%       phys = Physiology('human35m');
%       drug = loaddrugdata('Warfarin','species','human');
%       organs = {'adi','bon','gut','hea','kid','liv','lun','mus','ski','spl'};
%
%       K = lukacova(phys,drug,organs);
%
%   See also rodgersrowland, Physiology, DrugData

function [K, f, fC] = lukacova(phys, drug, organs, useConsistentKery)

assert(isa(phys,'Physiology'), 'Input #1 must be a Physiology object.')
assert(isa(drug,'DrugData'),   'Input #2 must be a DrugData object.')

assert(strcmp(drug.class,'sMD'),...
    "Lucacova's method is only valid for small molecule drugs.");

if nargin < 4
    useConsistentKery = false;
end

organs = organs(:);

[queryphys, querydrug, I] = loaddatabases(phys, drug, organs);

% species specific data
hct      = queryphys('hct');  
pH_cel   = queryphys('pH');    

fpwVpla = 0.93;   % RR approximate this quantity by 1, which is inconsistent (add [REF])

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

% drug-specific or mixed data
if strcmp(drug.subclass,'neutral')
    pKa = [];
else
    pKa = querydrug('pKa');  
end
fuP      = querydrug('fuP');         
Kery_up  = querydrug('K_ery_up'); 
logPow   = querydrug('logPow');

%%% assign logPvow value. Otherwise, estimate logPvow based on logPow 
%%% according to Poulin & Theil
try
    logPvow = querydrug('logPvow');
catch
    logPvow = 1.115*logPow - 1.35;  %TODO: add an assumption here.
end

%%% fraction neutral due to ionization effects
%%%
[fnC, ~, fcatC]   = ionized_fractions(drug.subclass,pKa,pH_cel);
[fnP, faniP, fcatP]   = ionized_fractions(drug.subclass,pKa,pH_pla);
[fn_ery,~,fcat_ery] = ionized_fractions(drug.subclass,pKa,pH_ery);

% same pH in plasma and extracellular space --> same ionization  
fnE   = fnP;
faniE = faniP;
fcatE = fcatP;

%%% neutral lipids-to-water partition coefficient
%%%
Knl   = 10^logPow * fnC;
if ismember('adi',organs)
    Knl(I.adi) = 10^logPvow * fnC(I.adi);
end
Knl_ery = 10^logPow * fn_ery;
Knl_pla = 10^logPow * fnP;

%%% approximate neutral phospholipids-to-water partition coefficient
%%%
Knp     = 0.3*Knl     + 0.7*fnC;
Knp_ery = 0.3*Knl_ery + 0.7*fn_ery;
Knp_pla = 0.3*Knl_pla + 0.7*fnP;

% association constant to proteins x concentration
KA_PR_x_PRpla = 1/fuP - fpwVpla - Knl_pla*fnlVtis_pla - Knp_pla*fnpVtis_pla;

% Association constant to acidic phospholipids
AP     = fapVtis;
AP_ery = fapVtis_ery;


if fcat_ery > 0
    if useConsistentKery
        KA_AP = (Kery_up*fn_ery/fnP - fcwVtis_ery - Knl_ery*fnlVtis_ery...
                     -Knp_ery*fnpVtis_ery) / (AP_ery*fcat_ery*(1-fn_ery));
    else
        KA_AP  = (Kery_up*fn_ery/fnP - fcwVtis_ery - Knl_ery*fnlVtis_ery...
                     -Knp_ery*fnpVtis_ery) / (AP_ery*fcat_ery);
    end
else
    % ensure that AP have no effect in case the cationic fraction is zero
    % (acids and neutrals)
    KA_AP = 0;

    % Compound Kery is ignored, otherwise the method is inconsistent
    Kery_up = (fcwVtis_ery + Knl_ery*fnlVtis_ery + Knp_ery*fnpVtis_ery)*fnP/fn_ery;

end

% tissue-to-plasma protein ratio
switch drug.subclass
    case {'neutral'}      % binding to lipoproteins (Lip)
        PRtis_to_PRpla = queryphys('rtpLip');
    case {'acid','base','diprotic acid','diprotic base','zwitter ion'} % binding to albumin (Alb)
        PRtis_to_PRpla = queryphys('rtpAlb');
    otherwise
        error('Unknown drug subclass "%s",', drug.subclass)
end
if ismember('ery',organs)
    PRtis_to_PRpla(I.ery) = 0;  % no interstitial space in ery
    fiwVtis(I.ery) = 0;  % no interstitial space in ery
end
%%% check for plausibility of estimated KA values
mustBeNonnegative(KA_AP)
mustBeNonnegative(KA_PR_x_PRpla(~isnan(KA_PR_x_PRpla)))

% Lukacova prediction method
K.tis_up =  fiwVtis + fnP./fnC .* fcwVtis + fnP * (fnlVtis.*Knl + fnpVtis.*Knp) ...
    + (fnE + faniE) * (1/fuP - fpwVpla - Knl_pla*fnlVtis_pla - Knp_pla*fnpVtis_pla) .* PRtis_to_PRpla ...
    + fcatE .* KA_AP .* AP .* (1./fnC - 1) .* fnP;
%      ^-- used to be fcatC


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
% if ismember('ery',organs)
%     K.tis_up(I.ery) = Kery_up;  % erythrocyte-to-unbound plasma partition coefficient
% end

%%% determine also total-to-unbound partition coefficients, i.e., 1/fu, for RBCs,
%%% interstitial and intra-cellular spaces
%%%
K.cel_ucel = ( fcwVtis + Knl.*fnlVtis + Knp.*fnpVtis + ...
                  KA_AP*AP.*fcatC ) ./ fcelVtis;

K.ery_uery      = fn_ery/fnP * Kery_up;             
              
K.int_uint = ( K.tis_up - fnP./fnC.*fcelVtis.*K.cel_ucel ) ./ fintVtis;   


if nargout > 1
    f = struct;
    
    f.u.pla = fuP;
    f.u.ery   = 1/K.ery_uery;
    f.u.int   = 1./K.int_uint;
    f.u.cel   = 1./K.cel_ucel;
    
    f.n.pla = fnP;
    f.n.ery = fn_ery;
    f.n.int = repmat(fnP, size(organs));
    f.n.cel = fnC;
end

% partitioning into tissue constituents
if nargout > 2
    KA_PR_x_PRtis = KA_PR_x_PRpla * PRtis_to_PRpla;

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

    denominator = sum(Vtis.*K.tis_up) + Very*Kery_up + Vpla/fuP;

    fC = struct;

    fC.uw = (sum(Viw + Vcw.*fnP./fnC) + Vcw_ery*fnP/fn_ery + Vpw) / denominator;    
    fC.pr = (KA_PR_x_PRpla*Vpla + sum(KA_PR_x_PRtis.*Vtis)* (fnE + faniE) ) / denominator;    
    fC.nl = (Vnl_pla * Knl_pla + fnP * (sum(Vnl .* Knl ./ fnC) + Vnl_ery * Knl_ery / fn_ery)) / denominator;
    fC.np = (Vnp_pla * Knp_pla + fnP * (sum(Vnp .* Knp ./ fnC) + Vnp_ery * Knp_ery / fn_ery)) / denominator;
    fC.ap = KA_AP * fnP * (sum(Vtis.*AP.*fcatC./fnC) + Very*AP_ery*fcat_ery/fn_ery )/ denominator;   
    
end

end

