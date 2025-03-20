% Test methods of the Individual class

%% Constructor - correct usage

% One individual
ind1 = Individual('Virtual');

assert(isequal(class(ind1), 'Individual'))
assert(isequal(ind1.type, 'Virtual individual'))
assert(isequal(ind1.name, []))
assert(isobject(ind1.dosing))
assert(isobject(ind1.physiology))
assert(isobject(ind1.drugdata))
assert(isa(ind1.dosing, 'EmptyDosing'))
assert(isempty(ind1.physiology.name))
assert(isempty(ind1.drugdata.name))

% Individual array
indarr = Individual('Virtual',2);

assert(isequal(size(indarr), [2 1]))

assert(isequal(class(indarr(1)), 'Individual'))
assert(isequal(indarr(1).type, 'Virtual individual'))
assert(isequal(indarr(1).name, []))
assert(isobject(indarr(1).dosing))
assert(isobject(indarr(1).physiology))
assert(isobject(indarr(1).drugdata))
assert(isequal(class(indarr(1).dosing), 'EmptyDosing'))
assert(isempty(indarr(1).physiology.name))
assert(isempty(indarr(1).drugdata.name))

assert(isequal(class(indarr(2)), 'Individual'))
assert(isequal(indarr(2).type, 'Virtual individual'))
assert(isequal(indarr(2).name, []))
assert(isobject(indarr(2).dosing))
assert(isobject(indarr(2).physiology))
assert(isobject(indarr(2).drugdata))
assert(isequal(class(indarr(2).dosing), 'EmptyDosing'))
assert(isempty(indarr(2).physiology.name))
assert(isempty(indarr(2).drugdata.name))

%% Test simple set methods

ind1 = Individual('Virtual');

%type
ind1.type = 'Experimental data';
assert(strcmp(ind1.type, 'Experimental data'))

% workaround because there is no generic set method for Individual objects
% TODO: add generic set/get methods?
assertError(@() setType(ind1, 'abc'), 'MATLAB:unrecognizedStringChoice')

%name
ind1.name = "ind1";
assert(strcmp(ind1.name, 'ind1'))
ind1.name = 123;
assert(strcmp(ind1.name, '123'))

%% Test set/get.drugdata

ind1 = Individual('Virtual');

% TODO: is this a good idea to use drugA and drugB from the database?
ind1.drugdata = loaddrugdata('drugB','species','human');
assert(strcmp(ind1.drugdata.name, 'drugB'))
assert(strcmp(ind1.drugdata.class, 'sMD'))
assert(strcmp(ind1.drugdata.subclass, 'base'))
assert(abs(ind1.drugdata.db.MW.Value/(u.kg/u.mol) - 0.2343) < 1e-04)
% TODO: Is it necessary to check other parameters of drugdata? I assume
% that all parameters are set in the same way and it is enough to check
% only one.

% empty
ind1.drugdata = [];
assert(isempty(ind1.drugdata))

% wrong object type
assertError(@() setDrugdata(ind1, 'abc'), 'compphysiol:Individual:setdrugdata:wrongObjType')

% with AutoAssignDrugData option
setoptcompphysiol('AutoAssignDrugData', true)

ind1.drugdata = [];
ind1.dosing = Oral('drugB', 0*u.h, 50*u.mg);
assert(strcmp(ind1.drugdata.name, 'drugB'))
assert(strcmp(ind1.drugdata.class, 'sMD'))
assert(strcmp(ind1.drugdata.subclass, 'base'))
assert(abs(ind1.drugdata.db.('MW').Value - 0.2343*(u.kg/u.mol)) < 1e-04*(u.kg/u.mol))

% AutoAssignDrugData + AutoFilterDrugData options
setoptcompphysiol('AutoFilterDrugData', true)
ind1.drugdata = [];
ind1.physiology = Physiology('human35f');
assert(strcmp(ind1.drugdata.name, 'drugB'))
assert(strcmp(ind1.drugdata.class, 'sMD'))
assert(strcmp(ind1.drugdata.subclass, 'base'))
assert(abs(ind1.drugdata.db.('MW').Value - 0.2343*(u.kg/u.mol)) < 1e-04*(u.kg/u.mol))

setoptcompphysiol('AutoFilterDrugData', false)
setoptcompphysiol('AutoAssignDrugData', false)

% only AutoFilterDrugData option
setoptcompphysiol('AutoFilterDrugData', true)
assert(isempty(ind1.drugdata))
assertWarning(@() ind1.drugdata)
% TODO: check for warning
setoptcompphysiol('AutoFilterDrugData', false)


%% Test set.physiology

