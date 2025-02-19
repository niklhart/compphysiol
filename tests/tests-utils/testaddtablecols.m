%% Column types

col1 = [1; 2; 3];
tab = table(col1);

tab1 = addtablecols(tab, 'col2', 'char');
assert(isequal(size(tab1), [3 2]))
assert(isequal(tab1.col2, {'';'';''}))

tab2 = addtablecols(tab, 'col2', 'double');
assert(isequal(size(tab2), [3 2]))
assert(all(isnan(tab2.col2)))

assertError(@() addtablecols(tab, 'col2', 'test'), ...
    'compphysiol:Utils:addtablecols:wrongColumnType')

%% Empty table

tab_empty = table();
tab3 = addtablecols(tab_empty, 'col', 'char');
assert(isequal(size(tab3), [0 1]))
assert(isempty(tab3.col))

%% Add several columns

col1 = [1; 2; 3];
tab = table(col1);
tab1 = addtablecols(tab, {'col2', 'col3'}, {'char', 'double'});
assert(isequal(size(tab1), [3 3]))
assert(isequal(tab1.col2, {'';'';''}))
assert(all(isnan(tab1.col3)))

%% Input sizes

col1 = [1; 2; 3];
tab = table(col1);
assertError(@() addtablecols(tab, {'col2', 'col3'}, {'char', 'char', 'double'}), ...
    'compphysiol:Utils:Uniformize_size:wrongInputDimensions')

%% Wrong argument type

col1 = [1; 2; 3];
assertError(@() addtablecols(col1, 'col2', 'char'), ...
    'compphysiol:Utils:addtablecols:wrongInputType')