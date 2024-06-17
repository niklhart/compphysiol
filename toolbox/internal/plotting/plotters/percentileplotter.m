%PERCENTILEPLOTTER Plotting function for dimensioned tabular longitudinal data
function percentileplotter(tab, xvar, yvar, xunit, yunit, percentiles)
    
    if nargin < 6 || isempty(percentiles)
        percentiles = [5 25 50 75 95];
    end

    if getoptPBPKtoolbox('DimVarPlot')
        if isempty(tab)
            x = NaN*str2u(xunit);
            y = NaN*str2u(yunit);

        else
            x = scd(tab.(xvar), xunit);
            y = scd(tab.(yvar), yunit);    
        end
    else
        if isempty(tab)
            x = NaN;
            y = NaN;
        else
            x = detachunit(tab.(xvar), xunit);
            y = detachunit(tab.(yvar), yunit);
        end
    end

    if isempty(tab)
        G = 1;
        xG = x;
    else
        [G, xG]  = findgroups(x);            
    end

    res = splitapply(@(x) {prctile(x, percentiles)}, y, G);
    pctmat = vertcat(res{:});

    if ~issorted(xG)
        [xG, ix] = sort(xG);
        pctmat = pctmat(ix,:);
    end 
    
    plot(xG, pctmat(:,3), 'r-')
    hold on
    ciplot(pctmat(:,2), pctmat(:,4), xG, [.4 .4 .4]);
    ciplot(pctmat(:,1), pctmat(:,5), xG, [.6 .6 .6]);   
 
end

