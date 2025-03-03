classdef DrugData < DB & LinearArray & CompactColumnDisplay
    %DrugData A handle class for storing the drug information
    %   For each drug, the following information can be stored:
    %   - MW           molecular weight
    %   - pKa          acid dissociation constant
    %   - logPow       log10-octanol-water partition coefficient
    %   - CLblood_hep  hepatic clearance (per species)
    %   - lambda_po    oral absorption rate (per species)
    %   - Egut         extractable fraction
    %   To add further parameters, the drugtemplate must be expanded.
    %
    %   See also DrugData/DrugData (constructor), drugtemplate

    properties
        name
        class
        subclass
    end
    
    properties (Constant = true)
        param      = DrugData.setParnames()
        units      = DrugData.setUnits()
        perspecies = DrugData.setPerspecies();
    end
    
    methods
        function obj = DrugData(varargin)
            %DrugData Construct an instance of this class
            %   OBJ = DRUGDATA() initializes an empty DrugData object OBJ.
            %
            %   OBJ = DRUGDATA(CPD) loads compound(s) CPD from the drug 
            %         database.
                        
            if nargin >= 1
                obj = loaddrugdata(varargin{:});
            else
                perspecies = DrugData.perspecies;

                dbtmp  = cell(numel(perspecies),1);
                dbtmp(perspecies) = {emptydbtable('Species')};
                dbtmp(~perspecies) = {emptydbtable()};
            
                obj.db = cell2struct(dbtmp, DrugData.param);
            end

        end
        
        function str = obj2str(obj, context)
            switch context
                case {'array','table'}

                    cl = {obj.name, obj.class, obj.subclass};
                    cl = cl(~cellfun(@isempty,cl));

                    isEmpty = structfun(@isempty,obj.db);
                    isAllEmpty = all(isEmpty);
                    if isAllEmpty
                        cl = [cl, {'(empty)'}];
                    else
                        cl = [cl, {['(' num2str(sum(~isEmpty)) ' parameters)']}];
                    end
                    str = strjoin(cl,'\t');
                otherwise
                    error('compphysiol:DrugData:obj2str:unknownContext', ...
                        'Function not defined for context "%s"',context)
            end

        end

        function disp(obj,N)
            if isscalar(obj)
                link = helpPopupStr('DrugData');
                if all(structfun(@isempty,obj.db))
                    fprintf('\tEmpty %s object.\n\n',link)
                else
                    fprintf('\t%s object (%s,%s,%s) with parameters:\n\n',...
                        link,obj.name,obj.class,obj.subclass)
                    dispdbcontent(obj)
                end 
            else
                if nargin == 1
                    disp@CompactColumnDisplay(obj)
                else
                    disp@CompactColumnDisplay(obj,N)
                end
            end
        end

        function addrecord(obj, nm, varargin)
            
            assert(isscalar(obj), 'Not permitted to add data for several drugs at the same time.')
            assert(isfield(obj.db, nm), ...
                'compphysiol:DrugData:addrecord:parameterNotFound', ...
                ['Parameter type ''' nm ''' not in drug database.'])

            colnames = obj.db.(nm).Properties.VariableNames;
            ncol = length(colnames);

            iVal = find(strcmp(colnames,'Value'));
            
            % parameters lacking any assumption / source will be flagged
            % with assumption "derived"
            if length(varargin) == ncol-2
                varargin = {varargin{1:iVal}, 'derived', ''};
            else
                narginchk(ncol+2, ncol+2) %1(obj) + 1(nm) + length(varargin)
            end
            
            assert(~isempty(varargin{end}) || ~isempty(varargin{end-1}), ...
                'Must provide source and/or assumption')

            % convert empty double assumption to empty string
            if isempty(varargin{end})
                varargin{end} = '';
            end

            % check units of value variable
            typecheck(varargin{iVal}, DrugData.getUnits(nm))     
            if strcmp(DrugData.getUnits(nm), 'char')
                varargin{iVal} = varargin(iVal); % char --> cellstr
            else
                varargin{iVal} = tounit(varargin{iVal});
            end

            % scalar values required except for pKa
            provided = numel(varargin{iVal});
            assert(ismember(nm,{'pKa_ani','pKa_cat'}) || provided == 1, ...
                'Exactly 1 value required, but %i elements provided.',...
                provided)

            
            toadd = cell2table(varargin, 'VariableNames', colnames);
                    
            obj.db.(nm) = [obj.db.(nm); toadd];
                
        end
        
        function updaterecord(obj, nm, varargin)
        %UPDATERECORD Update an existing record
        %   UPDATERECORD(OBJ, NM, NEWVAL), with DrugData object
        %   (array) OBJ, a species-independent parameter NM of the drug
        %   database, and a valid value NEWVAL replaces the existing record
        %   in the database, which would be obtained by GETRECORD(OBJ, NM),
        %   by NEWVAL.
        %   
        %   UPDATERECORD(OBJ, NM, SPEC, NEWVAL), with DrugData object
        %   (array) OBJ, a species-dependent parameter NM of the drug
        %   database, a char SPEC (a species) and a valid value NEWVAL 
        %   replaces the existing record in the database, which would be 
        %   obtained by GETRECORD(OBJ, NM, SPEC), by NEWVAL.        
        
            assert(isa(obj,'DrugData'), 'Input #1 must be a DrugData object.')
            assert(isfield(obj.db, nm), ...
                'compphysiol:DrugData:updaterecord:parameterNotFound', ...
                ['Parameter type ''' nm ''' not in drug database.'])

            if isscalar(obj)
                
                if DrugData.isperspecies(nm)  % expect varargin of length 2
                    narginchk(4,4)                    
                    [~,irec] = ismember(varargin{1}, obj.db.(nm).Species);
                    if ~irec
                       error(['No record "' varargin{1} '" of parameter type "' nm '" in database "' obj.name '".'])
                    end                    
                    val = varargin{2};
                else                      % expect varargin of length 1
                    narginchk(3,3)
                    irec = 1;
                    val = varargin{1};
                end
                typecheck(val, DrugData.getUnits(nm))
                val = tounit(val);
                obj.db.(nm).Value(irec) = val;
                
            else
                arrayfun(@(o) updaterecord(o, nm, varargin{:}), obj)
            end
        end
                
        function tf = hasrecord(obj, nm, varargin)
        %HASRECORD True if matches a record in the drug database

            assert(isfield(obj(1).db, nm), ...
                    'compphysiol:DrugData:hasrecord:parameterNotFound', ...
                    ['Parameter type ''' nm ''' not in database.'])

            if isscalar(obj)
                tf = logical(height(subset(obj.db.(nm), varargin{:})));
            else
                tf = arrayfun(@(o) hasrecord(o, nm, varargin{:}), obj);
            end
        end
        
        function rec = getrecord(obj, nm, varargin)
        %GETRECORD Get a record from a DrugData object
        %   There are two ways to call GETRECORD, depending on whether the
        %   queried parameter is scalar (e.g.: MW, logPow) or a per-species 
        %   parameter (e.g.: fuP, Egut).
        %   
        %   GETRECORD(OBJ,NM) accesses the DrugData object (array) OBJ to
        %   retrieve a scalar parameter NM. 
        %
        %   GETRECORD(OBJ,NM,TIS) queries OBJ for a per-species parameter 
        %   NM and returns the output corresponding to tissue TIS. 
        %
        %   See also drugtemplate, DrugData/getvalue
        
            assert(isfield(obj(1).db, nm), ...
                'compphysiol:DrugData:getrecord:parameterNotFound', ...
                ['Parameter type ''' nm ''' not in database.'])
                
            if isscalar(obj)
                tab = subset(obj.db.(nm), varargin{:});
                assert(height(tab) > 0, ...
                    'compphysiol:DrugData:getrecord:noEntriesFound', ...
                    'No matching database entry found.')
                assert(height(tab) < 2, ...
                    'compphysiol:DrugData:getrecord:severalEntriesFound', ...
                    'Several matching database entry found.')

                rec = tab{:,'Value'};
            else
                rec = arrayfun(@(o) getrecord(o,nm,varargin{:}), obj);
            end                    
        end
            

        function variants(obj,spec)
        %VARIANTS Display duplicate entries in a DrugData object or array
        %   VARIANTS(OBJ) shows any duplicate entries in OBJ, even those
        %       that refer to different species
        %   VARIANTS(OBJ,SPEC) shows only duplicates in species-independent
        %       parameters or those relating to species SPEC.
        %   
        %   See also DrugData, DrugData/filtervariants
            
            for i = 1:numel(obj)

                if all(structfun(@(x) height(x)<2,obj(i).db))
                    fprintf('%s: no variants.\n', obj(i).name)
                else
                    fprintf('%s: variants found:\n', obj(i).name)

                    parnm = fieldnames(obj(i).db);
                    for j = 1:numel(parnm)
                        nm = parnm{j};
                        dbnm = obj(i).db.(nm);

                        % first handle 2-input call (per-species subsetting)
                        if nargin > 1 && istablecol(dbnm,'Species') && ismember(spec, dbnm.Species)
                            dbnm = dbnm(strcmp(spec, dbnm.Species),:);
                        end

                        % now we can simply look for any duplicate entry
                        if height(dbnm) > 1                            
                            fprintf(['parameter "' nm '":\n'])                            
                            disp(dbnm)
                        end
                    end
                end
            end
        end

        function filtervariants(obj, varargin)
        %FILTERVARIANTS Filter a DrugData object 
        %   FILTERVARIANTS(OBJ, 'species', SPEC) filters OBJ by species, 
        %       keeping only values for species SPEC.
        %       Species-independent (in vitro) parameters are unaffected.
        %   FILTERVARIANTS(OBJ, 'reference', REF) filters OBJ by reference, 
        %       keeping only the values matching reference REF.
        %   FILTERVARIANTS(OBJ, 'assumption', ASMPT) filters OBJ by
        %       assumption, keeping only the values matching assumption
        %       ASMPT.
        %   FILTERVARIANTS(OBJ, 'parameters', PAR, ...) filters only drug
        %       parameters PAR, according to the 'species', 'reference' or
        %       'assumption' options described above.
        %   FILTERVARIANTS(..., 'silent', true) suppresses all messages
        %       that might be issued, which is useful for unit testing.
        %   
        %   See also DrugData, DrugData/variants

            if nargin > 1
                if ~isscalar(obj)
                    arrayfun(@(x) filtervariants(x,varargin{:}), obj);
                    return
                end
                props = struct(varargin{:});

                fnm = DrugData.param;

                % control message display
                silent = isfield(props,'silent') && isequal(props.silent,true);
                fprintfifverbose = @(varargin) callif(~silent, @fprintf, varargin{:});

                % argument 'parameters'
                if isfield(props,'parameters')
                    par = cellstr(props.parameters);
                else
                    par = fnm;
                end

                assert(sum(isfield(props,{'species','reference','assumption'})) <= 1, ...
                    'compphysiol:DrugData:filtervariants:wrongFilterParameters', ...
                    'Simulataneous filtering by species / reference / assumption not implemented.')

                % argument 'species'
                if isfield(props, 'species')

                    persp = fnm(DrugData.perspecies);
                    par = intersect(par, persp);        % only filter per-species parameters
                    
                    for i = 1:numel(par)
                        p = par{i};
                        keeprow = ismember(obj.db.(p).Species, props.species);
                        obj.db.(p) = obj.db.(p)(keeprow,:);
                    end
                    
                end

                % argument 'reference'
                if isfield(props, 'reference')

                    for i = 1:numel(par)
                        p = par{i};
                        if isa(obj.db.(p).Source,'Ref')
                            keeprow = obj.db.(p).Source == props.reference;
                        else % Legacy behaviour (TODO: remove once updated)
                            if iscellstr(obj.db.(p).Source)
                                keeprow = ismember(obj.db.(p).Source, props.reference);
                            else  % cell array of empty arrays
                                keeprow = false(size(obj.db.(p).Source));
                            end
                        end
                        if ~any(keeprow)
                            msg = ['Reference "%s" not found for drug '...
                                   'parameter "%s"; parameter not filtered.\n'];
                            fprintfifverbose(msg, props.reference, p)
                            keeprow = ~keeprow;
                        end
                        obj.db.(p) = obj.db.(p)(keeprow,:);
                    end
                    
                end

                % argument 'assumption'
                if isfield(props, 'assumption')

                    for i = 1:numel(par)
                        p = par{i};
                        if iscellstr(obj.db.(p).Assumption)
                            keeprow = ismember(obj.db.(p).Assumption, props.assumption);
                        else  % cell array of empty arrays
                            keeprow = false(size(obj.db.(p).Assumption));
                        end
                        if ~any(keeprow)
                            msg = ['Assumption "%s" not found for drug '...
                                   'parameter "%s"; parameter not filtered.\n'];
                            fprintfifverbose(msg, props.assumption, p)
                            keeprow = ~keeprow;
                        end
                        obj.db.(p) = obj.db.(p)(keeprow,:);
                    end
                    
                end
                
            end
      
        end

%         % Here, we can validate settable properties 
%         % (e.g. only classes 'mAB' / 'sMD'?)
%         function set.name(obj,nm)
%             assert(ischar(nm), 'Input must be char.')
%             obj.name = nm;
%         end
%         
%         function set.class(obj,cls)
%             obj.class = cls;
%         end            
%         
%         function set.subclass(obj,sbcls)            
%             obj.subclass = validatestring(sbcls, ...
%                  {'neutral','acid','base',...
%                   'diprotic acid','diprotic base','zwitter ion', ...
%                    'IgG1'});
%         end        
        
    end

    methods (Static = true)
        
        function TF = isperspecies(par)
            allpar = DrugData.param;
            par = validatestring(par, allpar);
            TF = DrugData.perspecies(ismember(allpar,par));
        end

        function units = getUnits(par)
            allpar = DrugData.param;
            par = validatestring(par, allpar);
            units = DrugData.units{ismember(allpar,par)};
        end

    end

    methods (Static = true, Access = protected)

        function parnames = setParnames()
            tmp = evalfhopt('DrugTemplate');
            parnames = tmp(:,1);
        end

        function units = setUnits()
            tmp = evalfhopt('DrugTemplate');
            units = tmp(:,2);
        end

        function perspecies = setPerspecies()
            tmp = evalfhopt('DrugTemplate');
            perspecies = cell2mat(tmp(:,3));
        end

    end
end

