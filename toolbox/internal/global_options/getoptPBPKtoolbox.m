%GETOPTPBPKTOOLBOX Get one/all global PBPK toolbox options
%
%   OPT = GETOPTPBPKTOOLBOX(NAME) returns the value OPT of option NAME. 
%
%   OPT = GETOPTPBPKTOOLBOX() or OPT = GETOPTPBPKTOOLBOX('all') returns all
%       options as a struct OPT.
%   
%   For a list of available options including explanations and the required 
%   format, refer to the help of function optionsparser 
%
%   See also setoptPBPKtoolbox, optionsPBPKtoolbox, optionsparser

function opt = getoptPBPKtoolbox(varargin)

    opt = optionsPBPKtoolbox('get',varargin{:});

end

