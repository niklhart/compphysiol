%GETUNITS Standardise format for units of t and y variables
function [tUnit, yUnit] = getunits(tab, tUnit, yUnit)

    isplotgrid = istablecol(tab,'SUBPLOTCAT');
    if isplotgrid
        subplot_lvl = categories(tab.SUBPLOTCAT);
        nSubplots = numel(subplot_lvl);
    else
        nSubplots = 1;
    end
    
    % process tUnit argument
    if isempty(tUnit)
        tUnit = getunitstr(tab.Time);
    end
    tUnit = reptosize(tUnit, nSubplots);
    
    % process yUnit argument
    if isempty(yUnit)
        % check that grouped data have common unit
        if isplotgrid
            yUnit = cell(nSubplots,1);
            for i = 1:nSubplots
                idx = tab.SUBPLOTCAT == subplot_lvl{i};
                yUnit{i} = getunitstr(tab.Value(idx));
            end
        else
            yUnit = getunitstr(tab.Value);
        end
    end
    % TODO: check that default subplot levels are not combined with non-default units
        
    yUnit = reptosize(yUnit, nSubplots);
    
    % check if all uniform yUnits are used for all subplots
    yUnitNonempty = yUnit(~cellfun(@isempty,yUnit));
    uniformYUnits = ~isempty(yUnitNonempty) && (isscalar(yUnitNonempty) || isequal(yUnitNonempty{:}));
        
    if uniformYUnits
        [yUnit{:}] = deal(yUnitNonempty{1});
    end

end

