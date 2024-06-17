% Test methods of the Observable class

%% Expansion of Observable object

% three observables
o1 = Observable('SimplePK','pla','total','Mass/Volume');
org = {'adi','ven'};
o2 = Observable('PBPK',org,'tis','total','Mass/Volume');

o = [o1 o2 o1];
test = expand(o);
ref  = tblvertcat(expand(o1),...
                  expand(o2),...
                  expand(o1));

assert(isequal(test,ref))

% empty observable
oe([]) = Observable();
test2 = expand(oe);

assert(isequal(size(test2),[0 1]))

%% Equal/ismember operators for Observable class

o1 = Observable('SimplePK','pla','total','Mass/Volume');
o2 = Observable('PBPK','adi','tis','total','Mass/Volume');

o11 = [o1; o1];
o12 = [o1; o2];
o21 = [o2; o1];
o22 = [o2; o2];

% assertions about '=='
assert(isequal(o11 == o12, [true; false]))
assert(isequal(o11 == o22, [false;false]))
assert(isequal(o1  == o12, [true; false]))
assert(isequal(o12 == o21, [false;false]))   %TODO: not working yet.

% assertions about '~='
assert(isequal(o11 ~= o12, [false; true]))
assert(isequal(o11 ~= o22, [true;  true]))
assert(isequal(o1  ~= o12, [false; true]))
assert(isequal(o12 ~= o21, [true;  true]))   

% assertions about 'ismember'
assert( ismember(o1,o12))
assert(~ismember(o1,o22))
assert(isequal(ismember(o12, o1), [true;false]))
assert(isequal(ismember(o12,o21), [true; true]))  

%% Unique function

