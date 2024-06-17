%PATHPBPKTOOLBOX Base path of PBPK toolbox
%   PATH = PATHPBPKTOOLBOX() returns the base path of the PBPK toolbox.
%   This function is used internally to find files specified by relative 
%   file paths.
%
%   PATHPBPKTOOLBOX(PATH) is used to set the base path during toolbox
%   initialization. It cannot be changed afterwards.

function path = pathPBPKtoolbox(setpath)

    persistent basePath
    
    if isempty(basePath)
        assert(nargin == 1, 'The toolbox path has not been set yet.')
        assert(isfolder(setpath), 'Input must be a valid directory.')
        basePath = setpath;
    else
        assert(nargin == 0, ...
            'The PBPK toolbox path cannot be changed once it is set.')        
    end
        
    path = basePath;
end

