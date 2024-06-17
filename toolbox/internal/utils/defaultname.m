%DEFAULTNAME Create a default name for an unnamed individual
function str = defaultname(individual)

    assert(isscalar(individual), 'Input must be scalar.')
        
    cdos  = {strjoin(compounds(individual.dosing),'/')};

    phys = individual.physiology;
    attr = {'species','sex','age','BW'};
    cphys = cell(numel(attr),1);
    for i = 1:numel(attr)        
        if hasuniquerecord(phys,attr{i})
            cphys{i} = num2str(getvalue(phys,attr{i}));
        end
    end

    ctype = {''};
    if ~isempty(individual.type)
        switch individual.type
            case 'Experimental data'
                ctype = {'exp. data'};            
            case 'Virtual individual'
                if isfield(individual.model,'fun')
                    ctype = {func2str(individual.model.fun)};
                end
        end
    end
    c = [cdos; cphys; ctype];
    str = strjoin(c(~cellfun(@isempty,c)),':');

    str = replace(str, '_', '\_');
end

