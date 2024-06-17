%% Correct usage

col1 = [1;2;3];
col2 = categorical({'a';'a';'b'});
tab1 = table(col1, col2);

% type of LVL argument: cellstr
tab = filterbylvl(tab1, 'col2', {'a'});
assert(isequal(size(tab), [2 2]))
assert(isequal(tab.col1, [1;2]))
assert(isequal(tab.col2, categorical({'a'; 'a'})))
% lvl not present in the column
assert(isempty(filterbylvl(tab1, 'col2', {'c'})))

% empty table
col3 = [];
col4 = categorical({});
tab2 = table(col3, col4);
tab = filterbylvl(tab2, 'col4', {'a'});
assert(isempty(tab))

% type of LVL argument: struct
tab = filterbylvl(tab1, 'col2', struct('test',{'a'}));
assert(isequal(size(tab), [2 2]))
assert(isequal(tab.col1, [1;2]))
assert(isequal(tab.col2, categorical({'a'; 'a'})))

% type of LVL argument: cell array
C = cell(1);
C{1} = 1;
tab = filterbylvl(tab1, 'col1', C);
assert(isequal(size(tab), [1 2]))
assert(isequal(tab.col1, 1))
assert(isequal(tab.col2, categorical({'a'})))

%% Wrong column name

col1 = [1;2;3];
col2 = categorical({'a';'a';'b'});
tab1 = table(col1, col2);
assertError(@() filterbylvl(tab1, 'col4', {'a'}), ...
    'MATLAB:table:UnrecognizedVarName')

%% Wrong type of LVL argument

col1 = [1;2;3];
col2 = categorical({'a';'a';'b'});
tab1 = table(col1, col2);

assertError(@() filterbylvl(tab1, 'col1', 'a'), ...
    'PBPK:Utils:Filterbylvl:Levels:invalidInputArgument')