% INITCMTIDX Initialize compartment indexing
%   S = INITCMTIDX(STR1,STR2,...,STRN) with character arrays STR1,...,STRN 
%   creates a structure S with fields S.(STR1) = 1, ..., S.(STRN) = N.
%
%   S = INITCMTIDX(CLSTR), with cellstr CLSTR of length N, works in a 
%   similar way, creating a structure S with fields S.(CLSTR{1}) = 1, ..., 
%   S.(CLSTR{N}) = N.
%
%   See also addcmtidx

function S = initcmtidx(varargin)

    if nargin == 1 && iscellstr(varargin{1})            % cellstr case
        numbering = num2cell(1:numel(varargin{1}));
        S = cell2struct(numbering,varargin{1},2);        
    else                                                % char list case
        numbering = num2cell(1:nargin);
        S = cell2struct(numbering,varargin,2);
    end
end

