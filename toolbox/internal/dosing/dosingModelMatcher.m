function [tincr, Xincr] = dosingModelMatcher(dosing, Id, X0)
%DOSINGMODELMATCHER Converting dosing into state change vectors

% To decouple process_dosing from the details of the SimpleDosing
% subclasses, this function is used. It is only a temporary solution and
% should be made more modular.

    assert(isa(dosing,'SimpleDosing'))
    switch class(dosing)
        case 'Bolus'
            [tincr, Xincr] = bolusOdeModelMatcher(dosing, Id, X0);
        case 'Infusion'
            [tincr, Xincr] = infusionOdeModelMatcher(dosing, Id, X0);
        case 'Oral'
            [tincr, Xincr] = oralOdeModelMatcher(dosing, Id, X0);
        otherwise
            error('Unsupported dosing class for model matching.')
    end

end

function [tincr, Xincr] = bolusOdeModelMatcher(bolus, Id, X0)

    cpd = compounds(bolus);
    cpd = cpd{1};

    nb = height(bolus.schedule);
    nX = numel(X0);
    
    X0 = reshape(X0,1,nX);

    Xincr = zeros(nb, nX) .* unitsOf(X0);
    tincr = bolus.schedule.Time;

    % assign into bolus increment matrix        
    isite = repmat(Id.(cpd).Bolus.cmt, [nb 1]);
    bolusincr = bolus.schedule.Dose/Id.(cpd).Bolus.scaling; 
    compatible(X0(isite), bolusincr)
    Xincr(sub2ind([nb nX],(1:nb)',isite)) = bolusincr;

end

function [tincr, Xincr] = oralOdeModelMatcher(oral, Id, X0)

    assert(all(cellfun(@isempty,oral.schedule.Formulation)), ...
        'Formulations not handled yet.')

    cpd = compounds(oral);
    cpd = cpd{1};

    no = height(oral.schedule);
    nX = numel(X0);

    Xincr = zeros(no, nX) .* unitsOf(X0);
    tincr = oral.schedule.Time;

    % assign into bolus increment matrix        
    isite = repmat(Id.(cpd).Oral.cmt, [no 1]); 
    oralincr = oral.schedule.Dose;
    compatible(X0(isite), oralincr)
    Xincr(sub2ind([no nX],(1:no)',isite)) = oralincr;

end

function [tincr, Xincr] = infusionOdeModelMatcher(infus, Id, X0)

    cpd = compounds(infus);
    cpd = cpd{1};

    ni = height(infus.schedule);
    nX = numel(X0);
    
    X0 = reshape(X0,1,nX);

    tstart = infus.schedule.Tstart;
    tstop = infus.schedule.Tstop;
    Xbag   = zeros(ni, nX) .* unitsOf(X0);
    Xrate  = zeros(ni, nX) .* unitsOf(X0);

    % assign into bolus increment matrix        
    ibag  = repmat(Id.(cpd).Infusion.bag, [ni 1]); 
    irate = repmat(Id.(cpd).Infusion.rate, [ni 1]);   
    bagincr  = infus.schedule.Dose;
    rateincr = infus.schedule.Rate;
    compatible(X0(ibag), bagincr)
    compatible(X0(irate), rateincr)
    Xbag(sub2ind([ni nX], (1:ni)',ibag))  = bagincr;
    Xrate(sub2ind([ni nX],(1:ni)',irate)) = rateincr;

    % concatenate with other dosing schemes
    tincr = [tstart; tstart;  tstop];
    Xincr = [  Xbag;  Xrate; -Xrate];       
end
