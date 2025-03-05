% Tests for Ref class

%% Constructor working as expected

r = Ref('label','description');
assert(isequal(r.label, 'label'))
assert(isequal(r.description, 'description'))

%% Comparison of scalar Ref working as expected

r = Ref('label','description');
assert(r == 'label')
assert(r ~= 'description')

%% Empty Ref handled correctly

r = Ref('label','description');
r0 = r([]);
val = r0 == 'label';
assert(isempty(val) && islogical(val))

%%  Comparison of Ref array working as expected

r1 = Ref('label','bla');
r2 = Ref('key',  'bla bla');
r1211 = [r1; r2; r1; r1];

val1211  = r1211 == 'label';
expected = [true; false; true; true];
assert(isequal(val1211,expected))

%% Concatenation with empty Ref working

r1  = Ref('label','description');
r2  = {[]};
r12 = [r1;r2];

assert(isequal(r12 == '<undefined>',[false;true]))
assert(isequal(r12 == 'label',[true;false]))
