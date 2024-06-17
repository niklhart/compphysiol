%ASSERTWARNING Assert function displays an warning (for use in testing)
%   ASSERTWARNING(FH) asserts that the function handle FH displays any
%   warning, i.e. if FH() doesn't display a warning, ASSERTWARNING will throw
%   an error.
%
%   ASSERTWARNING(FH, ID) asserts that the function handle FH displays a 
%   specific warning, with warning identifier ID.

function assertWarning(fh, id)

    % update warning states and save old settings 
    [lastmsg,lastid] = lastwarn('DummyWarnMsg','Dummy:WarnID');
    s = warning('off');

    % ensure that previous settings are safely restored even if fh() errors
    c1 = onCleanup(@() warning(s));
    c2 = onCleanup(@() lastwarn(lastmsg,lastid));

    % call the function and see whether a warning was produced
    fh();
    [warnmsg, warnid] = lastwarn(); 

    if strcmp(warnmsg,'DummyWarnMsg')
        error('assertWarning:noWarning', ...
            'Function "%s" did not produce any warning.', func2str(fh))
    end
    if nargin > 1 && ~strcmp(warnid,id)        
        error('assertWarning:wrongWarning', ...
            'Function "%s" did not produce warning "%s".', ...
            func2str(fh), id)
    end    
    
end