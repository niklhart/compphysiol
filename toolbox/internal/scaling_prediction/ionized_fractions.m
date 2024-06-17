%IONIZED_FRACTIONS Neutral/anionic/cationic fractions for a small molecule
%   [FN, FANI, FCAT] = IONIZED_FRACTIONS(SUBCLASS, PKA, PH) computes
%   fractions neutral (FN), anionic (FANI) and cationic (FCAT) for a small
%   molecule drug of a certain SUBCLASS (acid, base, neutral, ...) with
%   given pKa value(s) (PKA) and at a given environmental pH (PH). 
function [fn,fani,fcat] = ionized_fractions(subclass, pKa, pH)

    % pka values need to be in decreasing order
    pKa = sort(pKa,'ascend');

    switch subclass
        case 'acid' 
            fn   = 1./(1+10.^(pH-pKa(1)));
            fani = 1 - fn;
            fcat = zeros(size(pH));
        case 'base' 
            fn   = 1./(1+10.^-(pH-pKa(1)));
            fani = zeros(size(pH));
            fcat = 1 - fn;
        case 'neutral' 
            fn   = ones(size(pH));
            fani = zeros(size(pH));
            fcat = zeros(size(pH));
        case 'diprotic acid'
            % implicit assumption: single- and double-ionized species have 
            %                      the same partitioning behaviour
            fn = 1./(1+10.^(pH-pKa(1))+10.^(2*pH-pKa(1)-pKa(2)));               
            fani = 1 - fn;
            fcat = zeros(size(pH));
        case 'diprotic base'
            % implicit assumption: single- and double-ionized species have 
            %                      the same partitioning behaviour
            fn   = 1./(1+10.^-(pH-pKa(2))+ 10.^-(2*pH-pKa(1)-pKa(2)));
            fani = zeros(size(pH));
            fcat = 1 - fn;
        case 'zwitter ion'

            fn   = 1./(1+10.^(pH-pKa(2))+ 10.^-(pH-pKa(1)));
            fani = (10.^(pH-pKa(2)))./(1+10.^(pH-pKa(2))+ 10.^-(pH-pKa(1)));
            fcat = (10.^-(pH-pKa(1)))./(1+10.^(pH-pKa(2))+ 10.^-(pH-pKa(1)));
            
        otherwise
            error('Cannot compute ionization states for drug subclass "%s".',subclass)
    end
end 
