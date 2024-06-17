%OPTIONSPBPKTOOLBOX Global options for the PBPK toolbox
%   This function stores global options in a persistent variable. Options
%   can be get/set using getoptPBPKtoolbox() or setoptPBPKtoolbox(),
%   respectively. For a list of available options and instructions on how 
%   to customize these, refer to the help of function optionsparser 
%
%   See also getoptPBPKtoolbox, setoptPBPKtoolbox, optionsparser

function out = optionsPBPKtoolbox(type, varargin)
    
    persistent options

    if isempty(options)
        options = optionsparser(struct); % get default options
    end
    
    switch type
        case 'get'
            assert(nargin <= 2, 'Either a single option or the entire options struct can be accessed.')
            if nargin == 1 || strcmpi(varargin{1}, 'all')
                out = options;
            else
                opt = validatestring(varargin{1}, fieldnames(options));
                out = options.(opt);
            end
            
        case 'set'
            out = options; % old options
            if nargin == 2 && isstruct(varargin{1}) 
                options = optionsparser(varargin{1});
            else
                options = optionsparser(options, varargin{:});
            end
        otherwise
            error('Argument "type" must be either "get" or "set".') 
    end
        
end
