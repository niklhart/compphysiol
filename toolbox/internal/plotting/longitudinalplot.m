%LONGITUDINALPLOT Plotting function for longitudinal data
%   LONGITUDINALPLOT(INDIVIDUAL) produces an observable-time plot for the
%   Individual object (array) INDIVIDUAL, with default options.
%
%   LONGITUDINALPLOT(INDIVIDUAL,NM1,VAL1,NM2,VAL2,...) uses plot options 
%   specified as name-value pairs NM1,VAL1,NM2,VAL2,... (see below)
%
%   H = LONGITUDINALPLOT(...) returns the handle to the plot.
%
%   TAB = LONGITUDINALPLOT(INDIVIDUAL, 'tableOutput', true, ...) returns an
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
%                    (e.g., 'Site')
%   subplot_lvl      Custom subplotting levels  One subplot per category
%   group_by         'ID', 'Observable',        [] (no grouping)
%                    'IdType', 'Name' or 
%                    any Observable attribute
%                    (e.g., 'Site')
%   group_lvl        Custom grouping levels     One group per category
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
%   
%   See also Individual/plot, plottemplate, parseplotinput, 
%   compileplottable, aggregatelevels, toolboxplot, percentileplot

function varargout = longitudinalplot(individual, varargin)

    %% Input check
    nargoutchk(0,1)

    % process varargin with input parser
    pRes  = parseplotinput(varargin{:});
    
    %% Create plotting table
    
    % create a (potentially) large table for plotting
    obsattr = obstemplate();
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
        tab.GROUPCAT   = aggregatelevels(tab.(pRes.group_by), pRes.group_lvl);
        group_lvl      = categories(tab.GROUPCAT);
        switch pRes.group_by
            case 'ID'
                [style, ~] = graphicstyle(individual);
            case 'Name'
                if isempty(pRes.group_lvl)
                    [style, leg] = graphicstyle(individual);
                    tab.GROUPCAT = categorical(cellstr(tab.GROUPCAT), leg);
                else
                    [style, ~] = graphicstyle_attr(group_lvl);
                end
            case 'Observable'
                assert(isempty(pRes.group_lvl), ...
                    'group_lvl argument not yet implemented for group_by = "Observable".')
                [style, ~] = graphicstyle_attr(group_lvl);
            case 'IdType'
                style = {'+','-'};
            otherwise % attributes
                [style, ~] = graphicstyle_attr(group_lvl);
        end
    else 
        if all(issimid(individual),'all')
            style = {'k-'};
        else
            style = {'k+'}; %in mixed exp/sim arrays, virtual IDs are plotted as markers
        end
    end
    pRes.style = style;

    if isplotgrid 
        tab = filterbylvl(tab, pRes.subplot_by, pRes.subplot_lvl);
        tab.SUBPLOTCAT = aggregatelevels(tab.(pRes.subplot_by), pRes.subplot_lvl);
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

    longitudinalplotter = @(T,u,s) xyplotter(T,'Time','Value',u{1},u{2},s);
    
    h = toolboxplot(tab, longitudinalplotter, pRes);
        
    %% Assign output if requested
    if nargout
        varargout{1} = h;
    end
    
end



