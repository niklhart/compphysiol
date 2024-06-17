%ASSERTERROR Assert function throws an error (for use in testing)
%   ASSERTERROR(FH) asserts that the function handle FH throws any error,
%   i.e. if FH() doesn't throw an error, ASSERTERROR will throw an error.
%
%   ASSERTERROR(FH, ID) asserts that the function handle FH throws a 
%   specific error, with error identifier ID.

function assertError(fh, id)

    if nargin > 1
        throws = matlab.unittest.constraints.Throws(id);
    else
        throws = matlab.unittest.constraints.Throws(?MException);
    end
    passed = throws.satisfiedBy(fh);
    diagText = "";
    if ~passed
        diag = throws.getDiagnosticFor(fh);
        arrayfun(@diagnose, diag);
        diagText = strjoin({diag.DiagnosticText},[newline newline]);
    end
    
    assert(passed, diagText); 
    
end