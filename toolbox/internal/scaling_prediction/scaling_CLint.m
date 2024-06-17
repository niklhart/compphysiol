function dout = scaling_CLint(din, physout)
%SCALING_CLINT Scaling of intrinsic hepatic clearance between individuals
%   DOUT = SCALING_CLINT(DIN,PHYSOUT) scales intrinsic hepatic clearance 
%   from one physiology to another, assuming that CLint per liver organ 
%   weight is identical.
%
%   Requirements:
%   - DIN must define a parameter CLint together with a physiology
%     containing liver organ weight
%

    assert(isa(din,'DrugData'),       'Input #1 must be a DrugData object.')
    assert(isa(physout,'Physiology'), 'Input #2 must be a Physiology object.')

    error('Not implemented yet.')

    CLint_in = getvalue(din,'CLint'); %TODO sinnvolle Syntax finden.

end