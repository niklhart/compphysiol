% Tests for the DimVar class

%% Equivalent definitions
v1a = scd(1000*u.m,'km');
v1b = str2u('1 km');
v1c = u.km;

assert(isequal(v1a,v1b))
assert(isequal(v1a,v1c))


%% Arithmetics on scalars

% plus/ uplus methods 
v1a = u.kg + u.kg;
v1b = 2*u.kg;
assert(isequal(v1a,v1b))
assert(isequal(v1a,+v1a))

% minus / uminus methods
v2a = u.h - u.h;
v2b = 0*u.h;

assert(isequal(v2a,v2b))
assert(isequal(v2a,v2a+(-v2a)))

% quotients (custom units removed)
v3 = 1/u.min;

assert(istype(v3,'1/Time'))

% products / power / sqrt (custom units removed)
v4a = u.h;
v4b = u.h^2;

assert(v3*v4a == 60)
assert(isequal(v4a*v4a,v4b))
assert(isequal(sqrt(v4b),scd(v4a)))

% error for inconsistent units
assertError(@() u.kg+u.m)
assertError(@() u.mol-u.h)

% sign
v5a = 3*u.m;
v5b = -3*u.m;
v5c = 0*u.m;

assert(sign(v5a) == 1)
assert(sign(v5b) == -1)
assert(sign(v5c) == 0)


%% Non-scalar DimVars (consistent units)

% Concatenation, base unit first
v1a = [u.m u.km];
v1b = [u.m 1000*u.m];

assert(isequal(v1a,v1b))

% Concatenation, non-base unit first
v2a = [u.h u.s];
v2b = [u.h u.h/3600];

assert(isequal(v2a,v2b))

% different vector orientations
v3a = [u.h  u.s];
v3b = [u.h; u.s];

