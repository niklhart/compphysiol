classdef SamplingRange < matlab.mixin.Scalar
    %SAMPLINGRANGE Class for storing sampling ranges
    %   A sampling range is a timespan (length 2 time vector) together
    %   with an Observable array. Sampling times within the timespan are 
    %   determined by the ODE solver.

    properties
        timespan
        obs
    end

    methods

        function obj = SamplingRange(time, obs)
            %SAMPLINGRANGE Construct an instance of this class

            arguments
                time (1,2) DimVar {mustBeTimeVariable} = nan(1,2)*u.h
                obs Observable = Observable.empty
            end

            obj.timespan = time;
            obj.obs = obs;
        end

        function str = summary(obj)

            % Sampling timespan / window
            t1 = num2str(obj.timespan(1));
            t2 = num2str(obj.timespan(2));  
            str = sprintf('timespan %s - %s',t1,t2);
            if ~isempty(obj.obs)
                str = [str sprintf(' with %d observables',numel(obj.obs))];
            end

        end

        function disp(obj)
            %DISP Display a Sampling object
            %   DISP(OBJ) displays the content of a Sampling object OBJ. To
            %   see the underlying structure of OBJ, use builtin('disp',OBJ).

            link = helpPopupStr('SamplingRange');
            if any(isnan(obj.timespan)) || isempty(obj.obs)
                fprintf('\tEmpty %s object.\n\n',link)
            else
                fprintf('\t%s: %s - %s\n\n',link,obj.timespan(1),obj.timespan(2))
                fprintf('\twith\n\n')
                disp(obj.obs)
            end                
        end

    end
end