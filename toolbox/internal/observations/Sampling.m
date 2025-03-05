classdef Sampling < CompactTabularDisplay & matlab.mixin.Scalar
    %SAMPLING Class for storing sampling-related information
    %   
    %   See also Sampling/Sampling (syntax of constructor)
    
    properties
        schedule
        timespan
        obs
    end
    
    methods
        function obj = Sampling(time, obs)
            %SAMPLING Construct a Sampling object
            %   OBJ = SAMPLING(TIME), with a Time-type DimVar TIME, creates
            %   a sampling timespan OBJ. If TIME has two elements, it is
            %   considered as a time window, and if it has more, it is
            %   considered as a exact timepoints, consistent with the 
            %   behaviour of matlab ODE solvers.
            %    
            %   OBJ = SAMPLING(TIME, OBS), with an additional Observable
            %   object or array OBS, creates 
            %   - a sampling window if TIME has two elements,
            %   - a sampling schedule, consisting of all combinations of 
            %     times TIME and observables OBS, if TIME has more than two
            %     elements.
            %
            %   Examples:
            %
            %   Sampling([0 24]*u.h)       % time window
            %   Sampling((0:24)*u.h)       % exact times
            %   
            %   obs = Observable('SimplePK','pla','total','Mass/Volume');
            %   
            %   Sampling([0 24]*u.h, obs)  % sampling window
            %   Sampling((0:24)*u.h, obs)  % sampling schedule
            %
            %   See also Observable, Record.
            
            if nargin == 0 || numel(time) == 0  % empty schedule
                obj.schedule = emptytable('Time','Observable');
            elseif nargin == 1                  % timespan/timepoints
                typecheck(time,'Time')
                time = unique(time(:));
                assert(numel(time) >= 2, 'At least two different sampling timepoints must be given.')
                obj.timespan = time;
            else
                narginchk(2,2)
                assert(isnumvec(time))
                assert(isa(obs,'Observable'), ...
                    'Input #2 must be an object of class "Observable".')
                
                nt = numel(time);
                if nt == 2
                    obj.timespan = time(:);
                    obj.obs      = obs;
                else
                    ntypes = numel(obs);
    
                    Time = reshape(repmat(time(:)',[ntypes 1]), [], 1);
                    Observable = repmat(obs(:), [nt 1]);
                    
                    obj.schedule = table(Time, Observable);    % all possible combinations of times and types                
                end                
            end
        end
        
        function obj = set.schedule(obj,tab)
            assert(isscalar(obj), 'The schedule can only be set for a scalar Sampling object.') 
            assert(istable(tab), 'Input must be a table.')
            assert(all(strcmp(tab.Properties.VariableNames, {'Time','Observable'})), ...
                'Incorrect column names.')            
            if height(tab) > 0
                typecheck(tab.Time, 'Time')   
            end   
            obj.schedule = tab;
        end
        
        function str = summary(obj)
            
            if istable(obj.schedule)
                % Sampling schedule
                str = sprintf('schedule with %d observations', height(obj.schedule));
            else  
                % Sampling timespan / window
                t1 = num2str(obj.timespan(1));
                t2 = num2str(obj.timespan(end));  
                nt = numel(obj.timespan);
                if nt == 2
                    str = sprintf('timespan %s - %s',t1,t2);
                else
                    str = sprintf('timespan %s - %s (%d timepoints)',t1,t2,nt);
                end
                if ~isempty(obj.obs)
                    str = [str sprintf(' with %d observables',numel(obj.obs))];
                end
            end
        end

        function t = gettable(obj)
            t = obj.schedule;
            if isempty(t)
                t = emptytable('Time','Observable');
            end
        end
        
        function disp(obj)
            %DISP Display a Sampling object
            %   DISP(OBJ) displays the content of a Sampling object OBJ. To
            %   see the underlying structure of OBJ, use builtin('disp',OBJ).

            if isscalar(obj)
                link = helpPopupStr('Sampling');
                if isempty(obj.schedule) && isempty(obj.timespan)
                    fprintf('\tEmpty %s object.\n\n',link)
                else
                    if ~isempty(obj.schedule)
                        fprintf('\t%s schedule:\n\n',link)
                        disptable(obj)
                    end
                    if ~isempty(obj.timespan)
                        if numel(obj.timespan) > 2
                            fprintf('\t%s time points:\n\n',link)
                            disp(obj.timespan')
                        elseif isempty(obj.obs)
                            fprintf('\t%s time span:\n\n',link)
                            disp(obj.timespan')
                        else
                            fprintf('\t%s window:\n\n',link)
                            disp(obj.timespan')
                            fprintf('\twith\n\n')
                            disp(obj.obs)
                        end
                    end
                end                
            else
                builtin('disp',obj)
            end
        end
        
        function out = plus(obj1,obj2)
            %PLUS Combine two sampling schedules
            assert(isa(obj1,'Sampling') && isa(obj2,'Sampling'), ...
                'Both arguments must belong to class "Sampling"');
            out = Sampling();
            
            schedule12 = [obj1.schedule; obj2.schedule];
            if isempty(schedule12)
                msg = ['plus operator only defined for ' ...
                       'sampling schedules, not sampling times.'];
                warning(msg)
            else                
                out.schedule = sortrows(schedule12, 1);
            end
            
        end
    end

end

