% Testing data import functions 

testDirectory = fileparts(mfilename('fullpath'));

%% Test covariate tables

% Value column --> ensure that it is read as char and that no rows are
%                  skipped
file = fullfile(testDirectory,'..','data-for-testing','Test_COVARIATES.csv');

opts = detectImportOptions(file);
opts.VariableTypes{2} = 'char';  % read VALUE column as 'char'
opts.DataLines(1) = 2;           % don't skip any data row

data = ImportableData(file, opts);
data.setattr('Name','Covariate list');
data.setattr('[Value]','UNIT');
data.table = data.table(:,{'Name','COVARIATE','VALUE','UNIT'}); % for aesthetic reasons only
data.maprow('Covariate list','Covariate','Name','COVARIATE');
expid = import(data,'silent');

refphys = Covariates('species','human','sex','female','age',35*u.year,...
                'BH',1.8*u.m,'BW',70*u.kg);
assert(isequal(expid.physiology,refphys))

% One column per Covariate, multiple IDs
file2 = fullfile(testDirectory,'..','data-for-testing','Test_COVARIATES_POP.csv');
data2 = ImportableData(file2);
data2.flagcov('BW', 'BW');
data2.flagcov('Age','age');
data2.flagcov('sex','sex');
data2.flagcov('BH', 'BH');
expid2 = import(data2,'silent');
physarr = [expid2.physiology];

assert(iscolumn(expid2))
assert(all(hasrecord(physarr,'sex')))
assert(all(hasrecord(physarr,'age')))
assert(all(hasrecord(physarr,'BW')))
assert(all(hasrecord(physarr,'BH')))

%% Test different dosing formats

file = fullfile(testDirectory,'..','data-for-testing','Test_DOSING.csv');

data = ImportableData(file);
data.setattr('Name','TYPE');
data.setattr('Compound','DrugX');
data.maprow('Oral','Oral dosing');
data.maprow('Infusion','Infusion dosing','Target','iv');
data.maprow('Bolus','Bolus dosing','Target','iv');

expid = import(data,'silent');
impdos = expid.dosing;

refdos = Bolus('DrugX',[4 8]*u.h, [40 30]*u.mg,'iv') ...
            + Infusion('DrugX',[1 2]*u.h, [15 20]*u.mg,[30 60]*u.min,'iv') ...
            + Oral('DrugX',[0 1]*u.h,[15 20]*u.mg);

assert(isequal(impdos,refdos))

%% Different ways of encoding units in the dataset

% Units encoded in VALUE column
file = fullfile(testDirectory,'..','data-for-testing','Test_UNITS_DimVarColumns.csv');
data = ImportableData(file,'Delimiter',',');
data.maprow('Warfarin plasma concentration','Record','Site','pla');
testid = import(data,'silent');

% Units encoded in column headers
file2 = fullfile(testDirectory,'..','data-for-testing','Test_UNITS_InHeader.csv');
data2 = ImportableData(file2);
data2.maprow('Warfarin plasma concentration','Record','Site','pla');
testid2 = import(data2,'silent');

% Units encoded in a column UNITS, "map-then-set"
file3 = fullfile(testDirectory,'..','data-for-testing','Test_UNITS_ExtraColumns.csv');
data3 = ImportableData(file3);
data3.maprow('Warfarin plasma concentration','Record','Site','pla');
data3.setattr('[Time]','TIME_UNITS');
data3.setattr('[Value]','VALUE_UNITS');
testid3 = import(data3,'silent');

% Units encoded in a column UNITS, "set-then-map"
file4 = fullfile(testDirectory,'..','data-for-testing','Test_UNITS_ExtraColumns.csv');
data4 = ImportableData(file4);
data4.setattr('[Time]','TIME_UNITS');
data4.setattr('[Value]','VALUE_UNITS');
data4.maprow('Warfarin plasma concentration','Record','Site','pla');
testid4 = import(data4,'silent');

% Units hard-coded in mapping (column UNITS is not mapped, i.e. ignored)
file5 = fullfile(testDirectory,'..','data-for-testing','Test_UNITS_Unitless.csv');
data5 = ImportableData(file5);
data5.maprow('Warfarin plasma concentration','Record',...
    'Site','pla',...
    '[Time]','h',...
    '[Value]','ug/L');
testid5 = import(data5,'silent');

assert(isequal(testid,testid2,testid3,testid4,testid5))

