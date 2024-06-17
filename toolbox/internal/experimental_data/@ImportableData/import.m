%IMPORT Import an ImportableData object
%   EXPID = IMPORT(OBJ) imports the ImportableData object OBJ into an
%   Individual object or array EXPID.
%
%   EXPID = IMPORT(OBJ, 'silent') suppresses the success message.
%   
%   Examples:
%
%   data = ImportableData('data/Warfarin_Holford1986.csv','Delimiter',',');
%   data.maprow('Species','Covariate');
%   data.maprow('Warfarin oral dose','Oral dosing','Compound','Warfarin');
%   data.maprow('Warfarin plasma concentration','Record','Site','pla');
%   expid = import(data)
%   
%   See also ImportableData, Individual

function expid = import(obj, silent)

    [out, IDs] = tablesplit(obj);
    expid = arrayfun(@(id) readsingleid(id, out), IDs);
    if nargin < 2 || ~strcmp(silent,'silent')
        fprintf('%i experimental dataset(s) imported successfully.\n',numel(IDs))
    end
end

%% local subfunctions

%READSINGLEID Read standardized data for 1 ID into scalar Individual object
function expid = readsingleid(id, out)

    out = selectid(out, id);

    expid = Individual();             
    expid.type = 'Experimental data';
    expid.name = ['ID ' id{1}];

    types = {out.type};

    collapse_out_by = @(type) tblvertcat(out(strcmp({out.type},type)).tab);

    if ismember('Record', types)
        rectab = collapse_out_by('Record');
        rectab.Type = repmat({'ExpData'},height(rectab),1);
        expid.observation = Record(rectab);
    end

    if ismember('Covariate', types)
        covtab = collapse_out_by('Covariate');
        expid.physiology = Covariates(covtab);
    end

    % using "+" for Dosing objects to allow for multiple routes of administration 
    if ismember('Bolus dosing', types)
        dostab = collapse_out_by('Bolus dosing');
        expid.dosing = expid.dosing + Bolus(dostab);
    end

    if ismember('Infusion dosing', types)
        dostab = collapse_out_by('Infusion dosing');
        expid.dosing = expid.dosing + Infusion(dostab);
    end

    if ismember('Oral dosing', types)
        dostab = collapse_out_by('Oral dosing');
        expid.dosing = expid.dosing + Oral(dostab);
    end

end

% SELECTID Filter a data output structure by ID.
function out = selectid(out, id)
    for i = 1:numel(out)
        out(i).tab = out(i).tab(out(i).tab.ID == id,:);
        out(i).tab.ID = [];
    end
end

