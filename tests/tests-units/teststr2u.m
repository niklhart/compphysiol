% some test for str2u

%% Char input

% simple base unit
v1 = str2u('1.23 kg');
assert(isequal(v1, 1.23*u.kg))

% compound unit
v2 = str2u('1.23 kg*m*mol/s');
v2 = scd(v2);                    % clear custom display units
assert(isequal(v2, 1.23*u.kg*u.m*u.mol/u.s))

% custom display
v3 = str2u('1.23 M');
assert(isequal(v3, 1.23*u.M))

%% Cellstr input

% 2 different units
str = strcat('1.432',{'kg','m'});

v1 = str2u(str);
assert(isequal(v1, 1.432*[u.kg u.m]))

% 3 different units
str2 = strcat('1.432',{'kg','m','s'});

v2 = str2u(str2);
assert(isequal(v2, 1.432*[u.kg u.m u.s]))

%% Exponential notation

str = '1e-5 m';
v1 = str2u(str);
v2 = 1e-5*u.m;

assert(isequal(v1,v2))

%% NaN input

v1 = str2u('NaN');
v2 = str2u('NaN m');

assert(isequaln(v1,NaN))
assert(isequaln(v2,NaN*u.m))

%% Parentheses - FAILS

warning('Parentheses currently not supported')


% parentheses currently not supported
str = '(1/2) m';
%str2u(str)   % FAILS


