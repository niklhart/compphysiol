%OPTIONSCOMPPHYSIOL Global options for the compphysiol toolbox
%   This function stores global options in a persistent variable. Options
%   can be get/set using getoptcompphysiol() or setoptcompphysiol(),
%   respectively. For a list of available options and instructions on how 
%   to customize these, refer to the help of class optionsClass.
%
%   See also getoptcompphysiol, setoptcompphysiol, optionsClass

function out = optionscompphysiol(action, opt)
    
    persistent options

    if isempty(options)   % get default options
        state = warning('query', 'MATLAB:structOnObject');
        warning('off','MATLAB:structOnObject')
        options = struct(optionsClass); 
        warning(state)
    end
    
    switch action
        case 'get'

            if strcmp(opt, 'all')
                out = options;
            else
                out = options.(opt);
            end
            
        case 'set'

            out = options; % old options
            options = mergestructs(options, opt);

        otherwise
            error('Argument "type" must be either "get" or "set".') 
    end
        
end
