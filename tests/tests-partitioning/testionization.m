% test ionized_fractions.m

%% neutral

[fn, fani, fcat] = ionized_fractions('neutral',[],7);
assert(fn == 1 && fani == 0 && fcat == 0)

%% acid

% equilibrium at pH = pKa
[fn, fani, fcat] = ionized_fractions('acid',7,7);
assert(fn == 0.5 && fani == 0.5 && fcat == 0)

% very weak acid --> only neutral drug
[fn, fani, fcat] = ionized_fractions('acid',Inf,7);
assert(fn == 1 && fani == 0 && fcat == 0)

%% base

% equilibrium at pH = pKa
[fn, fani, fcat] = ionized_fractions('base',7,7);
assert(fn == 0.5 && fani == 0 && fcat == 0.5)

% very weak base --> only neutral drug
[fn, fani, fcat] = ionized_fractions('base',-Inf,7);
assert(fn == 1 && fani == 0 && fcat == 0)

%% diprotic acid

% diprotic acid with one large pKa --> same result as monoprotic acid
[fn, fani, fcat] = ionized_fractions('diprotic acid',[Inf 7],7);
assert(fn == 0.5 && fani == 0.5 && fcat == 0)

%% diprotic base

% diprotic acid with one small pKa --> same result as monoprotic base
[fn, fani, fcat] = ionized_fractions('diprotic base',[7 -Inf],7);
assert(fn == 0.5 && fani == 0 && fcat == 0.5)

%% zwitter ion

% check symmetric case, and the non-trivial mass balance
[fn, fani, fcat] = ionized_fractions('zwitter ion',[5 9],7);
assert(fani == fcat)                 
assert(abs(fn+fani+fcat-1) < 1e-10)

% very weak acid/base --> should behave like neutral
[fn, fani, fcat] = ionized_fractions('zwitter ion',[-Inf Inf],7);
assert(fn == 1 && fani == 0 && fcat == 0)
