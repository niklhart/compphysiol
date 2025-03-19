function out = referenceid(name)
%REFERENCEID Create a Physiology object for a physiology database individual
%   PHYSOBJ = REFERENCEID(NAME) matches character array NAME with the names
%   of reference individuals in the physiological database and returns the
%   physiology object associated to this individual. 
%
%   NAMES = REFERENCEID() returns the names of available reference
%   individuals as a cellstr.
%
%   See also Physiology, PhysiologyDB

    h = PhysiologyDB.Instance;
    
    if nargin == 0
        out = arrayfun(@(x) x.name, h, 'UniformOutput', false);
    else
        out = copy(h{name});
    end    
end

