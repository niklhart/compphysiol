%SETOPTPBPKTOOLBOX Set global PBPK toolbox options
%
%   SETOPTPBPKTOOLBOX(NM1,VAL1,...NMN,VALN) sets properties by name-value
%   pairs. Currently implemented options are
%   - 'unitHandling': {true} | false
%   - 'reporting': character array {'Assumptions'}
%   
%   SETOPTPBPKTOOLBOX(OPT), with valid options struct OPT, sets the options
%       to OPT.
%   
%   SETOPTPBPKTOOLBOX(OPT,NM1,VAL1,...NMN,VALN) first sets options to OPT,
%       then changes the options using the name-value pairs.
%   
%   OLDOPT = SETOPTPBPKTOOLBOX(...) returns the options struct OLDOPT prior
%   to any change. This allows to revert any change in the global options 
%   by SETOPTPBPKTOOLBOX(OLDOPT).
%   
%   SETOPTPBPKTOOLBOX('reset') restores the default options, without 
%   unloading the physiology / drug databases.
%   
%   For a list of available options including explanations and the required 
%   format, refer to the help of function optionsparser 
%
%   See also getoptPBPKtoolbox, optionsPBPKtoolbox, optionsparser

function varargout = setoptPBPKtoolbox(varargin)

    oldopt = optionsPBPKtoolbox('set', varargin{:});

    if nargout == 1
        varargout{1} = oldopt;
    end

end