ind1 = Individual('Virtual');

% correct usage
% TODO: test Physiology object similar to drugA/drugB
ind1.physiology = Physiology('human35f');
assert(strcmp(ind1.physiology.name, 'human35f'))
assert(ind1.physiology.db.('BW').Value == 60*u.kg)

% empty
ind1.physiology = [];
assert(isempty(ind1.physiology))

% wrong object type
assertError(@() setPhysiology(ind1, 'abc'), 'compphysiol:Individual:setphysiology:wrongObjType')


%% Test set.sampling

ind1 = Individual('Virtual');

% correct usage
s = Sampling([0;1;2]*u.h,PBPKobservables);
ind1.sampling = s;
assert(isequal(ind1.sampling, s))

% wrong object type
assertError(@() setSampling(ind1, 'abc'), 'compphysiol:Individual:setsampling:wrongObjType')


%% Test set.observation

ind1 = Individual('Virtual');

% TODO: correct usage

% empty
ind1.observation = [];
assert(isempty(ind1.observation))

% wrong object type
assertError(@() setObservation(ind1, 'abc'), 'compphysiol:Individual:setobservation:wrongObjType')

%% Test set.model

ind1 = Individual('Virtual');

% correct usage
ind1.model = test_model();
assert(isa(ind1.model, 'AnalyticalModel'))
assert(strcmp(ind1.model.name, 'test_model'))

% empty
ind1.model = [];
assert(isempty(ind1.model))

% wrong object type
assertError(@() setModel(ind1, 'abc'), 'compphysiol:Individual:setmodel:wrongObjType')

%% Test cloning


%% Test conversion methods

% exp2sim
[testDirectory] = fileparts(mfilename('fullpath'));
file = fullfile(testDirectory,'..','data-for-testing','Test_UNITS_DimVarColumns.csv');
data = ImportableData(file,'Delimiter',',');
data.maprow('Species','Covariate');
data.maprow('Warfarin oral dose','Oral dosing','Compound','Warfarin');
data.maprow('Warfarin plasma concentration','Record','Site','pla');
expid = import(data,'silent');

