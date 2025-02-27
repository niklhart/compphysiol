%SETOPTCOMPPHYSIOL Set global toolbox options
%
%   SETOPTCOMPPHYSIOL(NM1,VAL1,...NMN,VALN) sets properties by name-value
%   pairs. For a list of available options including explanations and the 
%   required format, refer to the help of function optionsparser. 
%   
%   SETOPTCOMPPHYSIOL(OPT), with valid options struct OPT, sets the options
%       to OPT.
%   
%   SETOPTCOMPPHYSIOL(OPT,NM1,VAL1,...NMN,VALN) first sets options to OPT,
%       then changes the options using the name-value pairs.
%   
%   OLDOPT = SETOPTCOMPPHYSIOL(...) returns the options struct OLDOPT prior
%   to any change. This allows to revert any change in the global options 
%   by SETOPTCOMPPHYSIOL(OLDOPT).
%   
%   To restore the defaults, use 
%
%   clear optionscompphysiol
%
%   See also getoptcompphysiol, optionscompphysiol, optionsparser

function varargout = setoptcompphysiol(S, options)

    arguments
        S = struct
        options.?optionsClass
    end

    options = mergestructs(S, options);

    oldopt = optionscompphysiol('set', options);

    if nargout == 1
        varargout{1} = oldopt;
    end

end

