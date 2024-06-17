function [] = axesUpdateCallback(ax, evt)
%AXESUPDATECALLBACK Callback function for unit checking when updating axes
%   Detailed explanation goes here

    xunit = rmexpo(ax.XRuler.SecondaryLabel.String);
    yunit = rmexpo(ax.YRuler.SecondaryLabel.String);

    chldrn = ax.Children;
    nwchld = evt.ChildNode;

    if numel(chldrn) > numel(nwchld) && (~isempty(xunit) || ~isempty(yunit))
        % UserData is used to flag those values that were converted from
        % DimVar. For these, the Callback function doesn't need to do
        % anything, since unit consistency has already been checked in
        % DimVar/plot.
        if isempty(evt.ChildNode.UserData)
            delete(ax.Children(1:numel(nwchld)))
            ME = MException('Plot:InvalidAxisVariable',...
                'Trying to plot double variable into DimVar axes.');
            throwAsCaller(ME)
        end
    end

end

function str = rmexpo(str)
    if startsWith(str, '\times')
        str = extractAfter(str, ' ');
    end
end