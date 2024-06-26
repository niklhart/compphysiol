%ASSERTEQUALSDIARY Compare function console output to reference diary file 
%ASSERTEQUALSDIARY(FH, REFDIARY) compares the content of the console output 
%   produced by the function handle FH to the content of a reference diary 
%   file REFDIARY. An error is thrown if the two are not equal.
function assertEqualsDiary(fh, refDiary)

    assert(isa(fh,'function_handle') && nargin(fh) == 0, ...
        'First input must be a zero-argument function handle.')
    output_test = evalc('fh()');

    refFile = diaryPath(refDiary);
    output_ref = fileread(refFile);
    
    % remove line breaks / tabs, which might differ between systems:
    output_test = strrep(output_test, newline, ' ');
    output_ref  = strrep(output_ref, newline, ' ');

    % remove multiplication sign '×' by letter 'x':
    output_test = strrep(output_test, char(215), 'x');
    output_ref  = strrep(output_ref, char(215), 'x');

    % merge repeated spaces, remove leading/trailing spaces
    output_test = strtrim(regexprep(output_test, ' +', ' '));
    output_ref  = strtrim(regexprep(output_ref, ' +', ' '));

    % compare text to reference
    success = strcmp(output_test, output_ref);

    if ~success
        msg = 'Expected console output:\n%s\n\nActual console output:\n%s\n';
        error(msg, output_ref, output_test)
    end

end
