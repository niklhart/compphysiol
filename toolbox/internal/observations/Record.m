classdef Record < TabularClass
    %RECORD A class for storing observation records
    %   Records may be experimental data or model predictions. They behave 
    %   like tables with three colums 'Time', 'Observable' and 'Value'.
    %
    %   Any additional column may be added to a record (e.g., 
    %   'StandardError'), but only the three ones above are supported 
    %   throughout the toolbox.
    %
    %   See also Record/Record (syntax of constructor)
    
    methods
        
        function obj = Record(tab)
            %RECORD Construct a Record object
            %   OBJ = RECORD(TAB), with a table TAB with three columns
            %   'Time' (a Time-type DimVar), 'Observable' (an Observable 
            %   array), and 'Value' (any numeric array) produces a Record
            %   object OBJ containing this information.
            %
            %   Any additional column in TAB will be kept, but not
            %   supported throughout the toolbox.
            %
            %   Alternatively, TAB may represent an Observable in expanded
            %   form, i.e. via a column 'Type' specifying the observable 
            %   type and one column per attribute (named accordingly), 
            %   instead of column 'Observable'.
            %
            %   Examples:
            %   obs = Observable('SimplePK','pla','total','Mass/Volume');
            %   tab = table([0;1;2]*u.h, ...
            %               repelem(obs,3), ...
            %               [1;3;5]*u.mg/u.h, ...
            %               'VariableNames',{'Time','Observable','Value'});
            %   rec = Record(tab)

            if nargin == 0
                
                default_names = {'Time','Observable','Value'};
                obj.table = emptytable(default_names{:});
                
            else
                
                assert(istable(tab) && all(istablecol(tab, {'Time','Value'})))

                % process '[Time]' and '[Value]' columns and turn into numeric type, possibly dimensioned
                tab = mergeunit(tab,'Time');
                tab = mergeunit(tab,'Value');

                typecheck(tab.Time,'Time')

                if istablecol(tab,'Observable')   % collapsed format

                    assert(isa(tab.Observable,'Observable'))

                elseif istablecol(tab,'Type')     % expanded format

                    % append Unit to Value, if available
                    if istablecol(tab,'Unit')
                        tab.Value = tab.Value .* str2u(tab.Unit);
                        tab.Unit = [];
                    end

                    % guess UnitType for ExpData
                    if ~istablecol(tab,'UnitType') && getoptcompphysiol('AutoExpDataUnitType') 
                        tab.UnitType = gettype(tab.Value);
                    end
                    tab.Observable = Observable(tab);

                    % delete any column that turned into the Observable
                    % object, but leave additional columns unchanged.
                    obstypes = unique(tab.Type);
                    attr = cellfun(@(x) evalfhopt('ObservableTemplate',x), ...
                        obstypes, 'UniformOutput', false);
                    attr = vertcat(attr{:});
                    tab = removevars(tab, intersect(tab.Properties.VariableNames,attr(:,1)));
                    tab.Type = [];

                end
                % mandatory columns first; sorting by Time
                tab = movevars(tab, {'Time','Observable','Value'},'Before',1); 
                tab = sortrows(tab,'Time');
                
                % assign to table property
                obj.table = tab;

            end
        end
               
        function tf = isempty(obj)
        %ISEMPTY True if a Record object is empty

            tf = isempty(obj.table);
        end
        
        function str = summary(obj)
            %SUMMARY Summarize a Record object
            str = sprintf('%s records',...
                          num2str(height(obj.table)));
        end
          
        %% Subsref
        
        function obj = transform(obj, varargin)
            %TRANSFORM Transform Record objects
            %   OUT = TRANSFORM(OBJ, FUN), with a Record object OBJ and a
            %   function handle FUN that takes exactly one input argument,
            %   returns a Record object OUT with all data transformed by
            %   function FUN. 
            %   
            %   OUT = TRANSFORM(OBJ, OBSIN, OBSOUT), renames Observable 
            %   objects OBSIN to OBSOUT, which is useful to switch between
            %   SimplePK and PBPK types of experimental data.
            %   
            %   OUT = TRANSFORM(OBJ, FUN, OBSIN, OBSOUT), with Observable 
            %   objects/arrays OBSIN and OBSOUT, applies FUN only to 
            %   observables in OBSIN and renames the resulting observable
            %   OBSOUT. This is useful e.g. for a change in units in 
            %   experimental data.
            
            switch nargin 
                case 2
                    fun = varargin{1};
                    assert(isa(fun,'function_handle'), 'Input #2 must be a function handle.')
                    obj.table.Value = fun(obj.table.Value);
                case 3
                    obj = transform(obj, @(x) x, varargin{:});  % -> case 4
                case 4                   
                    assert(all(cellfun(@(x) isa(x,'Observable'), varargin(2:3))), ...
                        'The last two inputs must be Observable objects.')
                    fun   = varargin{1};
                    ObsIn = varargin{2};
                    ObsOut = varargin{3};
                    assert(numel(ObsIn) == numel(ObsOut), ...
                        'Observable objects must have the same size.')

                    for i=1:numel(ObsIn)
                        tf_i = ismember(obj.table.Observable, ObsIn(i));
                        if any(tf_i,'all')
                            obj.table.Value(tf_i) = fun(obj.table.Value(tf_i));
                            obj.table.Observable(tf_i) = ObsOut(i);
                        end
                    end
                    
                otherwise
                    error('Unexpected number of input arguments.')
            end
        end

        function rec = filter(rec, varargin)
            %FILTER Filter a Record object by Time, Observable and/or Value
            %   OUT = FILTER(REC, P1, V1, ...) with Record object REC and 
            %   property-value pairs (PI, VI), I=1,2,... filters REC 
            %   according to the property-value pairs and returns the 
            %   filtered Record object OUT.
            %
            %   Properties can be 'Time', 'Observable', or 'Value', and
            %   values can be one of the following to types:
            %   * a function handle operating on the column and returning a
            %     logical value such as @(t) t < 2*u.h;
            %   * a vector of valid objects, in which case only matches
            %     will be kept.
            %   Also see the examples below.
            %   
            %   Examples:
            %   
            %   % Create a Record object from scratch
            %   obs = Observable('SimplePK','pla',{'total','free'},'Mass/Volume');
            %   tab = table([0;2;5;6]*u.h,[obs;obs],[6;2;3;1]*u.nM,...
            %       'VariableNames',{'Time','Observable','Value'});
            %   rec = Record(tab)
            %   
            %   % filter by observable / by time
            %   
            %   filter(rec, 'Time', @(t) t <= 2*u.h)
            %   filter(rec, 'Observable', obs(1))
            %
            %   See also Observable.
        
            p = inputParser;
            p.addParameter('Observable',[])
            p.addParameter('Time',[])
            p.addParameter('Value',[])    
            p.parse(varargin{:})

            r = p.Results;

            for flds = fieldnames(r)'
                fld = flds{1};
                if ~isempty(r.(fld))
                    if isa(r.(fld),'function_handle')
                        f = r.(fld);
                        rec.table = rec.table(f(rec.table.(fld)), :);                    
                    else
                        rec.table = rec.table(ismember(rec.table.(fld),r.(fld)), :);
                    end
                end
            end

        end

        function sdl = schedule(obj)
            %SCHEDULE Extract the schedule of a Record object.
            tab = obj.table(:,{'Time','Observable'}); 
            sdl = SamplingSchedule(tab);
        end
        
        function tab = expand(obj)
            %EXPAND Expand a Record object into a table
            %   TAB = EXPAND(OBJ) returns a table TAB containing one column
            %   per attribute of observables in OBJ, ordered in the same
            %   way as the Record object OBJ.
            
            obs   = obj.table.Observable;
            
            if isempty(obs) % edge case: empty input
                obs = Observable();
                obs = obs([]);
            end
            Time  = obj.table.Time;
            Value = obj.table.Value;
            rest  = obj.table(:,4:end);    % optional colums
            
            tab = [table(Time) expand(obs) table(Value) rest];
            
        end
        
    end
    methods (Static, Access = public)
        function obj = empty()
            obj = Record();
        end
    end
    
end
    