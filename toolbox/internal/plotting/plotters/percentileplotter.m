%PERCENTILEPLOTTER Plotting function for dimensioned tabular longitudinal data
function percentileplotter(tab, xvar, yvar, xunit, yunit, coverage)
    
    if nargin < 6
        coverage = [50 90];
    end
    ncov = numel(coverage);

    percentiles = coverage2percentile(coverage);

    if getoptcompphysiol('DimVarPlot')
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
    
    plot(xG, pctmat(:,ncov+1), 'r-')
    hold on
    for i = 1:ncov
        ciplot(pctmat(:,ncov+1-i), pctmat(:,ncov+1+i), xG, (i+1)*0.2*[1 1 1]);
    end 
end

