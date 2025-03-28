%GENERATEFUNCTIONINDEX Generate html with alphabetical list of functions.
%   GENERATEFUNCTIONINDEX(TBXDIR, DOCDIR) parses all .m files in directory
%   TBXDIR for class, function and method help. It then produces an html
%   file "function-index.html" in directory DOCDIR, containing an 
%   alphabetical list of functions, together with the first line of 
%   function help (if available).
function generateFunctionIndex(tbxDir, docDir)

    arguments
        tbxDir (1,:) char = '.'
        docDir (1,:) char = 'help'
    end


    % Store current path to restore later
    originalPath = path;
    c = onCleanup(@() path(originalPath));

    % add everything to the path
    addpath(genpath(tbxDir));

    % Get all .m files in the toolbox folder
    mFiles = dir(fullfile(tbxDir, '**', '*.m'));
    functionList = [];
    methodSet = containers.Map(); % Store detected methods to prevent duplicates

    % First, scan files to collect function/method definitions
    for k = 1:length(mFiles)
        filePath = fullfile(mFiles(k).folder, mFiles(k).name);
        functionName = mFiles(k).name(1:end-2); % Remove .m extension

        % Check if it's a class method in an @-folder
        classMatch = regexp(mFiles(k).folder, ['\' filesep '@([^' filesep ']*)'], 'tokens', 'once');
        if ~isempty(classMatch)
            className = classMatch{1};
            if strcmp(className,functionName)     % class definition
                fullFunctionName = functionName;
            else                                  % class method
                fullFunctionName = sprintf('%s/%s', className, functionName);
            end
            methodSet(fullFunctionName) = true; % Mark as added

        else                                      % regular function 
            fullFunctionName = functionName;
        end

        % Extract first help line
        helpText = getFunctionHelp(filePath, functionName);

        % Append function/method to the list
        functionList = [functionList; struct( ...
            'name', functionName, ...
            'fullName', fullFunctionName, ...
            'description', helpText )]; %#ok<AGROW>

        % Track functions and standalone methods
        methodSet(fullFunctionName) = true;
    end

    % Second, process classdef files and add missing methods
    for k = 1:length(mFiles)
        filePath = fullfile(mFiles(k).folder, mFiles(k).name);
        functionName = mFiles(k).name(1:end-2); % Remove .m extension

        if isClassFile(filePath)
            classMethods = getClassMethods(functionName);
            for i = 1:length(classMethods)
                methodName = classMethods{i};
                fullFunctionName = sprintf('%s/%s', functionName, methodName);

                % Skip if method already exists in @Class/method.m
                if isKey(methodSet, fullFunctionName)
                    continue;
                end
                methodSet(fullFunctionName) = true; % Mark as added

                % Extract method help from the classdef file
                helpText = getMethodHelp(filePath, methodName);

                functionList = [functionList; struct( ...
                    'name', methodName, ...
                    'fullName', fullFunctionName, ...
                    'description', helpText )]; %#ok<AGROW>
            end
        end
    end

    % Sort functions alphabetically
    functionList = sortStructArray(functionList, 'name');

    % Generate the alphabetical.html file
    outputFile = fullfile(docDir, 'function-index.html');
    writeAlphabeticalHTML(functionList, outputFile);

    fprintf('Function list generated: %s\n', outputFile);
end

function helpText = getMethodHelp(classFilePath, methodName)
    helpText = '';
    fid = fopen(classFilePath, 'r');

    if fid == -1
        return;
    end

    foundMethod = false;

    while ~feof(fid)
        line = strtrim(fgetl(fid));

        % Generalized pattern to match function definitions
        match = regexp(line, ['^function\s+(?:\[[^\]]*\]\s*=|\w+\s*=)?\s*' methodName '\s*\('], 'once');
        
        if ~isempty(match)
            foundMethod = true;
            continue; % Move to the next line to check for help comments
        end

        % If we've found the function, look for help comments
        if foundMethod
            if startsWith(line, '%')
                helpText = strtrim(line(2:end)); % Remove '%' and trim spaces
                break;
            elseif ~isempty(line)  % Stop if a non-comment line appears
                break;
            end
        end
    end

    fclose(fid);

    % Remove redundant function name if present at start
    words = strsplit(helpText, ' ');
    if ~isempty(words) && strcmpi(words{1}, methodName)
        helpText = strjoin(words(2:end), ' '); % Remove first word
    end

    % Default if no help was found
    if isempty(helpText)
        helpText = sprintf('%s (no description available)', methodName);
    end

end

function helpText = getFunctionHelp(filePath, functionName)
    % Read the first help line from the function file
    fid = fopen(filePath, 'r');
    helpText = '';
    if fid == -1
        return;
    end
    
    % Read lines while checking if they belong to the help section
    isInsideHelpBlock = false;
    foundFunctionSignature = false;
    
    while ~feof(fid)
        line = strtrim(fgetl(fid));

         % Check for function definition line
        if startsWith(line, 'function', 'IgnoreCase', true)
            foundFunctionSignature = true;
            isInsideHelpBlock = false; % Reset help block detection
            continue; % Move to the next line after the function signature
        end

        % Detect comment lines
        if startsWith(line, '%')

            % Case 1: Help is at the top of the file
            if ~foundFunctionSignature && ~isInsideHelpBlock
                isInsideHelpBlock = true;
                helpText = strtrim(line(2:end));

            % Case 2: Help is right after the function signature
            elseif foundFunctionSignature && isempty(helpText)
                helpText = strtrim(line(2:end));
                break; % Stop after first valid help line

            end

        elseif isInsideHelpBlock
            break; % Stop reading if a non-comment appears after help block
        end
    end
    fclose(fid);
    
    % Remove redundant function name if present at start
    words = strsplit(helpText, ' ');
    if ~isempty(words) && strcmpi(words{1}, functionName)
        helpText = strjoin(words(2:end), ' '); % Remove first word
    end

    % Use function name if no help text is found
    if isempty(helpText)
        [~, name, ~] = fileparts(filePath);
        helpText = sprintf('%s (no description available)', name);
    end
end


function writeAlphabeticalHTML(functionList, outputFile)
    % Writes an alphabetical list of functions to an HTML file
    fid = fopen(outputFile, 'w', 'n', 'UTF-8');
    
    if fid == -1
        error('Could not open %s for writing.', outputFile);
    end

    fprintf(fid, '<html><head><title>Function Index</title></head><body>\n');
    fprintf(fid, '<h1>Alphabetical List of Functions</h1>\n');
    fprintf(fid, '<ul>\n');
    
    for k = 1:length(functionList)
        func = functionList(k);
        fprintf(fid, ...
            '<li><a href="matlab:helpPopup(''%s'')">%s</a> - %s</li>\n', ...
            func.fullName, func.fullName, func.description);
    end
    
    fprintf(fid, '</ul>\n</body></html>\n');
    fclose(fid);
end

function sortedStruct = sortStructArray(structArray, fieldName)
    [~, idx] = sort({structArray.(fieldName)});
    sortedStruct = structArray(idx);
end

function isClass = isClassFile(filePath)
    % Checks if an .m file defines a class
    fid = fopen(filePath, 'r');
    isClass = false;
    
    if fid == -1
        return;
    end
    
    while ~feof(fid)
        line = strtrim(fgetl(fid));
        if startsWith(line, 'classdef', 'IgnoreCase', true)
            isClass = true;
            break;
        elseif startsWith(line, 'function')
            break;
        end
    end

    fclose(fid);
end

function methodList = getClassMethods(className)
    % Uses MATLAB's `methods` function to retrieve a list of public methods
    try
        methodList = methods(className);
    catch
        methodList = {};
    end
end

