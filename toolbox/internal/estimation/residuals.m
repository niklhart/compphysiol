%RESIDUALS Residuals of a model prediction
%
%   RTAB = RESIDUALS(MODEL, DATA) takes an initialized model struct MODEL
%   and a scalar experimental data Individual object DATA and computes the
%   residuals (observations minus predictions), returned as a table RTAB.
%   DATA must contain the design (dosing, sampling, physiology) required by
%   MODEL. 
%
%   See also nll, exp2sim, Individual/observe

function rtab = residuals(model, data)
    
    assert(isa(data,'Individual') && isscalar(data) && isexpid(data), ...
        'Input #2 must be a scalar experimental dataset.')
    
    simid = exp2sim(data);
    simid.model = model;
    if ~isinitialized(simid)
        initialize(simid);
    end
    simulate(simid);
    
    ypredtab = simid.observation;
    yobstab  = data.observation;
    
    Time        = ypredtab.Time;
    Observable  = ypredtab.Observable;
    Prediction  = ypredtab.Value;
    Observation = yobstab.Value;
    Residuals   = Observation - Prediction;

    rtab = table(Time,Observable,Prediction,Observation,Residuals);
    
end
