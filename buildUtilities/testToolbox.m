% main testing function (merging my own function and the MATLAB mock tbx)
function testToolbox(ReportSubdirectory)

    arguments
        ReportSubdirectory (1,1) string = "";
    end

    import matlab.unittest.plugins.CodeCoveragePlugin;
    import matlab.unittest.plugins.XMLPlugin;
    import matlab.unittest.plugins.codecoverage.CoverageReport;
    import matlab.unittest.plugins.codecoverage.CoberturaFormat;

    oldpath  = addpath('tests', ...
        fullfile('tests','utils'), ...
        fullfile('tests','data-for-testing'), ...
        fullfile('tests','models-for-testing'), ...
        fullfile('tests','diary'), ...
        genpath('toolbox'));
    finalize = onCleanup(@()(path(oldpath)));

    outputDirectory = fullfile("reports",ReportSubdirectory);
    if isempty(dir(outputDirectory))
        mkdir(outputDirectory)
    end

    suite = testsuite('tests',...
        'IncludeSubfolders',true, ...
        'BaseFolder', '*tests-*');

    wd = 'toolbox';

    runner = testrunner('textoutput');

    sourceCodeFolder = fullfile(wd, {'internal','models'});
    codecoverageFileName = fullfile(outputDirectory,"codecoverage.xml");

    runner.addPlugin(XMLPlugin.producingJUnitFormat(fullfile(outputDirectory,'test-results.xml')));
    runner.addPlugin(CodeCoveragePlugin.forFolder(sourceCodeFolder, ...
        'IncludingSubfolders', true, ...
        'Producing', CoberturaFormat(codecoverageFileName)));

    results = run(runner, suite);

    results.assertSuccess()

end
