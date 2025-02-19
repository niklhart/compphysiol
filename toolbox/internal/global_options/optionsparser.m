%OPTIONSPARSER Parses its arguments and returns a valid options struct.
%   
%Options defined in OPTIONSPARSER: 
%
%   reporting - Control level of reporting [character array {Assumptions}]
%       This option is currently unused.
%   
%   XScaleLog - Log x scale in plots by default [ true | {false} ]
%   
%   YScaleLog - Log y scale in plots by default [ true | {false} ]
%   
%   OdeUnitCheck - Unit check frequency when solving ODEs [ never | {once} | always] 
%   
%   DisplayUnits - List of preferred display units [ cellstr {empty} ]
%   
%   AutoAssignDrugData - Load drug data when assigning dosing [ true | {false} ]
%   
%   AutoFilterDrugData - Filter drug data by species when assigning physiology & dosing [ true | {false} ]
%
%   DefaultObservable - An Observable array used by default when
%       unspecified in simulations, or empty (default).
%
%   PlotOptions - Size of plot lines, markers and text [ struct (see below) ]
%       One or several of the following fields can be defined: 
%          .lw    line width     default = 2
%          .ms    marker size    default = 10
%          .fs    font size      default = 18
%       On some systems, these defaults produce unreasonable plots and
%       should be modified.
%
%   LoadExpDrugData - Use ExpDrugData specification [ {true} | false ]
%   
%   AutoExpDataUnitType - Extract data unit type automatically [ {true} | false ]
%       If true, unit types of experimental data are determined automatically
%       from the units of the Value column. Otherwise, they always have to
%       be specified manually.
%
%   ReportToConsole - Console reports during modelling tasks [ true | {false} ]
%
%   DimVarPlot - Use DimVar plot method for toolbox plots [ true | {false} ]
%       If true, toolbox plots are created with the DimVar plot method,
%       which means that these plots can be customized afterwards using
%       dimensioned variables. It also shows units in a different location.
%
%   PhysiologyDB - Function handle to the initialization function of the
%       physiological database
%   
%   DrugDB - Function handle to the initialization function of the drug
%       database
%
%   PhysiologyTemplate - Function handle to the physiology template
%
%   DrugTemplate - Function handle to the drug template
%
%   PlotTemplate - Function handle to the plot template
%
%   ObservableTemplate - Function handle to the observable template
%
%   See also optionscompphysiol, getoptcompphysiol, setoptcompphysiol

function options = optionsparser(options, varargin)

    p = inputParser();
    
    %              Parameter             Default                         Validation function
    p.addOptional( 'reset',              [],                             @(x) strcmpi(x,'reset'));
    p.addParameter('reporting',          'Assumptions',                  @ischar);
    p.addParameter('XScaleLog',          false,                          @isboolean);
    p.addParameter('YScaleLog',          false,                          @isboolean);
    p.addParameter('OdeUnitCheck',       'once',                         @(x) ismember(x,{'never','once','always'}));
    p.addParameter('DisplayUnits',       {},                             @iscellstr);
    p.addParameter('AutoAssignDrugData', false,                          @isboolean);
    p.addParameter('AutoFilterDrugData', false,                          @isboolean);
    p.addParameter('AutoExpDataUnitType',true,                           @isboolean);
    p.addParameter('PlotOptions',        struct('lw',2,'ms',10,'fs',18), @isplotoptions);
    p.addParameter('LoadExpDrugData',    true,                           @isboolean);
    p.addParameter('DefaultObservable',  [],                             @(x) isempty(x) || isa(x,'Observable'));
    p.addParameter('ReportToConsole',    false,                          @isboolean);
    p.addParameter('DimVarPlot',         false,                          @isboolean);
    p.addParameter('PhysiologyDB',       @initphysiologydb,              @isfunctionhandle);
    p.addParameter('DrugDB',             @initdrugdb,                    @isfunctionhandle);
    p.addParameter('PhysiologyTemplate', @physiologytemplate,            @isfunctionhandle);
    p.addParameter('DrugTemplate',       @drugtemplate,                  @isfunctionhandle);
    p.addParameter('PlotTemplate',       @plottemplate,                  @isfunctionhandle);
    p.addParameter('ObservableTemplate', @obstemplate,                   @isfunctionhandle);

    p.parse(varargin{:});
    
    % resetting options to default
    if ~isempty(p.Results.reset)
        options = rmfield(p.Results, 'reset');
        return
    end
    
    % initialization -> take all parsed results
    if isempty(fieldnames(options))
        options = rmfield(p.Results, 'reset');
        return
    end
    
    % update only defined options, not defaults
    defined = setdiff(p.Parameters, p.UsingDefaults);
    for fldcell = defined
        fld = fldcell{1};
        options.(fld) = p.Results.(fld);
    end
    
end

function TF = isplotoptions(x)
    TF = false; %#ok<NASGU>
    valid = {'lw','ms','fs'};
    if ~isstruct(x) || ~isscalar(x)
        error('Must be a scalar struct.')        
    elseif ~isfield(x, valid)
        error(['Must contain the following fields: ' strjoin(valid,', ') '.'])
    elseif any(structfun(@(z) z<=0, x))
        error(['Plot options ' strjoin(valid,', ') ' must all be positive.'])
    else
        TF = true;
    end
end

function TF = isfunctionhandle(x)
    TF = isa(x,'function_handle');
    assert(TF, 'Must be a function handle.')
end

