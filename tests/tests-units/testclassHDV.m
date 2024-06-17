% Tests for the HDV class

%% Subsetting

v1 = [u.m u.kg u.L];

% subsetting triggering conversion to DimVar

assert(isequal(v1(1),u.m))           % conversion to DimVar triggered

% subsetting not triggering conversion to DimVar

assert(isequal(v1(2:3),[u.kg u.L]))  % here, still HDV

% empty subsetting is valid and doesn't trigger conversion to DimVar
v1c = v1([]);
assert(isequal(size(v1c.exponents),   [0 9]))     
assert(isempty(v1c.customDisplay))              

assert(ischar(evalc('disp(v1c)')))   % check empty HDV display

%% Subassignment

v2 = [u.m u.kg u.L];
v2(2) = u.m;
assert(isequal(v2,[u.m u.m u.L]))  % no conversion to DimVar triggered
v2(2:3) = u.km;
assert(isequal(v2,[1 1000 1000]*u.m)) % conversion to DimVar triggered

%% Arithmetics

% plus / minus
v1a = [u.m   u.kg u.L];
v1b = [5*u.m 2*u.g u.m^3];

vab = v1a + v1b;
v  = [6*u.m 1.002*u.kg 1001*u.L];
assert(all(abs(double(vab - v)) < 1e-14))   % some arithmetic inaccuracy

assertError(@() v1a + u.m)
assertError(@() v1a + double(v1a))

% uplus / uminus
assert(isequal(v1a,+v1a))
assert(isequal(-v1a, 0*v1a - v1a))

% times / mtimes / rdivide / mrdivide
v2a = [u.m   u.kg u.L];
v2b = [1/u.m 1/u.kg 1/u.L];
v2c = u.h;

assert(all(v2a .* v2b == 1)) 
assert(all(v2a ./ v2a == 1)) 
assert(all(v2a .* v2a == v2a.^2)) 
assert(all(v2a .* v2a == [v2a(1)*v2a(1) v2a(2)*v2a(2) v2a(3)*v2a(3)])) 
assert(all(v2a  * v2c == [v2a(1)*v2c    v2a(2)*v2c    v2a(3)*v2c]))
assert(all(v2a  * 5   == [v2a(1)*5      v2a(2)*5      v2a(3)*5]))
assert(all(v2a  / v2c == v2a ./ v2c))
assert(all(v2a  / 5   == v2a ./ 5  ))

%% Compatibility assertions

v1 = [u.m  u.kg];
v2 = [u.kg  u.m];

assert(iscompatible(v1,v1))
assert(~iscompatible(v1,v2))
assert(~iscompatible(v1,u.m))
assert(~iscompatible(v1,5))

%% Conversions

% base units --> 1
v1 = [u.m  u.kg  u.s];
d1a = double(v1);
d1b = v1 ./ unitsOf(v1);

assert(all(d1a == 1))
assert(isequal(d1a,d1b))

%% Array shapes

% reshape / horzcat / vertcat / ctranspose methods
vmat = [u.m  u.L; 
        0*u.kg u.km];
vtrs = [u.m  0*u.kg; 
        u.L  u.km];
vcol = [u.m; 0*u.kg; u.L; u.km];
vrow = [u.m  0*u.kg  u.L  u.km];

assert(isequal(vmat(:), vcol))
assert(isequal(vrow', vcol))
assert(isequal(vmat', vtrs))
assert(isequal(reshape(vrow,2,2), vmat))
assert(isequal(reshape(vcol,2,2), vmat))

% size / numel / length /nnz methods
assert(isequal(size(vmat),[2 2]))
assert(numel(vmat) == 4)
assert(length(vmat) == 2)
assert(length(vcol) == 4)
assert(nnz(vmat) == 3)

% permute method
assert(isequal(permute(vmat,[2 1]),vtrs))
assert(isequal(permute(vrow,[2 1]),vcol))


%% Validators (is* functions)

vmat = [u.m  NaN*u.L; 
        u.kg NaN*u.km];
vemp = vmat([]);

% isnan
assert(isequal(isnan(vmat),[0 1; 0 1]))

% isempty
assert(~isempty(vmat))
assert(isempty(vemp))

% isnumeric
assert(isnumeric(vmat))
assert(isnumeric(vemp))

% isscalar  
% (HDV is never scalar, since it would be converted to DimVar otherwise)
assert(~isscalar(vmat))
assert(~isscalar(vemp))





