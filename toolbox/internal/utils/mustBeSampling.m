function mustBeSampling(obj)
%MUSTBESAMPLING Validation function for sampling classes

    if ~(isa(obj,'SamplingSchedule') || isa(obj,'SamplingRange'))
        id = 'compphysiol:mustBeSampling:notSampling';
        msg= 'Input argument must be a SamplingSchedule or SamplingRange object.';
        error(id,msg);
    end
end