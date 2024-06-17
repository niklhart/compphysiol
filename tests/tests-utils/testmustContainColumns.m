%% Correct usage

col1 = [1;2;3];
col2 = categorical({'a';'a';'b'});
tab1 = table(col1, col2);

mustContainColumns(tab1, {'col1'})
assertError(@() mustContainColumns(tab1, {'col3'}), 'PBPK:missingCol')