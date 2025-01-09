% test isequaltol.m

%% Different classes

tf1 = isequaltol([1 2 3],{1,2,3});
tf2 = isequaltol(["a" "b"],{'a' 'b'});

assert(tf1 == false)
assert(tf2 == false)

%% Numeric input

% value mismatch
tf1 = isequaltol([1,2,3],[1,2,3]+0.1,0.2);
tf2 = isequaltol([1,2,3],[1,2,3]+0.1,0.01);

assert(tf1 == true)
assert(tf2 == false)

% size mismatch
tf3 = isequaltol([1,2,3],[1,2]);
tf4 = isequaltol([1,2,3],[1;2;3]);

assert(tf3 == false)
assert(tf4 == false)


%% String and char input

% string input
tf1 = isequaltol(["a" "b"],["a" "b"]);
tf2 = isequaltol("a","b");

assert(tf1 == true)
assert(tf2 == false)

% char input
tf3 = isequaltol('abc','abc');
tf4 = isequaltol('abc','bca');

assert(tf3 == true)
assert(tf4 == false)

%% Cell input

% numeric content only
tf1 = isequaltol({[1 2],3},{[1 2],3});
tf2 = isequaltol({[1 2],3},{[1 2],3.2},0.1);

assert(tf1 == true)
assert(tf2 == false)

%% Table input

T1 = table([1;2;3],[4;5;6]);
T2 = table([1;2;3],[4;5;6.1]);
assert(isequaltol(T1,T2,0.2))
assert(~isequaltol(T1,T2,0.01))

%% Struct input

% scalar struct
S1 = struct('a',[1;2;3],'b',[4;5;6]);
S2 = struct('a',[1;2;3]+0.1,'b',[4;5;6]);
S3 = struct('a',[1;2;3],'c',[4;5;6]);
S4 = struct('a',[1;2;3]);

assert(isequaltol(S1,S2,0.2))
assert(~isequaltol(S1,S3,0.2))
assert(~isequaltol(S1,S4,0.2))

% struct array
S5 = struct('a',{1;2;3});
S6 = struct('a',{1;2.1;3});
S7 = struct('a',{1;2.3;3});
S8 = struct('b',{1;2;3});

assert(isequaltol(S5,S6,0.2))
assert(~isequaltol(S5,S7,0.2))
assert(~isequaltol(S5,S8,0.2))

%% Nested input

% nested structs
o1 = struct('a',struct('b',[1;2;3]));
o2 = struct('a',struct('b',[1;2;3]+0.1));
assert(isequaltol(o1,o2,0.2))





