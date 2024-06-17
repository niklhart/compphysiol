%RECAPPLY Recursively apply function F to nested object O.
% Y = RECAPPLY(F,O) with a single-output function F and any object O for 
%   which F is defined, or a combination of nested structs, cells or tables
%   of such objects, recursively applies F to any object nested within O 
%   and stores the modified output in the same position, such that the 
%   output Y has the same structure as O.
%
%   Notice:
%   * Elementwise operations should work for any nesting structure, as long
%     as they are well defined for any input they encounter (in particular,
%     vectorized for vector input and defined for all input types). 
%   * If F changes the size of its input argument (e.g., summary statis-
%     tics), RECAPPLY will result in an error if the nesting structure con-
%     tains any tables. 
%   * If F changes the type of its input argument, RECAPPLY will result 
%     in an error if the nesting structure contains any tables and if the 
%     change of type is not consistent within a table column. 
%   * If an error occurs, no effort is done to track at which level of the
%     nesting structure this happens.
%
%   For example, RECAPPLY may be useful for modifying function arguments
%   (encoded as a cell array) prior to calling a function, i.e. instead of
%   calling 
%
%       g(args{:})
%
%   call
%
%       modargs = recapply(f,args);
%       g(modargs{:})

function y = recapply(f,o)

    assert(isa(f,'function_handle') && nargout(f) == 1, ...
        'Input #1 must be a function handle with a single output.')
        
        y = o;
        if isstruct(o)
            fld = fieldnames(o);     
            nfld = numel(fld);
            for i = 1:numel(o)
                for j = 1:nfld
                    y(i).(fld{j}) = recapply(f, o(i).(fld{j}));
                end
            end
        elseif iscell(o)
            for i = 1:numel(o)
                y{i} = recapply(f, o{i});
            end
        elseif istable(o)
            for i = 1:width(o)
                y{:,i} = recapply(f, o{:,i});
            end
        else
            y = f(o);
        end
    
end

