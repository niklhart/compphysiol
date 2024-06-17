% Tests for process_dosing function

%% Empty dosing handled correctly

dosing = EmptyDosing();
Id = struct;
X0 = unan(1,1);

[tincr, Xincr] = process_dosing(dosing, Id, X0); % arguments 2 & 3 not needed
assert(isempty(tincr) && isempty(Xincr))

%% Different types of single dose handled correctly

% dosing struct & initial values ("drug-free" syntax)
Id = struct;
Id.Bolus.iv.cmt     = 1;
Id.Bolus.iv.scaling = u.L;
Id.Oral.cmt         = 2;
Id.Infusion.iv.bag  = 3;
Id.Infusion.iv.rate = 4;

X0 = 0*[u.mg/u.L; u.mg; u.mg; u.mg/u.h]'; % row vector here, in contrast to models

% different dosing types
dos1 = Bolus('Warfarin',0*u.h,5*u.mg,'iv');
dos2 = Oral('Warfarin',0*u.h,5*u.mg);
dos3 = Infusion('Warfarin',0*u.h,5*u.mg,1*u.h,'iv');


% apply process_dosing function (the valid cases)
[t1,x1] = process_dosing(dos1, Id, X0);
[t2,x2] = process_dosing(dos2, Id, X0);
[t3,x3] = process_dosing(dos3, Id, X0);

% assertions about the valid cases
assert(t1 == 0*u.h && all(x1 == [5*u.mg/u.L X0(2:4)]))
assert(t2 == 0*u.h && all(x2 == [X0(1)   5*u.mg X0(3:4)]))
assert(all(t3 == [0;1]*u.h) && ...
    all(x3 == [X0(1:2) 5*u.mg 5*u.mg/u.h; X0(1:3) -5*u.mg/u.h],'all'))

% invalid case: misspecified site
dos4 = Bolus('Warfarin',0*u.h,5*u.mg,'strangesite');
assertError(@() process_dosing(dos4,Id,X0));

%% Multiple doses for same drug handled correctly

% dosing struct & initial values ("drug-free" syntax)
Id = struct;
Id.Bolus.ia.cmt     = 1;
Id.Bolus.ia.scaling = u.L;
Id.Oral.cmt         = 2;
Id.Infusion.iv.bag  = 3;
Id.Infusion.iv.rate = 4;

X0 = 0*[u.mg/u.L; u.mg; u.mg; u.mg/u.h]'; % row vector here, in contrast to models

% different dosing types (different site per route works, but different 
%                         sites within one route are not implemented yet)
dos1 = Bolus('Warfarin',[0 3]*u.h,5*u.mg,'ia');
dos2 = Oral('Warfarin',[0 3]*u.h,5*u.mg);
dos3 = Infusion('Warfarin',[0 3]*u.h,5*u.mg,1*u.h,'iv');
dos  = dos1 + dos2 + dos3;

% apply process_dosing function (the valid cases)
[t,x] = process_dosing(dos, Id, X0);
xref = [5*u.mg/u.L 5*u.mg 5*u.mg  5*u.mg/u.h;
        0*u.mg/u.L 0*u.mg 0*u.mg -5*u.mg/u.h;
        5*u.mg/u.L 5*u.mg 5*u.mg  5*u.mg/u.h;
        0*u.mg/u.L 0*u.mg 0*u.mg -5*u.mg/u.h];

assert(all(t == [0;1;3;4]*u.h) && all(x == xref,'all'))


%% Multiple drugs handled correctly

% dosing struct & initial values
Id = struct;
Id.Warfarin.Bolus.iv.cmt     = 1;
Id.Warfarin.Bolus.iv.scaling = u.L;
Id.Amitriptyline.Infusion.iv.bag  = 2;
Id.Amitriptyline.Infusion.iv.rate = 3;

X0 = 0*[u.mg/u.L; u.mg; u.mg/u.h]'; % row vector here, in contrast to models

% different dosing types
dos1 = Bolus('Warfarin',0*u.h,5*u.mg,'iv');
dos2 = Infusion('Amitriptyline',0*u.h,5*u.mg,1*u.h,'iv');
dos  = dos1 + dos2;

% apply process_dosing function and assert output
[t,x] = process_dosing(dos, Id, X0);
assert(all(t == [0;1]*u.h) && ...
    all(x == [5*u.mg/u.L 5*u.mg 5*u.mg/u.h; X0(1:2) -5*u.mg/u.h],'all'))

