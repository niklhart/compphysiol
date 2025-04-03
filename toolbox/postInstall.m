function postInstall()
%STARTUP compphysiol startup function to render documentation searchable
%   At the first restart of MATLAB after installing the Computational 
%   Physiology Toolbox, this function runs automatically and renders
%   the toolbox documentation searchable. It can also be executed manually
%   after toolbox installation.
%   
%   See also builddocsearchdb.

    if ~isempty(compphysiol_version())
        toolbox_path = getCompphysiolPath();
    
        html_path = fullfile(toolbox_path,'examples','html');
    
        if ~isfolder(fullfile(html_path,'helpsearch-v4_en'))
            oldpath = addpath(html_path);
            c = onCleanup(@(x) path(oldpath));
        
            builddocsearchdb(html_path)
        end
    end
end