% main testing function (merging my own function and the MATLAB mock tbx)
function testToolbox()

    import matlab.unittest.plugins.CodeCoveragePlugin
    import matlab.unittest.plugins.codecoverage.CoverageReport

    wd = pathPBPKtoolbox();

    suite = testsuite('tests',...
        'IncludeSubfolders',true, ...
        'BaseFolder', '*tests-*');

    oldpath  = addpath('tests', ...
        fullfile('tests','utils'), ...
        fullfile('tests','data-for-testing'), ...
        fullfile('tests','models-for-testing'), ...
        fullfile('tests','diary'));
    finalize = onCleanup(@()(path(oldpath)));

    runner = testrunner('textoutput');
    sourceCodeFolder = fullfile(wd, {'internal','models'});
    reportFolder = fullfile('tests','coverageReport');
    reportFormat = CoverageReport(reportFolder);
    p = CodeCoveragePlugin.forFolder(sourceCodeFolder,...
        'Producing',reportFormat,'IncludingSubfolders',true);
    runner.addPlugin(p)

    results = run(runner, suite);

    results.assertSuccess()

end
