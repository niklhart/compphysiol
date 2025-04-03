function compphysiol_builddocsearchdb()
%COMPPHYSIOL_BUILDDOCSEARCHDB Render compphysiol documentation searchable
%   Run this function once after toolbox installation to render the toolbox
%   documentation searchable. Executing this function again has no effect.
%   
%   See also builddocsearchdb.

    if ~isempty(compphysiol_version())
        toolboxPath = getCompphysiolPath();
    
        docPath = fullfile(toolboxPath,'examples','html');
    
        if ~isfolder(fullfile(docPath,'helpsearch-v4_en'))
            oldpath = addpath(docPath);
            c = onCleanup(@(x) path(oldpath));
        
            builddocsearchdb(docPath)
            msgbox('Documentation search database has been created!', 'Success');

        end
    end
end