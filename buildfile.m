function plan = buildfile
    % Create a plan from the task functions
    plan = buildplan(localfunctions);
    
    % Make the "test" task the default task in the plan
    plan.DefaultTasks = "test";

    % Make the "release" task dependent on the "check" and "test" tasks
    plan("release").Dependencies = ["check" "test"];
end
    
    function checkTask(~)
        % Identify code errors (info and warning are OK, for now)
        issues = codeIssues;
        errors = issues.Issues(issues.Issues.Severity == 'error',:);
        assert(isempty(errors),formattedDisplayText( ...
            errors(:,["Location" "Severity" "Description"])))
    end
    
    function testTask(context)
        % Run unit tests

        % Temporarily add buildUtilities to the path (remove it at the end of the function)
        oldPath = addpath(fullfile(context.Plan.RootFolder,"buildUtilities"));
        cleanup = onCleanup(@()(path(oldPath)));

        testToolbox()
    end
    
    function releaseTask(~)
        releaseFolderName = "release";
        % Create a release and put it in the release directory
        opts = matlab.addons.toolbox.ToolboxOptions("toolboxPackaging.prj");

        % By default, the packaging GUI restricts the name of the getting started guide, so we fix that here.
        opts.ToolboxGettingStartedGuide = fullfile("toolbox", "gettingStarted.mlx");

        % GitHub releases don't allow spaces, so replace spaces with underscores
        mltbxFileName = strrep(opts.ToolboxName," ","_") + ".mltbx";
        opts.OutputFile = fullfile(releaseFolderName,mltbxFileName);

        % Create the release directory, if needed
        if ~exist(releaseFolderName,"dir")
            mkdir(releaseFolderName)
        end
        matlab.addons.toolbox.packageToolbox(opts);
    end
    