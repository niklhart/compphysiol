% test getunits and getunitstr

Time = [0; 0; 1; 1; 2; 2; 3; 3]*u.day;
Site = {'ven';'mus';'ven';'mus';'ven';'mus';'ven';'mus'};
Subspace = {'tot'; 'tot'; 'tot'; 'tot'; 'vas'; 'vas'; 'tis'; 'tis'};
Value = [0.2; 0.3; 1.2; 1.3; 2.2; 2.3; 3.2; 3.3]*u.kg/u.m^3;

tbl = table(Time, Site, Subspace, Value);

% temporarily deactivate display units for these tests
oldopt = setoptcompphysiol('DisplayUnits',{});
c = onCleanup(@() setoptcompphysiol(oldopt));

%% Correct usage: single plot

% empty input units
[tUnit, yUnit] = getunits(tbl, [], []);
assert(isequal(tUnit,{'day'}))
assert(isequal(yUnit,{'kg/m^3'}))

%non-empty input units
[tUnit2, yUnit2] = getunits(tbl, {'min'}, {'g/L'});
assert(isequal(tUnit2,{'min'}))
assert(isequal(yUnit2,{'g/L'}))

%% Correct usage: subplots

% GROUPCAT added for completeness, but it doesn't influence getunits()
tbl.GROUPCAT = categorical(tbl.Site);
tbl.SUBPLOTCAT = categorical(tbl.Subspace);

[tUnit, yUnit] = getunits(tbl,[],[]);
assert(isequal(tUnit,repmat({'day'},[3 1])))
assert(isequal(yUnit,repmat({'kg/m^3'},[3 1])))

%% Incompatible units in data

tbl.Time(1) = 1*u.kg;
assertError(@() getunits(tbl, [], []));

%% Test getunitstr

 % base unit
assert(isequal(getunitstr(1*u.kg/u.s), 'kg/s'))     

% custom display (per-variable)
assert(isequal(getunitstr(1*u.mg), 'mg'))      

% custom display (global)
opt = setoptcompphysiol('DisplayUnits',{'mg'});
c = onCleanup(@() setoptcompphysiol(opt));

assert(isequal(getunitstr(scd(u.kg)),'mg'))      

% unitless (double)
assert(isequal(getunitstr(1), 'unitless'))

% invalid input
assertError(@() getunitstr('kg'))


