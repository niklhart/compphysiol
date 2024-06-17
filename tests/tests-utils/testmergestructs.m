%% Correct usage

s1.a = 1;
s1.b = {'A','B','C'};
s2.a = 2;
s2.b = {'D','E','F'};
s3.a = 3;
s3.c = {'D','E','F'};
s4.a = 3;
s4.b = {'A','B','C'};
s4.c = {'D','E','F'};

assert(isequal(mergestructs(struct(), struct()), struct()))
assert(isequal(mergestructs(s1, s2), s2))
assert(isequal(mergestructs(s1, s3), s4))
