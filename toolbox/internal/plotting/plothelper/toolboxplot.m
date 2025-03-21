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
%   See also Individual/plot, compileplottable, parseplotinput, polish,
%   percentileplot, xyplotter, xysortplotter, percentileplotter.

function h = toolboxplot(tab, plotter, options)

    arguments
        tab table
        plotter function_handle 
        options struct
    end

    %% Preparations
    
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
    [nRow,nCol] = plotgridsize(nSub,options.maxSubplotRows,options.maxSubplotCols);

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

    if isplotgrid
        if options.linkAxes
            tilespacing = 'tight';
        else
            tilespacing = 'compact';
        end
        t = tiledlayout(nRow,nCol,'TileSpacing',tilespacing, 'Padding', 'compact');
    end
    for i = 1:nSub
        if isplotgrid
            ax = nexttile;
        end
        for j = 1:nGrp
            plotter(tabgrid{j,i}, units{i}, options.style{j});         
            hold on
        end                

        % subplot titles
        if isplotgrid
            switch options.subplot_label
                case 'name/value'
                    title([options.subplot_by ' = ' num2str(subplot_lvl{i})])
                case 'value'
                    title(num2str(subplot_lvl{i}))
                case 'none'
                    % pass
            end
        end

        % inverting role of col <--> row since tiledlayout works by row, 
        % not by column as in matrix indexing
        [col,row] = ind2sub([nCol nRow],i);

        % linked plot grid --> tick labels only in last row & first column
        if options.linkAxes && row < nRow                 
            ax.XTickLabel = [];
        end
        if options.linkAxes && col ~= 1
            ax.YTickLabel = [];
        end

        % log one or both axes if requested
        if options.xscalelog
            set(gca,'XScale','log');
        end
        if options.yscalelog
            set(gca,'YScale','log');
        end
    end

    if isplotgrid
        gob = t;
        sgtitle(options.title)
    else
        gob = gca;
        title(options.title)
    end

    if getoptcompphysiol('DimVarPlot')
        xlabel(gob,options.xlabel)
        ylabel(gob,options.ylabel)
    else
        xlabel(gob,[options.xlabel ' [' options.tunit{i} ']' ])
        ylabel(gob,[options.ylabel ' [' options.yunit{i} ']' ])
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
        leg = legend(group_lvl{:},'Location','East');
        title(leg, options.group_by)
        % if isplotgrid
        %     leg.Layout.Tile = 'East'; %TODO: turn legend placement into a plot option
        % end
    end
    
    polish(h, options.polish)
    hold off

end

%% Local subfunctions

function [nRow,nCol] = plotgridsize(nSub,maxRow,maxCol)

    maxSub = maxRow*maxCol;
        if nSub > maxSub
            msg = ['At most %s subplots allowed, but %s requested. '...
               'Filter the data or increase option maxSubplotRows'...
               'and/or maxSubplotCols'];
            error(msg, num2str(maxSub), num2str(nSub))
        end

        nRow = ceil(nSub * maxRow / maxSub);
        nCol = ceil(nSub / nRow);
end

