% Test for SimpleDosing methods and subclass constructors

%% Extraction of compounds working

dos1a = Bolus('X',0*u.h,5*u.mg,'iv') + Bolus('Y',0*u.h,6*u.mg,'iv');

cpd1a = compounds(dos1a);
assert(issetequal(cpd1a,{'X','Y'}))

%% Vectorized input matches summed schedules

% Test for bolus dosing, same doses
dos1a = Bolus('X',0*u.h,5*u.mg,'iv') + Bolus('X',1*u.h,5*u.mg,'iv');
dos1b = Bolus('X',[0 1]*u.h,5*u.mg,'iv');

assert(isequal(dos1a, dos1b))

% Test for bolus dosing, different doses
dos1c = Bolus('X',0*u.h,5*u.mg,'iv') + Bolus('X',1*u.h,10*u.mg,'iv');
dos1d = Bolus('X',[0 1]*u.h,[5 10]*u.mg,'iv');

assert(isequal(dos1c, dos1d))

% Test for infusion dosing, same doses
dos2a = Infusion('X',0*u.h,5*u.mg,1*u.h,'iv') + Infusion('X',2*u.h,5*u.mg,1*u.h,'iv');
dos2b = Infusion('X',[0 2]*u.h,5*u.mg,1*u.h,'iv');

assert(isequal(dos2a, dos2b))

% Test for infusion dosing, different doses
dos2c = Infusion('X',0*u.h,5*u.mg,1*u.h,'iv') + Infusion('X',2*u.h,10*u.mg,1*u.h,'iv');
dos2d = Infusion('X',[0 2]*u.h,[5 10]*u.mg,1*u.h,'iv');

assert(isequal(dos2c, dos2d))

% Test for oral dosing, same doses
dos3a   = Oral('X',0*u.h,5*u.mg) + Oral('X',1*u.h,5*u.mg);
dos3b   = Oral('X',[0 1]*u.h,5*u.mg);

assert(isequal(dos3a, dos3b))

% Test for oral dosing, different doses
dos3c   = Oral('X',0*u.h,5*u.mg) + Oral('X',1*u.h,10*u.mg);
dos3d   = Oral('X',[0 1]*u.h,[5 10]*u.mg);

assert(isequal(dos3c, dos3d))

%% Summation of doses at equal dosing times working

% Test for bolus dosing
dos1a = Bolus('X',1*u.h,5*u.mg,'iv') + Bolus('X',1*u.h,6*u.mg,'iv');
dos1b = Bolus('X',1*u.h,11*u.mg,'iv');

assert(isequal(dos1a, dos1b))

% Test for infusion dosing
dos2a = Infusion('X',0*u.h,5*u.mg,1*u.h,'iv') + Infusion('X',0*u.h,6*u.mg,1*u.h,'iv');
dos2b = Infusion('X',0*u.h,11*u.mg,1*u.h,'iv');

assert(isequal(dos2a, dos2b))

% Test for oral dosing
dos3a   = Oral('X',0*u.h,5*u.mg) + Oral('X',0*u.h,6*u.mg);
dos3b   = Oral('X',0*u.h,11*u.mg);

assert(isequal(dos3a, dos3b))

%% Filtering SimpleDosing objects

dos   = Oral('X',0*u.h,5*u.mg);
dosXO = filterDosing(dos,'X','Oral');
dosYO = filterDosing(dos,'Y','Oral');
dosXB = filterDosing(dos,'X','Bolus');
dosX_ = filterDosing(dos,'X',[]);
dos_O = filterDosing(dos,[],'Oral');
dos0  = EmptyDosing;

assert(isequal(dosXO, dos ))
assert(isequal(dosYO, dos0))
assert(isequal(dosXB, dos0))
assert(isequal(dosX_, dos ))
assert(isequal(dos_O, dos ))

%% Alternative syntax using table input working correctly

dos1a = Bolus('Warfarin',0*u.h,5*u.mg,'iv');
dos1b = Bolus(struct2table(struct(...
    'Compound','Warfarin',...
    'Time',    0*u.h,...
    'Dose',    5*u.mg,...
    'Target',  'iv')));
assert(isequal(dos1a,dos1b))

dos2a = Oral('Warfarin',0*u.h,5*u.mg);
dos2b = Oral(struct2table(struct(...
    'Compound',{{'Warfarin'}},...
    'Time',    0*u.h,...
    'Dose',    5*u.mg, ...
    'Formulation', {{''}})));
assert(isequal(dos2a,dos2b))

dos3a = Infusion('Warfarin',0*u.h,5*u.mg,1*u.h,'iv');
dos3b = Infusion(struct2table(struct(...
    'Compound','Warfarin',...
    'Tstart',    0*u.h,...
    'Dose',    5*u.mg,...
    'Duration',1*u.h,...
    'Target',  'iv')));
assert(isequal(dos3a,dos3b))

%% Common argument order errors 

% bolus dosing
f_bol = @() Bolus('Warfarin',5*u.mg,0*u.h,'iv');            % time <--> dose

% oral dosing
f_oral = @() Oral('Warfarin',5*u.mg,0*u.h);                 % time <--> dose

% infusion dosing
f_infus1 = @() Infusion('Warfarin',0*u.h,1*u.h,5*u.mg);     % dose <--> duration
f_infus2 = @() Infusion('Warfarin',0*u.h,u.mg/u.h,5*u.mg);  % dose <--> rate

% checking error messages
assertError(f_bol,'PBPK:typecheck:incompatibleUnits') 
assertError(f_oral,'PBPK:typecheck:incompatibleUnits') 
assertError(f_infus1,'PBPK:Infusion:doseDurationSwitched') 
assertError(f_infus2,'PBPK:Infusion:doseRateSwitched') 



