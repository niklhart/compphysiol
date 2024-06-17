%GETFILETYPE Determine if a file is a class, function, or script
%   TYPE = GETFILETYPE(FILE) determines the file type of char input FILE;
%   the return value TYPE is:
%
%   - 'script' for MATLAB scripts;
%   - 'function' for MATLAB functions;
%   - 'class' for MATLAB class definitions.
%   
%   If FILE is anything else than the above, an error is thrown.

function type = getfiletype(file)

    assert(endsWith(file,'.m'), 'Input must be a .m file.')
    file = extractBefore(file,'.m');

    try
        nargin(file); % error for scripts
        
        if exist(file,'class') == 8     % see help('exist')
            type = 'class';
        else
            type = 'function';
        end
        
    catch exception
        if strcmp(exception.identifier, 'MATLAB:nargin:isScript')
            type = 'script';
        else
            % We are only looking for scripts so anything else
            % will be reported as an error.
            disp(exception.message)
        end
    end

end

