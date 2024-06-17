% EMPTYDBTABLE Empty database table with given column names
%   TAB = EMPTYDBTABLE(VARARGIN) creates a  0-by-(nargin+3) table TAB, 
%   where the first nargin column names are taken from VARARGIN{1}, ..., 
%   VARARGIN{nargin} and the last 3 column names are default names present 
%   in all database tables.
%
%   See also emptytable

function tab = emptydbtable(varargin)
    tab = emptytable(varargin{:},'Value','Source','Assumption');
end

