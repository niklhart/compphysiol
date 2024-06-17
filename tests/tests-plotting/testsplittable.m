% test splittable

%% Splittable correct usage
Time = [0; 0; 1; 1; 2; 2; 3; 3]*u.day;
Site = {'ven';'mus';'ven';'mus';'ven';'mus';'ven';'mus'};
Subspace = {'tot'; 'tot'; 'tot'; 'tot'; 'vas'; 'vas'; 'vas'; 'vas'};
Value = [0.2; 0.3; 1.2; 1.3; 2.2; 2.3; 3.2; 3.3]*u.kg/u.m^3;

tbl = table(Time, Site, Subspace, Value);
tbl.GROUPCAT = categorical(tbl.Site);
tbl.SUBPLOTCAT = categorical(tbl.Subspace);

t11 = table([0; 1]*u.day, {'mus';'mus'}, {'tot';'tot'}, [0.3;1.3]*u.kg/u.m^3, ...
    'VariableNames',{'Time','Site','Subspace','Value'});
t11.GROUPCAT = categorical(t11.Site);
t11.SUBPLOTCAT = categorical(t11.Subspace);

t12 = table([2; 3]*u.day, {'mus';'mus'}, {'vas';'vas'}, [2.3;3.3]*u.kg/u.m^3, ...
    'VariableNames',{'Time','Site','Subspace','Value'});
t12.GROUPCAT = categorical(t12.Site);
t12.SUBPLOTCAT = categorical(t12.Subspace);

t21 = table([0; 1]*u.day, {'ven';'ven'}, {'tot';'tot'}, [0.2;1.2]*u.kg/u.m^3, ...
    'VariableNames',{'Time','Site','Subspace','Value'});
t21.GROUPCAT = categorical(t21.Site);
t21.SUBPLOTCAT = categorical(t21.Subspace);

t22 = table([2; 3]*u.day, {'ven';'ven'}, {'vas';'vas'}, [2.2;3.2]*u.kg/u.m^3, ...
    'VariableNames',{'Time','Site','Subspace','Value'});
t22.GROUPCAT = categorical(t22.Site);
t22.SUBPLOTCAT = categorical(t22.Subspace);

split = splittable(tbl, 'GROUPCAT', 'SUBPLOTCAT');
assert(isequal(split{1,1}, t11))
assert(isequal(split{1,2}, t12))
assert(isequal(split{2,1}, t21))
assert(isequal(split{2,2}, t22))