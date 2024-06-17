% tests for Covariates function

%% correct usage: property-value pairs
p1 = Covariates('Species','human','sex','male','BH',1.80*u.m);
assert(isa(p1, 'Physiology'))
assert(strcmp(p1.db.species.Value, 'human'))
assert(strcmp(p1.db.species.Source, 'Covariate'))
assert(strcmp(p1.db.species.Assumption, 'manually set'))
assert(strcmp(p1.db.sex.Value, 'male'))
assert(p1.db.BH.Value == 1.80*u.m)

%% correct usage: stratified covariate
p2 = Covariates('Species','human','Qblo|liv',5*u.L/u.h);
assert(isa(p2, 'Physiology'))
assert(strcmp(p2.db.species.Value, 'human'))
assert(strcmp(p2.db.Qblo.Tissue, 'liv'))
assert(strcmp(p2.db.Qblo.Source, 'Covariate'))
assert(strcmp(p2.db.Qblo.Assumption, 'manually set'))
assert(p2.db.Qblo.Value == 5*u.L/u.h)

%% correct usag: table as a single argument
Name = {'Species'; 'sex'; 'BH'};
Value = {'human'; 'male'; 1.80*u.m};
p3 = Covariates(table(Name, Value));
assert(isa(p3, 'Physiology'))
assert(strcmp(p3.db.species.Value, 'human'))
assert(strcmp(p3.db.sex.Value, 'male'))
assert(p3.db.BH.Value == 1.80*u.m)

%% wrong table columns
Name = {'Species'; 'sex'; 'BH'};
Value = {'human'; 'male'; 1.80*u.m};
assertError(@() Covariates(table(Name)), ...
    'PBPK:Covariates:wrongInputTableColumns');
assertError(@() Covariates(table(Name, Name)), ...
    'PBPK:Covariates:wrongInputTableColumns');
% no error expected in case of additional columns:
Name1 = Name;
p4 = Covariates(table(Name, Value, Name1));

%% missing value in a property-value pair
assertError(@() Covariates('Species','human','sex'), ...
    'PBPK:Covariates:missingValue')
