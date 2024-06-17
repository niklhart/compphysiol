%MATCHDOSE Matching a dosing object to a dosing struct. 
%   Function MATCHDOSE is called by function process_dosing to ensure that 
%   all dosing events can be mapped to model compartments via the (model-
%   specific) dosing struct. If anything is missing, an error is thrown. 
%
%   In addition, to simplify the code in the parent function, the "target" 
%   layer is removed from the dosing struct, assuming only a single dosing
%   target is present per drug and per route of administration.

function Id = matchdose(Id, dosing)
    
    cpds  = compounds(dosing);
    types = dosingTypes(dosing);

    for i = 1:numel(cpds)
        
        cpd = cpds{i};

        for j = 1:numel(types)

            typ = types{j};
            dos = filterDosing(dosing, [], typ);

            hasDosType = ismember(cpd, compounds(dos));

            if hasDosType
                assert(isfield(Id.(cpd), typ), ...
                    '%s dosing not defined in the model.', typ)
                if ~strcmp(typ,'Oral')      %TODO remove this dependency on Oral class
                    targets = dos.schedule.Target(strcmp(cpd, dos.schedule.Compound));
                    assert(isscalar(unique(targets)), ...
                        'Dosing with multiple targets per drug and per route of administration not implemented yet.')
                    targ = targets{1}; %cellstr->char
                    if isfield(Id.(cpd).(typ), targ)
                        Id.(cpd).(typ) = Id.(cpd).(typ).(targ);
                    else
                        error('%s dosing site "%s" not defined in the model.', typ, targ)
                    end
                end
            end
        end
    end
end
