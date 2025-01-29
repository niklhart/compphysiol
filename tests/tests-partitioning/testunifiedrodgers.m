% test unified_rodgers.m

% choose organs
organs = {'lun','adi','bra','hea','kid','mus','bon','ski','gut','spl','liv'};

% choose physiology
phys = Physiology('rat250');
spec = getvalue(phys,'species');

%% Unified Rodgers et al. model identical to standard for neutrals/acids

% neutral compound
drug = DrugData();
drug.class = 'sMD'; 
drug.subclass = 'neutral';

addrecord(drug,'logPow',-2);
addrecord(drug,'fuP',spec,0.9);
addrecord(drug,'K_ery_up',spec,1);

[K1,f1,fC1] = rodgersrowland(phys,drug,organs);
[K2,f2,fC2] = unified_rodgers(phys,drug,organs);

assert(isequaltol(K1,K2))
assert(isequaltol(f1,f2))
assert(isequaltol(fC1,fC2))

% acidic compound
drug = DrugData();
drug.class = 'sMD';
drug.subclass = 'acid';

addrecord(drug,'logPow',-2);
addrecord(drug,'pKa_ani',5);
addrecord(drug,'fuP',spec,0.9);
addrecord(drug,'K_ery_up',spec,1);

[K1,f1,fC1] = rodgersrowland(phys,drug,organs);
[K2,f2,fC2] = unified_rodgers(phys,drug,organs);

assert(isequaltol(K1,K2))
assert(isequaltol(f1,f2))
assert(isequaltol(fC1,fC2))

%% Unified Rodgers et al. model similar to standard for very strong bases
% protein binding differs between models --> enforce zero binding affinity

% basic compound
drug = DrugData();
drug.class = 'sMD';
drug.subclass = 'base';

addrecord(drug,'logPow',-2);
addrecord(drug,'pKa_cat',10);
addrecord(drug,'fuP',spec,1);     
addrecord(drug,'K_ery_up',spec,1);

[K1,f1,fC1] = rodgersrowland(phys,drug,organs,plasmaWaterFraction=1,fupIncludesLipids=false);
[K2,f2,fC2] = unified_rodgers(phys,drug,organs,plasmaWaterFraction=1,fupIncludesLipids=false);

assert(isequaltol(K1,K2))
assert(isequaltol(f1,f2))
assert(isequaltol(fC1,fC2))

