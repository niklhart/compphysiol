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
    
    assert(isequal(output_test, output_ref))

end
