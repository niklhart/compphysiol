%TEST_MODEL Non-physiological analytical model for toolbox testing
%   This function specifies a model with low runtime and the same input-
%   output behaviour as physiological models. It has no physiological
%   meaning. This model can be used to test functions appearing downstream
%   of (the usually time-consuming) Individual/simulate() method.
%
%   Only the sampling property needs to be specified for test_model() to
%   work (i.e., physiology, dosing and drug data are ignored). Supported 
%   observables are of type 'MultiPK'. The output is exponential decay at
%   a rate 1/h, starting at an observable-specific initial value:
%   
%       1 for Compound = 'A', Site = 'pla'
%       2 for Compound = 'A', Site = 'tis'
%       3 for Compound = 'B', Site = 'pla'
%       4 for Compound = 'B', Site = 'tis'
%
%   Example:
%
%   indv = Individual('Virtual');
%   indv.model = test_model();
%   indv.sampling = Sampling([0 1 2]*u.h, Observable('MultiPK','A','pla'));
%
%   initialize(indv)
%   simulate(indv)

% ========================================================================%
% General structure
% ========================================================================%
function model = test_model()

    % Analytical model definition requires initialization and solution 
    % functions. See below for their definition.
    
    model = AnalyticalModel;
    model.initfun = @initfun;
    model.solfun  = @solfun; 
    model.name    = mfilename;
end

% ========================================================================%
% Initialization of model
% ========================================================================%
function setup = initfun(~, ~, ~, ~)
%INITFUN Initialization of test model (empty setup struct

    setup = struct;
end


% ========================================================================%
% Analytical solution of the model
% ========================================================================%
function rec = solfun(~, ~, sampling)
%SOLFUN Solution of test model

    % check that sampling is as expected 
    schedule = sampling.schedule;
    
    C_Apla = Observable('MultiPK','A','pla');
    C_Atis = Observable('MultiPK','A','tis');
    C_Bpla = Observable('MultiPK','B','pla');
    C_Btis = Observable('MultiPK','B','tis');
    assert(all(ismember(schedule.Observable, ...
        [C_Apla C_Atis C_Bpla C_Btis])), ...
        'Only plasma concentration observable allowed.')

    % allocate result
    Value = unan(height(schedule),1);
    Value(schedule.Observable == C_Apla) = 1;
    Value(schedule.Observable == C_Atis) = 2;
    Value(schedule.Observable == C_Bpla) = 3;
    Value(schedule.Observable == C_Btis) = 4;

    % observation times
    tObs = schedule.Time;   

    Value = Value .* exp(-tObs/u.h);

    % return a Record object
    rec = Record([schedule table(Value)]);

end