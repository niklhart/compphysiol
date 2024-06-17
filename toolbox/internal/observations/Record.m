classdef Record < CompactTabularDisplay
    %RECORD A class for storing observation records
    %   Records may be experimental data or model predictions. They behave 
    %   like tables with three colums 'Time', 'Observable' and 'Value'.
    %
    %   Any additional column may be added to a record (e.g., 
    %   'StandardError'), but only the three ones above are supported 
    %   throughout the toolbox.
    %
    %   See also Record/Record (syntax of constructor)

    properties
        record    % table with columns 'Time', 'Observable', 'Value'
    end
    
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

            if nargin == 0
                
                default_names = {'Time','Observable','Value'};
                obj.record = emptytable(default_names{:});
                
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
                    if ~istablecol(tab,'UnitType') && getoptPBPKtoolbox('AutoExpDataUnitType') 
                        tab.UnitType = gettype(tab.Value);
                    end
                    tab.Observable = Observable(tab);

                    % delete any column that turned into the Observable
                    % object, but leave additional columns unchanged.
                    obstypes = unique(tab.Type);
                    attr = cellfun(@obstemplate, obstypes, 'UniformOutput', false);
                    attr = vertcat(attr{:});
                    tab = removevars(tab, intersect(tab.Properties.VariableNames,attr(:,1)));
                    tab.Type = [];

                end
                % mandatory columns first; sorting by Time
                tab = movevars(tab, {'Time','Observable','Value'},'Before',1); 
                tab = sortrows(tab,'Time');
                
                % assign to record property
                obj.record = tab;

            end
        end
        
        function ind = end(obj,k,n)
        %END Last index in a Record object
            assert(n == 2 && k == 1, 'PBPK:Record:invalidUseOfEndKeyword', ...
                "Invalid use of 'end' keyword")
            ind = height(obj.record);
        end

        function n = numel(obj)
        %NUMEL Number of records in a Record object
            
            n = height(obj.record);
        end
        
        function varargout = size(obj)
        %SIZE Size of a Record object
            
            nargoutchk(0,2)
            sz = [numel(obj) 1];
            if nargout < 2
                varargout{1} = sz;                    
            else
                varargout{1} = sz(1);                    
                varargout{2} = sz(2);                    
            end
        end
        
        function n = numArgumentsFromSubscript(~,~,~)
            n = 1;
        end
        
        function tf = isempty(obj)
        %ISEMPTY True if a Record object is empty

            tf = isempty(obj.record);
        end
            
        function disp(obj)
            %DISP Display a Record object
            %   DISP(OBJ) displays the content of a Record object OBJ. 
            %   To see its underlying structure, use builtin('disp',OBJ).

            link = helpPopupStr('Record');
            if isempty(obj.record)
                fprintf('\tEmpty %s object.\n\n',link)
            else
                fprintf('\t%s array:\n\n', link)
                disptable(obj)
            end
        end
        
        function str = summary(obj)
            %SUMMARY Summarize a Record object
            str = sprintf('%s records',...
                          num2str(height(obj.record)));
        end

        function t = gettable(obj)
            t = obj.record;
        end
        
        %% Concatenation
        function out = cat(~,varargin)
            assert(all(cellfun(@(x) isa(x,'Record'), varargin)), ...
                'All input arguments must be Record objects.');
            cl = cellfun(@(x) x.record, varargin, 'UniformOutput', false);
            out = Record(vertcat(cl{:}));
        end
        function out = horzcat(varargin)
            out = cat(2,varargin{:});
        end
        function out = vertcat(varargin)
            out = cat(1,varargin{:});
        end        
        
        %% Subsref
        function v = subsref(v,S)
            %SUBSREF Subscripted referencing for Record objects
            %   R(I,:), with Record object R and indexing vector I, 
            %   returns the rows of the subsetted Record object.
            %
            %   R.Time returns a Time-type DimVar column vector of
            %   observation tupes,
            %   R.Value, or R.Observable returns a vector 
            switch S(1).type
                case '()'
                    v.record = subsref(v.record,S(1));
                    assert(all(ismember({'Time','Observable','Value'}, ...
                        v.record.Properties.VariableNames)), ...
                        'Invalid call to subsref. Use V(I,:) instead.')
                    switch numel(S)
                        case 1
                            % pass
                        case 2
                            % TODO not working properly yet. Probably there
                            %      is some problem with function
                            %      numArgumentsFromSubscript.
                            assert(strcmp(S(2).type,'.'),'Invalid call to subsref.')
                            v = builtin('subsref',v.record,S(2));
                        otherwise 
                            error('Invalid call to subsref.')
                    end
                case '.'
                    if strcmp(S(1).subs,'record')
                        v = builtin('subsref',v,S);                        
                    else
                        v = builtin('subsref',v.record,S);
                    end
                otherwise 
                    error('Invalid call to subsref.')
            end
        end   
        
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
                    obj.record.Value = fun(obj.record.Value);
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
                        tf_i = ismember(obj.record.Observable, ObsIn(i));
                        if any(tf_i,'all')
                            obj.record.Value(tf_i) = fun(obj.record.Value(tf_i));
                            obj.record.Observable(tf_i) = ObsOut(i);
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
                        rec.record = rec.record(f(rec.record.(fld)), :);                    
                    else
                        rec.record = rec.record(ismember(rec.record.(fld),r.(fld)), :);
                    end
                end
            end

        end

        function sdl = schedule(obj)
            %SCHEDULE Extract the schedule of a Record object.
            sdl = Sampling();
            sdl.schedule = obj.record(:,{'Time','Observable'});            
        end
        
        function tab = expand(obj)
            %EXPAND Expand a Record object into a table
            %   TAB = EXPAND(OBJ) returns a table TAB containing one column
            %   per attribute of observables in OBJ, ordered in the same
            %   way as the Record object OBJ.
            
            obs   = obj.record.Observable;
            
            if isempty(obs) % edge case: empty input
                obs = Observable();
                obs = obs([]);
            end
            Time  = obj.record.Time;
            Value = obj.record.Value;
            rest  = obj.record(:,4:end);    % optional colums
            
            tab = [table(Time) expand(obs) table(Value) rest];
            
        end
        
    end
   
    
end
    