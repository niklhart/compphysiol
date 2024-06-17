%PREDICT_PERM Predict cellular or intestinal permeability by PK-Sim method.
%   P = PREDICT_PERM(DRUG,TYPE) The following parameters of DrugData object 
%   DRUG must be defined:
%   - MW;
%   - formula;
%   - logMA (preferred) or logPow.
%   Input #2, TYPE, can be either 'intestinal' or 'cellular'.
%   The predicted permeability P is then returned as an output. 

function P = predict_perm(drug, type)

    assert(isa(drug,'DrugData'), 'Input must be a DrugData object.')
    assert(hasrecord(drug,'formula') && hasrecord(drug,'MW') && ...
        (hasrecord(drug,'logMA') || hasrecord(drug,'logPow')), ...
        'PBPK:predict_cellperm:missingDrugParam', ...
        'DrugData parameters "formula", "MW" and either "logMA" or "logPow" must be defined.')

    type = validatestring(type, {'intestinal','cellular'});

    MW = getvalue(drug,'MW');
    form = getvalue(drug,'formula');
    MWeff = MW - ( 17*natoms(form,'F') + 22*natoms(form,'Cl') + ...
                   62*natoms(form,'Br') + 98*natoms(form,'I') )*u.g/u.mol;

    if hasrecord(drug,'logMA')
        logMA = getvalue(drug,'logMA');
    else
        logMA = getvalue(drug,'logPow'); 
        % TODO: add a message for the 'else' case.
        % TODO, extend this to also include the formula logMA = 1.294 + 0.304*logP
    end

    switch type
        case 'intestinal' % Thelen et al. (2011)
            MWref = 1*u.g/u.mol;
            Pref  = 265.796*u.cm/u.s;
            Pmem = Pref * 10^logMA * (MWeff / MWref)^-4.5;
            
        case 'cellular'   % PK-Sim
            MWref = 336*u.g/u.mol;
            Pref  = 2e-5*u.cm/u.min;
            Pmem = Pref * 10^logMA * (MWref / MWeff)^6;
    end
   % assum = sprintf('Predicted by PK-Sim formula (%s)',type);
    %addrecord(drug,'cellPerm','human',Pmem,[],assum)

    P = Pmem;

end