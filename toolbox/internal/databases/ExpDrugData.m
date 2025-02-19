classdef ExpDrugData < DB 
    %ExpDrugData A handle class for storing experimental drug information
    %
    %NOTE: THIS FUNCTION IS CURRENTLY NOT FUNCTIONAL AND UNUSED
    %
    %   For each drug, the following information can be stored:
    %   - MW           molecular weight
    %   - pKa          acid dissociation constant
    %   - logPow       log10-octanol-water partition coefficient
    %   - CLblood_hep  hepatic clearance (per species)
    %   - lambda_po    oral absorption rate (per species)
    %   - Egut         extractable fraction
    %   To add further parameters, the expdrugtemplate must be expanded.
    %
    %   See also ExpDrugData/ExpDrugData (constructor), expdrugtemplate

    properties
        name
        class
        subclass
    end
    
    properties (SetAccess = protected)
        units
        perspecies
    end
    
    methods
        function obj = ExpDrugData(cpd)
            %ExpDrugData Construct an instance of this class
            %   OBJ = EXPDRUGDATA() initializes an empty ExpDrugData object OBJ.
            %
            %   OBJ = EXPDRUGDATA(CPD) loads compound(s) CPD from the exp drug 
            %         database.
                        
            params = expdrugtemplate();
            
            perspecies = [params{:,3}];

            
            obj.perspecies = cell2struct(params(:,3),params(:,1));
            obj.units = cell2struct(params(:,2), params(:,1));

            if nargin < 1
                dbtmp  = cell(numel(perspecies),1);
                dbtmp(:) = {emptytable('Value','Source','Conditions','Assumption')};
            
                obj.db = cell2struct(dbtmp, params(:,1));
            else
                obj = loadexpdrugdata(cpd);
            end

        end
        
        function disp(obj)
            if isscalar(obj)
                link = helpPopupStr('ExpDrugData');
                if all(structfun(@isempty,obj.db))
                    fprintf('\tEmpty %s object.\n\n',link)
                else
                    fprintf('\t%s object (%s,%s,%s) with parameters:\n\n',...
                        link,obj.name,obj.class,obj.subclass)
                    dispdbcontent(obj)
                end 
            else
                builtin('disp',obj)
            end
        end

        function addrecord(obj, nm, value, ref, cond, assum)
            
            assert(isscalar(obj), 'Not permitted to add data for several drugs at the same time.')
            assert(isfield(obj.db, nm), ['Parameter type ''' nm ''' not in drug database.'])
            
            % handle default values for ref / cond / assum
            switch nargin
                case 3
                    ref  = Ref([]);
                    cond = ExpConditions();
                    assum = '';
                case 4
                    cond = ExpConditions();
                    assum = '';
                case 5
                    assum = '';
            end

            % class conversions
            ref = Ref(ref);
            cond = ExpConditions(cond);

            % parameters lacking any assumption / source will be flagged
            % with assumption "derived"
            if ismissing(ref) && isempty(assum)
                assum = 'derived';
            end

            % check units of 'value' argument
            typecheck(value, obj.units.(nm))           
            value = tounit(value);

            % TODO: find a more general rule than this one.
            provided = numel(value);
            if strcmp(nm,'pKa')
                switch obj.subclass
                    case {'neutral'}
                        expected = 0;
                    case {'acid','base'}
                        expected = 1;
                    case {'zwitter ion','diprotic base','diprotic acid'}
                        expected = 2;
                    otherwise
                        error('Cannot determine expected pKa length for drug subclass "%s".',obj.subclass)
                end
            else
                expected = 1;
            end
            assert(provided == expected, ...
                'Exactly %i value required, but %i elements provided.',...
                expected, provided)

            % everything checked, now write the new data to OBJ
            colnames = obj.db.(nm).Properties.VariableNames;
            toadd = cell2table({value, ref, cond, assum}, 'VariableNames', colnames);
                    
            obj.db.(nm) = [obj.db.(nm); toadd];
                
        end
        
%         function updaterecord(obj, nm, varargin)
%         %UPDATERECORD Update an existing record
%         %   UPDATERECORD(OBJ, NM, NEWVAL), with DrugData object
%         %   (array) OBJ, a species-independent parameter NM of the drug
%         %   database, and a valid value NEWVAL replaces the existing record
%         %   in the database, which would be obtained by GETRECORD(OBJ, NM),
%         %   by NEWVAL.
%         %   
%         %   UPDATERECORD(OBJ, NM, SPEC, NEWVAL), with DrugData object
%         %   (array) OBJ, a species-dependent parameter NM of the drug
%         %   database, a char SPEC (a species) and a valid value NEWVAL 
%         %   replaces the existing record in the database, which would be 
%         %   obtained by GETRECORD(OBJ, NM, SPEC), by NEWVAL.        
%         
%             assert(isa(obj,'DrugData'), 'Input #1 must be a DrugData object.')
%             assert(isfield(obj.db, nm), ['Parameter type ''' nm ''' not in drug database.'])
% 
%             if isscalar(obj)
%                 
%                 if obj(1).perspecies.(nm)  % expect varargin of length 2
%                     narginchk(4,4)                    
%                     [~,irec] = ismember(varargin{1}, obj.db.(nm).Species);
%                     if ~irec
%                        error(['No record "' varargin{1} '" of parameter type "' nm '" in database "' obj.name '".'])
%                     end                    
%                     val = varargin{2};
%                 else                      % expect varargin of length 1
%                     narginchk(3,3)
%                     irec = 1;
%                     val = varargin{1};
%                 end
%                 typecheck(val, obj.units.(nm))
%                 val = tounit(val);
%                 obj.db.(nm).Value(irec) = val;
%                 
%             else
%                 arrayfun(@(o) updaterecord(o, nm, varargin{:}), obj)
%             end
%         end
                
        function tf = hasrecord(obj, nm, varargin)
        %HASRECORD True if ExpDrugData object OBJ contains matching record(s)

            assert(isfield(obj(1).db, nm), ['Parameter type ''' nm ''' not in database.'])

            if isscalar(obj)
                tf = ~isempty(getrecords(obj, nm, varargin{:}));
            else
                tf = arrayfun(@(o) hasrecord(o, nm, varargin{:}), obj);
            end
        end
        

        function [val, cond] = getvalue(obj, nm, varargin)
        %GETVALUE Get a value from an ExpDrugData object.
        %   VAL = GETVALUE(OBJ, NM) accesses the scalar ExpDrugData object
        %   OBJ to retrieve a uniquely defined parameter of type NM.
        %
        %   VAL = GETVALUE(OBJ, NM, P1, V1, P2, V2, ...) only looks for
        %   parameter NM for which P1 == V1, P2 == V2, etc. PX can either
        %   be 'Source', in which case VX is the corresponding label of the
        %   Ref object, or an experimental condition (e.g., 'species' or 
        %   'sex'), in which case VX is the value of that condition. 
        % 
        %   [VAL, COND] = GETVALUE(...) additionally returns experimental
        %   conditions of VAL as an ExpCondition object COND.    

            rec = getrecords(obj, nm, varargin{:});

            checkdbmatch(obj, height(rec), nm, varargin{:})   % only continue for a single match.

            val = rec.Value;
            if nargout > 1
                cond = rec.Conditions;
            end
        end    


        function rec = getrecords(obj, nm, varargin)
        %GETRECORDS Get records from an ExpDrugData object.
        %   REC = GETRECORDS(OBJ, NM) accesses the scalar ExpDrugData object
        %   OBJ to retrieve all records for parameter NM as a table.
        %
        %   REC = GETRECORDS(OBJ, NM, P1, V1, P2, V2, ...) only looks for
        %   parameter NM for which P1 == V1, P2 == V2, etc. PX can either
        %   be 'Source', in which case VX is the corresponding label of the
        %   Ref object, or an experimental condition (e.g., 'species' or 
        %   'BW'), in which case VX is the value of that condition. 

            % validations
            assert(isscalar(obj), 'Input #1 must be scalar.')
            nm = validatestring(nm, fieldnames(obj.db));
            
            % access the desired parameter (still in table format)
            rec = obj.db.(nm);

            % process property-value pairs (subsetting)
            P = varargin(1:2:end);
            V = varargin(2:2:end);

            for i = 1:numel(P)
                if height(rec) > 0  % no need to stratify further if empty
                    if strcmp(P{i},'Source')
                        rec = rec(rec.Source == V{i}, :);
                    else   % everything else interpreted as an ExpCondition
                        cond = getcondition(rec.Conditions, P{i});
                        if isnumeric(V{i})
                            
                            % replace missing values by NaN with correct units
                            filler    = NaN*unitsOf(V{i});
                            if iscell(cond)
                                ismissing = cellfun(@isempty, cond);
                                cond(ismissing) = {filler};
                                cond = cellfun(@(x) x, cond);
                            elseif isempty(cond)
                                cond = filler;
                            end
                            % now, subsetting works
                            rec = rec(cond == V{i}, :);
                        else
                            rec = rec(strcmp(cond,V{i}), :);
                        end
                    end
                end
            end
            
        end
            
        function variants(obj,spec)
        %VARIANTS Display duplicate entries in ExpDrugData object or array
        %   VARIANTS(OBJ) shows any duplicate entries in OBJ, even those
        %       that refer to different species
        %   VARIANTS(OBJ, SPEC) shows only duplicates in species-independent
        %       parameters or those relating to species SPEC.
        %   
        %   See also ExpDrugData
                        
            allPars = fieldnames(obj(1).db);

            for i = 1:numel(obj)

                fprintf('%s: ', obj(i).name)

                hasSeveralRecs = structfun(@(x) height(x)>1,obj(i).db);
                parnm = allPars(hasSeveralRecs);
                hasVariant = false;

                for j = 1:numel(parnm)
                    nm = parnm{j};

                    % access records in 1- or 2-argument call
                    if nargin == 1
                        rec = getrecords(obj(i), nm);
                    else % nargin == 2
                        rec = getrecords(obj(i), nm, 'species', spec);
                    end

                    % now we can simply look for any duplicate entry
                    if height(rec) > 1                            
                        fprintf(['\nparameter "' nm '":\n'])                            
                        disp(rec)
                        hasVariant = true;
                    end
                end

                if ~hasVariant
                    fprintf('no variants.\n')
                end
            end
        end

        function varargout = filtervariants(obj, varargin)
        %FILTERVARIANTS Filter an ExpDrugData object 
        %   FILTERVARIANTS(OBJ, P1, V1, P2, V2, ...) filters ExpDrugData
        %   object OBJ using the provided property-value pairs (P1, V1),
        %   (P2, V2), ...
        %
        %   The following properties are supported:
        %
        %   * 'Source': Filters by reference (the corresponding value can
        %       be a Ref object or char).
        %   * 'Parameter': A char or cellstr of parameters to filter.
        %   * 'Assumption': Filters by assumption (char)
        %   * 'KeepNoMatch': specify what to do if none of the variants for
        %       a parameter match the other property-value pairs. The
        %       default is true, meaning those parameters are not filtered.
        %
        %   Any other property will be interpreted as an ExpCondition.
        %
        %   OBJ = FILTERVARIANTS(...) returns the filtered object (this is
        %   not really needed, since OBJ is modified in place).
        %
        %   Examples:
        %   
        %   eD = ExpDrugData('Warfarin');
        %   variants(eD)
        %   filtervariants(eD,'species','human')
        %   variants(eD)
        %
        %   See also ExpDrugData, ExpDrugData/variants
        
            assert(~mod(numel(varargin),2), 'Missing value for a property/value pair.')
            P = varargin(1:2:end);
            V = varargin(2:2:end);

            % first look for 'KeepNoMatch'-Option
            isKeepNoMatch = strcmpi(P,'KeepNoMatch');
            if any(isKeepNoMatch)
                keepNoMatch = V{isKeepNoMatch};
                P = P(~isKeepNoMatch);
                V = V(~isKeepNoMatch);
            else
                keepNoMatch = true; % the default
            end
                       

            % list of ExpDrugData parameters to be considered
            isDefinedPar = structfun(@(x) ~isempty(x), obj.db);
            allPar       = fieldnames(obj.db);
            definedPar   = allPar(isDefinedPar);
        
            % account for 'Parameter' option
            [lia, locb] = ismember({'Parameter'}, P);
            if lia
                customPar  = V{locb};
                definedPar = intersect(definedPar,customPar);
                P(locb) = [];
                V(locb) = [];
            end

            % iterate over the remaining properties (if any)
            for i = 1:numel(P)
                                
                for j = 1:numel(definedPar)
                    par = definedPar{j};

                    rec = getrecords(obj,par,P{i},V{i});
                    if ~(isempty(rec) && keepNoMatch)
                        obj.db.(par) = rec;
                    end
                end

            end

            if nargout >0
                varargout{1} = obj;
            end

        end


        function iD = transferrecord(eD, iD, nm, varargin)
        %TRANSFERRECORD Transfer ExpDrugData record to a DrugData object.
        %   TRANSFERRECORD(ED, ID, NM) transfers species-independent (i.e.,
        %   physio-chemical) parameter NM from the ExpDrugData object ED to
        %   the DrugData object ID. If parameter NM is undefined in ED, ID
        %   is simply left unchanged.
        %
        %   TRANSFERRECORD(ED, ID, NM, P1, V1, P2, V2, ...) specifies
        %   additional parameter-value pairs PX/VX. These can be specific
        %   references or experimental conditions. For species-dependent
        %   parameters, one of the PX must be 'species'.
        %
        %   ID = TRANSFERRECORD(ED, ID, ...) returns the updated DrugData
        %   object ID as an output.

            assert(isa(eD,'ExpDrugData') && isa(iD,'DrugData'))
                        
            rec = getrecords(eD, nm, varargin{:});
            
            nmatch = height(rec);
            if nmatch>0 
                checkdbmatch(eD, nmatch, nm, varargin{:})
    
                if eD.perspecies.(nm)
                    spec = getcondition(rec.Conditions,'species');
                    assert(~isempty(spec), ...
                        'For per-species parameters, species must be defined.')
                    addrecord(iD, nm, spec, rec.Value, rec.Source, rec.Assumption);
                else
                    addrecord(iD, nm, rec.Value, rec.Source, rec.Assumption);
                end
            end
        end


        function iD = copyphyschem(eD)
        %COPYPHYSCHEM Copy phys/chem properties from exp. to indiv. DrugData
        %   ID = COPYPHYSCHEM(ED) creates a DrugData object ID containing
        %   physiochemical properties 'MW', 'pKa', 'logPow' and 'logPvow' 
        %   (if available) from ExpDrugData object ED.

            % allocate iD
            iD = DrugData();
            iD.name = eD.name;
            iD.class = eD.class;
            iD.subclass = eD.subclass;
            
            % iterate over physiochemical parameters
            for par = {'MW','pKa','logPow','logPvow'}
                transferrecord(eD, iD, par{1});
            end

        end

    end

   methods (Access = private)

        function checkdbmatch(obj,nmatch,nm,varargin)

            if nmatch ~= 1
                % common preparation for the missing/ambiguous case.
                if isempty(obj.name)
                    dbnm = '';
                else
                    dbnm = [' "' obj.name '"'];
                end
                parnm = strjoin([cellstr(nm) varargin],'/');

                if nmatch == 0
                    % throw an error.
                    ME = MException('ExpDrugData:NoDbMatch', ...
                        'No matches for parameter "%s" found in ExpDrugData object%s.',...
                        parnm, dbnm);
                else
                    % the call is ambiguous - we want to see what's there.
                    par  = obj.db.(nm);
                    lbl  = {par.Source.label}';
                    cond = arrayfun(@(x) obj2str(x,'array'),par.Conditions,'UniformOutput',false);
                    allmatches = strjoin(strcat(lbl,' (',cond,')'),'\n');
                    ME = MException('ExpDrugData:NoDbMatch', ...
                        'Several matches for parameter "%s" found in ExpDrugData object%s:\n\n%s',...
                        parnm, dbnm, allmatches);
                end
                throwAsCaller(ME);
            end
           
        end
   end

end

