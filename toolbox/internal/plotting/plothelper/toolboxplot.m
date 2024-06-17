%TOOLBOXPLOT Low-level toolbox function for (grouped / stratified) plots 
%   H = TOOLBOXPLOT(TAB, PLOTTER, OPTIONS) creates a figure with handle H 
%   representing a data table TAB via a plotting function PLOTTER, using an
%   options struct OPTIONS. 
%
%   - TAB is a data table as outputted from 'compileplottable()'
%   - PLOTTER is a three-argument function creating a plot from the  
%     following three input arguments: 
%      - a data table (same format as TAB)
%      - a plotting unit (character array)
%      - a plotting style (character array)
%     For example, @(T,u,s) xyplotter(T,'time','data',u{1},u{2},s)
%   - OPTIONS is a parsed input struct as outputted from 'parseplotinput()'.
%
%   See also compileplottable, parseplotinput, polish, longitudinalplot,
%   percentileplot, xyplotter, xysortplotter, percentileplotter.

function h = toolboxplot(tab, plotter, options)

    %% Preparations
    assert(istable(tab), 'Input #1 must be a table.')
    assert(isa(plotter,'function_handle'), 'Input #2 must be a function handle')
    
    isgrouped  = istablecol(tab, 'GROUPCAT');
    isplotgrid = istablecol(tab, 'SUBPLOTCAT');
    
    tabgrid   = splittable(tab,'GROUPCAT','SUBPLOTCAT');

    if isgrouped   
        group_lvl = categories(tab.GROUPCAT);
    end
    if isplotgrid
        subplot_lvl = categories(tab.SUBPLOTCAT);
    end
    
    [nGrp,nSub] = size(tabgrid);
    [nRow,nCol] = subplotsize(nSub,options.maxSubplots,options.maxSubplotRows,options.maxSubplotCols);

    units = cellfun(@(x,y) {x y}, options.tunit, options.yunit, 'UniformOutput', false);
    
    %% Main control flow    

    % if 'figure()' was called just before calling a toolbox plot (i.e., we
    % have an empty figure available), don't create another figure. This
    % allows to programmatically test plotting functions without visible
    % figures. At some point, we might remove the 'figure()' part here
    % altogether.
    if ~isempty(get(0,'CurrentFigure')) && isempty(get(gcf,'Children'))
        h = gcf;
    else
        h = figure();
    end

    for i = 1:nSub
        if isplotgrid
            subplot(nRow,nCol,i)
        end
        for j = 1:nGrp
            plotter(tabgrid{j,i}, units{i}, options.style{j});         
            hold on
        end                
        if isplotgrid
            title([options.subplot_by ' = ' num2str(subplot_lvl{i})])
        end
        if getoptPBPKtoolbox('DimVarPlot')
            xlabel(options.xlabel)
            ylabel(options.ylabel)
        else
            xlabel([options.xlabel ' [' options.tunit{i} ']' ])
            ylabel([options.ylabel ' [' options.yunit{i} ']' ])
        end
        if options.xscalelog
            set(gca,'XScale','log');
        end
        if options.yscalelog
            set(gca,'YScale','log');
        end
    end
    if isplotgrid
        sgtitle(options.title)
    else
        title(options.title)
    end
    if options.linkAxes         
        ax = findobj(h,'Type','Axes');
        if ~isempty(ax)
            linkaxes(ax)
        end
        pause(0.15)  % linkaxis takes some time; otherwise legends/titles 
                     % are sometimes plotted into the wrong figure
    end
    if isgrouped
        hleg = legend(group_lvl{:});
        if isplotgrid
            % suitable legend position for default 3x4 layout and 10 plots
            set(hleg,'Position',[0.60 0.15 0.3 0.13])
        end
        title(hleg, options.group_by)
    end
    
    polish(h, options.polish)
    hold off

end

%% Local subfunctions

function [nRow,nCol] = subplotsize(nSub,maxSub,maxRow,maxCol)

    maxSub2 = min(maxSub,maxRow*maxCol);
        if nSub > maxSub2
            if maxSub2 >= maxSub
                msg = ['At most %s subplots allowed, but %s requested. '...
                   'Filter the data or increase option maxSubplots'];
            else
                msg = ['At most %s subplots allowed, but %s requested. '...
                   'Filter the data or increase option maxSubplotRows'...
                   'and/or maxSubplotCols'];
            end
            error(msg, num2str(maxSub2), num2str(nSub))
        end

        nRow = ceil(nSub * maxRow / maxSub);
        nCol = ceil(nSub / nRow);
end

