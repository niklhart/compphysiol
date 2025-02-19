%XYSORTPLOTTER Plotting function for dimensioned tabular longitudinal data

function xysortplotter(tab, xvar, yvar, xunit, yunit, style)

    if getoptcompphysiol('DimVarPlot')
        if isempty(tab)
            x = NaN*str2u(xunit);
            y = NaN*str2u(yunit);
        else
            x = scd(tab.(xvar), xunit);
            y = scd(tab.(yvar), yunit);            
        end
    else   % legacy behaviour
        if isempty(tab)
            x = NaN;
            y = NaN;
        else
            x = detachunit(tab.(xvar), xunit);
            y = detachunit(tab.(yvar), yunit);            
        end
    end

    if ~issorted(x) && contains(style,'-')
        [x, ix] = sort(x);
        y = y(ix);
    end

    plot(x, y, style)

end

