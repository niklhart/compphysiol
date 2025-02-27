classdef optionsClass
%OPTIONSCLASS Class defining global options, their format and defaults: 
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

    properties
        reporting (1,:) char = 'Assumptions'
        XScaleLog (1,1) logical = false
        YScaleLog (1,1) logical = false
        OdeUnitCheck (1,:) char {mustBeMember(OdeUnitCheck, {'never','once','always'})} = 'once'
        DisplayUnits cell = {}
        AutoAssignDrugData (1,1) logical = false
        AutoFilterDrugData (1,1) logical = false
        AutoExpDataUnitType (1,1) logical = true
        PlotOptions struct {optionsClass.mustBePlotOptions} = struct('lw',2,'ms',10,'fs',18)
        LoadExpDrugData (1,1) logical = true
        DefaultObservable Observable = Observable.empty
        ReportToConsole (1,1) logical = false
        DimVarPlot (1,1) logical = false
        PhysiologyDB function_handle = @initphysiologydb
        DrugDB function_handle = @initdrugdb
        PhysiologyTemplate function_handle = @physiologytemplate
        DrugTemplate function_handle = @drugtemplate
        PlotTemplate function_handle = @plottemplate
        ObservableTemplate function_handle = @obstemplate
    end

    methods (Static)
        function mustBePlotOptions(x)
            valid = {'lw','ms','fs'};
            if ~isstruct(x) || ~isscalar(x)
                error('Must be a scalar struct.')        
            elseif ~isfield(x, valid)
                error(['Must contain the following fields: ' strjoin(valid,', ') '.'])
            elseif any(structfun(@(z) z<=0, x))
                error(['Plot options ' strjoin(valid,', ') ' must all be positive.'])
            end
        end
    end
end

