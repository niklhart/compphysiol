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
    
    properties
        label char
        description char
    end
    
    methods
        function obj = Ref(lbl, dscr)
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
            
            % early return for single REF input
            if isa(lbl, 'Ref') && nargin == 1
                obj = lbl;
                return
            end

            % pre-processing: {'text'} --> 'text' and {[]} --> []
            if iscell(lbl)             
                assert(isscalar(lbl))
                lbl = lbl{1};
            end

            if nargin == 1
                dscr = '';
            elseif iscell(dscr)  
                assert(isscalar(dscr))
                dscr = dscr{1};
            end
            
            % main branching: undefined or defined reference?
            if isempty(lbl) 
                assert(isempty(dscr), 'Description must be empty for empty labels.')
                obj.label = '<undefined>';
                obj.description = '';
            else
                assert(ischar(lbl) && isrow(lbl),   'Input #1 must be char.')
                assert(ischar(dscr) && (isrow(dscr) || isempty(dscr)), 'Input #2 must be char.')
                obj.label = lbl;
                obj.description = dscr;
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

            assert(isscalar(obj))
            switch context
                case {'scalar','array'}
                    lbl = obj.label;
                    dsc = obj.description;
                    if ~isempty(dsc)
                        dsc = [':' dsc];
                    end
                    str = strcat(lbl,dsc);
                case 'table'
                    str = obj.label;
                otherwise
                    error('Function not defined for context "%s"',context)
            end
        end

    end
end

