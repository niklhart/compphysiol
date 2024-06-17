%COLLECTION = COLLECT_ASSUMPTIONS(ASSUM) Collect assumptions for later use
%   Assumptions are stored in a persistent variable.
%   
%   COLLECT_ASSUMPTIONS(ASSUM), with no output argument, simply adds a new
%   assumption to the list.
%   
%   COLLECTION = COLLECT_ASSUMPTIONS() returns all assumptions collected so
%   far. 
%
%   Up to now, there is no means to delete an assumption once it has been 
%   collected; this should probably be done at the start of any analysis.
%
%   TO DO: choose a type/class for storing assumptions, and check for this 
%   type here.
%

function collection = collect_assumptions(assum)
    persistent assumlist
    
    if isempty(assumlist)
        assumlist = {};    %choose here the type we want
    end
    if nargin > 0
        assumlist = [assumlist; assum];
    end
    collection = assumlist;
end