% exp2sim correct usage
sim = exp2sim(expid);
assert(isa(sim, 'Individual'))
assert(strcmp(sim.type, 'Virtual individual'))
assert(strcmp(sim.name, 'ID 1'))
assert(isa(sim.sampling, 'SamplingSchedule'))
assert(isequal(sim.sampling.Time, [0.5 1 2 4 8 12 24 32]'*u.h))

% exp2sim: virtual individual input
expid.type = 'Virtual individual';
assertError(@() exp2sim(expid), 'compphysiol:Individual:exp2sim:needExperimentalData')

% sim2exp
vid = Individual('Virtual');

% sim2exp: no simulation
assertError(@() sim2exp(vid), 'compphysiol:Individual:checkSimulated:notSimulated')

% sim2exp correct usage
vid.model = test_model();
vid.sampling = Sampling([0 1 2]*u.h, Observable('MultiPK', ...
    {'A','B'},{'pla'}));

initialize(vid);
simulate(vid);

expdata = sim2exp(vid);
assert(isa(expdata, 'Individual'))
assert(strcmp(expdata.type, 'Experimental data'))
assert(isequal(expdata.observation.Time, [0 0 1 1 2 2]'*u.h))

% sim2exp: experimental data input
vid.type = 'Experimental data';
assertError(@() sim2exp(vid), 'compphysiol:Individual:sim2exp:needVirtualIndividual')

% TODO: sim2exp: no sampling schedule



%% Test plot
vid = Individual('Virtual',2);

% not simulated virtual individual
assertError(@() plot(vid), 'compphysiol:Individual:checkSimulated:notSimulated')

obs = Observable('MultiPK','A','pla');
vid(1).model = test_model();
vid(1).sampling = Sampling([0 0.5 1]*u.h, obs);
vid(2).model = test_model();
vid(2).sampling = Sampling([0 0.2 0.4 0.6 0.8 1]*u.h, obs);

initialize(vid);
simulate(vid);

% TODO: bug? Plotting requires vid.name set, even if only one individual is
% plotted
vid(1).name = 'Ind1';
vid(2).name = 'Ind2';

h = figure('Visible','off');
defaultPlots(vid, 'plasmaConcentration')
ax = findobj(get(h,'Children'), '-depth', 1, 'type', 'axes');
assert(length(ax) == 1)
assert(strcmp(ax.Title.String, 'Plasma concentration'))

% check plot contents. The plot is expected to have two lines, plotting two
% different subsets of values of the indiv.observation.table.
li = findobj(ax(1), 'Type', 'Line');
assert(strcmp(li(1).DisplayName, 'Ind2'))
assert(strcmp(li(2).DisplayName, 'Ind1'))

xplot1 = li(2).XData';
yplot1 = li(2).YData';
xplot2 = li(1).XData';
yplot2 = li(1).YData';

xobs1 = vid(1).observation.Time / u.h;
yobs1 = vid(1).observation.Value;
xobs2 = vid(2).observation.Time / u.h;
yobs2 = vid(2).observation.Value;

assert(isequal(xobs1,xplot1) && isequal(yobs1,yplot1), ...
    'Unexpected x/y values plotted.')
assert(isequal(xobs2,xplot2) && isequal(yobs2,yplot2), ...
    'Unexpected x/y values plotted.')

% TODO: other plot types

%% Test initialization

obs = Observable('MultiPK','A','pla');
indarr = Individual('Virtual',2);

% Model property not set
assertError(@() initialize(indarr))

indarr(1).model = test_model();
indarr(2).model = test_model();

% Sampling property not set
assertError(@() initialize(indarr))

indarr(1).sampling = Sampling([0 0.5 1]*u.h, obs);
indarr(2).sampling = Sampling([0 0.5 1]*u.h, obs);

initialize(indarr)

%% Test simulation

obs = Observable('MultiPK','A','pla');
indarr = Individual('Virtual',2);

% Individual is not initialized
assertError(@() simulate(indarr), 'compphysiol:Individual:checkInitialized:notInitialized')

indarr(1).model = test_model();
indarr(1).sampling = Sampling([0 0.5 1]*u.h, obs);
indarr(2) = clone(indarr(1));
indarr(1).name = 'Ind1';
indarr(2).name = 'Ind2';

initialize(indarr);
simulate(indarr)

assert(isa(indarr(1).observation, 'Record'))
assert(isa(indarr(2).observation, 'Record'))
assert(isequal(indarr(1).observation.Time, [0 0.5 1]'*u.h))
assert(isequal(indarr(2).observation.Time, [0 0.5 1]'*u.h))


%% Test estimation

% TODO

%% Test function getestimationwrapper

% TODO

%% Test helpers

obs = Observable('MultiPK','A','pla');
indarr = Individual('Virtual',2);
indarr(1).model = test_model();
indarr(1).sampling = Sampling([0 0.5 1]*u.h, obs);

% checkHandleDuplicates
indarr = Individual('Virtual',2);
indarr(1).model = test_model();
indarr(1).sampling = Sampling([0 0.5 1]*u.h, obs);
indarr(2) = indarr(1);

assertError(@() checkHandleDuplicates(indarr), ...
    'compphysiol:Individual:checkHandleDuplicates:handleDuplicates')

indarr(2) = clone(indarr(1));
checkHandleDuplicates(indarr)

% issimid/isexpid
indarr(2).type = 'Experimental data';
assert(isequal(issimid(indarr), [1;0]))
assert(isequal(isexpid(indarr), [0;1]))

% isinitialized/issimulated
assert(isequal(isinitialized(indarr), [0;0]))
initialize(indarr(1));
assert(isequal(isinitialized(indarr), [1;0]))

assert(isequal(issimulated(indarr), [0;0]))
simulate(indarr(1));
assert(isequal(issimulated(indarr), [1;0]))

%% Display

% individuals array
ind1 = Individual('Virtual',2);
obs = Observable('MultiPK','A','pla');
ind1(1).model = test_model();
ind1(1).sampling = Sampling([0 0.5 1]*u.h, obs);
ind1(2).model = test_model();
ind1(2).sampling = Sampling([0 0.2 0.4 0.6 0.8 1]*u.h, obs);
assertEqualsDiary(@() disp(ind1), 'testindividual_disp1.txt');

% simulated individual
obs = Observable('MultiPK','A','pla');
ind2 = Individual('Virtual');
ind2.model = test_model();
ind2.sampling = Sampling([0 0.5 1]*u.h, obs);
ind2.type = 'Virtual individual';
initialize(ind2);
simulate(ind2);
assertEqualsDiary(@() disp(ind2), 'testindividual_disp2.txt');

%% 
% helpers
% workaround because there is no generic set method for Individual objects
% TODO: add generic set/get methods?
function setType(ind, value)
    ind.type = value;
end

function setDrugdata(ind, value)
    ind.drugdata = value;
end

function setPhysiology(ind, value)
    ind.physiology = value;
end

function setSampling(ind, value)
    ind.sampling = value;
end

function setObservation(ind, value)
    ind.observation = value;
end

function setModel(ind, value)
    ind.model = value;
end