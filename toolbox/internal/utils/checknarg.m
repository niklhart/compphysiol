function checknarg(f,nin,nout)
%CHECKNARG Check number of function in-/outputs, accounting for varargin/-out
%   CHECKNARG(F,NIN,NOUT) checks that function F can be given NIN input 
%   and NOUT output arguments. If also covers the case where F uses
%   varargin/varargout.
    
    assert(isa(f,'function_handle'), 'Input 1 must be a function handle.')

    nin_f  = nargin(f);
    nout_f = nargout(f);
    nm_f   = func2str(f);

    msg = 'Function "%s" expected to have %d %s argument(s), but has %d.';

    assert(nin_f < 0  || nin_f == nin,   msg, nm_f, nin,  'input',  nin_f)
    assert(nout_f < 0 || nout_f == nout, msg, nm_f, nout, 'output', nout_f)

end