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
    
    rtab = yobstab.record;
    rtab.Properties.VariableNames{'Value'} = 'Observation';
    rtab.Prediction = ypredtab.record.Value;
    
    rtab.Residuals = rtab.Observation - rtab.Prediction;
    
end
