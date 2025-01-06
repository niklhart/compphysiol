function ver = compphysiol_version()
%COMPPHYSIOL_VERSION Query version number of installed compphysiol toolbox

    toolboxInfo = matlab.addons.toolbox.installedToolboxes;
    for i = 1:length(toolboxInfo)
        if strcmp(toolboxInfo(i).Name,'compphysiol')
            
            ver = toolboxInfo(i).Version;
            return
        end
    end

    % fallback if toolbox wasn't installed (e.g., source code downloaded)
    ver = '';

end