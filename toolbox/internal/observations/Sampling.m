function obj = Sampling(time, obs)
%SAMPLING Create a SamplingRange or SamplingSchedule object

    arguments
        time (:,1) DimVar {mustBeUnitType(time,'Time')}
        obs Observable = Observable.empty
    end

    if numel(time) == 2
        obj = SamplingRange(time, obs);
    else
        obj = SamplingSchedule(time, obs);
    end

end
