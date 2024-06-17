%ADDCMTIDX Adds a new index to an compartment index structure
%   S = ADDCMTIDX(S, 'STR1', 'STR2',...,'STRN') adds compartments
%       STR1, ..., S.STRN to existing index structure S.
%
%   S = ADDCMTIDX(S, C), with cellstr C of length N, adds compartments 
%       C{1}, ..., C{N} to the index structure S.
%
%   See also initcmtidx

function S = addcmtidx(S, varargin)
    
    comp = fieldnames(S);

    if nargin == 2 && iscellstr(varargin{1})  % cellstr case
        args = varargin{1};
    else                                      % char list case
        args = varargin;
    end
    
    if ~isempty(intersect(comp, args))
        error(['Compartment name(s) ' ...
            strjoin(intersect(comp, args),',') ' already in use.'])
    end

    ncmt = numel(comp);
    for i=1:numel(args)
        S.(args{i}) = ncmt+i;
    end
    
end
