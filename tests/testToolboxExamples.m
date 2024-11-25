% TESTTOOLBOXEXAMPLES Does any of the toolbox examples produce an error?
%   TESTTOOLBOXEXAMPLES()
%   TESTTOOLBOXEXAMPLES(VERBOSITY) controls information display:
%       'all':   all functions found, whether they have examples or not
%       'run':   all functions with examples (whether they error or not)
%       'error': only functions with examples that error 
%   TESTTOOLBOXEXAMPLES(VERBOSITY,INCLUDEMETHODS) controls whether examples
%       in toolbox methods are also tested (default: FALSE).
function testToolboxExamples(verbosity,includeMethods)

    if nargin < 1
        verbosity = 'all';
    end
    if nargin < 2
        includeMethods = false;
    end

    verbosity = validatestring(verbosity,{'all','run','error'});

    wd = ['toolbox' filesep 'internal'];
%    wd = [pathPBPKtoolbox() filesep 'internal'];
    toolboxFiles = dir(fullfile(wd,['**' filesep '*.m']));
    
    % filter out methods in separate files, which may pose problems 
    % (they will be retrieved automatically using 'methods', if requested)
    isMethodOrClassFile = arrayfun(@(x) contains(x.folder,'@'), toolboxFiles);
    isClassFile  = arrayfun(@(x) endsWith(x.folder, extractBefore(x.name,'.m')), toolboxFiles);
    isMethodFile = isMethodOrClassFile & ~isClassFile;
    toolboxFiles = toolboxFiles(~isMethodFile);

    % turn off warnings and revert afterwards, since it's a global change
    S = warning('off');
    clnObj = onCleanup(@() warning(S));
    
    for i = 1:numel(toolboxFiles)
        % find out if any examples are defined in the function help
        fun = toolboxFiles(i).name;
        
        type = getfiletype(fun);
        switch type
            case 'script'
                % pass
            case 'function'
                % apply to main function
                testExample(fun, 'function', verbosity);                
            case 'class'
                % apply to class definition and optionally to methods
                testExample(fun, 'class', verbosity);     
                if includeMethods
                    meth = methods(extractBefore(fun,'.m'));
                    for j = 1:numel(meth)
                        testExample(replace(fun,'.m',['/' meth{j}]), 'function', verbosity);
                    end
                end
        end
        
    end
    
end

function testExample(fun, type, verbosity)
    capture = evalc(['help ' fun]);
    hasExamples = contains(capture,'Examples:');
    hasSeeAlso  = contains(capture,'See also');

    % run the examples
    if hasExamples
        % obtain examples section
        if hasSeeAlso
            examples = extractBetween(capture,'Examples:','See also');
        else
            switch type
                case 'function'
                    examples = extractAfter(capture,'Examples:');
                case 'class'
                    examples = extractBetween(capture,'Examples:','<a href=');
            end
        end

        % separate into valid input commands for eval
        examples = splitlines(examples);
        examples = strip(examples);
        examples = examples(~cellfun('isempty',examples));
        hasMultiLine = contains(examples,'...');
        examples(hasMultiLine) = extractBefore(examples(hasMultiLine),'...');

        % hack for grouping lines corresponding to the same command
        grp = cumsum(~[false;hasMultiLine]);
        grp = grp(1:end-1);

        % strjoin per group
        commands = splitapply(@(x) {strjoin(x)},examples,grp);

        % remove HTML tag for bold formatting
        commands = replace(commands,{'<strong>','</strong>'},'');

        % remove comments at the end of a command
        withComments = contains(commands,'%');
        commands(withComments) = extractBefore(commands(withComments),'%');

        % add ';' to suppress output
        withOutput = ~endsWith(commands,';');
        commands(withOutput) = append(commands(withOutput),';');

        for j = 1:numel(commands)  
            success = true;
            try
                eval(commands{j});                    
            catch
                disp(['"' fun '": Error when running example(s)'])

                disp(['   ' commands{j}])
                success = false;
            end               
        end
        if success & ~strcmp(verbosity,'error')
            disp(['"' fun '": Example(s) executed successfully.'])
        end
    elseif strcmp(verbosity,'all')
        disp(['"' fun '": No example(s) to execute.'])

    end
end

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
            % We are only looking for scripts and functions so anything else
            % will be reported as an error.
            disp(exception.message)
        end
    end

end

