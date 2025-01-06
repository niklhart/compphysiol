% IONIZED_FRACTIONS Neutral/anionic/cationic fractions for a small molecule
%   [FN, FANI, FCAT] = IONIZED_FRACTIONS(PH, ACIDIC_PKA, BASIC_PKA) computes
%   fractions neutral (FN), anionic (FANI) and cationic (FCAT) for a small
%   molecule drug, given the environmental pH (PH) and its acidic and/or 
%   basic pKa value(s) (ACIDIC_PKA, BASIC_PKA). 
%
%   Note: for zwitter ions, FN represents the net neutral molecule form.
%
%   Examples:
%   % neutral drug
%   [fn,fani,fcat] = ionized_fractions(7.4,[],[])
%   
%   monoprotic acid
%   [fn,fani,fcat] = ionized_fractions(7.4,5,[])
%   
%   % monoprotic base
%   [fn,fani,fcat] = ionized_fractions(7.4,[],10)
%   
%   % diprotic acid
%   [fn,fani,fcat] = ionized_fractions(7.4,[5 7],[])
%   
%   % diprotic base
%   [fn,fani,fcat] = ionized_fractions(7.4,[],[8 10])
%
%   % zwitter ion
%   [fn,fani,fcat] = ionized_fractions(7.4,5,10)
%   
function [fn,fani,fcat] = ionized_fractions(pH, acidic_pKa, basic_pKa)

    if ~isscalar(pH)
        [fn, fani, fcat] = arrayfun(@(x) ionized_fractions(x,acidic_pKa, basic_pKa), pH);
        return
    end
    
    nacid = numel(acidic_pKa);
    nbase = numel(basic_pKa);

    % sort pKa values in ascending order and reallocate basic/acidic
    pKa = sort([acidic_pKa(:); basic_pKa(:)])';
    basic_pKa   = pKa(1:nbase);
    acidic_pKa  = pKa(nbase+(1:nacid));

    sn = 1;
    sani = sum(10 .^ ((1:nacid)*pH - cumsum(acidic_pKa)));
    scat = sum(10 .^ (cumsum(flip(basic_pKa)) - (1:nbase)*pH));

    stot = sn + sani + scat;

    fn = sn / stot;
    fani = sani / stot;
    fcat = scat / stot;

end