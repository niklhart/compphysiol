% main testing function (merging my own function and the MATLAB mock tbx)
function testToolbox()

    import matlab.unittest.plugins.CodeCoveragePlugin
    import matlab.unittest.plugins.codecoverage.CoverageReport

    wd = pathPBPKtoolbox();

    suite = testsuite([wd '/tests'], ...
        'IncludeSubfolders',true, ...
        'BaseFolder', '*tests-*');

    runner = testrunner('textoutput');
    sourceCodeFolder = strcat(wd, {'/internal/','/models/'});
    reportFolder = [wd '/tests/coverageReport'];
    reportFormat = CoverageReport(reportFolder);
    p = CodeCoveragePlugin.forFolder(sourceCodeFolder,...
        'Producing',reportFormat,'IncludingSubfolders',true);
    runner.addPlugin(p)

    results = run(runner, suite);

    results.assertSuccess()

end
