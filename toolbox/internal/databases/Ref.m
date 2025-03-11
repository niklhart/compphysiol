classdef Ref < ColumnClass
    %REF Class for literature references
    %   The Ref class is used to assign a short and easy to remember label
    %   (e.g. AuthorYear) to a complicated literature reference, containing
    %   details on journal, pages, figure/table number, etc.
    %   
    %   Ref objects can be compared with '==', which will only compare the
    %   label.
    %
    %   Examples:
    %   
    %   r = Ref('Rodgers2007',...
    %        'Rodgers & Rowland, "Vss", Pharm Res 2007, Table II')
    %   r == 'Rodgers2007'
    %   r.description
    
    properties (Access = private)
        label
        description
        DOI
    end
    
    methods
        function obj = Ref(lbl, dscr, doi)
            %REF Construct an instance of this class
            %   OBJ = REF(LBL, DSCR), with char LBL and DSCR, creates a Ref
            %   object OBJ. OBJ behaves like a categorical array with
            %   category LBL, in particular OBJ == LBL is true.
            %
            %   OBJ = REF(LBL) is shorthand for OBJ = REF(LBL,''). 
            %
            %   OBJ = REF({[]}) creates a scalar REF object OBJ repre-
            %   senting an undefined reference; it is equivalent to 
            %   OBJ = REF('<undefined>',''). This syntax allows to encode
            %   missing references as [] in databases because the 
            %   concatenation method can take care of the class conversion.
            
            arguments 
                lbl (1,:) {Ref.mustBeCharLike} = '<undefined>'
                dscr (1,:) char = ''
                doi (1,:) char = ''
            end

            % early return for single REF input
            if nargin == 1
                if isa(lbl, 'Ref')
                    obj = lbl;
                    return
                else
                    lbl = char(lbl);
                end
            end
            
            % main branching: undefined or defined reference?
            if isempty(lbl) 
                assert(isempty(dscr) && isempty(doi), ...
                    'Description and DOI must be empty for empty labels.')
                obj.label = '<undefined>';
                obj.description = '';
                obj.DOI = '';
            else
                obj.label = lbl;
                obj.description = dscr;
                obj.DOI = doi;
            end

        end
        
        function tf = ismissing(obj)
        %ISMISSING Find undefined references.
        %   TF = ISMISSING(OBJ) returns a logical array TF of the same size
        %   as OBJ, "true" meaning that a reference is missing.

            tf = obj == '<undefined>';
        end
        
        function tf = eq(obj,str)
            %EQ Element-by-element equal operator (==) for Ref class
            %   Detailed explanation goes here
            if isa(obj,'Ref')
                assert(ischar(str), ...
                    ['Cannot compare Ref objects to class "' class(str) '".'])
                tf = strcmp({obj.label}, str);            
                tf = reshape(tf, size(obj));
                
            else % -> str must be Ref because the Ref method was called
                tf = eq(str,obj);
            end
        end
        
        function tf = ne(obj,str)
            %NE Element-by-element not-equal operator (~=) for Ref class

            tf = ~eq(obj,str);
        end
        
        function str = obj2str(obj,context)    
            %OBJ2STR Represent scalar Ref object as string
            %   STR = OBJ2STR(OBJ,CONTEXT) turns the scalar Ref object OBJ
            %   into a character array STR depending on CONTEXT as follows:
            %   
            %       'scalar' and 'array' use both the label and the 
            %           description of OBJ
            %       'table' only uses label of OBJ but not the description.
            %   
            %   See also ColumnClass

            arguments
                obj (1,1) Ref
                context char {mustBeMember(context,{'scalar','array','table'})}
            end

            switch context
                case {'scalar','array'}
                    lbl = obj.label;
                    dsc = obj.description;
                    doi = obj.DOI;
                    if ~isempty(dsc)
                        dsc = [':' dsc];
                    end
                    if ~isempty(doi)
                        doi = [' (DOI:' doi ')'];
                    end
                    str = strcat(lbl,doi,dsc);
                case 'table'
                    str = obj.label;
            end
        end

    end

    methods (Static, Hidden)
        function mustBeCharLike(x)
            try 
                char(x);
                %pass
            catch 
                error('compphysiol:Ref:mustBeCharLikeOrRef', ...
                    'Input must be a Ref object or convertible to char.')
            end
        end
    end
end

