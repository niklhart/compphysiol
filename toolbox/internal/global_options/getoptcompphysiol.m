%GETOPTCOMPPHYSIOL Get one or all global toolbox options
%
%   OPT = GETOPTCOMPPHYSIOL(NAME) returns the value OPT of option NAME. 
%
%   OPT = GETOPTCOMPPHYSIOL() or OPT = GETOPTCOMPPHYSIOL('all') returns all
%       options as a struct OPT.
%   
%   For a list of available options including explanations and the required 
%   format, refer to the help of function optionsparser.
%
%   See also setoptcompphysiol, optionscompphysiol, optionsparser

function opt = getoptcompphysiol(name)

    arguments
        name char {mustBeMember(name, {'reporting','XScaleLog','YScaleLog','OdeUnitCheck','DisplayUnits','AutoAssignDrugData','AutoFilterDrugData','AutoExpDataUnitType','PlotOptions','LoadExpDrugData','DefaultObservable','ReportToConsole','DimVarPlot','PhysiologyDB','DrugDB','PhysiologyTemplate','DrugTemplate','PlotTemplate','ObservableTemplate','all'})} = 'all'
    end

    opt = optionscompphysiol('get',name);

end

