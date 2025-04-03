function compphysiol_builddocsearchdb()
%COMPPHYSIOL_BUILDDOCSEARCHDB Render compphysiol documentation searchable
%   Run this function once after toolbox installation to render the toolbox
%   documentation searchable.
%   
%   See also builddocsearchdb.

    if ~isempty(compphysiol_version())
        toolboxPath = getCompphysiolPath();
    
        docPath = fullfile(toolboxPath,'examples','html');
    
        if ~isfolder(fullfile(docPath,'helpsearch-v4_en'))
            oldpath = addpath(docPath);
            c = onCleanup(@(x) path(oldpath));
        
            builddocsearchdb(docPath)
            msgbox('Documentation search database has been updated!', 'Success');

            indexFile = fullfile(docPath, 'index.html');

            % Modify index.html to update the searchable documentation section
            if isfile(indexFile)
                try
                    % Read the current index.html content
                    fid = fopen(indexFile, 'r');
                    htmlContent = fscanf(fid, '%c');
                    fclose(fid);
    
                    % Backup the original file before modifying
                    backupFile = fullfile(docPath, 'index_backup.html');
                    copyfile(indexFile, backupFile);
    
                    % Define patterns for replacement
                    oldText = '<p>After installation, the compphysiol toolbox documentation is accessible, but not searchable. <a href="matlab:compphysiol_builddocsearchdb()">Click here to render it searchable</a></p>';
                    newText = '<p>The compphysiol toolbox documentation is now <strong>searchable</strong>.</p>';
    
                    % Replace the old message with the new one
                    htmlContent = regexprep(htmlContent, oldText, newText);
    
                    % Write back the modified content
                    fid = fopen(indexFile, 'w');
                    fwrite(fid, htmlContent);
                    fclose(fid);
                catch
                    warning('Could not modify index.html. Please update it manually if necessary.');
                end
    
            end
        end
    end
end