% Test methods of the DrugData class and related functions

%% loaddrugdata function

% correct usage: no filtering
dd1 = loaddrugdata('drugA');
assert(strcmp(dd1.name, 'drugA'))
assert(strcmp(dd1.class, 'sMD'))
assert(strcmp(dd1.subclass, 'acid'))
assert(abs(dd1.db.MW.Value/(u.kg/u.mol) - 0.30833) < 1e-6)
assert(isequal(size(dd1.db.CLint_hep_perOWliv), [2 4]))

% correct usage: filtering
dd2 = loaddrugdata('drugA','species','rat');
assert(strcmp(dd2.name, 'drugA'))
assert(strcmp(dd2.class, 'sMD'))
assert(strcmp(dd2.subclass, 'acid'))
assert(abs(dd2.db.MW.Value/(u.kg/u.mol) - 0.30833) < 1e-6)
assert(isequal(size(dd2.db.CLint_hep_perOWliv), [1 4]))


%% Constructor

% empty
dd1 = DrugData;
assert(isa(dd1, 'DrugData'))

% load compounds
dd2 = DrugData('drugA');
assert(strcmp(dd2.name, 'drugA'))
assert(strcmp(dd2.class, 'sMD'))
assert(strcmp(dd2.subclass, 'acid'))
assert(abs(dd2.db.MW.Value/(u.kg/u.mol) - 0.30833) < 1e-5)


%% Display

dd1 = loaddrugdata('drugA');
assertEqualsDiary(@() disp(dd1), ...
    'testdrugdata_disp1.txt');

dd2 = DrugData;
assertEqualsDiary(@() disp(dd2), ...
    'testdrugdata_disp2.txt');


%% Database record manipulation

dd1 = loaddrugdata('drugA');
dd2 = loaddrugdata('drugB');

% getrecord
assert(abs(getrecord(dd1,'MW')/(u.kg/u.mol) - 0.3083) < 1e-4)
assert(all(abs(getrecord([dd1 dd2], 'MW')/(u.kg/u.mol) - [0.3083 0.2343]) < 1e-4))
assertError(@() getrecord(dd1, 'test'), ...
    'PBPK:DrugData:getrecord:parameterNotFound')
assertError(@() getrecord(dd1, 'CLint_hep_perOWliv'), ...
    'PBPK:DrugData:getrecord:severalEntriesFound')
assertError(@() getrecord(dd1, 'fuP', 'mouse'), ...
    'PBPK:DrugData:getrecord:noEntriesFound')

% hasrecord
assert(hasrecord(dd1, 'MW'))
assert(~hasrecord(dd1, 'fuP', 'mouse'))
assertError(@() hasrecord(dd1, 'test'), ...
    'PBPK:DrugData:hasrecord:parameterNotFound')

% updaterecord
updaterecord(dd1, 'MW', 1*u.kg/u.mol);
assert(dd1.db.MW.Value == 1*u.kg/u.mol)
assertError(@() updaterecord(dd1, 'test', 1), ...
    'PBPK:DrugData:updaterecord:parameterNotFound')

% addrecord
addrecord(dd1, 'fuP', 'mouse', 1);
assert(all(abs(dd1.db.fuP.Value - [0.38;0.01;1.00]) < 1e-4))
assert(isequal(dd1.db.fuP.Source{3}, 'derived'))
assertError(@() addrecord(dd1, 'test', 1), ...
    'PBPK:DrugData:addrecord:parameterNotFound')


%% Variants / filtervariants

dd1 = loaddrugdata('drugA','species','rat');
assertEqualsDiary(@() variants(dd1), ...
    'testdrugdata_variants1.txt');

dd2 = loaddrugdata('drugA');
assertEqualsDiary(@() variants(dd2), ...
    'testdrugdata_variants2.txt');

assertEqualsDiary(@() filtervariants(dd1, 'assumption', 'test'), ...
    'testdrugdata_variants3.txt');

% no suitable test drug for this test
dd2 = loaddrugdata('Warfarin');
filtervariants(dd2, 'reference', ...
    'Julkunen1980', ...
    'silent',true);
assert(isequal(size(dd2.db.fuP), [2 4]))
assert(isequal(size(dd2.db.lambda_po), [1 4]))
assert(dd2.db.lambda_po.Value/(1/u.h) - 2 < 1e-4)

% no suitable test drug for this test
dd4 = loaddrugdata('Amitriptyline');
assertError(@() filtervariants(dd4, 'reference', 'test', 'assumption', 'test'), ...
    'PBPK:DrugData:filtervariants:wrongFilterParameters')
filtervariants(dd4, 'assumption', 'Assumed Egut=0','silent',true);
assert(isequal(size(dd4.db.Egut), [2 4]))
