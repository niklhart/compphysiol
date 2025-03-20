%PERCENTILEPLOT Plotting function for percentile plots
%   PERCENTILEPLOT(INDIVIDUAL) produces a percentile plot for the
%   Individual object (array) INDIVIDUAL, with default options.
%
%   PERCENTILEPLOT(INDIVIDUAL,NM1,VAL1,NM2,VAL2,...) uses plot options 
%   specified as name-value pairs NM1,VAL1,NM2,VAL2,... 
%
%   H = PERCENTILEPLOT(...) returns the handle to the plot.
%
%   The following plot options are defined:
%
%   Parameter        Explanation                Default         
%   ---------        -----------                -------
%   coverage         Coverage probability       [50 90]
%   tunit            Time unit                  Same as in dataset/model
%   yunit            Unit(s) of observables     Same as in dataset/model
%   subplot_by       'ID', 'IdType', 'Name' or  [] (no subplotting)
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
%   plotter          Fct. handle for plotting   percentileplotter
%   
%   Note: groupings are not supported by PERCENTILEPLOT.
%
%   See also Individual/plot, plottemplate, parseplotinput, 
%   compileplottable, aggregatelevels, toolboxplot

function varargout = percentileplot(individual, varargin)

    nargoutchk(0,1)

    % process varargin with input parser
    pRes  = parseplotinput(varargin{:});

    assert(isempty(pRes.group_by),'Option "group_by" is not available for percentile plots.')

    % create a (potentially) large table for plotting
    obsattr = evalfhopt('ObservableTemplate');
    obs_args = selectfields(pRes, obsattr(:,1));
    tab = compileplottable(individual, obs_args);

    % assign default/derived values based on provided input
    subplot_by = pRes.subplot_by;
    isplotgrid = ~isempty(subplot_by);
    
    if isplotgrid 
        tab.SUBPLOTCAT = aggregatelevels(tab, pRes.subplot_by);
        pRes.subplot_by = strjoin(cellstr(pRes.subplot_by),'/');
    end
    pRes.style = {''}; % no plotting style required

    %% Early return if table output was requested
    % (TODO: rather a summary of percentiles)??
    if pRes.tableOutput
        varargout{1} = tab;
        return
    end  
    
    %% Process unit arguments and link axis argument
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
        
    %% Create figure

    h = toolboxplot(tab, pRes.plotter, pRes);
    
    percentiles = coverage2percentile(pRes.coverage);

    perc = cellfun(@num2str,num2cell(percentiles),'UniformOutput',false);
    ncov = numel(pRes.coverage);
    legendArgs = cell(ncov+1,1);
    legendArgs{1} = perc{ncov+1};
    for i = 1:ncov
        legendArgs{i+1} = [perc{ncov+1-i} '-' perc{ncov+1+i}];
    end
    hleg = legend(legendArgs{:});
    title(hleg, 'Percentiles')

    
    %% Assign output if requested
    switch nargout
        case 1
            varargout{1} = h;
    end
    
end


