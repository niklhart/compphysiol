% Test for ComplexDosing methods and subclass constructors

%% Combination of SimpleDosing objects into ComplexDosing objects working

dos = Bolus('X',u.h,u.g,'iv') + Bolus('Y',u.h,u.g,'iv') + ...
    Oral('Y',u.h,u.g)  + Oral('Z',u.h,u.g) + ...
    Infusion('X',0*u.h,u.g,1*u.h,'iv') + Infusion('Z',0*u.h,u.g,1*u.h,'iv');
assert(isa(dos,'ComplexDosing'))
assert(issetequal(compounds(dos),{'X','Y','Z'}))
assert(issetequal(dosingTypes(dos),{'Bolus','Oral','Infusion'}))

%% Combination with EmptyDosing objects working

bol   = Bolus('X',0*u.h,5*u.mg,'iv');
orl   = Oral('X',0*u.h,5*u.mg);
ifs   = Infusion('X',0*u.h,5*u.mg,1*u.h,'iv');
cpx   = bol + orl + ifs;
emp   = EmptyDosing;

assert(isequal(bol + emp, bol))
assert(isequal(orl + emp, orl))
assert(isequal(ifs + emp, ifs))
assert(isequal(cpx + emp, cpx))
assert(isequal(emp + emp, emp))

%% Filtering ComplexDosing objects

bol   = Bolus('X',0*u.h,5*u.mg,'iv');
orl   = Oral('X',0*u.h,5*u.mg);
cpx   = bol + orl;
emp   = EmptyDosing;

dosXO = filterDosing(cpx,'X','Oral');
dosXB = filterDosing(cpx,'X','Bolus');
dosXI = filterDosing(cpx,'X','Infusion');
dosX_ = filterDosing(cpx,'X',[]);
dosY_ = filterDosing(cpx,'Y',[]);
dos_O = filterDosing(cpx,[],'Oral');

assert(isequal(dosXO, orl))
assert(isequal(dosXB, bol))
assert(isequal(dosXI, emp))
assert(isequal(dosX_, cpx))
assert(isequal(dosY_, emp))
assert(isequal(dos_O, orl))

