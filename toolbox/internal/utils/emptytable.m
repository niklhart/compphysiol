%TAB = EMPTYTABLE(VARARGIN) Empty table with given column names
%   TAB is a 0-by-nargin table, with column names taken from VARARGIN{1}, 
%   ..., VARARGIN{nargin}. All input arguments must be character arrays.

function tab = emptytable(varargin)
    assert(all(cellfun(@ischar, varargin)), ...
        'all input arguments must be character arrays')
    
    tab = cell2table(cell(0,nargin), 'VariableNames', varargin);
    
end

