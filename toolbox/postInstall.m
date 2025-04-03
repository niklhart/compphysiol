function postInstall()
%POSTINSTALL render compphysiol documentation searchable
%   Run this function once after toolbox installation to render the toolbox
%   documentation searchable.
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