assert(isequal(v3a',v3b))
assert(isequal(v3a(:),v3b))
assert(isequal(reshape(v3a,[],1),v3b))

% matrix operations
vm = [0 5 9;0 10 1]*u.m;
vv = [0;0;5;10;9;1]*u.m;
assert(nnz(vm) == 4)
assert(isequal(size(vm), [2 3]))
assert(isequal(vm(:),vv))

% permute 
assert(isequal(permute(vm,[2 1]), [0 0; 5 10; 9 1]*u.m))

% colon operator
v4a = 0*u.min:u.min:u.h;
v4b = (0:60)*u.min;

assert(isequal(v4a,v4b))
assertError(@() u.min:u.h)

%% Arithmetics on vectors / matrices

vm = [0 5 9;0 10 1]*u.m;
vv = [0;0;5;10;9;1]*u.m;

% sum / cumsum ------------------------------------
assert(isequal(sum(vm),   [0,15,10]*u.m))
assert(isequal(sum(vm,2), [14;11]*u.m))
assert(isequal(sum(vv),   25*u.m))
assert(isequal(sum(vv,2), vv))

assert(isequal(cumsum(vv),   [0;0;5;15;24;25]*u.m))
assert(isequal(cumsum(vv,2), vv))
assert(isequal(cumsum(vm),   [0 5 9;0 15 10]*u.m))
assert(isequal(cumsum(vm,2), [0 5 14;0 10 11]*u.m))

% trapz / cumtrapz ---------------------------------


% max / min ----------------------------------------
v1 = 2*u.m;
v2 = 0*u.m;
v3 = []*u.m;
v4 = [0,2]*u.m;
v5 = [4,1]*u.m;
v6 = 3*u.kg;

% correct usage
assert(isequal(max(v1,v2), 2*u.m))
assert(isequal(max(v4),    2*u.m))
assert(isequal(max(v3),    []*u.m))
assert(isequal(max(v4,v5), [4,2]*u.m))
assert(isequal(max(v1,v5), [4,2]*u.m))
assert(isequal(max(v1,v3), []*u.m))
assert(isequal(max(v2,v3), []*u.m))
assert(isequal(max(vm),    [0 10 9]*u.m))
assert(isequal(max(vv),    10*u.m))

assert(isequal(min(v1,v2), 0*u.m))
assert(isequal(min(v4),    0*u.m))
assert(isequal(min(v3),    []*u.m))
assert(isequal(min(v4,v5), [0,1]*u.m))
assert(isequal(min(v1,v5), [2,1]*u.m))
assert(isequal(min(v1,v3), []*u.m))
assert(isequal(min(v2,v3), []*u.m))
assert(isequal(min(vm),    [0 5 1]*u.m))
assert(isequal(min(vv),    0*u.m))

% error throwing
assertError(@() max(v1,v6))
assertError(@() max(v3,v4))

assertError(@() min(v1,v6))
assertError(@() min(v3,v4))

% mean / median ------------------------------------


% norm ---------------------------------------------


% circshift ----------------------------------------
assert(isequal(circshift(vm, 1), [0 10 1;0 5 9]*u.m))
assert(isequal(circshift(vm, [1 1]), [1 0 10;9 0 5]*u.m))
assert(isequal(circshift(vv, 1), [1;0;0;5;10;9]*u.m))

% trace --------------------------------------------
vs = [1 0; 5 10]*u.m;
assert(trace(vs) == 11*u.m)

%% compatibility

% assert(compatible(u.m/u.s,u.km/u.h)) compatible doesn't return a value
assertError(@() compatible(u.m/u.s,u.kg/u.h))
assertError(@() compatible(1*u.m, 2))

assert(iscompatible(u.m/u.s,u.km/u.h))
assert(~iscompatible(u.m/u.s,u.kg/u.h))
assert(~iscompatible(1*u.m, 2))

%% conversion

% conversion to double
v1 = u.km;
assert(double(v1) == 1000)        % internal units
assert(displayingvalue(v1) == 1)  % display units

% logical
v2 = 0*u.km;
v3 = -1*u.km;
assert(logical(v1) == true)
assert(logical(v2) == false)
assert(logical(v3) == true)

% string
vm = [0 5 9;0 10 1]*u.m;
vv = [0;0;5;10;9;1]*u.m;
assert(isequal(string(v1), "1 km"))
assert(isequal(string(vm), ["0 m" "5 m" "9 m"; "0 m" "10 m" "1 m"]))
assert(isequal(string(vv), ["0 m";"0 m";"5 m";"10 m";"9 m";"1 m"]))

% categorical
assert(isequal(categorical(v1), categorical("1000 m")))
assert(isequal(categorical(vm), categorical(["0 m" "5 m" "9 m"; "0 m" "10 m" "1 m"])))
assert(isequal(categorical(vv), categorical(["0 m";"0 m";"5 m";"10 m";"9 m";"1 m"])))

% u2num
v4 = u.km^2;
assert(u2num(v1) == 1000)
assert(u2num(v1, u.km) == 1)
assert(u2num(v2) == 0)
assert(u2num(v3) == -1000)
assert(isequal(u2num(vm), [0 5 9;0 10 1]))
assertError(@() u2num(v4, u.km))

% u2duration
v5 = 2*u.s;
v6 = 2*u.sec;
v7 = 2*u.m;
v8 = 2*u.min;
v9 = 2*u.h;
v10 = 2*u.d;
v11 = 2*u.year;
v12 = [0 100 6]*u.s;
assert(u2duration(v5) == seconds(2))
assert(u2duration(v6) == seconds(2))
assert(u2duration(v8) == minutes(2))
assert(u2duration(v9) == hours(2))
assert(u2duration(v10) == days(2))
%assert(u2duration(v11) == years(2)) %TODO: Gregorian years
assert(isequal(u2duration(v12), [seconds(0), seconds(100), seconds(6)]))
assertError(@() u2duration(v1))
assertError(@() u2duration(v7))
assertError(@() u2duration(v5.^2))


%% is* functions

v1 = u.mm;
v2 = [v1 v1];
v0 = v1([]);
vinf = Inf*v1;
vnan = NaN*v1;
v3 = 0.1*u.m;
v4 = 1*u.m;

% isscalar
assert( isscalar(v1))
assert(~isscalar(v2))
assert(~isscalar(v0))

% isempty
assert( isempty(v0))
assert(~isempty(v1))
assert(~isempty(v2))

% istype
assert(istype(v1,'Length'))
assert(~istype(v1,'Mass'))

% issorted
assert(issorted(v1))
assert(issorted(v2))
assert(issorted(vinf))
assert(issorted(v0))
assert(~issorted([u.km u.m]))

% isfinite / isinf / isnan
assert( isfinite(v1))
assert(~isfinite(vinf))
assert(~isfinite(vnan))

assert(~isinf(v1))
assert( isinf(vinf))
assert(~isinf(vnan))

assert(~isnan(v1))
assert(~isnan(vinf))
assert( isnan(vnan))

% isnumeric (always true for DimVar)
assert(isnumeric(v1))
assert(isnumeric(v2))
assert(isnumeric(v0))
assert(isnumeric(vinf))
assert(isnumeric(vnan))

% isreal
assert(isreal(v0))
assert(isreal(v1))
assert(isreal(v2))
assert(isreal(v3))
assert(isreal(v4))
assert(isreal(vinf))
assert(isreal(nan))


%% Validators

vp = u.m;
vn = -vp;
v0 = 0*vp;

mustBeGreaterThan(vp,vn)
assertError(@()mustBeGreaterThan(vp,vp))
assertError(@()mustBeGreaterThan(vn,vp))

mustBeGreaterThanOrEqual(vp,vn)
mustBeGreaterThanOrEqual(vp,vp)
assertError(@()mustBeGreaterThanOrEqual(vn,vp))

mustBeLessThan(vn,vp)
assertError(@()mustBeLessThan(vp,vn))
assertError(@()mustBeLessThan(vp,vp))

mustBeLessThanOrEqual(vn,vp)
mustBeLessThanOrEqual(vp,vp)
assertError(@()mustBeLessThanOrEqual(vp,vn))

mustBeNegative(vn)
assertError(@()mustBeNegative(vp))
assertError(@()mustBeNegative(v0))

mustBeNonnegative(v0)
mustBeNonnegative(vp)
assertError(@()mustBeNonnegative(vn))

mustBePositive(vp)
assertError(@()mustBePositive(vn))
assertError(@()mustBePositive(v0))

mustBeNonpositive(v0)
mustBeNonpositive(vn)
assertError(@()mustBeNonpositive(vp))

mustBeNonzero(vp)
mustBeNonzero(vn)
assertError(@()mustBeNonzero(v0))


%% Complex numbers arithmetics


%% Complicated functions

% unique
v1a = [4 7 2 4]*u.km;
v1b = [4 7 2]*u.km;
v1c = [2 4 7]*u.km;

assert(isequal(unique(v1a),v1c))
assert(isequal(unique(v1a,'stable'),v1b))
assert(isequal(unique(v1a,'sorted'),v1c))

% trapz and cumtrapz
y = [4 7 2 4]'*u.km;
x = 5*u.min;

I1a = trapz(x,y);
I1b = x*trapz(1,y);
I1c = unitsOf(y)*trapz(x,double(y));
I1d = x*unitsOf(y)*trapz(double(y));

assert(isequal(I1a,I1b))
assert(isequal(I1a,I1c))
assert(isequal(I1a,I1d))

I2a = cumtrapz(x,y);
I2b = x*cumtrapz(1,y);
I2c = unitsOf(y)*cumtrapz(x,double(y));
I2d = x*unitsOf(y)*cumtrapz(double(y));

assert(isequal(I2a,I2b))
assert(isequal(I2a,I2c))
assert(isequal(I2a,I2d))

%% Concatenation

v1 = [1 2 3]*u.m;
v2 = [4 5 6]*u.m;

assert(isequal(cat(1, v1, v2), [1 2 3; 4 5 6]*u.m))
assert(isequal(cat(2, v1, v2), [1 2 3 4 5 6]*u.m))


%% Power / mpower

v1 = 2*u.m;
v2 = 0*u.m;
v3 = -2*u.m;
v4 = 2*(1/u.m);

assert(v1.^2 == 4*u.m^2)
assert(v1.^-2 == 0.25*(1/u.m^2))
assert(v1.^0 == 1)

assert(v2.^2 == 0*u.m^2)
assert(v3.^2 == 4*u.m^2)
assert(v4.^2 == 4*(1/u.m^2))

assertError(@() v1.^v1)

vm = [1 2; 3 4]*u.m;

assert(isequal(v1.^2,  4*u.m^2))
assertError(@() vm^v1)


%% Num2str tests

v1 = 2*u.m;
v2 = -2*u.m;
v3 = 2*(1/u.m);
v4 = [-2 2]*u.m;
v5 = []*u.m;

% correct usage
assert(isequal(num2str(v1), '2 m'))
assert(isequal(num2str(v2), '-2 m'))
assert(isequal(num2str(v3), '2 1/m'))
assert(isequal(num2str(v4), '-2  2 m'))
assert(isequal(num2str(v5), '[] m'))


%% Displayparser

% scalar, property units
[val1,~,ustr1] = displayparser(u.h);
assert(isequal(val1,1) && isequal(ustr1,'h'))

% scalar, custom display unit
[val2,~,ustr2] = displayparser(scd(u.m/u.s,'km/h'));
assert(abs(val2-3.6) < 1e-10 && isequal(ustr2,'km/h'))

% matrix, property unit
[val3,~,ustr3] = displayparser(ones(2)*u.h);
assert(isequal(val3,ones(2)) && isequal(ustr3,'h'))

% empty, property unit
[val4,~,ustr4] = displayparser([]*u.h);
assert(isequal(val4,[]) && isequal(ustr4,'h'))


%% ldivide / mldivide
v1 = [-2, 2]*u.m;
v2 = [2, -2]*u.m;
v3 = 0*u.m;
v4 = [2, 4];

assert(isequal(v1.\v2, [-1 -1]))
assert(isequal(v1.\v4, [-1 2]*(1/u.m)))
assert(isequal(v1.\v3, [0 0]))
assert(isequal(v4.\v2, [1, -0.5]*u.m))

assert(isequal(v1\v2, [-1 1; 0 0]))
assert(isequal(v1\v3, [0; 0]))
assert(isequal(v1\v4, [-1 -2; 0 0]*(1/u.m)))
assert(isequal(v4\v1, [0 0; -0.5 0.5]*u.m))
