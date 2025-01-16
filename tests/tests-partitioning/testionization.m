% test ionized_fractions.m

%% neutral

[fn, fani, fcat] = ionized_fractions(7,[],[]);
assert(fn == 1 && fani == 0 && fcat == 0)

%% acid

% equilibrium at pH = pKa
[fn, fani, fcat] = ionized_fractions(7,7,[]);
assert(fn == 0.5 && fani == 0.5 && fcat == 0)

% very weak acid --> only neutral drug
[fn, fani, fcat] = ionized_fractions(7,Inf,[]);
assert(fn == 1 && fani == 0 && fcat == 0)

%% base

% equilibrium at pH = pKa
[fn, fani, fcat] = ionized_fractions(7,[],7);
assert(fn == 0.5 && fani == 0 && fcat == 0.5)

% very weak base --> only neutral drug
[fn, fani, fcat] = ionized_fractions(7,[],-Inf);
assert(fn == 1 && fani == 0 && fcat == 0)

%% diprotic acid

% diprotic acid with one large pKa --> same result as monoprotic acid
[fn, fani, fcat] = ionized_fractions(7,[7 Inf],[]);
assert(fn == 0.5 && fani == 0.5 && fcat == 0)

%% diprotic base

% diprotic base with one small pKa --> same result as monoprotic base
[fn, fani, fcat] = ionized_fractions(7,[],[-Inf 7]);
assert(fn == 0.5 && fani == 0 && fcat == 0.5)

%% ampholyte

% check symmetric case, and the non-trivial mass balance
[fn, fani, fcat] = ionized_fractions(7,9,5);
assert(fani == fcat)                 
assert(abs(fn+fani+fcat-1) < 1e-10)

% equilibrium at pKa
[fn, fani, fcat] = ionized_fractions(7,7,7);
assert(fn == fani && fn == fcat)

% equilibrium at pKa including zwitter ions
[fn, fani, fcat, fz] = ionized_fractions(7,7,7,1);
fnz = fn+fz;
assert(fnz == fani && fnz == fcat && fn == fz)

%% complex scenarios compared to httk R package
% Nomenclature and behaviour of httk::calc_ionization() is a bit different:
% In compphysiol, any cationic pKa must be less than any anionic pKa, 
% whereas in httk, they are simply reordered to fulfill this property. 
% Therefore, care must be taken to specify pKas in a consistent way.

% zwitter ion with two cationic pKa values
[fn, fani, fcat] = ionized_fractions(7,8,[4 6]);
fn_ref   = 0.8333;
fani_ref = 0.08333;
fcat_ref = 0.08341;
assert(all(abs([fn fani fcat]-[fn_ref fani_ref fcat_ref]) < 4e-5)) 

% zwitter ion with two anionic pKa values
[fn, fani, fcat] = ionized_fractions(7,[6 8],5);
fn_ref   = 0.08326;
fani_ref = 0.9159;
fcat_ref = 0.0008326;
assert(all(abs([fn fani fcat]-[fn_ref fani_ref fcat_ref]) < 1e-5)) 


