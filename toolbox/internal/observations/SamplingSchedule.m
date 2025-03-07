classdef SamplingSchedule < TabularClass
    %SAMPLINGSCHEDULE Class for storing sampling schedules

    methods
        function obj = SamplingSchedule(time, obs)
            %SAMPLINGSCHEDULE Construct an instance of this class

            if nargin == 1
                tab = time;
                assert(istable(tab) && all(istablecol(tab,{'Time','Observable'})) && ...
                    istype(tab.Time,'Time') && isa(tab.Observable,'Observable'), ...
                    'In a one-input call, the argument must be a table with columns "Time" and "Observable".')
                obj.table = time;

            elseif nargin == 0 || numel(time) == 0 || numel(obs) == 0  % empty schedule
                obj.table = emptytable('Time','Observable');

            else
                nt = numel(time);
                ntypes = numel(obs);
                
                time = repelem(time(:),ntypes);
                obs  = repmat(obs(:), [nt 1]);

                % all possible combinations of times and types
                obj.table = table(time, obs, ...
                    'variableNames',{'Time','Observable'});
            end

        end

        function str = summary(obj)
            str = sprintf('schedule with %d observations', numel(obj));
        end

    end
end