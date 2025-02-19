%RESETCOMPPHYSIOL Restore defaults of compphysiol toolbox
%   RESETCOMPPHYSIOL() clears all persistent variables that may have been
%   set when using the toolbox, in particular the physiology and drug
%   databases. Calling this function is necessary when changing the
%   database to load from. If any such objects exist in the workspace,
%   they will be cleared after a prompt.
%
%   See also PhysiologyDB, DrugDB.
function resetcompphysiol()

    clear DrugDB PhysiologyDB

end