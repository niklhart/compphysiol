function generateHelptoc(docFolder)
    if nargin < 1
        docFolder = '.'; % Default to current folder
    end

    % Get all HTML files in the documentation folder
    htmlFiles = dir(fullfile(docFolder, '*.html'));
    
    % Create the helptoc.xml file
    tocFilePath = fullfile(docFolder, 'helptoc.xml');
    fid = fopen(tocFilePath, 'w');
    
    if fid == -1
        error('Could not open helptoc.xml for writing.');
    end
    
    % Write XML header
    fprintf(fid, '<?xml version="1.0" encoding="utf-8"?>\n');
    fprintf(fid, '<toc version="2.0">\n');
    
    % Add a main title entry (modify as needed)
    fprintf(fid, '    <tocitem target="index.html">\n');
    fprintf(fid, '        Computational Physiology Toolbox\n');
    
    % Loop through each HTML file and add to TOC
    for k = 1:length(htmlFiles)
        fileName = htmlFiles(k).name;
        title = extractTitle(fullfile(docFolder, fileName));
        
        fprintf(fid, '        <tocitem target="%s">\n', fileName);
        fprintf(fid, '            %s\n', title);
        fprintf(fid, '        </tocitem>\n');
    end
    
    % Close the main title entry
    fprintf(fid, '    </tocitem>\n');
    
    % Close XML
    fprintf(fid, '</toc>\n');
    fclose(fid);
    
    fprintf('helptoc.xml generated successfully in %s\n', docFolder);
end

function title = extractTitle(htmlFile)
    % Read the first few lines of the file to find the title
    fid = fopen(htmlFile, 'r');
    if fid == -1
        title = htmlFile; % Default to filename if file can't be read
        return;
    end
    
    title = ''; % Default empty title
    while ~feof(fid)
        line = fgetl(fid);
        match = regexp(line, '<title>(.*?)</title>', 'tokens', 'once');
        if ~isempty(match)
            title = match{1};
            break;
        end
    end
    fclose(fid);
    
    % If no title found, use the filename without extension
    if isempty(title)
        [~, name, ~] = fileparts(htmlFile);
        title = name;
    end
end
