% Test methods of the Record class

%% Empty Record object

r1 = Record();       % empty Record object

assert(isa(r1,'Record'))
assert(isempty(r1))
assert(numel(r1) == 0)

%% Record object constructor in collapsed/expanded format

o1 = Observable('SimplePK','pla','','');
Time  = 0*u.h;
Value = 0*u.mg;
r1 = Record(table(Time,o1,Value,'VariableNames',{'Time','Observable','Value'}));
o2 = expand(o1);
r2 = Record([table(Time) o2 table(Value)]);

assert(isequal(r1,r2))

%% Expand method on empty Record

r = Record();
e = expand(r);

assert(isequal(size(e),[0 3]))

%% Size of Record object

o1 = Observable('SimplePK','pla','','');
Time  = 0*u.h;
Value = 0*u.mg;
r1 = Record(table(Time,o1,Value,'VariableNames',{'Time','Observable','Value'}));

assert(isequal(size(r1), [1,1]))

[s1, s2] = size(r1);
assert(isequal(s1, 1))
assert(isequal(s2, 1))

% empty record
r1 = Record();
assert(isequal(size(r1), [0,1]))

%% Test concatenation of Record objects

o1 = Observable('SimplePK','pla','total','Mass/Volume');
o2 = Observable('PBPK','ven','tis','total','Mass/Volume');
Time  = 0*u.h;
Value = 0*u.mg;
r1 = Record(table(Time,o1,Value,'VariableNames',{'Time','Observable','Value'}));
r2 = Record(table(Time,o2,Value,'VariableNames',{'Time','Observable','Value'}));

% Record objects are 1D --> horizontal/vertical concatenation treated identically 
r12a = Record(table(repmat(Time,2,1), [o1;o2], repmat(Value,2,1),'VariableNames',{'Time','Observable','Value'}));
r12b = [r1 r2];
r12c = [r1; r2];

assert(isequal(r12a,r12b))
assert(isequal(r12a,r12c))


%% Test subscripted referencing of Record objects

o1 = Observable('SimplePK','pla','total','Mass/Volume');
o2 = Observable('PBPK','ven','tis','total','Mass/Volume');
Time  = 0*u.h;
Value = 0*u.mg;
r1 = Record(table(Time,o1,Value,'VariableNames',{'Time','Observable','Value'}));
r2 = Record(table(Time,o2,Value,'VariableNames',{'Time','Observable','Value'}));

r12 = [r1;r2];

assert(isequal(r12(2, :), r2))
assert(isequal(r12.Time, [0; 0]*u.h))

%TODO: check invalid use

%% Display

o1 = Observable('SimplePK','pla','total','Mass/Volume');
Time  = 0*u.h;
Value = 0*u.mg;
r1 = Record(table(Time,o1,Value,'VariableNames',{'Time','Observable','Value'}));
assertEqualsDiary(@() disp(r1), 'testrecord_disp1.txt');

%% End method

tab = table([1;2;3]*u.h,Observable('SimplePK',{'a','b','c'},'',''),[1;2;3], ...
    'VariableNames',{'Time','Observable','Value'});
r1 = Record(tab);

assert(isequal(r1(end,:), r1(3,:)))
assertError(@() r1(:,end), 'PBPK:Record:invalidUseOfEndKeyword')
