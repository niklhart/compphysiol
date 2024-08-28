% main testing function (merging my own function and the MATLAB mock tbx)
function testToolbox()

    import matlab.unittest.plugins.CodeCoveragePlugin;
    import matlab.unittest.plugins.XMLPlugin;
    import matlab.unittest.plugins.codecoverage.CoverageReport;
    import matlab.unittest.plugins.codecoverage.CoberturaFormat;

    oldpath  = addpath('tests', ...
        fullfile('tests','utils'), ...
        fullfile('tests','data-for-testing'), ...
        fullfile('tests','models-for-testing'), ...
        fullfile('tests','diary'), ...
        'toolbox');
    finalize = onCleanup(@()(path(oldpath)));

    outputDirectory = "reports";
    if isempty(dir(outputDirectory))
        mkdir(outputDirectory)
    end

    suite = testsuite('tests',...
        'IncludeSubfolders',true, ...
        'BaseFolder', '*tests-*');

    initcompphysiol('silent');

    wd = pathPBPKtoolbox();

    runner = testrunner('textoutput');

    sourceCodeFolder = fullfile(wd, {'internal','models'});

    codecoverageFileName = fullfile(outputDirectory,"codecoverage.xml");

%    reportFolder = fullfile('tests','coverageReport');
%    reportFormat = CoverageReport(reportFolder);
%    p = CodeCoveragePlugin.forFolder(sourceCodeFolder,...
%        'Producing',reportFormat,'IncludingSubfolders',true);
%    runner.addPlugin(p)

    runner.addPlugin(XMLPlugin.producingJUnitFormat(fullfile(outputDirectory,'test-results.xml')));
    runner.addPlugin(CodeCoveragePlugin.forFolder(sourceCodeFolder, ...
        'IncludingSubfolders', true, ...
        'Producing', CoberturaFormat(codecoverageFileName)));

    results = run(runner, suite);

    results.assertSuccess()

end
