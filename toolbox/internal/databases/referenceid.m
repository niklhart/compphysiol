function out = referenceid(name)
%REFERENCEID Create a Physiology object for a physiology database individual
%   PHYSOBJ = REFERENCEID(NAME) matches character array NAME with the names
%   of reference individuals in the physiological database and returns the
%   physiology object associated to this individual. In this way, it is made 
%   transparent on the script level that no scaling is done.
%
%   NAMES = REFERENCEID() returns the names of available reference
%   individuals as a cellstr.

    h = getoptPBPKtoolbox('PhysiologyDBhandle');
    
    if isempty(h)
        error('PBPK:referenceid:dbNotInitialized', ...
            'Physiological database must be initialized first.')
    elseif nargin == 0
        out = {h.name};
    else
        valid = {h.name};
        try 
            name = validatestring(name, valid);
        catch ME
            aliases = {h.alias};
            try
                alias = validatestring(name, aliases);
                name = valid{strcmp(aliases,alias)};
            catch 
                rethrow(ME)
            end
        end
        out = copy(h{name});
    end    
end

