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
%                    bute (e.g., 'Site')
%   subplot_lvl      Custom subplotting levels  One subplot per category
%   group_by         'ID', 'Name', 'IdType'     [] (no grouping)
%                    or any Observable attri-
%                    bute (e.g., 'Site')
%   group_lvl        Custom grouping levels     One group per category
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
%   Also, Observable attributes ('Site', 'Subspace', 'Binding', 'UnitType', 
%   ...) can be provided as parameters, in which case the data are filtered
%   to the value set of that parameter prior to plotting.

function pRes = parseplotinput(varargin)

    %% process varargin with input parser
    
    p = inputParser();
%                  Parameter         Default         Validation function
    p.addParameter('tunit',          [],             @ischar);
    p.addParameter('yunit',          [],             @(x) isempty(x) || ischar(x) || iscellstr(x)); %#ok<*ISCLSTR>
    p.addParameter('subplot_by',     [],             @(x) isempty(x) || ischar(x));
    p.addParameter('subplot_lvl',    {},             @isaggregation); 
    p.addParameter('group_by',       [],             @(x) isempty(x) || ischar(x));
    p.addParameter('group_lvl',      {},             @isaggregation); 

    obsattr = obstemplate();
    for i = 1:size(obsattr,1)
        p.addParameter(obsattr{i,1}, '',    @(x) ischar(x) || iscellstr(x));
    end

    p.addParameter('Type',           [],             @ischar);
    p.addParameter('xlabel',         'Time',         @ischar);
    p.addParameter('ylabel',         'Data',         @ischar);
    p.addParameter('xscalelog',      getoptPBPKtoolbox('XScaleLog'),  @isboolean);
    p.addParameter('yscalelog',      getoptPBPKtoolbox('YScaleLog'),  @isboolean);
    p.addParameter('title',          [],             @ischar);
    p.addParameter('maxSubplots',    12,             @isnumeric);
    p.addParameter('maxSubplotRows',  3,             @isnumeric);
    p.addParameter('maxSubplotCols',  4,             @isnumeric);
    p.addParameter('linkAxes',       [],             @isboolean);
    p.addParameter('polish',         struct,         @isstruct);
    p.addParameter('tableOutput',    false,          @isboolean);
    p.addParameter('percentiles',    [5 25 50 75 95],@isnumeric);
    
    p.parse(varargin{:});
       
    %% string input validation & standardization
    pRes = p.Results;
        
    %% Derived plot options
    
    % polish option priority: 
    %   1) input argument 'polish'
    %   2) global plot options
    %   3) defaults defined in polish 
    pRes.polish = mergestructs(getoptPBPKtoolbox('PlotOptions'), pRes.polish);
end
    
function tf = isaggregation(x)
    
    if iscell(x) && ~iscellstr(x)
         % cell array of cellstr --> unnamed aggregation --> ok
        tf = all(cellfun(@iscellstr,x),'all');   
    elseif isstruct(x)
        % struct of cellstr --> named aggregation --> ok
        tf = all(structfun(@iscellstr,x),'all');  
    else
        % cellstr --> equivalent to scalar cell of cellstr --> ok
        tf = iscellstr(x);
    end

end
    