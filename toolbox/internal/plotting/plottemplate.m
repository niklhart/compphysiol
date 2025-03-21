%PLOTTEMPLATE Define templates for types of graphs
%   Function PLOTTEMPLATE is called from within the 'plot' method of class
%   'Individual'; it defines templates for frequently used types of graphs.
%
%   PLOTTEMPLATE(INDIVIDUAL) displays the default graphics specified in
%   cell array DEFPLOTS. 
%
%   PLOTTEMPLATE(INDIVIDUAL, TYPE) matches TYPE to a plotting subfunction
%   and, if successful, displays the corresponding plot. TYPE need not be
%   defined in PLOTS.
%
%   PLOTTEMPLATE(INDIVIDUAL, TYPE, ...) can use any of the name-value pairs
%   described in function 'parseplotinput' to customize the templated
%   plot TYPE (properties already defined in template TYPE are overridden).
%
%   PLOTTEMPLATE(INDIVIDUAL, ...) customizes all default graphics specified
%   in cell array DEFPLOTS the same way.
%
%   H = PLOTTEMPLATE(...) returns a handle (array) to the produced plots.
%
%   Customizing templates
%
%   - Each local subfunction defines one plot template, which can be 
%     modified as required
%   - Additional templates can be built from low-level plotting functions
%     such as plot / percentileplot
%   - The default plotting behaviour can be adapted by adding/removing 
%     local functions to/from variable 'defplots'
%
%   See also Individual/plot, percentileplot, parseplotinput.

function h = plottemplate(individual, type, varargin)
    
    % default plots (customize as required) 
    % if no 'type' input argument is specified, the local functions to be
    % called can be specified here
    defaultplots = {
        @plasmaConcentration
        @allTissues        
    };
       
    if mod(nargin,2) == 1   % no "type" argument provided
        % show default plots
        nh = numel(defaultplots);
        h = gobjects(nh,1);
        if nargin == 1
            addargs = {};
        else
            addargs = [{type},varargin];
        end
        for i = 1:nh
            h(i) = defaultplots{i}(individual,addargs{:});
            pause(0.1)
        end
    else
        % show plot 'type'
        locfnm = cellfun(@func2str,localfunctions(),'UniformOutput',false);
        type = validatestring(type, locfnm);
        plotfun = str2func(type);
        h = plotfun(individual,varargin{:});
    end
end

%% local functions 
% plot templates -- customize/add as required

function h = plasmaConcentration(individual,varargin)

    h = plot(individual,...
        'Site',       'pla', ...
        'group_by',   'Name', ...
        'xlabel',     'Time',...
        'ylabel',     'Conc.',...
        'title',      'Plasma concentration',...
        varargin{:});
end

function h = allTissues(individual,varargin)

    tissues = {'adi','bon','gut','hea','kid','liv','lun','mus','ski','spl'};

    h = plot(individual, ...
        'Site',        tissues, ...
        'Subspace',   'tot', ...
        'subplot_by', 'Site', ...
        'group_by',   'Name', ...
        'xlabel',     'Time', ...
        'ylabel',     'Conc.', ...
        'title',      'Tissue concentrations', ...
        varargin{:});

end

function h = massBalance(individual,varargin)

    h = plot(individual, ...
        'Type',       'MassBalance', ...
        'group_by',   'Name', ...
        'xlabel',     'Time', ...
        'ylabel',     'Total amount', ...
        'title',      'Mass balance (should be constant within dosing intervals)',...
        varargin{:});
end

function h = percentilesPlasmaConc(individual,varargin)

    h = percentileplot(individual,...
        'Site',       'pla', ...
        'xlabel',     'Time',...
        'ylabel',     'Plasma concentration',...
        'title',      ['Percentile plot (N=' num2str(numel(individual)) ')'],...
        varargin{:});
end


