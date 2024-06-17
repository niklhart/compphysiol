function [xu,yu,zu] = getAxesUnits(ax)

    
    xu = rmexpo(ax.XRuler.SecondaryLabel.String);
    if nargout > 1
        yu = rmexpo(ax.YRuler.SecondaryLabel.String);
    end
    if nargout > 2
        zu = rmexpo(ax.ZRuler.SecondaryLabel.String);
    end

end


function str = rmexpo(str)
    if startsWith(str, '\times')
        str = extractAfter(str, ' ');
    end
end