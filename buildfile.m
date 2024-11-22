function plan = buildfile
    % Create a plan from the task functions
    plan = buildplan(localfunctions);
    
    % Make the "test" task the default task in the plan
    plan.DefaultTasks = "test";

    plan("package").Dependencies = "test";

    plan("test").Dependencies = "check";
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

function packageTask(context)
    % Package the toolbox in an MLTBX, just incrementing build.  
    % Note that GitHub action calls packageToolbox directly.

    % Temporarily add buildUtilities to the path (remove it at the end of the function)
    oldPath = addpath(fullfile(context.Plan.RootFolder,"buildUtilities"));
    raii = onCleanup(@()(path(oldPath)));

    packageToolbox("build")
end 






    