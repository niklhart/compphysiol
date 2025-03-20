%PLOT Plotting method of Individual class
%   PLOT(INDIVIDUAL) produces an observable-time plot for the
%   Individual object (array) INDIVIDUAL, with default options.
%
%   PLOT(INDIVIDUAL,NM1,VAL1,NM2,VAL2,...) uses plot options 
%   specified as name-value pairs NM1,VAL1,NM2,VAL2,... (see below)
%
%   H = PLOT(...) returns the handle to the plot.
%
%   TAB = PLOT(INDIVIDUAL, 'tableOutput', true, ...) returns an
%   aggregated table that can be used for customized plotting if there is
%   need for more control over the plots. Of the additional arguments (...)
%   provided, only 'obs' will impact (=subsetting TAB) on the output. No
%   figure will be drawn.
%
%   The following plot options are defined:
%
%   Parameter        Explanation                Default         
%   ---------        -----------                -------
%   tunit            Time unit                  Same as in dataset/model
%   yunit            Unit(s) of observables     Same as in dataset/model
%   subplot_by       'ID', 'Observable',        [] (no subplotting)
%                    'IdType', 'Name' or 
%                    any Observable attribute
%                    (e.g., 'Site'), or a 
%                    cellstr thereof.
%   group_by         'ID', 'Observable',        [] (no grouping)
%                    'IdType', 'Name' or 
%                    any Observable attribute
%                    (e.g., 'Site'), or a 
%                    cellstr thereof.
%   Site             Filter by Site attribute   [] (don't filter by site)
%                    of class Observable
%                    (e.g. {'liv','adi'})     
%   Subspace         As above                   [] (don't filter by subspace)
%   Binding          As above                   [] (don't filter by binding)
%   UnitType         As above                   [] (don't filter by unit type)
%   xlabel           x label (without tunit)    'Time'
%   ylabel           y label (without yunit)    'Data'
%   xscalelog        log x axis (boolean)?      From global options      
%   yscalelog        log y axis (boolean)?      From global options      
%   title            Global plot title          [] (no title)
%   maxSubplots      Max # of subplots          12 
%   maxSubplotRows   Max # of subplot rows       3 
%   maxSubplotCols   Max # of subplot cols       4 
%   linkAxes         Link axes of subplots?     true if all yunits are equal
%   polish           Arg. OPTS to polish()      From global options
%   tableOutput      Return table output in-    false
%                    stead of creating figure?
%   plotter          Fct. handle for plotting   xyplotter (Time/Value args)
%   style            cellstr of plotting styles []
%                    (e.g., {'b:','r-'})
%   
%   See also plottemplate, parseplotinput, xyplotter
%   compileplottable, aggregatelevels, toolboxplot, percentileplot

function varargout = plot(individual, varargin)

    %% Input check
    nargoutchk(0,1)

    % process varargin with input parser
    defaultPlotter = @(T,u,s) xyplotter(T,'Time','Value',u{1},u{2},s);
    pRes  = parseplotinput('plotter',defaultPlotter,varargin{:});
    
    %% Create plotting table
    
    % create a (potentially) large table for plotting
    obsattr = evalfhopt('ObservableTemplate');
    obs_args = selectfields(pRes,obsattr(:,1));
    tab = compileplottable(individual, obs_args);
        
    % handle the empty table case
    if isempty(tab)
        warning('Nothing to plot.')
        if nargout == 1
            varargout{1} = figure();
        end
        return
    end
    
    % Define grouping / subplotting categories, define plot style
    isplotgrid = ~isempty(pRes.subplot_by);
    isgrouped  = ~isempty(pRes.group_by);
        
    if isgrouped
        tab.GROUPCAT   = aggregatelevels(tab, pRes.group_by);
        pRes.group_by = strjoin(cellstr(pRes.group_by),'/');
        group_lvl      = categories(tab.GROUPCAT);

        if ~isempty(pRes.style)
            assert(numel(group_lvl) == numel(pRes.style), ...
                'Number of styles must equal number of groups.')
            style = pRes.style;
        else
            switch pRes.group_by
                case 'ID'
                    [style, ~] = graphicstyle(individual);
                case 'Name'
                    [style, leg] = graphicstyle(individual);
                    [uleg, idx] = unique(leg);
                    style = style(idx);
                    tab.GROUPCAT = categorical(cellstr(tab.GROUPCAT), uleg);
                case 'IdType'
                    style = {'+','-'};
                otherwise % attributes
                    [style, ~] = graphicstyle_attr(group_lvl);
            end
        end

    else 
        if ~isempty(pRes.style)
            style = cellstr(pRes.style);
            assert(numel(style) == 1, 'Exactly one style required for ungrouped plots.')
        else
            if all(issimid(individual),'all')
                style = {'k-'};
            else
                style = {'k+'}; %in mixed exp/sim arrays, virtual IDs are plotted as markers
            end
        end
    end
    pRes.style = style;

    if isplotgrid 
        tab.SUBPLOTCAT = aggregatelevels(tab, pRes.subplot_by);
        pRes.subplot_by = strjoin(cellstr(pRes.subplot_by),'/');
    end
    
    %% Early return if table output was requested
    if pRes.tableOutput
        varargout{1} = tab;
        return
    end  
    
    %% Process unit arguments and link axis argument
    if isempty(tab)
        warning('Nothing to plot.')
        return
    end
    
    [tunit, yunit] = getunits(tab, pRes.tunit, pRes.yunit);
    pRes.tunit = tunit;
    pRes.yunit = yunit;
    
    % default: link axes if uniform yUnits are used for all subplots
    linkAxes = pRes.linkAxes;
    if isempty(linkAxes)
        uniformYUnits = all(strcmp(yunit, yunit{1}));
        linkAxes = uniformYUnits && ~isscalar(yunit);
    end
    pRes.linkAxes = linkAxes;
        
    %% create figure

    h = toolboxplot(tab, pRes.plotter, pRes);
        
    %% Assign output if requested
    if nargout
        varargout{1} = h;
    end
    
end



