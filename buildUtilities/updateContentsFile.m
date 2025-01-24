function updateContentsFile(newVersion, newDate)

    filename = "Contents.m";
    filepath = fullfile(pwd,"toolbox",filename);

    % Read the file
    fid = fopen(filepath, 'r');
    if fid == -1
        error('Cannot open file: %s', filepath);
    end
    fileContents = fread(fid, '*char')';
    fclose(fid);
    
    % Update the version number
    versionPattern = '(?<=Version )[\d\.]+';
    fileContents = regexprep(fileContents, versionPattern, newVersion);
    
    % Update the date
    datePattern = '(?<=Version [\d\.]+ )\d{2}-[A-Za-z]{3}-\d{4}';
    fileContents = regexprep(fileContents, datePattern, newDate);
    
    % Write back to the file
    fid = fopen(filepath, 'w');
    if fid == -1
        error('Cannot write to file: %s', filepath);
    end
    fwrite(fid, fileContents, 'char');
    fclose(fid);
    
    fprintf('File "%s" updated successfully.\n', filename);
end
