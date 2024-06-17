function subtab = subset(tab, varargin)
%SUBSET Subsets a table according to the remaining arguments.
%   SUBTAB = SUBSET(TAB, VARARGIN) returns the rows I of table TAB which 
%   satisfy TAB{I,1} == VARARGIN{1}, ..., TAB{I,N} == VARARGIN{N}, where
%   N = length(VARARGIN).
%
%   Examples:
%   x = {'a','a','a','b','b','b'}'
%   y = {'a','b','b','a','a','b'}'
%   z = { 1 , 2 , 3 , 4 , 5 , 6 }'
%   tab = table(x,y,z);
%   subset(tab, 'a')

    switch nargin
        case 1
            subtab = tab;
        case 2
            oktab = strcmp(tab{:,1}, varargin{1});
            subtab = tab(oktab, :);
        otherwise
            error('Subsetting with more than one subcategory not implemented.')
    end
    
end

