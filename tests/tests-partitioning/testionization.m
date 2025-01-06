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

% diprotic acid with one small pKa --> same result as monoprotic base
[fn, fani, fcat] = ionized_fractions(7,[],[-Inf 7]);
assert(fn == 0.5 && fani == 0 && fcat == 0.5)

%% zwitter ion

% check symmetric case, and the non-trivial mass balance
[fn, fani, fcat] = ionized_fractions(7,5,9);
assert(fani == fcat)                 
assert(abs(fn+fani+fcat-1) < 1e-10)

% very weak acid/base --> should behave like neutral
[fn, fani, fcat] = ionized_fractions(7,-Inf,Inf);
assert(fn == 1 && fani == 0 && fcat == 0)

% equilibrium at pKa
[fn, fani, fcat] = ionized_fractions(7,7,7);
assert(fn == fani && fn == fcat)

%% complex scenarios compared to httk R package

% zwitter ion with two acidic pKa
[fn, fani, fcat] = ionized_fractions(7,[4 8],6);
fn_ref   = 0.08333;
fani_ref = 0.9166;
fcat_ref = 8.333e-05;
assert(all(abs([fn fani fcat]-[fn_ref fani_ref fcat_ref]) < 1e-5)) 

% zwitter ion with two basic pKa
[fn, fani, fcat] = ionized_fractions(7,6,[5 8]);
fn_ref   = 0.8326;
fani_ref = 0.08326;
fcat_ref = 0.0841;
assert(all(abs([fn fani fcat]-[fn_ref fani_ref fcat_ref]) < 4e-4)) 


