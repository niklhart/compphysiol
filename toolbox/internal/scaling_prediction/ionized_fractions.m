% IONIZED_FRACTIONS Ionized fractions for a small molecule drug
%   [FN, FANI, FCAT] = IONIZED_FRACTIONS(PH, PKA_ANI, PKA_CAT) computes
%   fractions neutral FN, anionic (negatively charged) FANI and cationic 
%   (positively charged) FCAT for a small molecule drug, given the 
%   environmental pH (PH) and its anionic and/or cationic pKa value(s) 
%   (PKA_ANI, PKA_CAT). 
%
%   For acids, PKA_ANI contains the acidic pKa value(s) whereas for bases, 
%   PKA_CAT contains the basic pKa value(s), the other input being empty.
%   
%   [FN, FANI, FCAT, FZ] = IONIZED_FRACTIONS(___, KZ) allows to specify the 
%   tautomeric constant (defaulting to zero) for ampholytes (substances 
%   with non-empty PKA_ANI and PKA_CAT), which defines the ratio of 
%   zwitterionic to neutral fractions, i.e. KZ = FZ/FN (the value KZ = +Inf
%   is allowed and means that the shift from anionic to cationic species 
%   occurs exclusively via the zwitter ion). For ampholytes, it is required
%   that PKA_CAT <= PKA_ANI, which can be derived from theory based on 
%   electrostatic interactions.
%
%   Examples:
%   % neutral drug
%   [fn,fani,fcat] = ionized_fractions(7.4, [], [])
%   
%   monoprotic acid
%   [fn,fani,fcat] = ionized_fractions(7.4, 5, [])
%   
%   % monoprotic base
%   [fn,fani,fcat] = ionized_fractions(7.4, [], 10)
%   
%   % diprotic acid
%   [fn,fani,fcat] = ionized_fractions(7.4, [5 7], [])
%   
%   % diprotic base
%   [fn,fani,fcat] = ionized_fractions(7.4, [], [8 10])
%
%   % ordinary ampholyte
%   [fn,fani,fcat] = ionized_fractions(7.4, 10, 5)
%   
%   % purely zwitterionic ampholyte 
%   [fn,fani,fcat,fz] = ionized_fractions(7.4, 10, 5, Inf)
function [fn, fani, fcat, fz] = ionized_fractions(pH, pKa_ani, pKa_cat, Kz)

    arguments
        pH double
        pKa_ani double
        pKa_cat double {mustBeAllLessThanOrEqual(pKa_cat,pKa_ani)}
        Kz (1,1) double {mustBeNonnegative} = 0
    end

    assert(~(isempty(pKa_ani) || isempty(pKa_cat)) || Kz == 0, ...
        'Kz must be zero except for ampholytes.')

    if ~isscalar(pH)
        [fn, fani, fcat, fz] = arrayfun(@(x) ionized_fractions(x,pKa_ani,pKa_cat,Kz), pH);
        return
    end
    
    pKa_ani = sort(pKa_ani(:), 'ascend')';
    pKa_cat = sort(pKa_cat(:), 'descend')';

    % unnormalized abundances of net neutral, anionic and cationic species
    snz = 1;
    sani = sum(10 .^ cumsum(pH - pKa_ani));
    scat = sum(10 .^ cumsum(pKa_cat - pH));

    stot = snz + sani + scat;

    % allocate fractions net neutral, anionic and cationic
    fnz = snz / stot;
    fani = sani / stot;
    fcat = scat / stot;

    % allocate fractions neutral/zwitterionic by tautomeric constant Kz
    fn = fnz/(1+Kz);
    fz = fnz-fn;
end


function mustBeAllLessThanOrEqual(A,B)
    if ~isempty(A) && ~isempty(B)
        mustBeLessThanOrEqual(max(A,[],"all"),min(B,[],"all"))
    end
end