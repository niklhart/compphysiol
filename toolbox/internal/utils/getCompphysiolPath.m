function toolboxPath = getCompphysiolPath()
    %GETCOMPPHYSIOLPATH Retrieve path of compphysiol toolbox

    toolboxPath = which('getCompphysiolPath');
    i = find(filesep == toolboxPath);

    % main toolbox path: two folders up from getCompphysiolPath.m location
    toolboxPath = toolboxPath(1:i(end-2)); 

end