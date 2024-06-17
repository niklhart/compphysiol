% Define two dummy ExpDrugData objects for testing.

d = ExpDrugData;
addrecord(d,'CLblo_perBW',3*u.L/u.min/u.kg, ...
    Ref('Test'), ...
    ExpConditions('BW',70*u.kg,'species','human'));

d2 = ExpDrugData;
addrecord(d2,'CLblo_perBW',3*u.L/u.min/u.kg, ...
    Ref('HumRef'), ...
    ExpConditions('BW',70*u.kg,'species','human'));
addrecord(d2,'CLblo_perBW',30*u.L/u.min/u.kg, ...
    Ref('RatRef'), ...
    ExpConditions('BW',0.4*u.kg,'species','rat'));
addrecord(d2,'CLblo_perBW',20*u.L/u.min/u.kg, ...
    Ref('MessyRef'), ...
    ExpConditions('species','rat'));

%% Filtering values in various ways (simple ExpDrugData)

CL1 = getvalue(d,'CLblo_perBW','BW',70*u.kg);       % continuous ExpCondition
CL2 = getvalue(d,'CLblo_perBW','species','human');  % categorical ExpCondition
CL3 = getvalue(d,'CLblo_perBW','Source','Test');    % Reference

assert(CL1 == CL2)
assert(CL1 == CL3)

%% Accessing experimental conditions

[~, c] = getvalue(d,'CLblo_perBW');
BW     = getcondition(c,'BW');           % continuous ExpCondition
spec   = getcondition(c,'species');      % categorical ExpCondition

assert(BW == 70*u.kg)
assert(strcmp(spec, 'human'))


%% Filtering values in various ways (challenging ExpDrugData)

CL1 = getvalue(d2,'CLblo_perBW','BW',70*u.kg);
CL2 = getvalue(d2,'CLblo_perBW','species','human');
CL3 = getvalue(d2,'CLblo_perBW','Source','HumRef');
CL4 = getvalue(d2,'CLblo_perBW','Source','HumRef','species','human','BW',70*u.kg);

assert(CL1 == 3*u.L/u.min/u.kg)
assert(CL1 == CL2)
assert(CL1 == CL3)
assert(CL1 == CL4)


