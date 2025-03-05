% Test for TabularClass via the dummy ConcreteTabularClass

%% Empty ConcreteTabularClass object

obj = ConcreteTabularClass;
assert(isempty(obj))

%% Concatenation of ConcreteTabularClass objects

T = table([1;2;3],{'a';'b';'c'});

obj1 = ConcreteTabularClass(T);
obj2 = ConcreteTabularClass([T;T]);

% both horzcat and vertcat simply append the tables
assert(isequal([obj1 obj1], obj2))
assert(isequal([obj1; obj1], obj2))

%% Subsetting of ConcreteTabularClass objects

T = table([1;2;3],{'a';'b';'c'});

obj = ConcreteTabularClass(T);

objSlice1 = obj(2);
objSlice2 = obj(2,:);
tabSlice = ConcreteTabularClass(T(2,:));

assert(isequal(objSlice1, tabSlice))
assert(isequal(objSlice2, tabSlice))

%% Subassignment into ConcreteTabularClass objects

T1 = table([1;2;3],{'a';'b';'c'});
T2 = table([4;5],{'d';'e'});
T3 = table([1;4;5],{'a';'d';'e'});

obj1 = ConcreteTabularClass(T1);
obj2 = ConcreteTabularClass(T2);
obj3 = ConcreteTabularClass(T3);

obj1(2:3) = obj2;

assert(isequal(obj1,obj3))


