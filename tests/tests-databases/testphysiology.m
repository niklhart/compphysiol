% Test methods of the Physiology class and related functions

%% Referenceid function

refids = referenceid();
assert(length(refids) == 12)

% TODO: test for empty physiology database

assertError(@() referenceid('test'), 'MATLAB:unrecognizedStringChoice')

% correct usage
ref = referenceid('human35f');
assert(isa(ref, 'Physiology'))
assert(strcmp(ref.name, 'human35f'))

%% Constructor

phys1 = Physiology;
assert(isa(phys1, 'Physiology'))

phys2 = Physiology('human35f');
assert(strcmp(phys2.name, 'human35f'))
assert(phys2.db.age.Value == 35*u.year)
assert(strcmp(phys2.db.sex.Value, {'female'}))
assert(strcmp(phys2.db.species.Value, {'human'}))


%% set.name

phys1 = Physiology;
phys1.name = 'test';
assert(strcmp(phys1.name, 'test'))
assertError(@() setName(phys1, 1), ...
    'PBPK:Physiology:setname:charInputExpected')


%% Database record manipulation

% TODO: checkintegrity

%% addrecord

phys1 = Physiology;

% correct usage: single Physiology object
addrecord(phys1, 'sex', 'female');
assert(strcmp(phys1.db.sex.Value, 'female'))
assert(strcmp(phys1.db.sex.Source, 'derived'))
addrecord(phys1, 'sex', 'male');
assert(strcmp(phys1.db.sex.Value{2}, 'male'))

% correct usage: more than one Physiology object
% TODO

% wrong parameter name
assertError(@() addrecord(phys1, 'test', 'test'), ...
    'PBPK:Physiology:addrecord:parameterNotFound')

% wrong value type
assertError(@() addrecord(phys1, 'sex', 1), 'PBPK:typecheck:nonChar')


%% hasrecord

phys1 = Physiology;
addrecord(phys1, 'sex', 'female');

assert(hasrecord(phys1, 'sex'))
assert(~hasrecord(phys1, 'age'))

% wrong parameter name
assertError(@() hasrecord(phys1, 'test'), ...
    'PBPK:Physiology:hasrecord:parameterNotFound')


%% getrecord

phys1 = Physiology;
addrecord(phys1, 'sex', 'female');

% correct usage
assert(strcmp(getrecord(phys1, 'sex'), 'female'))

% No entries found
assertError(@() getrecord(phys1, 'age'), ...
    'PBPK:Physiology:getrecord:noEntriesFound1')
assertError(@() getrecord(phys1, 'pH', 'blood'), ...
    'PBPK:Physiology:getrecord:noEntriesFound2')

% Multiple entries
addrecord(phys1, 'sex', 'male');
addrecord(phys1, 'pH', 'blood', 1);
addrecord(phys1, 'pH', 'blood', 2);
assertError(@() getrecord(phys1, 'sex'), ...
    'PBPK:Physiology:getrecord:multipleEntries1')
assertError(@() getrecord(phys1, 'pH', 'blood'), ...
    'PBPK:Physiology:getrecord:multipleEntries2')

% Wrong parameter name
assertError(@() getrecord(phys1, 'test'), ...
    'PBPK:Physiology:getrecord:parameterNotFound')


%% updaterecord

phys1 = Physiology;
addrecord(phys1, 'sex', 'female');

% Correct usage
updaterecord(phys1, 'sex', 'male')
assert(strcmp(phys1.db.sex.Value, 'male'))

% Wrong argument type
assertError(@() updaterecord(phys1, 1, 1), ...
    'PBPK:Physiology:updaterecord:valueMustBeChar')

% No entries found
assertError(@() updaterecord(phys1, 'pH', 'blood', 1), ...
    'PBPK:Physiology:updaterecord:noEntriesFound')


%% aliasrecord

phys1 = Physiology;
addrecord(phys1, 'pH', 'blood', 1);

% Correct usage
aliasrecord(phys1, 'pH', 'blood', 'blood1');
assert(strcmp(phys1.db.pH.Tissue{2}, 'blood1'))
assert(phys1.db.pH.Value(2) == 1)
assert(strcmp(phys1.db.pH.Source{2}, 'derived (identical to blood)'))

% Not a per-tissue parameter
assertError(@() aliasrecord(phys1, 'sex', 'blood', 'blood1'), ...
    'PBPK:Physiology:aliasrecord:mustBePerTissueParameter')

% No entry
assertError(@() aliasrecord(phys1, 'pH', 'blood2', 'blood3'), ...
    'PBPK:Physiology:aliasrecord:noEntriesFound')

% Wrong parameter type
assertError(@() aliasrecord(phys1, 'pH', 'blood', 1), ...
    'PBPK:Physiology:aliasrecord:mustBeChar')
assertError(@() aliasrecord(phys1, 'pH', 1, 'test'), ...
    'PBPK:Physiology:aliasrecord:mustBeChar')
assertError(@() aliasrecord(phys1, 1, 'blood', 'test'), ...
    'PBPK:Physiology:aliasrecord:mustBeChar')


%% deleterecord

phys1 = Physiology;
addrecord(phys1, 'sex', 'female');
addrecord(phys1, 'pH', 'tis1', 1);
addrecord(phys1, 'pH', 'tis2', 1);
addrecord(phys1, 'pH', 'tis3', 1);

% Correct usage
deleterecord(phys1, 'sex');
assert(isempty(phys1.db.sex))
deleterecord(phys1, 'pH', 'tis1');
assert(height(phys1.db.pH) == 2)
deleterecord(phys1, 'pH');
assert(isempty(phys1.db.pH))

% Wrong parameter name
assertError(@() deleterecord(phys1, 'test'), ...
    'PBPK:Physiology:deleterecord:parameterNotFound')


%% Display


phys1 = Physiology;
assertEqualsDiary(@() disp(phys1), 'testphysiology_disp1.txt');

phys2 = Physiology('human35f');
assertEqualsDiary(@() disp(phys2), 'testphysiology_disp2.txt');

str1 = obj2str(phys2, 'array');
assert(isequal(str1, ...
    'human	Caucasian	female	35.00 year	163.00 cm	60.00 kg...'))
str2 = obj2str(phys2, 'table');
assert(isequal(str1, ...
    'human	Caucasian	female	35.00 year	163.00 cm	60.00 kg...'))
assertError(@() obj2str(phys2, 'test'), ...
    'PBPK:Physiology:obj2str:unknownContext')

%% getvalue (inherited from superclass DB)

BW_ = 70*u.kg;
Qliv_ = u.L/u.h;
rho_ = u.kg/u.L;
phys = Covariates('BW',BW_,'Qblo|liv',Qliv_,'dens|liv',rho_,'dens|mus',2*rho_);

BW    = getvalue(phys,'BW');
Qliv  = getvalue(phys,'Qblo','liv');
Qliv2 = getvalue(phys,'Qblo');
rho = getvalue(phys,'dens','liv');

assert(BW == BW_)
assert(Qliv == Qliv_)
assert(Qliv2 == Qliv_)
assert(rho == rho_)
assertError(@() getvalue(phys,'BH'), 'PBPK:DB:noDbMatch')
assertError(@() getvalue(phys,'dens'), 'PBPK:DB:multiDbMatch')


%% subsref (inherited from superclass DB)






% helpers
function setName(obj, val)
    obj.name = val;
end