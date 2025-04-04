%PARSEPLOTINPUT Parse input for plotting function
%   PRES = PARSEPLOTINPUT(NM1,VAL1,...) parses name-value pairs and returns
%   a struct PRES of parsed inputs. 
%
%   The following properties are defined:
%
%   Parameter        Explanation                Default         
%   ---------        -----------                -------
%   tunit            Time unit                  Same as in dataset/model
%   yunit            Unit(s) of observables     Same as in dataset/model
%   subplot_by       'ID', 'Name', 'IdType'     [] (no subplotting)
%                    or any Observable attri-
%                    bute (e.g., 'Site'), or 
%                    a cellstr of those.
%   group_by         'ID', 'Name', 'IdType'     [] (no grouping)
%                    or any Observable attri-
%                    bute (e.g., 'Site'), or 
%                    a cellstr of those.
%   xlabel           x label (without tunit)    'Time'
%   ylabel           y label (without yunit)    'Data'
%   subplot_label    subplot labelling method   'name/value'
%                    ('name/value','value' or
%                    'none')
%   xscalelog        log x axis (boolean)?      From global options      
%   yscalelog        log y axis (boolean)?      From global options      
%   title            Global plot title          [] (no title)
%   maxSubplotRows   Max # of subplot rows       3 
%   maxSubplotCols   Max # of subplot cols       4 
%   linkAxes         Link axes of subplots?     true if all yunits are equal
%   polish           Arg. OPTS to polish()      From global options
%   tableOutput      Return table output in-    false
%                    stead of creating figure?
%   style            cellstr of plotting styles []
%                    (e.g., {'b:','r-'})
%
%   Also, Observable attributes ('Site', 'Subspace', 'Binding', 'UnitType', 
%   ...) can be provided as parameters, in which case the data are filtered
%   to the value set of that parameter prior to plotting.

function pRes = parseplotinput(varargin)

    %% process varargin with input parser
    
    p = inputParser();
%                  Parameter         Default         Validation function
    p.addParameter('tunit',          [],             @ischar);
    p.addParameter('yunit',          [],             @(x) isempty(x) || ischar(x) || iscellstr(x)); %#ok<*ISCLSTR>
    p.addParameter('subplot_by',     [],             @(x) isempty(x) || ischar(x) || iscellstr(x));
    p.addParameter('group_by',       [],             @(x) isempty(x) || ischar(x) || iscellstr(x));

    obsattr = evalfhopt('ObservableTemplate');
    for i = 1:size(obsattr,1)
        p.addParameter(obsattr{i,1}, '',    @(x) ischar(x) || iscellstr(x));
    end

    p.addParameter('Type',           [],             @ischar);
    p.addParameter('xlabel',         'Time',         @ischar);
    p.addParameter('ylabel',         'Data',         @ischar);
    p.addParameter('subplot_label',  'name/value',   @(x) ismember(x,{'name/value','value','none'}));
    p.addParameter('xscalelog',      getoptcompphysiol('XScaleLog'),  @isboolean);
    p.addParameter('yscalelog',      getoptcompphysiol('YScaleLog'),  @isboolean);
    p.addParameter('title',          [],             @ischar);
    p.addParameter('maxSubplotRows',  3,             @isnumeric);
    p.addParameter('maxSubplotCols',  4,             @isnumeric);
    p.addParameter('linkAxes',       [],             @isboolean);
    p.addParameter('polish',         struct,         @isstruct);
    p.addParameter('tableOutput',    false,          @isboolean);
    p.addParameter('coverage',       [50 90],        @isnumeric);
    p.addParameter('plotter',        []);
    p.addParameter('style',          [],             @(x) ischar(x) || iscellstr(x));

    p.parse(varargin{:});
       
    %% string input validation & standardization
    pRes = p.Results;
        
    %% percentile plotter default
    if isempty(pRes.plotter)
        pRes.plotter = @(T,u,~) percentileplotter(T,'Time','Value',u{1},u{2},pRes.coverage);
    end

    %% Derived plot options
    
    % polish option priority: 
    %   1) input argument 'polish'
    %   2) global plot options
    %   3) defaults defined in polish 
    pRes.polish = mergestructs(getoptcompphysiol('PlotOptions'), pRes.polish);
end
    