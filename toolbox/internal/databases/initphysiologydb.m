%INITPHYSIOLOGYDB Initialize the physiology database    
%   PHYSIOLOGYDB = INITPHYSIOLOGYDB() creates an array of reference 
%   individuals of class Physiology. It is executed automatically the first
%   time that PhysiologyDB.Instance is accessed. 
% 
%   The resulting Physiology array can be queried in different ways:
%
%   1) Physiology(ID), with char ID corresponding to the name of a
%      reference individual, retrieves the individual from the physiology
%      database
%   2) Physiology and drug databases can be loaded jointly with function 
%      loaddatabases()
%   
%   See Physiology for details.
%
%   To customize the physiology database, use one or both of the following 
%   options:
%   
%   1) write a custom initialization function (see this function for syntax)
%      and activate it using 
%   
%      setoptcompphysiol('PhysiologyDB', @INITFUN)
%
%      where INITFUN is the name of the custom initialization function.
%   
%   2) write a custom physiology template and activate it using 
%   
%      setoptcompphysiol('PhysiologyTemplate', @TEMPLATE)
%
%      where TEMPLATE is the name of the custom physiology template.
%
%   In either of these cases, for the changes to take an effect, first call 
%
%   resetcompphysiol() 
%
%   See also physiologytemplate, Physiology, PhysiologyDB, loaddatabases, 
%   resetcompphysiol

function physiologydb = initphysiologydb()

fprintf('Initializing the physiology database...\n')
%%% ========================================================================================================
%%% Data: Mostly reported for F344 rats
%%% 
%%% Source: Brown et al, Tox Ind Health 1997 (Table 3)
%%%
%%% Note: Male rats of 250g are only 10 weeks of age and in rapid growth phase.
%%% Growth is much slower between age 20-55 weeks (ca. 380-470g) and reaches 
%%% a plateau of 475g at age 56-91 weeks.  

nrats = 2;
rat(nrats,1) = Physiology();   % IMPORTANT: since Physiology is a handle class, don't use `rat(1:nrats) = Physiology()`!

rat(1).name  = 'rat250';
rat(2).name  = 'rat475';

ref = 'Brown et al, Tox Ind Health 1997 (Table 3)';

addrecord(rat(1), 'species', 'rat', ref, [])
addrecord(rat(2), 'species', 'rat', ref, [])

addrecord(rat(1), 'type', 'F344', ref, [])
addrecord(rat(2), 'type', 'F344', ref, [])

addrecord(rat(1), 'sex', 'male', ref, [])
addrecord(rat(2), 'sex', 'male', ref, [])

addrecord(rat(1), 'age', 10*u.week, ref, [])
addrecord(rat(2), 'age', 70*u.week, ref, [])  % 70w = between 56-91w

addrecord(rat(1), 'BW', 250*u.g, ref, [])
addrecord(rat(2), 'BW', 475*u.g, ref, [])

%%% ========================================================================================================
%%% Data  : Density of tissue
%%%
%%% Unit  : kg/l (= g/cm^3)
%%%

%%% ASSUMPTION: 
%%%
%%% Density assumed identical to human density data
%%% Source: Human data. See Brown et al, Tox Ind Health 1997 and ICRP report 1975
%%%
ref = struct(...
    'brown1997_T19',     'Brown et al, Tox Ind Health 1997 (Table 19)',...
    'icrp1975_p44',      'ICRP report 1975 (p.44)',...
    'icrp2002_T2_20',    'ICRP report 2002 (Table 2.20)'...
);
assum = 'Density assumed identical to human density data';

addrecord(rat, 'dens', 'adi', '0.916 kg/L',   ref.icrp1975_p44,   assum) 
addrecord(rat, 'dens', 'bon', '1.3   kg/L',   ref.icrp2002_T2_20, assum) % (whole skeleton, adults)
addrecord(rat, 'dens', 'bra', '1     kg/L',   ref.brown1997_T19,  assum) 
addrecord(rat, 'dens', 'gut', '1     kg/L',   ref.brown1997_T19,  assum)
addrecord(rat, 'dens', 'hea', '1     kg/L',   ref.brown1997_T19,  assum)
addrecord(rat, 'dens', 'kid', '1     kg/L',   ref.brown1997_T19,  assum)
addrecord(rat, 'dens', 'liv', '1     kg/L',   ref.brown1997_T19,  assum)
addrecord(rat, 'dens', 'lun', '1     kg/L',   ref.brown1997_T19,  assum)
addrecord(rat, 'dens', 'mus', '1     kg/L',   ref.brown1997_T19,  assum)
addrecord(rat, 'dens', 'ski', '1     kg/L',   ref.brown1997_T19,  assum)
addrecord(rat, 'dens', 'spl', '1     kg/L',   ref.brown1997_T19,  assum)

%NH hinzugefuegt
addrecord(rat, 'dens', 'tbl', '1     kg/L',   ref.brown1997_T19,  assum)

%%% ========================================================================================================
%%% Data  : fraction of total body weight that is experimental organ weight or 
%%%         total blood volume
%%%         According to Brown et al. p.411, in most cases, the values provided 
%%%         reflect the weight of organs that are drained of blood.
%%%
%%% Unit  : fraction (converted from percentage by dividing by 100]
%%% Source: Brown et al, Tox Ind Health 1997: Table 5 (most tissues), 
%%%         Table 13 (adi), top paragraph on p.425 (bone),


ref = struct(...
    'brown1997_p425', 'Brown et al, Tox Ind Health 1997 (p.425, top paragraph)',...
    'brown1997_T5',      'Brown et al, Tox Ind Health 1997 (Table 5)',...
    'brown1997_T13',     'Brown et al, Tox Ind Health 1997 (Table 13)',...
    'diehl2001_T5',      'Diehl etal J. Appl. Toxicol. 21, 15?23 (2001), Table 5'...
);
%%%             age(weeks)    10w   70w
addrecord(rat, 'fowtisBW', 'adi', [10.6  16.0 ] *u.percent,   ref.brown1997_T13,  []) 
addrecord(rat, 'fowtisBW', 'bon', [ 7.3   7.3 ] *u.percent,   ref.brown1997_p425, [])
addrecord(rat, 'fowtisBW', 'bra', [ 0.57  0.57] *u.percent,   ref.brown1997_T5,   [])
addrecord(rat, 'fowtisBW', 'gut', [ 2.7   2.7 ] *u.percent,   ref.brown1997_T5,   [])      % sum of stomach, small and large intestine (2.7=0.46+1.40+0.84) 
addrecord(rat, 'fowtisBW', 'hea', [ 0.33  0.33] *u.percent,   ref.brown1997_T5,   [])
addrecord(rat, 'fowtisBW', 'kid', [ 0.73  0.73] *u.percent,   ref.brown1997_T5,   [])
addrecord(rat, 'fowtisBW', 'liv', [ 3.66  3.66] *u.percent,   ref.brown1997_T5,   [])
addrecord(rat, 'fowtisBW', 'lun', [ 0.50  0.50] *u.percent,   ref.brown1997_T5,   [])
addrecord(rat, 'fowtisBW', 'mus', [40.43 40.43] *u.percent,   ref.brown1997_T5,   [])
addrecord(rat, 'fowtisBW', 'ski', [19.03 19.03] *u.percent,   ref.brown1997_T5,   [])
addrecord(rat, 'fowtisBW', 'spl', [ 0.2   0.2 ] *u.percent,   ref.brown1997_T5,   [])

%%% fraction of total blood volume, including peripheral regional blood
addrecord(rat, 'ftblBW', [ 6.4   6.4 ] *u.percent,   ref.diehl2001_T5,   []) 


%%% ========================================================================================================
%%% Assign tissue organ weights and tissue volumes
%%%

%%% ASSUMPTION:
%%%
%%% We assume that the experimental organ weights (including residual 
%%% blood to some varying degree) are approximately equal to 
%%% the tissue organ weight (not including residual blood), since 
%%% according to Brown et al. p.411, in most cases, the values provided 
%%% reflect the weight of organs that are drained of blood.

tissues = {'adi','bon','bra','gut','hea','kid','liv','lun','mus','ski','spl'};

BW = getrecord(rat,'BW');

for i = 1:numel(tissues)
    tis = tissues{i};
    
    OWtis = getrecord(rat,'fowtisBW',tis) .* BW;
    Vtis   = OWtis ./ getrecord(rat,'dens',tis);

    addrecord(rat,'OWtis',tis, OWtis)   
    addrecord(rat,'Vtis', tis, Vtis)
end

OWtbl = BW .* getrecord(rat,'ftblBW');
Vtbl = OWtbl ./ getrecord(rat,'dens','tbl');
LBW  = getrecord(rat,'BW') - getrecord(rat,'OWtis','adi');

addrecord(rat, 'OWtbl', OWtbl)
addrecord(rat, 'Vtbl', Vtbl)
addrecord(rat, 'LBW', LBW)

%%% ========================================================================================================
%%% Data  : pH values in plasma/interstitial water and intra-cellular
%%% water
%%%
%%% Unit  : - 
%%% Source: Rodgers, Leahy, and Rowland, J Pharm Sci (2005), p. 1263
%%%

%%% ASSUMPTION: 
%%%
%%% pH values assumed to be tissue independent, as in Rodgers et al.
%%%

ref = 'Rodgers, Leahy, and Rowland, J Pharm Sci (2005), p. 1263';
assum = 'pH values assumed to be tissue independent, as in Rodgers et al.';

addrecord(rat, 'pH', 'pla', 7.4, ref,   [] )   % plasma water
addrecord(rat, 'pH', 'ery', 7.22,  ref,   [] )   % RBC

%tissues = {'adi','bon','bra','gut','hea','kid','liv','lun','mus','ski','spl'};
for i = 1:numel(tissues)
    tis = tissues{i};
    addrecord(rat, 'pH', tis, 7,  [],  assum);  % intra-cellular water
end

%%% ========================================================================================================
%%% Data  : Fraction of experimental organ weight that is vascular volume and 
%%%         interstitial space volume in non-bled rats 
%%%
%%% Unit  : fraction in [L/kg]
%%% Source: Kawai et al, J Pharmacokinet Biopharm, Vol 22, 1994 (Table B-I),
%%%         based on measurements in nonbled rats, see Appendix B, p. 362
%%% Note  : The vascular volume fractions in Kawai et al are in good agreement
%%%         with the mean residual blood data in Brown et al, Table 30 (rats)
%%%         There, however, it is mentioned (on p.457, Section 'Blood
%%%         volume data') that the values in Table 30 are not
%%%         representations of the fraction of the total blood volume that
%%%         resides in the tissue. 
%%%

%%% ASSUMPTION:
%%%
%%% We assume that fractions with respect to total organ weight are 
%%% approximately identical to the fractions with respect to experimental 
%%% organ weight, since fractions were determined from non-bled rats 
%%% according to the footnote of table B-I, Kawai et al. (2004).
%%%

ref = struct;
ref.kawai = 'Kawai et al, J Pharmacokinet Biopharm, Vol 22, 1994 (Table B-I)';

                                                            % Alternative values from Brown et al, 1997 (table 30)
addrecord(rat, 'fvasOWtot', 'adi', 0.010, ref.kawai, [])    % n.a.
addrecord(rat, 'fvasOWtot', 'bon', 0.041, ref.kawai, [])    % 0.04
addrecord(rat, 'fvasOWtot', 'bra', 0.037, ref.kawai, [])    % 0.03
addrecord(rat, 'fvasOWtot', 'gut', 0.024, ref.kawai, [])    % n.a.
addrecord(rat, 'fvasOWtot', 'hea', 0.262, ref.kawai, [])    % 0.26
addrecord(rat, 'fvasOWtot', 'kid', 0.105, ref.kawai, [])    % [0.11-0.27], n=3
addrecord(rat, 'fvasOWtot', 'liv', 0.115, ref.kawai, [])    % [0.12-0.27], n=3 
addrecord(rat, 'fvasOWtot', 'lun', 0.262, ref.kawai, [])    % [0.26-0.52], n=3
addrecord(rat, 'fvasOWtot', 'mus', 0.026, ref.kawai, [])    % [0.01-0.04], n=3
addrecord(rat, 'fvasOWtot', 'ski', 0.019, ref.kawai, [])    % 0.02
addrecord(rat, 'fvasOWtot', 'spl', 0.282, ref.kawai, [])    % [0.17-0.28], n=3
addrecord(rat, 'fvasOWtot', 'pan', 0.180, ref.kawai, [])    % 
addrecord(rat, 'fvasOWtot', 'thy', 0.030, ref.kawai, [])    % 

addrecord(rat, 'fintOWtot', 'adi', 0.135, ref.kawai, [])   
addrecord(rat, 'fintOWtot', 'bon', 0.100, ref.kawai, [])   
addrecord(rat, 'fintOWtot', 'bra', 0.004, ref.kawai, [])   
addrecord(rat, 'fintOWtot', 'gut', 0.094, ref.kawai, [])   
addrecord(rat, 'fintOWtot', 'hea', 0.100, ref.kawai, [])    
addrecord(rat, 'fintOWtot', 'kid', 0.200, ref.kawai, [])   
addrecord(rat, 'fintOWtot', 'liv', 0.163, ref.kawai, [])  
addrecord(rat, 'fintOWtot', 'lun', 0.188, ref.kawai, [])   
addrecord(rat, 'fintOWtot', 'mus', 0.120, ref.kawai, [])   
addrecord(rat, 'fintOWtot', 'ski', 0.302, ref.kawai, [])   
addrecord(rat, 'fintOWtot', 'spl', 0.150, ref.kawai, [])  
addrecord(rat, 'fintOWtot', 'pan', 0.120, ref.kawai, [])    % 
addrecord(rat, 'fintOWtot', 'thy', 0.150, ref.kawai, [])    % 

tissues_kawai = {'adi','bon','bra','gut','hea','kid','liv','lun','mus','ski','spl','pan','thy'};

for i = 1:numel(tissues_kawai)
    
    tis = tissues_kawai{i};
    
    fvasOWtot = getrecord(rat,'fvasOWtot',tis);
    fintOWtot = getrecord(rat,'fintOWtot',tis);
    fcelOWtot = 1 - (fvasOWtot + fintOWtot);
    addrecord(rat, 'fcelOWtot', tis, fcelOWtot)
    
    %%% Determining fraction of interstitial and intra-cellular space with
    %%% respect to tissue weight NOT INCLUDING regional vascular blood so that
    %%% fVtis.int+fVtis.cel = 1
    %%%

    fintOWtis = fintOWtot./(fintOWtot+fcelOWtot);
    fcelOWtis = 1 - fintOWtis;
    addrecord(rat, 'fintOWtis', tis, fintOWtis)   
    addrecord(rat, 'fcelOWtis', tis, fcelOWtis)   

    %%% ASSUMPTION:
    %%%
    %%% We assume that fractions with respect to volume are identical
    %%% to those with respect to weight.
    
    fcelVtot = fcelOWtot;
    fintVtot = fintOWtot;
    fvasVtot = fvasOWtot;
    addrecord(rat, 'fcelVtot', tis, fcelVtot)   
    addrecord(rat, 'fintVtot', tis, fintVtot)   
    addrecord(rat, 'fvasVtot', tis, fvasVtot)   

    %%% Determining fraction of interstitial and intra-cellular space with
    %%% respect to tissue weight NOT INCLUDING regional vascular blood so that
    %%% fintVtis+fcelVtis = 1

    fcelVtis = fcelVtot ./ (fcelVtot + fintVtot);
    fintVtis = fintVtot ./ (fcelVtot + fintVtot);
    
    addrecord(rat, 'fcelVtis', tis, fcelVtis)   
    addrecord(rat, 'fintVtis', tis, fintVtis)  
end


%%% ========================================================================================================
%%% Data  : Fraction of experimental organ weight that is residual blood
%%%         in exanguinated rats
%%%
%%% Unit  : fraction in [L/kg]
%%% Source: Kawai etal, J Pharmacokinet Biopharm, Vol 22, 1994 (Table B-I)
%%%

ref = 'Kawai etal, J Pharmacokinet Biopharm, Vol 22, 1994 (Table B-I)';
                                                        % Alternative values from Brown et al 1997, Table 30, 
                                                        % (see 2nd paragraph on p.457 under BLOOD VOLUME DATA) 
addrecord(rat, 'fresOWrbt', 'adi', 0.005, ref, [])  
addrecord(rat, 'fresOWrbt', 'bon', 0.019, ref, [])  % Brown etal 1997(Table 30) = 0.04  
addrecord(rat, 'fresOWrbt', 'bra', 0.014, ref, [])  % Brown etal 1997(Table 30) = [0.02-0.04] 
addrecord(rat, 'fresOWrbt', 'gut', 0.010, ref, [])  
addrecord(rat, 'fresOWrbt', 'hea', 0.061, ref, [])  % Brown etal 1997(Table 30) = 0.26 
addrecord(rat, 'fresOWrbt', 'kid', 0.046, ref, [])  % Brown etal 1997(Table 30) = [0.11-0.27], mean 0.16 
addrecord(rat, 'fresOWrbt', 'liv', 0.057, ref, [])  % Brown etal 1997(Table 30) = [0.12-0.27], mean 0.21 
addrecord(rat, 'fresOWrbt', 'lun', 0.175, ref, [])  % Brown etal 1997(Table 30) = [0.26-0.52], mean 0.36 
addrecord(rat, 'fresOWrbt', 'mus', 0.004, ref, [])  % Brown etal 1997(Table 30) = [0.01-0.04], mean 0.04
addrecord(rat, 'fresOWrbt', 'ski', 0.002, ref, [])  % Brown etal 1997(Table 30) = 0.02 
addrecord(rat, 'fresOWrbt', 'spl', 0.321, ref, [])  % Brown etal 1997(Table 30) = [0.17-0.28], mean 0.22 


%%% ========================================================================================================
%%% Data  : Fraction of total blood volume that is regional peripheral blood volume
%%%         associated with each organ
%%%
%%% Unit  : percent (%)
%%% Source: see above
%%%

% hier blood density verwenden
denstbl = getrecord(rat,'dens','tbl');

for i = 1:numel(tissues)
    tis = tissues{i};
    
    OWtis  = getrecord(rat,'OWtis',tis);
    fintOWtot = getrecord(rat, 'fintOWtot', tis);
    fcelOWtot = getrecord(rat, 'fcelOWtot', tis);
    OWtot  = OWtis ./ (fintOWtot+fcelOWtot); 
    Vvas  = getrecord(rat,'fvasOWtot',tis) .* OWtot ./ denstbl;
    Vvas  = scd(Vvas,'L');     % set correct display unit (lost during multiplication)
    Vtis  = getrecord(rat,'Vtis',tis);
    Vtot  = Vvas + Vtis;

    fresOWrbt = getrecord(rat,'fresOWrbt',tis);
    OWrbt  = OWtis ./ (1 - fresOWrbt);          % from OWrbt = OWtis + fresOWrbt*OWrbt
    Vres  = fresOWrbt .* OWrbt ./ denstbl; 
    Vres = scd(Vres,'L');     % set correct display unit (lost during multiplication)
  
    addrecord(rat,'OWtot',tis,OWtot)    
    addrecord(rat,'OWrbt',tis,OWrbt)    
    addrecord(rat,'Vvas',tis,Vvas)
    addrecord(rat,'Vtot',tis,Vtot)
    addrecord(rat,'Vres',tis,Vres)
    
    %%% define fraction of total blood that is regional blood, i.e.,
    %%% vascular blood associated with each organ
    
    fregVtbl = Vvas ./ getrecord(rat,'Vtbl');

    addrecord(rat,'fregVtbl',tis,fregVtbl)
end


%%% ASSUMPTION:
%%%
%%% Assume that veneous and arterial blood are 2/3 and 1/3 of 
%%% total blood and set the hematocrit value

assum = 'Assumed that veneous and arterial blood are 2/3 and 1/3 of total blood';
addrecord(rat, 'fvenVtbl', 2/3, [], assum)   
addrecord(rat, 'fartVtbl', 1/3, [], assum)   

ref = 'Windberger et al., Exp Physiol, 88(3):431–40, 2003';
addrecord(rat, 'hct', 0.43, ref, [])   


%%% ========================================================================================================
%%% Data  : cardiac output and regional blood flows
%%%
%%% Unit  : co in [L/min] and fraction of co that is regional blood flow
%%% Source: Brown et al, Tox Ind Health 1997 (Table 25)
%%%

co = str2u('0.235 L/min') * (getrecord(rat,'BW')./u.kg).^0.75; % Brown et al, Tox Ind Health 1997, p.441
addrecord(rat, 'co', co)   


%%% fraction of cardiac output that is regional blood flow
%%%
ref = 'Poulin & Theil, J Pharm Sci 2002';

addrecord(rat, 'fqbloCO', 'adi', 7.0/100,  '?', [])
addrecord(rat, 'fqbloCO', 'bon', 12.2/100, '?', [])
addrecord(rat, 'fqbloCO', 'bra', 2.0/100,  '?', [])
addrecord(rat, 'fqbloCO', 'gut', 13.1/100, '?', [])  % Ref: ?? 
addrecord(rat, 'fqbloCO', 'hea', 4.9/100,  '?', [])
addrecord(rat, 'fqbloCO', 'kid', 14.1/100, '?', [])
addrecord(rat, 'fqbloCO', 'liv', 17.4/100, '?', [])
addrecord(rat, 'fqbloCO', 'mus', 27.8/100, '?', [])
addrecord(rat, 'fqbloCO', 'ski', 5.8/100,  '?', [])
addrecord(rat, 'fqbloCO', 'spl', 2.0/100,  ref, [])

nolung = setdiff(tissues,'lun');

for i = 1:numel(nolung)
    
    tis = nolung{i};
    Q   = getrecord(rat,'fqbloCO',tis) .* getrecord(rat,'co');
    addrecord(rat, 'Qblo', tis, Q)
end


%%% ========================================================================================================
%%% Data  : Fraction of tissue volume that is total tissue water 
%%%
%%% Unit  : fraction of tissue volume
%%% Source: Rodgers and Rowland, J Pharm Sci (2006), Table 1, total tissue water is reported, corrected 
%%%         for residual (see eq. (A2)). According to email correspondance
%%%         with T. Rodgers, f_residual was taken from ref. 15 (Kawai et
%%%         al. 1994), not from ref. 16 as mentioned in the article)
%%%

ref = 'Rodgers and Rowland, J Pharm Sci (2006), Table 1';

%%% total tissue water (extra-cellular)

addrecord(rat, 'fwtotVtis', 'adi', 0.144, ref, [])
addrecord(rat, 'fwtotVtis', 'bon', 0.417, ref, [])
addrecord(rat, 'fwtotVtis', 'bra', 0.753, ref, [])
addrecord(rat, 'fwtotVtis', 'gut', 0.738, ref, [])
addrecord(rat, 'fwtotVtis', 'hea', 0.568, ref, [])
addrecord(rat, 'fwtotVtis', 'kid', 0.672, ref, [])
addrecord(rat, 'fwtotVtis', 'liv', 0.642, ref, [])
addrecord(rat, 'fwtotVtis', 'lun', 0.574, ref, [])
addrecord(rat, 'fwtotVtis', 'mus', 0.726, ref, [])
addrecord(rat, 'fwtotVtis', 'ski', 0.658, ref, [])
addrecord(rat, 'fwtotVtis', 'spl', 0.562, ref, [])

%%% ========================================================================================================
%%% Data  : Fraction of experimental organ weight that is extracellular and intracelluar tissue water 
%%%
%%% Unit  : fraction of experimental organ weight and tissue volume
%%% Source: Rodgers, Leahy, and Rowland, J Pharm Sci (2005), identical to Graham etal, J Pharm Pharmacol (2011)
%%% Note  : fraction of intra-cellular water was determined as difference
%%%         of extra-cellular water to total experimental tissue water, i.e
%%%         fVexp.wic = fVexp.wtot - fVexp.wex
%%%

ref = 'Rodgers, Leahy, and Rowland, J Pharm Sci (2005)';

%%% tissue water (extra-cellular)           

addrecord(rat, 'fwecVrbt', 'adi', 0.135, ref, [])
addrecord(rat, 'fwecVrbt', 'bon', 0.100, ref, [])
addrecord(rat, 'fwecVrbt', 'bra', 0.162, ref, [])
addrecord(rat, 'fwecVrbt', 'gut', 0.282, ref, [])
addrecord(rat, 'fwecVrbt', 'hea', 0.320, ref, [])
addrecord(rat, 'fwecVrbt', 'kid', 0.273, ref, [])
addrecord(rat, 'fwecVrbt', 'liv', 0.161, ref, [])
addrecord(rat, 'fwecVrbt', 'lun', 0.336, ref, [])
addrecord(rat, 'fwecVrbt', 'mus', 0.118, ref, [])
addrecord(rat, 'fwecVrbt', 'ski', 0.382, ref, [])
addrecord(rat, 'fwecVrbt', 'spl', 0.207, ref, [])

addrecord(rat, 'fwecVrbt', 'ery', 0,     ref, [])


%%% tissue water (intra-cellular)

addrecord(rat, 'fwicVrbt', 'adi', 0.017, ref, [])
addrecord(rat, 'fwicVrbt', 'bon', 0.346, ref, [])
addrecord(rat, 'fwicVrbt', 'bra', 0.620, ref, [])
addrecord(rat, 'fwicVrbt', 'gut', 0.475, ref, [])
addrecord(rat, 'fwicVrbt', 'hea', 0.456, ref, [])
addrecord(rat, 'fwicVrbt', 'kid', 0.483, ref, [])
addrecord(rat, 'fwicVrbt', 'liv', 0.573, ref, [])
addrecord(rat, 'fwicVrbt', 'lun', 0.446, ref, [])
addrecord(rat, 'fwicVrbt', 'mus', 0.630, ref, [])
addrecord(rat, 'fwicVrbt', 'ski', 0.291, ref, [])
addrecord(rat, 'fwicVrbt', 'spl', 0.579, ref, [])

addrecord(rat, 'fwicVrbt', 'ery', 0.603, ref, [])

%%% ASSUMPTION:
%%%
%%% As stated in Rodgers et al. (2005), we compute the cellular water
%%% fraction based on total tissue water minus interstitial water fraction.
%%% To this end, the correction for residual blood from Rodgers/Rowland
%%% (2006) is applied to the total tissue water fraction first
%%

for i = 1:numel(tissues)
    tis = tissues{i};
    fwecVrbt   = getrecord(rat,'fwecVrbt',tis);
    fwicVtis   = getrecord(rat,'fwtotVtis',tis) - fwecVrbt;
    
    addrecord(rat, 'fwecVtis',tis, fwecVrbt,ref, 'Contamination from residual blood neglected')
    addrecord(rat, 'fwicVtis',tis, fwicVtis, [], 'Residual blood-corrected total minus extracellular water fraction')
end

fwicVrbt_ery = getrecord(rat,'fwicVrbt','ery');
addrecord(rat, 'fwicVtis', 'ery', fwicVrbt_ery);

%%% ========================================================================================================
%%% Data  : Fraction of tissue volume that is neutral lipids (nli) and neutal phospholipids (nph)
%%%
%%% Unit  : fraction of tissue volume
%%% Source: Rodgers and Rowland, J Pharm Sci (2006)
%%% Note  : Values have been corrected for residual blood contributions,
%%%         i.e., reported values do not contain resdiual blood contributions
%%%         (see Rodgers & Rowland, p.1252 top left paragraph)

ref = 'Rodgers and Rowland, J Pharm Sci (2006)';

%%% neutral lipids

addrecord(rat, 'fnliVtis', 'adi', 0.8530, ref, []) % note: in Rodgers and Rowland (2006) incorrectly reported under neutral phospholipids
addrecord(rat, 'fnliVtis', 'bon', 0.0174, ref, [])
addrecord(rat, 'fnliVtis', 'bra', 0.0391, ref, [])
addrecord(rat, 'fnliVtis', 'gut', 0.0375, ref, [])
addrecord(rat, 'fnliVtis', 'hea', 0.0135, ref, [])
addrecord(rat, 'fnliVtis', 'kid', 0.0121, ref, [])
addrecord(rat, 'fnliVtis', 'liv', 0.0135, ref, [])
addrecord(rat, 'fnliVtis', 'lun', 0.0215, ref, [])
addrecord(rat, 'fnliVtis', 'mus', 0.0100, ref, [])
addrecord(rat, 'fnliVtis', 'ski', 0.0603, ref, [])
addrecord(rat, 'fnliVtis', 'spl', 0.0071, ref, [])
addrecord(rat, 'fnliVtis', 'pla', 0.0023, ref, [])% p. 1241, paragarph "Tissue Specific Input Parameters"
addrecord(rat, 'fnliVtis', 'ery', 0.0017, ref, [])% Rodgers, Leahy, Rowland (2005), Table 1

%%% neutral phospholipids

addrecord(rat, 'fnphVtis', 'adi', 0.0016, ref, []) % note: in Rodgers and Rowland (2006) incorrectly reported under neutral lipids
addrecord(rat, 'fnphVtis', 'bon', 0.0016, ref, [])
addrecord(rat, 'fnphVtis', 'bra', 0.0015, ref, [])
addrecord(rat, 'fnphVtis', 'gut', 0.0124, ref, [])
addrecord(rat, 'fnphVtis', 'hea', 0.0106, ref, [])
addrecord(rat, 'fnphVtis', 'kid', 0.0240, ref, [])
addrecord(rat, 'fnphVtis', 'liv', 0.0238, ref, [])
addrecord(rat, 'fnphVtis', 'lun', 0.0123, ref, [])
addrecord(rat, 'fnphVtis', 'mus', 0.0072, ref, [])
addrecord(rat, 'fnphVtis', 'ski', 0.0044, ref, [])
addrecord(rat, 'fnphVtis', 'spl', 0.0107, ref, [])
addrecord(rat, 'fnphVtis', 'pla', 0.0013, ref, [])% p. 1241, paragarph "Tissue Specific Input Parameters"
addrecord(rat, 'fnphVtis', 'ery', 0.0029, ref, [])% Rodgers, Leahy, Rowland (2005), Table 1


%%% ========================================================================================================
%%% Data  : Intra-cellular acidic phospholipids (aph) in rat
%%%
%%% Unit  : mg/g tissue (original) scaled to fraction
%%% Source: Rodgers, Leahy, and Rowland, J Pharm Sci (2005), identical to Graham etal, J Pharm Pharmacol (2011)
%%% Note  : Not so clear, whether fractions are with respect to residual
%%%         blood corrected or contaminated tissue weight. We assume that
%%%         values have been corrected for residual blood (as fVtis.nlt or
%%%         fVtis.npt in the same article)
%%%

ref = 'Rodgers, Leahy, and Rowland, J Pharm Sci (2005)';

addrecord(rat, 'faphOWtis', 'adi', 0.40 * u.permil, ref, []) 
addrecord(rat, 'faphOWtis', 'bon', 0.67 * u.permil, ref, [])
addrecord(rat, 'faphOWtis', 'bra', 0.40 * u.permil, ref, [])
addrecord(rat, 'faphOWtis', 'gut', 2.41 * u.permil, ref, [])
addrecord(rat, 'faphOWtis', 'hea', 2.25 * u.permil, ref, [])
addrecord(rat, 'faphOWtis', 'kid', 5.03 * u.permil, ref, [])
addrecord(rat, 'faphOWtis', 'liv', 4.56 * u.permil, ref, [])
addrecord(rat, 'faphOWtis', 'lun', 3.91 * u.permil, ref, [])
addrecord(rat, 'faphOWtis', 'mus', 1.53 * u.permil, ref, [])
addrecord(rat, 'faphOWtis', 'ski', 1.32 * u.permil, ref, [])
addrecord(rat, 'faphOWtis', 'spl', 3.18 * u.permil, ref, [])
addrecord(rat, 'faphOWtis', 'ery', 0.5  * u.permil, ref, [])


tis_ery = union(tissues,'ery');
for i = 1:numel(tis_ery)
    
    tis = tis_ery{i};
    
    faphOWtis = getrecord(rat,'faphOWtis',tis);

    %%% ASSUMPTION:
    %%%
    %%% weight fractions identical to volume fractions
    
    addrecord(rat, 'faphVtis', tis, faphOWtis)
end


%%% ========================================================================================================
%%% Data  : Albumin tissue-to-plasma ratio (rtpAlb) in rat
%%%
%%% Unit  : --
%%% Source: Rodgers, and Rowland, J Pharm Sci 95 (2006), identical to Graham etal, J Pharm Pharmacol (2011)
%%% Note  : Not so clear, whether fractions are with respect to residual
%%%         blood corrected or contaminated tissue weight. We assume that
%%%         values have been corrected for residual blood (as fVtis.nlt or
%%%         fVtis.npt in the same article)
%%% 

%NH Note nicht als Assumption verwendet.

ref = 'Rodgers, and Rowland, J Pharm Sci 95 (2006)';

addrecord(rat, 'rtpAlb', 'adi', 0.049, ref, [])   
addrecord(rat, 'rtpAlb', 'bon', 0.100, ref, [])   
addrecord(rat, 'rtpAlb', 'bra', 0.048, ref, [])   
addrecord(rat, 'rtpAlb', 'gut', 0.158, ref, [])   
addrecord(rat, 'rtpAlb', 'hea', 0.157, ref, [])   
addrecord(rat, 'rtpAlb', 'kid', 0.130, ref, [])   
addrecord(rat, 'rtpAlb', 'liv', 0.086, ref, [])   
addrecord(rat, 'rtpAlb', 'lun', 0.212, ref, [])   
addrecord(rat, 'rtpAlb', 'mus', 0.064, ref, [])   
addrecord(rat, 'rtpAlb', 'ski', 0.277, ref, [])   
addrecord(rat, 'rtpAlb', 'spl', 0.097, ref, [])   


%%% ========================================================================================================
%%% Data  : Lipoprotein tissue-to-plasma ratio (rtpLip) in rat
%%%
%%% Unit  : --
%%% Source: Rodgers, and Rowland, J Pharm Sci 95 (2006), identical to Graham etal, J Pharm Pharmacol (2011)
%%% 

ref = 'Rodgers, and Rowland, J Pharm Sci 95 (2006)';

addrecord(rat, 'rtpLip', 'adi', 0.068, ref, [])   
addrecord(rat, 'rtpLip', 'bon', 0.050, ref, [])   
addrecord(rat, 'rtpLip', 'bra', 0.041, ref, [])   
addrecord(rat, 'rtpLip', 'gut', 0.141, ref, [])   
addrecord(rat, 'rtpLip', 'hea', 0.160, ref, [])   
addrecord(rat, 'rtpLip', 'kid', 0.137, ref, [])   
addrecord(rat, 'rtpLip', 'liv', 0.161, ref, [])   
addrecord(rat, 'rtpLip', 'lun', 0.168, ref, [])   
addrecord(rat, 'rtpLip', 'mus', 0.059, ref, [])   
addrecord(rat, 'rtpLip', 'ski', 0.096, ref, [])   
addrecord(rat, 'rtpLip', 'spl', 0.207, ref, [])   


%%% +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
%%% END:  RAT +++ RAT +++ RAT +++ RAT +++ RAT +++ RAT +++ RAT +++ RAT +++++
%%% +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++

%%% +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
%%% BEGIN:   MOUSE +++ MOUSE +++ MOUSE +++ MOUSE +++ MOUSE +++ MOUSE ++++++
%%% +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++

%%% =======================================================================
%%% Data: Mostly reported for B6C3F1 mice
%%% 
%%% Source: Brown et al, Tox Ind Health 1997 (Table 1)
%%%
%%% Note: Male mice of 25g are only 9 weeks of age and in rapid growth phase.
%%% Growth is much slower between age 20-67 weeks (ca. 31.5-40 g) and reaches 
%%% a plateau of 40g at age 68-91 weeks.  


nmice = 2;
mouse(nmice,1) = Physiology();   % IMPORTANT: since Physiology is a handle class, don't use `mouse(1:nmice) = Physiology()`!


mouse(1).name  = 'mouse25';
mouse(2).name  = 'mouse40';

ref = 'Brown et al, Tox Ind Health 1997 (Table 1)';

addrecord(mouse(1), 'species', 'mouse', ref, [])
addrecord(mouse(2), 'species', 'mouse', ref, [])

addrecord(mouse(1), 'type', 'B6C3F1', ref, [])
addrecord(mouse(2), 'type', 'B6C3F1', ref, [])

addrecord(mouse(1), 'sex', 'male', ref, [])
addrecord(mouse(2), 'sex', 'male', ref, [])

addrecord(mouse(1), 'age',  9*u.week, ref, [])
addrecord(mouse(2), 'age', 70*u.week, ref, [])  % 70w = between 56-91w

addrecord(mouse(1), 'BW', 25*u.g, ref, [])
addrecord(mouse(2), 'BW', 40*u.g, ref, [])


%%% ========================================================================================================
%%% Data  : Density of tissue
%%%
%%% Unit  : kg/l (= g/cm^3)
%%%

%%% ASSUMPTION: 
%%%
%%% Density assumed identical to human density data
%%% Source: Human data. See Brown et al, Tox Ind Health 1997 and ICRP report 1975
%%%

ref = struct(...
    'brown1997_T19',     'Brown et al, Tox Ind Health 1997 (Table 19)',...
    'icrp1975_p44',      'ICRP report 1975 (p.44)',...
    'icrp2002_T2_20',    'ICRP report 2002 (Table 2.20)'...
);
assum = 'Density assumed identical to human density data';

addrecord(mouse, 'dens', 'adi', '0.916 kg/L',   ref.icrp1975_p44,   assum) 
addrecord(mouse, 'dens', 'bon', '1.3   kg/L',   ref.icrp2002_T2_20, assum) % (whole skeleton, adults)
addrecord(mouse, 'dens', 'bra', '1     kg/L',   ref.brown1997_T19,  assum) 
addrecord(mouse, 'dens', 'gut', '1     kg/L',   ref.brown1997_T19,  assum)
addrecord(mouse, 'dens', 'hea', '1     kg/L',   ref.brown1997_T19,  assum)
addrecord(mouse, 'dens', 'kid', '1     kg/L',   ref.brown1997_T19,  assum)
addrecord(mouse, 'dens', 'liv', '1     kg/L',   ref.brown1997_T19,  assum)
addrecord(mouse, 'dens', 'lun', '1     kg/L',   ref.brown1997_T19,  assum)
addrecord(mouse, 'dens', 'mus', '1     kg/L',   ref.brown1997_T19,  assum)
addrecord(mouse, 'dens', 'ski', '1     kg/L',   ref.brown1997_T19,  assum)
addrecord(mouse, 'dens', 'spl', '1     kg/L',   ref.brown1997_T19,  assum)

addrecord(mouse, 'dens', 'tbl', '1     kg/L',   ref.brown1997_T19,  assum)


%%% ========================================================================================================
%%% Data  : fraction of total body weight that is experimental organ weight or 
%%%         total blood volume
%%%
%%% Unit  : fraction (converted from percentage by dividing by 100]
%%% Source: 1st and 2nd column:
%%%         Brown et al, Tox Ind Health 1997: Table 4 (most tissues), 
%%%         Table 10 (adi), Table 21 (adi,blo) 
%%%         Tissue volumes were corrected for residual blood
%%%            

ref = struct(...
    'brown1997',  'Brown et al, Tox Ind Health 1997',...
    'diehl2001',  'Diehl et al, J Appl Toxicol 2001:21, 15-23 (Table 5)'...
);
%%%                     age(weeks)     9w   70w
addrecord(mouse, 'fowtisBW', 'adi', [ 7.0   7.0 ] *u.percent,   ref.brown1997,  []) 
addrecord(mouse, 'fowtisBW', 'bon', [10.73 10.73] *u.percent,   ref.brown1997,  [])
addrecord(mouse, 'fowtisBW', 'bra', [ 1.65  1.65] *u.percent,   ref.brown1997,   [])
addrecord(mouse, 'fowtisBW', 'gut', [ 4.22  4.22] *u.percent,   ref.brown1997,   [])      % sum of stomach, small and large intestine (4.22=0.60+2.53+1.09) 
addrecord(mouse, 'fowtisBW', 'hea', [ 0.50  0.50] *u.percent,   ref.brown1997,   [])
addrecord(mouse, 'fowtisBW', 'kid', [ 1.67  1.67] *u.percent,   ref.brown1997,   [])
addrecord(mouse, 'fowtisBW', 'liv', [ 5.49  5.49] *u.percent,   ref.brown1997,   [])
addrecord(mouse, 'fowtisBW', 'lun', [ 0.73  0.73] *u.percent,   ref.brown1997,   [])
addrecord(mouse, 'fowtisBW', 'mus', [38.40 38.40] *u.percent,   ref.brown1997,   [])
addrecord(mouse, 'fowtisBW', 'ski', [16.53 16.53] *u.percent,   ref.brown1997,   [])
addrecord(mouse, 'fowtisBW', 'spl', [ 0.35  0.35] *u.percent,   ref.brown1997,   [])

addrecord(mouse, 'ftblBW', [ 7.2   7.2 ] *u.percent,   ref.diehl2001,   []) 


%%% tissue organ weights                             
%%%
%%% ASSUMPTION:
%%%
%%% We assume that the experimental organ weights (including residual 
%%% blood to some varying degree) are approximately equal to 
%%% the tissue organ weight (not including residual blood), since 
%%% according to Brown et al. p.411, in most cases, the values provided 
%%% reflect the weight of organs that are drained of blood.

BW = getrecord(mouse,'BW');

for i = 1:numel(tissues)
    tis = tissues{i};
    
    OWtis = getrecord(mouse,'fowtisBW',tis) .* BW;
    Vtis   = OWtis ./ getrecord(mouse,'dens',tis);

    addrecord(mouse,'OWtis',tis, OWtis)   
    addrecord(mouse,'Vtis', tis, Vtis)
end

OWtbl = BW .* getrecord(mouse,'ftblBW');
Vtbl = OWtbl ./ getrecord(mouse,'dens','tbl');
LBW  = getrecord(mouse,'BW') - getrecord(mouse,'OWtis','adi');

addrecord(mouse, 'OWtbl', OWtbl)
addrecord(mouse, 'Vtbl', Vtbl)
addrecord(mouse, 'LBW', LBW)

%%% ========================================================================================================
%%% Data  : pH values in plasma/interstitital water and intra-cellular
%%% water

clonerecord(mouse, 'pH', rat(1));

%%% ========================================================================================================
%%% Data  : Different fractions of organ weight / volume
%%%
%%% Unit  : unitless

%%% ASSUMPTION:
%%%
%%% Data for mice are identical to the corresponding data for rats. This is
%%% supported by Brown et al, Table 30, comparing the data for mouse and
%%% rat, when taking the reported range of values (n=3) into account. Note
%%% that the mean has been reported, although it is very sensitive to
%%% outliers. 

clonerecord(mouse, 'fvasOWtot', rat(1));
clonerecord(mouse, 'fintOWtot', rat(1));
clonerecord(mouse, 'fcelOWtot', rat(1));
clonerecord(mouse, 'fintOWtis', rat(1));
clonerecord(mouse, 'fcelOWtis', rat(1));

clonerecord(mouse, 'fvasVtot', rat(1));
clonerecord(mouse, 'fintVtot', rat(1));
clonerecord(mouse, 'fcelVtot', rat(1));
clonerecord(mouse, 'fintVtis', rat(1));
clonerecord(mouse, 'fcelVtis', rat(1));
clonerecord(mouse, 'fwtotVtis',rat(1));
clonerecord(mouse, 'fwicVtis', rat(1));
clonerecord(mouse, 'fwecVtis', rat(1));
clonerecord(mouse, 'fnliVtis', rat(1));
clonerecord(mouse, 'fnphVtis', rat(1));
clonerecord(mouse, 'faphVtis', rat(1));


%%% ========================================================================================================
%%% Data  : Fraction of experimental organ weight that is residual blood 
%%%
%%% Unit  : volume fraction of experimental organ weight
%%% Source: residual fractions, Garg, PhD thesis (2007), Table III, p.105,
%%%         reported as ratio of the residual blood volume to the tissue volume in mL/100g tissue
%%%

ref = 'Garg, PhD thesis (2007), Table III, p.105';
                                                                  % Alternative values from Brown et al, 1997 (Table 30): 
                                                                  % bon: 0.11 
                                                                  % bra: 0.03
addrecord(mouse, 'fresOWrbt', 'gut',  1.27 * u.percent, ref, [])
addrecord(mouse, 'fresOWrbt', 'hea',  4.81 * u.percent, ref, [])
addrecord(mouse, 'fresOWrbt', 'kid',  6.23 * u.percent, ref, [])  % [0.12-0.34], mean 0.24
addrecord(mouse, 'fresOWrbt', 'liv',  5.27 * u.percent, ref, [])  % [0.23-0.36], mean 0.31
addrecord(mouse, 'fresOWrbt', 'lun', 13.13 * u.percent, ref, [])  % [0.40-0.62], mean 0.50
addrecord(mouse, 'fresOWrbt', 'mus',  0.63 * u.percent, ref, [])  % [0.03-0.05], mean 0.04
addrecord(mouse, 'fresOWrbt', 'ski',  0.77 * u.percent, ref, [])  % 0.03
addrecord(mouse, 'fresOWrbt', 'spl', 21.51 * u.percent, ref, [])  % [0.17-0.19], mean 0.17


%%% ========================================================================================================
%%% Data  : Fraction of total blood volume that is regional peripheral blood volume
%%%         associated with each organ
%%%
%%% Unit  : percent (%)
%%% Source: see above
%%%

denstbl = getrecord(mouse,'dens','tbl');

for i = 1:numel(tissues)
    tis = tissues{i};
    
    OWtis  = getrecord(mouse,'OWtis',tis);
    fintOWtot = getrecord(mouse, 'fintOWtot', tis);
    fcelOWtot = getrecord(mouse, 'fcelOWtot', tis);
    OWtot  = OWtis ./ (fintOWtot+fcelOWtot); 
    Vvas  = getrecord(mouse,'fvasOWtot',tis) .* OWtot ./ denstbl;
    Vvas  = scd(Vvas,'L');     % set correct display unit (lost during multiplication)
    Vtis  = getrecord(mouse,'Vtis',tis);
    Vtot  = Vvas + Vtis;

    addrecord(mouse,'OWtot',tis,OWtot)    
    addrecord(mouse,'Vvas',tis,Vvas)
    addrecord(mouse,'Vtot',tis,Vtot)
    
    ires = hasrecord(mouse,'fresOWrbt',tis);
    if any(ires)
        fresOWrbt = getrecord(mouse(ires),'fresOWrbt',tis);
        OWrbt  = OWtis(ires) ./ (1 - fresOWrbt);          % from OWrbt = OWtis + fresOWrbt*OWrbt
        Vres  = fresOWrbt .* OWrbt ./ denstbl(ires); 
        Vres = scd(Vres,'L');     % set correct display unit (lost during multiplication)

        addrecord(mouse(ires),'OWrbt',tis,OWrbt)    
        addrecord(mouse(ires),'Vres',tis,Vres)
    end
    
    %%% define fraction of total blood that is regional blood, i.e.,
    %%% vascular blood associated with each organ
    
    fregVtbl = Vvas ./ getrecord(mouse,'Vtbl');

    addrecord(mouse,'fregVtbl',tis,fregVtbl)
end

%%% ASSUMPTION:
%%%
%%% Assume that veneous and arterial blood are 2/3 and 1/3 of 
%%% total blood and set the hematocrit value to 0.45

assum = 'Veneous and arterial blood assumed 2/3 and 1/3 of total blood';

addrecord(mouse,'fvenVtbl', 2/3, [], assum)
addrecord(mouse,'fartVtbl', 1/3, [], assum)
addrecord(mouse,'hct', 0.40, 'Windberger et al.', [])


%%% ========================================================================================================
%%% Data  : cardiac output and regional blood flows
%%%
%%% Unit  : co in [L/min] and fraction of co that is regional blood flow
%%% Source: Brown et al, Tox Ind Health 1997 (Table 24) or for the 3rd column
%%%         Baxter et al. (1994) as fraction of plasma flow = fraction of 
%%%         blood flow; and El-Masri and Portier, DMD Vol.26 (1998), 585-594
%%%         for adi, bon, bra, gut and spl
%%%

%%% Brown et al, Tox Ind Health 1997, p.440 (based on Arms and Travis
%%% (1988)), involving different scaling steps
co12 = str2u('0.275 L/min') * (getrecord(mouse,'BW')./u.kg).^0.75; % Brown et al, Tox Ind Health 1997, p.440
addrecord(mouse, 'co', co12)   


%%% fraction of cardiac output that is regional blood flow
%%%
%%%                                     9w        70w 
addrecord(mouse, 'fqbloCO', 'adi', [   7/100,    7/100], '?', []) %  7%   of blood flow, El-Masri (1998) 
addrecord(mouse, 'fqbloCO', 'bon', [  11/100,   11/100], '?', []) % 11%   of blood flow, El-Masri (1998) 
addrecord(mouse, 'fqbloCO', 'bra', [ 3.3/100,  3.3/100], '?', []) %  3.3% of blood flow, El-Masri (1998) 
addrecord(mouse, 'fqbloCO', 'gut', [14.1/100, 14.1/100], '?', []) % 14.1% of blood flow, El-Masri (1998)
addrecord(mouse, 'fqbloCO', 'hea', [ 6.6/100,  6.6/100], '?', [])
addrecord(mouse, 'fqbloCO', 'kid', [ 9.1/100,  9.1/100], '?', [])
addrecord(mouse, 'fqbloCO', 'liv', [16.2/100, 16.2/100], '?', [])
addrecord(mouse, 'fqbloCO', 'mus', [15.9/100, 15.9/100], '?', [])
addrecord(mouse, 'fqbloCO', 'ski', [ 5.8/100,  5.8/100], '?', [])
addrecord(mouse, 'fqbloCO', 'spl', [   1/100,    1/100], '?', []) %  1%   of blood flow, El-Masri (1998)

nolung = setdiff(tissues,'lun');

for i = 1:numel(nolung)
    
    tis = nolung{i};
    Q   = getrecord(mouse,'fqbloCO',tis) .* getrecord(mouse,'co');
    addrecord(mouse, 'Qblo', tis, Q)
end

%%% ========================================================================================================
%%% Data  : Fractions of tissue water (fwecVtis, fwicVtis, fwtotVtis)

clonerecord(mouse,'fwtotVtis',rat(1))  %NH added
clonerecord(mouse,'fwecVtis',rat(1))
clonerecord(mouse,'fwicVtis',rat(1))


%%% Data  : Neutral lipids (fnliVtis) and neurtal phospholipids (fnphVtis)

clonerecord(mouse,'fnliVtis',rat(1))
clonerecord(mouse,'fnphVtis',rat(1))


%%% Data  : Intra-cellular acidic phospholipids (aph) in rat

clonerecord(mouse,'faphVtis',rat(1))


%%% Data  : Albumin tissue-to-plasma ratio in mouse

clonerecord(mouse,'rtpAlb',rat(1))


%%% Data  : Lipoprotein tissue-to-plasma ratio in mouse

clonerecord(mouse,'rtpLip',rat(1))


%%% +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
%%% END: +++ MOUSE +++ MOUSE +++ MOUSE +++ MOUSE +++ MOUSE +++ MOUSE ++++++
%%% +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++

    
%%% +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
%%% BEGIN: HUMAN +++ HUMAN +++ HUMAN +++ HUMAN +++ HUMAN +++ HUMAN ++++++++
%%% +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++


%%% =======================================================================
%%% Model: Age and sex
%%%
%%% Children:
%%% newborn (nb), age 1 (age1), 5 (age5), 10 (age10) , all uni sex
%%% age 15 male (age15m), age 15 female (age15f), 
%%% Adults:
%%% age 20-50 male (age35m), age 20-50 female (age35f)
%%% As in the source, we associate an average age of 35 with the adult
%%% 
%%% Source: ICRP report 2002
%%%

nhumans = 8;
human(nhumans,1) = Physiology();   % IMPORTANT: since Physiology is a handle class, don't use `humans(1:nhumans) = Physiology()`!

human(1).name  = 'human0u';
human(2).name  = 'human1u';
human(3).name  = 'human5u';
human(4).name  = 'human10u';
human(5).name  = 'human15m';
human(6).name  = 'human15f';
human(7).name  = 'human35m';
human(8).name  = 'human35f';

ref = 'Basic covariates';

for i=1:nhumans
    addrecord(human(i), 'species', 'human',  ref, [])
    addrecord(human(i), 'type', 'Caucasian', ref, [])
end

addrecord(human(1), 'sex', 'unisex', ref, [])
addrecord(human(2), 'sex', 'unisex', ref, [])
addrecord(human(3), 'sex', 'unisex', ref, [])
addrecord(human(4), 'sex', 'unisex', ref, [])
addrecord(human(5), 'sex', 'male',   ref, [])
addrecord(human(6), 'sex', 'female', ref, [])
addrecord(human(7), 'sex', 'male',   ref, [])
addrecord(human(8), 'sex', 'female', ref, [])

addrecord(human(1), 'age', 0*u.year,  ref, [])
addrecord(human(2), 'age', 1*u.year,  ref, [])
addrecord(human(3), 'age', 5*u.year,  ref, [])
addrecord(human(4), 'age', 10*u.year, ref, [])
addrecord(human(5), 'age', 15*u.year, ref, [])
addrecord(human(6), 'age', 15*u.year, ref, [])
addrecord(human(7), 'age', 35*u.year, ref, [])
addrecord(human(8), 'age', 35*u.year, ref, [])



%%% ========================================================================================================
%%% Data  : Body weight (BW), body height (BH) and body surface area (BSA)
%%%
%%% Units : BW in kg, BH in cm, BSA in m^2
%%% Source: ICRP report 2002 (Table 2.9)
%%%

ref = 'ICRP report 2002 (Table 2.9)';

addrecord(human(1), 'BW', 3.5*u.kg, ref, [])
addrecord(human(2), 'BW',  10*u.kg, ref, [])
addrecord(human(3), 'BW',  19*u.kg, ref, [])
addrecord(human(4), 'BW',  32*u.kg, ref, [])
addrecord(human(5), 'BW',  56*u.kg, ref, [])
addrecord(human(6), 'BW',  53*u.kg, ref, [])
addrecord(human(7), 'BW',  73*u.kg, ref, [])
addrecord(human(8), 'BW',  60*u.kg, ref, [])

addrecord(human(1), 'BH', 51*u.cm,  ref, [])
addrecord(human(2), 'BH', 76*u.cm,  ref, [])
addrecord(human(3), 'BH', 109*u.cm, ref, [])
addrecord(human(4), 'BH', 138*u.cm, ref, [])
addrecord(human(5), 'BH', 167*u.cm, ref, [])
addrecord(human(6), 'BH', 161*u.cm, ref, [])
addrecord(human(7), 'BH', 176*u.cm, ref, [])
addrecord(human(8), 'BH', 163*u.cm, ref, [])


for i=1:nhumans
    BW = getrecord(human(i), 'BW');
    BH = getrecord(human(i), 'BH');
    BMI = BW/BH^2;
    addrecord(human(i), 'BMI', BMI)
end
%                           nb   age1    age5   age10  age15m  age15f  age35m   age35f
addrecord(human, 'BSA', [ 0.24   0.48    0.78    1.12    1.62    1.55    1.90    1.66] * u.m^2, ref, [])


%%% ========================================================================================================
%%% Data  : Organ weight, density and volume 
%%%
%%% Unit  : weight in g, density in g/mL, volume in L
%%% Source: ICRP report 2002 (Table 2.8)
%%% 
%%% 

ref = 'ICRP report 2002 (Table 2.8)';

assum = ['experimental organ weights (incl. residual blood to some varying degree) '...
    'approximately equal to tissue organ weight'];
                                             %%% nb   age1   age5  age10  age15m  age15f  age35m   age35f  
addrecord(human, 'OWtis', 'adipose_tissue',    [930   3800   5500   8600   12000   18700   18200   22500] * u.g, ref, assum) % entry duplicates other mass information
addrecord(human, 'OWtis', 'separable_adipose', [890   3600   5000   7500    9500   16000   14500   19000] * u.g, ref, assum)
addrecord(human, 'OWtis', 'adrenals',          [  6      4      5      7      10       9      14      13] * u.g, ref, assum)

% alimentary system                                                nb   age1   age5  age10  age15m  age15f  age35m   age35f
addrecord(human, 'OWtis', 'tongue',                              [  3.5   10     19     32      56      53      73      60] * u.g, ref, assum)
addrecord(human, 'OWtis', 'salivary_glands',                     [  6     24     34     44      68      65      85      70] * u.g, ref, assum)
addrecord(human, 'OWtis', 'oesophagus_wall',                     [  2      5     10     18      30      30      40      35] * u.g, ref, assum)
addrecord(human, 'OWtis', 'stomach_wall',                        [  7     20     50     85     120     120     150     140] * u.g, ref, assum)
addrecord(human, 'OWtis', 'stomach_content',                     [ 40     67     83    117     200     200     250     230] * u.g, ref, assum)
addrecord(human, 'OWtis', 'small_intestine_wall',                [ 30     85    220    370     520     520     650     600] * u.g, ref, assum)
addrecord(human, 'OWtis', 'small_intestine_contents',            [ 56     93    117    163     280     280     350     280] * u.g, ref, assum)
addrecord(human, 'OWtis', 'large_intestine_right_colon_wall',    [  7     20     49     85     122     122     150     145] * u.g, ref, assum)
addrecord(human, 'OWtis', 'large_intestine_right_colon_content', [ 24     40     50     70     120     120     150     160] * u.g, ref, assum)
addrecord(human, 'OWtis', 'large_intestine_left_colon_wall',     [  7     20     49     85     122     122     150     145] * u.g, ref, assum)
addrecord(human, 'OWtis', 'large_intestine_left_colon_content',  [ 12     20     25     35      60      60      75      80] * u.g, ref, assum)
addrecord(human, 'OWtis', 'large_intestine_rectosigmoid_wall',   [  3     10     22     40      56      56      70      70] * u.g, ref, assum)
addrecord(human, 'OWtis', 'small_intestine_rectosigmoid_content',[ 12     20     25     35      60      60      75      80] * u.g, ref, assum)
addrecord(human, 'OWtis', 'liver',                               [130    330    570    830    1300    1300    1800    1400] * u.g, ref, assum)
addrecord(human, 'OWtis', 'gallbladder_wall',                    [  0.5    1.4    2.6    4.4     7.7     7.3    10       8] * u.g, ref, assum)
addrecord(human, 'OWtis', 'gallbladder_content',                 [  2.8    8     15     26      45      42      58      48] * u.g, ref, assum)
addrecord(human, 'OWtis', 'pancreas',                            [  6     20     35     60     110     100     140     120] * u.g, ref, assum)


%%% Note: brain organ weight age5  = 1245 = mean value of 1310 (male) and 1180 (female) 
%%%       brain organ weight age10 = 1310 = mean value of 1400 (male) and 1220 (female) 
%                                               nb   age1   age5  age10  age15m  age15f  age35m   age35f
addrecord(human, 'OWtis', 'brain',            [380    950   1245   1310    1420    1300    1450    1300] * u.g, ref, assum)
addrecord(human(5:8), 'OWtis', 'breasts',                                [   15     250      25     500] * u.g, ref, assum)
% circulatory system
addrecord(human, 'OWtis', 'heart_with_blood', [ 46     98    220    370     660     540     840     620] * u.g, ref, assum) % entry duplicates other mass information
addrecord(human, 'OWtis', 'heart_tissue_only',[ 20     50     85    140     230     220     330     250] * u.g, ref, assum)
% Table sec 7.4
addrecord(human, 'OWtbl'       ,              [270    500   1400   2400    4500    3300    5300    3900] * u.g, ref, assum)
addrecord(human, 'OWtis', 'eyes',             [  6      7     11     12      13      13      15      15] * u.g, ref, assum)
addrecord(human, 'OWtis', 'storage_fat',      [370   2300   3600   6000    9000   14000   14600   18000] * u.g, ref, assum)
addrecord(human, 'OWtis', 'skin',             [175    350    570    820    2000    1700    3300    2300] * u.g, ref, assum)
addrecord(human, 'OWtis', 'skeletal_muscle',  [800   1900   5600  11000   24000   17000   29000   17500] * u.g, ref, assum)
addrecord(human, 'OWtis', 'pituitary_gland',  [  0.1   0.15   0.25   0.35     0.5     0.5     0.6     0.6]*u.g, ref, assum)
% Respiratory system
addrecord(human, 'OWtis', 'larynx',           [  1.3    4      7     12      22      15      28      19] * u.g, ref, assum)
addrecord(human, 'OWtis', 'trachea',          [  0.5    1.5    2.5    4.5     7.5     6      10       8] * u.g, ref, assum)
addrecord(human, 'OWtis', 'lung_with_blood',  [ 60    150    300    500     900     750    1200     950] * u.g, ref, assum) % entry duplicates other mass information
addrecord(human, 'OWtis', 'lung_tissue_only', [ 30     80    125    210     330     290     500     420] * u.g, ref, assum)
% skeletal system
addrecord(human, 'OWtis', 'total_skeleton',   [370   1170   2430   4500    7950    7180   10500    7800] * u.g, ref, assum) % entry duplicates other mass information
addrecord(human, 'OWtis', 'bone_cortical',    [135    470   1010   1840    3240    2960    4400    3200] * u.g, ref, assum)
addrecord(human, 'OWtis', 'bone_trabecular',  [ 35    120    250    460     810     740    1100     800] * u.g, ref, assum)
% bone_total = bone_cortical + bone_trabecular
addrecord(human, 'OWtis', 'bone_total',       [170    590   1260   2300    4050    3700    5500    4000] * u.g, ref, assum) % entry duplicates other mass information
addrecord(human, 'OWtis', 'marrow_active',    [ 50    150    340    630    1080    1000    1170     900] * u.g, ref, assum)
addrecord(human, 'OWtis', 'marrow_inactive',  [  0     20    160    630    1480    1380    2480    1800] * u.g, ref, assum)
addrecord(human, 'OWtis', 'cartilage',        [130    360    600    820    1140     920    1100     900] * u.g, ref, assum)
addrecord(human, 'OWtis', 'teeth',            [  0.7    5     15     30      45      35      50      40] * u.g, ref, assum)
addrecord(human, 'OWtis', 'skeleton_misc',    [ 20     45     55     90     155     145     200     160] * u.g, ref, assum) %miscellaneous
addrecord(human, 'OWtis', 'spleen',           [  9.5   29     50     80     130     130     150     130] * u.g, ref, assum)

%%% Note: thymus organ weight age10 = 37.5 = mean value of 40 (male) and 35 (female) 
addrecord(human, 'OWtis', 'thymus',           [ 13     30     30     37.5    35      30      25      20] * u.g, ref, assum)
addrecord(human, 'OWtis', 'thyroid',          [  1.3    1.8    3.4    7.9    12      12      20      17] * u.g, ref, assum)
addrecord(human, 'OWtis', 'tonsils',          [  0.1    0.5    2      3       3       3        3      3] * u.g, ref, assum)
% Urogenital system
addrecord(human, 'OWtis', 'kidneys',          [ 25     70    110    180     250     240     310     275] * u.g, ref, assum)
addrecord(human, 'OWtis', 'ureters',          [  0.77   2.2    4.2    7.0    12      12      16      15] * u.g, ref, assum)
addrecord(human, 'OWtis', 'uninary_bladder',  [  4      9     16     25      40      35      50      40] * u.g, ref, assum)

%%% Note: urethra organ weight nb    = 0.31 = mean value of 0.48 (male) and 0.14 (female) 
%%%       urethra organ weight age1  = 0.91 = mean value of 1.4  (male) and 0.42 (female) 
%%%       urethra organ weight age5  = 1.69 = mean value of 2.6  (male) and 0.78 (female) 
%%%       urethra organ weight age10 = 2.85 = mean value of 4.4  (male) and 1.3  (female) 
addrecord(human, 'OWtis', 'urethra',          [  0.31   0.91   1.69   2.85    7.7     2.3    10       3] * u.g, ref, assum)
addrecord(human, 'OWtis', 'testers',          [  0.85   1.5    1.7    2      16       0      35       0] * u.g, ref, assum) 
addrecord(human, 'OWtis', 'epididymes',       [  0.25   0.35   0.45   0.6     1.6     0       4       0] * u.g, ref, assum)
addrecord(human, 'OWtis', 'prostate',         [  0.8    1.0    1.2    1.6     4.3     0      17       0] * u.g, ref, assum)
addrecord(human, 'OWtis', 'ovaries',          [  0.3    0.8    2.0    3.5     0       6       0      11] * u.g, ref, assum)
addrecord(human, 'OWtis', 'fallopian_tubes',  [  0.25   0.25   0.35   0.50    0       1.1     0     2.1] * u.g, ref, assum) 
addrecord(human, 'OWtis', 'uterus',           [  4.0    1.5    3      4       0      30       0      80] * u.g, ref, assum)


%%% ========================================================================================================
%%% Data  : Regional blood volumes as percentage of total blood volume
%%%
%%% Unit  : percent (%)
%%% Source: ICRP report 2002 (Table 2.14)
%%%

ref = 'ICRP report 2002 (Table 2.14)';

%%%                                              
adults = human{'human35m','human35f'};         %        age35m   age35f
addrecord(adults, 'fregVtbl', 'fat',                    [ 5.00    8.50] * u.percent, ref, [])
addrecord(adults, 'fregVtbl', 'brain',                  [ 1.20    1.20] * u.percent, ref, [])
addrecord(adults, 'fregVtbl', 'stomach_and_oesophagus', [ 1.00    1.00] * u.percent, ref, [])
addrecord(adults, 'fregVtbl', 'small_intestine',        [ 3.80    3.80] * u.percent, ref, [])
addrecord(adults, 'fregVtbl', 'large_intestine',        [ 2.20    2.20] * u.percent, ref, [])
addrecord(adults, 'fregVtbl', 'right_heart',            [ 4.50    4.50] * u.percent, ref, [])
addrecord(adults, 'fregVtbl', 'left_heart',             [ 4.50    4.50] * u.percent, ref, [])
addrecord(adults, 'fregVtbl', 'coronary_tissue',        [ 1.00    1.00] * u.percent, ref, [])
addrecord(adults, 'fregVtbl', 'kidneys',                [ 2.00    2.00] * u.percent, ref, [])
addrecord(adults, 'fregVtbl', 'liver',                  [10.00   10.00] * u.percent, ref, [])
addrecord(adults, 'fregVtbl', 'bronchial_tissue',       [ 2.00    2.00] * u.percent, ref, [])
addrecord(adults, 'fregVtbl', 'skeletal_muscle',        [14.00   10.50] * u.percent, ref, [])
addrecord(adults, 'fregVtbl', 'pancreas',               [ 0.60    0.60] * u.percent, ref, [])
addrecord(adults, 'fregVtbl', 'skeleton_total',         [ 7.00    7.00] * u.percent, ref, [])
addrecord(adults, 'fregVtbl', 'skeleton_red_marrow',    [ 4.00    4.00] * u.percent, ref, [])  % entry duplicates other information
addrecord(adults, 'fregVtbl', 'skeleton_trabecular_bone',[1.20    1.20] * u.percent, ref, [])  % entry duplicates other information
addrecord(adults, 'fregVtbl', 'skeleton_cortical_bone', [ 0.80    0.80] * u.percent, ref, [])  % entry duplicates other information
addrecord(adults, 'fregVtbl', 'skeleton_others',        [ 1.00    1.00] * u.percent, ref, [])  % entry duplicates other information
addrecord(adults, 'fregVtbl', 'skin',                   [ 3.00    3.00] * u.percent, ref, [])
addrecord(adults, 'fregVtbl', 'spleen',                 [ 1.40    1.40] * u.percent, ref, [])
addrecord(adults, 'fregVtbl', 'thyroid',                [ 0.06    0.06] * u.percent, ref, [])
addrecord(adults, 'fregVtbl', 'lymph_nodes',            [ 0.20    0.20] * u.percent, ref, [])
addrecord(adults, 'fregVtbl', 'gonads',                 [ 0.04    0.02] * u.percent, ref, [])
addrecord(adults, 'fregVtbl', 'adrenals',               [ 0.06    0.06] * u.percent, ref, [])
addrecord(adults, 'fregVtbl', 'uninary_bladder',        [ 0.02    0.02] * u.percent, ref, [])
addrecord(adults, 'fregVtbl', 'all_other_tissues',      [ 1.92    1.92] * u.percent, ref, [])

%%% ========================================================================================================
%%% Data  : Volume of total blood, blood plasma and red blood cells
%%%
%%% Unit  : ml
%%% Source: ICRP report (Table 2.12)

ref = 'ICRP report (Table 2.12)';
%                                        age35m   age35f   
addrecord(adults, 'Vtis', 'erythrocyte', [ 2300    1500] * u.mL, ref, [])
addrecord(adults, 'Vtis', 'plasma',      [ 3000    2400] * u.mL, ref, [])

%%% ========================================================================================================
%%% Data  : Distribution of blood in the vascular system
%%%
%%% Unit  : Percentage (%) of total blood volume
%%% Source: ICRP report 2002 (Table 2.13) 

ref = 'ICRP report (Table 2.13)';

%NH eigentlich kein 'fregVtbl'...

addrecord(human{'human35m'}, 'fregVtbl', 'heart_chambers',                  9.00 * u.percent, ref, [])
addrecord(human{'human35m'}, 'fregVtbl', 'pulmonary_total',                10.50 * u.percent, ref, [])
addrecord(human{'human35m'}, 'fregVtbl', 'pulmonary_arteries',              3.00 * u.percent, ref, [])
addrecord(human{'human35m'}, 'fregVtbl', 'pulmonary_capillaries',           2.00 * u.percent, ref, [])
addrecord(human{'human35m'}, 'fregVtbl', 'pulmonary_veins',                 5.50 * u.percent, ref, [])
addrecord(human{'human35m'}, 'fregVtbl', 'systemic_total',                 80.50 * u.percent, ref, [])
addrecord(human{'human35m'}, 'fregVtbl', 'systemic_aorta_large_arteries',   6.00 * u.percent, ref, [])
addrecord(human{'human35m'}, 'fregVtbl', 'systemic_small_arteries',        10.00 * u.percent, ref, [])
addrecord(human{'human35m'}, 'fregVtbl', 'systemic_capillaries',            5.00 * u.percent, ref, [])
addrecord(human{'human35m'}, 'fregVtbl', 'systemic_small_veins',           41.50 * u.percent, ref, [])
addrecord(human{'human35m'}, 'fregVtbl', 'systemic_large_veins',           18.00 * u.percent, ref, [])


%%% ========================================================================================================
%%% Data  : Density of tissue
%%%
%%% Unit  : kg/l (= g/cm^3)
%%% Source: Brown et al, Tox Ind Health 1997 and ICRP report 1975 
%%% 

ref = struct;
ref.brown = 'Brown et al, Tox Ind Health 1997, Table 19';
ref.icrp75 = 'ICRP report 1975, p.44';
ref.icrp02 = 'ICRP report 2002, Table 2.20 (whole skeleton, adults)';

addrecord(human, 'dens', 'adi', '0.916 kg/L',   ref.icrp75, []) 
addrecord(human, 'dens', 'bon', '1.3   kg/L',   ref.icrp02, []) % (whole skeleton, adults)
addrecord(human, 'dens', 'bra', '1     kg/L',   ref.brown,  []) 
addrecord(human, 'dens', 'gut', '1     kg/L',   ref.brown,  [])
addrecord(human, 'dens', 'hea', '1     kg/L',   ref.brown,  [])
addrecord(human, 'dens', 'kid', '1     kg/L',   ref.brown,  [])
addrecord(human, 'dens', 'liv', '1     kg/L',   ref.brown,  [])
addrecord(human, 'dens', 'lun', '1     kg/L',   ref.brown,  [])
addrecord(human, 'dens', 'mus', '1     kg/L',   ref.brown,  [])
addrecord(human, 'dens', 'ski', '1     kg/L',   ref.brown,  [])
addrecord(human, 'dens', 'spl', '1     kg/L',   ref.brown,  [])

addrecord(human, 'dens', 'tbl', '1     kg/L',   ref.brown,  [])


% Total blood volume

Vtbl = getrecord(human, 'OWtbl') ./ getrecord(human,'dens','tbl') ;
addrecord(human, 'Vtbl', Vtbl)


%%% ========================================================================================================
%%% Data  : pH values in plasma/interstitital water and intra-cellular
%%% water
%%%
%%% Unit  : - 
%%% Source: Rodgers, Leahy, and Rowland, J Pharm Sci (2005), p. 1263
%%%

clonerecord(human, 'pH', rat{'rat250'})


%%% ========================================================================================================
%%% Model: Regional vascular blood volumes and fractions of total blood
%%%
%%% Unit : [L] and fraction of total blood
%%%


aliasrecord(adults, 'fregVtbl', 'fat',             'adi');
aliasrecord(adults, 'fregVtbl', 'skeleton_total',  'bon');
aliasrecord(adults, 'fregVtbl', 'brain',           'bra');
aliasrecord(adults, 'fregVtbl', 'coronary_tissue', 'hea');
aliasrecord(adults, 'fregVtbl', 'kidneys',         'kid');
aliasrecord(adults, 'fregVtbl', 'liver',           'liv');
aliasrecord(adults, 'fregVtbl', 'bronchial_tissue','lun');
aliasrecord(adults, 'fregVtbl', 'skeletal_muscle', 'mus');
aliasrecord(adults, 'fregVtbl', 'skin',            'ski');
aliasrecord(adults, 'fregVtbl', 'spleen',          'spl');


fregVtbl_gut = getrecord(adults,'fregVtbl','small_intestine') + getrecord(adults,'fregVtbl','large_intestine');
addrecord(adults, 'fregVtbl', 'gut', fregVtbl_gut);

% fraction of arterial / venous blood
getregVtbl = @(x) getrecord(human{'human35m'}, 'fregVtbl', x);

fartVtbl = 0.5*getregVtbl('heart_chambers') ...
    + getregVtbl('pulmonary_veins') ...
    + 0.5*getregVtbl('pulmonary_capillaries') ...
    + 0.5*getregVtbl('systemic_capillaries') ...
    + getregVtbl('systemic_aorta_large_arteries') ...
    + getregVtbl('systemic_small_arteries');
fvenVtbl = 0.5*getregVtbl('heart_chambers') ...
    + getregVtbl('pulmonary_arteries') ...
    + 0.5*getregVtbl('pulmonary_capillaries') ...
    + 0.5*getregVtbl('systemic_capillaries') ...
    + getregVtbl('systemic_large_veins') ...
    + getregVtbl('systemic_small_veins');

addrecord(human{'human35m'}, 'fartVtbl', fartVtbl);
addrecord(human{'human35m'}, 'fvenVtbl', fvenVtbl);


% hematocrit
hct = getrecord(adults, 'Vtis', 'erythrocyte') ./ getrecord(adults, 'Vtbl');
addrecord(adults, 'hct', hct)


%%% ASSUMPTION: 
%%%
%%% For female adults, male data for fraction of venous and arterial blood 
%%% were adopted

clonerecord(human{'human35f'}, 'fvenVtbl', human{'human35m'})
clonerecord(human{'human35f'}, 'fartVtbl', human{'human35m'})

%%% ASSUMPTION: 
%%%
%%% For children of age 1,5, 10 and 15f, adult female data were adopted 
%%% for all fVblood entries. For children of age 15m, corresponding 
%%% adult male data were adopted. This is in line with the NHANES study 
%%% (for age 5 and older)
%%% 
%%%
children    = {'human0u', 'human1u', 'human5u' ,'human10u','human15m','human15f'};
refAgeClass = {'human35f','human35f','human35f','human35f','human35m','human35f'};  

for a = 1:length(children)   
    
    %%% target age (age) and age class used for reference (refAge)
    age        = children{a};
    refAge     = refAgeClass{a};
    clonerecord(human{age}, 'hct',      human{refAge})
    clonerecord(human{age}, 'fvenVtbl', human{refAge})
    clonerecord(human{age}, 'fartVtbl', human{refAge})
    clonerecord(human{age}, 'fregVtbl', human{refAge})
        
end

%%% ========================================================================================================
%%% Model: Organ weights (OW) and tissue volumes (V)
%%%
%%% Unit : OW in kg and V in L 
%%%

% standard naming convention
aliasrecord(human, 'OWtis', 'separable_adipose','adi')
aliasrecord(human, 'OWtis', 'total_skeleton',   'bon') % includes total bone and marrow
aliasrecord(human, 'OWtis', 'brain',            'bra')

OWgut = getrecord(human,'OWtis','small_intestine_wall') ...
    + getrecord(human,'OWtis','large_intestine_right_colon_wall') ...
    + getrecord(human,'OWtis','large_intestine_left_colon_wall') ...
    + getrecord(human,'OWtis','large_intestine_rectosigmoid_wall');
    
addrecord(human,   'OWtis', 'gut', OWgut)

aliasrecord(human, 'OWtis', 'heart_tissue_only','hea')
aliasrecord(human, 'OWtis', 'kidneys',          'kid')
aliasrecord(human, 'OWtis', 'liver',            'liv')
aliasrecord(human, 'OWtis', 'lung_tissue_only', 'lun')
aliasrecord(human, 'OWtis', 'skeletal_muscle',  'mus')
aliasrecord(human, 'OWtis', 'skin',             'ski')
aliasrecord(human, 'OWtis', 'spleen',           'spl')

BW = getrecord(human, 'BW');
LBW = BW - getrecord(human, 'OWtis', 'adi');
addrecord(human, 'LBW', LBW)

for i=1:numel(tissues)
    tis = tissues{i};
    
    % organ weight fraction of body weight
    OWtis = getrecord(human, 'OWtis', tis);
    fowtisBW =  OWtis./ BW;
    addrecord(human, 'fowtisBW', tis, fowtisBW)
    
    % tissue volumes
    Vtis = OWtis ./ getrecord(human, 'dens', tis);
    Vvas = getrecord(human, 'fregVtbl', tis) .* getrecord(human, 'Vtbl');
    Vtot = Vtis + Vvas;
    
    addrecord(human, 'Vtis', tis, Vtis)
    addrecord(human, 'Vvas', tis, Vvas)
    addrecord(human, 'Vtot', tis, Vtot)
    
end


%%% ========================================================================================================
%%% Data  : Cardiac output
%%%
%%% Unit  : L/min
%%% Source: ICRP report 2002 (Table 2.39). For newborn and children age 1,
%%% the values of Alverson et al 1987 (cited in Abraham et al, Arch Toxicol 
%%% (2005) 79: 63?73) have been taken, since the values of the ICRP report
%%% appear to be too low (age1: ICRP.co=1.2, Alverson.co = 1.8. For newborn
%%% the difference is 0.6 vs. 0.7. The ICRP value for age 1 is a marked
%%% outlier from the expectations of allometric scaling. 

ref = struct;
ref.icrp2002 = 'ICRP report 2002 (Table 2.39)';
ref.alverson = 'Alverson et al 1987 (cited in Abraham et al, Arch Toxicol (2005) 79: 63-73)';

%%%                          nb   age1   age5  age10  age15m  age15f  age35m   age35f
addrecord(human(3:8), 'co',              [3.4    5.0     6.1     6.1     6.5     5.9] * str2u('L/min'), ref.icrp2002, []);
addrecord(human(1:2), 'co', [44   109]/60                                             * str2u('L/min'), ref.alverson, [])

%%% ========================================================================================================
%%% Data  : blood flow rates
%%%
%%% Unit  : percentage (%) of cardiac output
%%% Source: ICRP report 2002 (Table 2.40)

ref = 'ICRP report 2002 (Table 2.40)';
%                                                        age35m   age35f
addrecord(adults, 'fqbloCO', 'fat',                     [  5.00    8.50] * u.percent, ref, [])
addrecord(adults, 'fqbloCO', 'brain',                   [ 12.00   12.00] * u.percent, ref, [])
addrecord(adults, 'fqbloCO', 'stomach_and_oesophagus',  [  1.00    1.00] * u.percent, ref, []) % not used in PBPK model
addrecord(adults, 'fqbloCO', 'small_intestine',         [ 10.00   11.00] * u.percent, ref, [])
addrecord(adults, 'fqbloCO', 'large_intestine',         [  4.00    5.00] * u.percent, ref, [])
addrecord(adults, 'fqbloCO', 'coronary_tissue',         [  4.00    5.00] * u.percent, ref, [])
addrecord(adults, 'fqbloCO', 'kidney',                  [ 19.00   17.00] * u.percent, ref, [])
addrecord(adults, 'fqbloCO', 'liver',                   [ 25.50   27.00] * u.percent, ref, []) % total, arterial = [6.5 6.5]
addrecord(adults, 'fqbloCO', 'bronchial_tissue',        [  2.50    2.50] * u.percent, ref, []) % not used in PBPK model
addrecord(adults, 'fqbloCO', 'skeletal_muscle',         [ 17.00   12.00] * u.percent, ref, [])
addrecord(adults, 'fqbloCO', 'pancreas',                [  1.00    1.00] * u.percent, ref, []) % not used in PBPK model
addrecord(adults, 'fqbloCO', 'skeleton_total',          [  5.00    5.00] * u.percent, ref, [])
addrecord(adults, 'fqbloCO', 'skeleton_red_marrow',     [  3.00    3.00] * u.percent, ref, [])
addrecord(adults, 'fqbloCO', 'skeleton_trabecular_bone',[  0.90    0.90] * u.percent, ref, [])
addrecord(adults, 'fqbloCO', 'skeleton_cortical_bone',  [  0.60    0.60] * u.percent, ref, [])
addrecord(adults, 'fqbloCO', 'skeleton_others',         [  0.50    0.50] * u.percent, ref, [])
addrecord(adults, 'fqbloCO', 'skin',                    [  5.00    5.00] * u.percent, ref, [])
addrecord(adults, 'fqbloCO', 'spleen',                  [  3.00    3.00] * u.percent, ref, [])
addrecord(adults, 'fqbloCO', 'thyroid',                 [  1.50    1.50] * u.percent, ref, []) % not used in PBPK model
addrecord(adults, 'fqbloCO', 'lymph_nodes',             [  1.70    1.70] * u.percent, ref, []) % not used in PBPK model
addrecord(adults, 'fqbloCO', 'gonads',                  [  0.05    0.02] * u.percent, ref, []) % not used in PBPK model
addrecord(adults, 'fqbloCO', 'adrenals',                [  0.30    0.30] * u.percent, ref, []) % not used in PBPK model
addrecord(adults, 'fqbloCO', 'urinary_bladder',         [  0.06    0.06] * u.percent, ref, []) % not used in PBPK model
addrecord(adults, 'fqbloCO', 'all_other_tissues',       [  1.39    1.92] * u.percent, ref, []) % not used in PBPK model

aliasrecord(adults, 'fqbloCO', 'fat',            'adi')
aliasrecord(adults, 'fqbloCO', 'skeleton_total', 'bon')
aliasrecord(adults, 'fqbloCO', 'brain',          'bra')

fqbloCO_gut = getrecord(adults, 'fqbloCO', 'small_intestine') ...
    + getrecord(adults, 'fqbloCO', 'large_intestine');
addrecord(adults, 'fqbloCO', 'gut', fqbloCO_gut)

aliasrecord(adults, 'fqbloCO', 'coronary_tissue','hea')
aliasrecord(adults, 'fqbloCO', 'kidney',         'kid')
aliasrecord(adults, 'fqbloCO', 'liver',          'liv')
aliasrecord(adults, 'fqbloCO', 'skeletal_muscle','mus')
aliasrecord(adults, 'fqbloCO', 'skin',           'ski')
aliasrecord(adults, 'fqbloCO', 'spleen',         'spl')

%%% ========================================================================================================
%%% Model: Tissue blood flow (fraction of cardiac output and absolut values)
%%%
%%% Unit : fraction and L/min
%%% 
%%% 

for i=1:numel(nolung)
    tis = nolung{i};
    
    % organ weight fraction of body weight
    Q = getrecord(adults, 'fqbloCO', tis) .* getrecord(adults, 'co');
    addrecord(adults, 'Qblo', tis, Q)
end


%%% ASSUMPTION: 
%%%
%%% For all children age classes: fQco values were estimated based on the
%%% approach presented in Abraham et al, Arch Toxicol, Vol 79 (2005), pp.
%%% 63-73, except when experimental data are available
%%%

children    = {'human0u', 'human1u', 'human5u' ,'human10u','human15m','human15f'};
refAgeClass = {'human35f','human35f','human35f','human35f','human35m','human35f'};  

%%% used experimental data for children
%%%
%%% Brain:
%%% Blood flow data in [ml/min/100g] that were converted to [L/min/kg] from
%%% Chiron et al, 1992

Q_perKg_bra = [50 59 71 68 57 57] * u.mL/u.min/(100*u.g);

%%%
%%% Kidneys: 
%%% Assume that blood flow per kg kidney tissue is independent of age
%%% according to Grunert et al, 1990

for a = 1:length(children)   
    
    %%% target age (age) and age class used for reference (refAge)
    age        = children{a};
    refAge     = refAgeClass{a};

    %%% intermediate target regional blood flow, scaled solely 
    %%% according to ratio of target-to-reference tissue volumes
    for i = 1:numel(nolung)

        tis = nolung{i};    

        refQblo  = getrecord(human{refAge}, 'Qblo',  tis);
        refOWtis = getrecord(human{refAge}, 'OWtis', tis);
        tarOWtis = getrecord(human{age},    'OWtis', tis);

        SF_Qblo   = tarOWtis ./ refOWtis;
        Q_inter    = SF_Qblo .* refQblo;
        
        addrecord(human{age}, 'Qblo', tis, Q_inter)  % intermediate value, will be updated
    end
    
    %%% use experimental data for children (see above)
    Qbra = Q_perKg_bra(a) * getrecord(human{age}, 'OWtis', 'bra');
    Qbra = scd(Qbra,'mL/min');
    updaterecord(human{age}, 'Qblo', 'bra', Qbra)
    
    % rest of body (rob) 
    intoven = setdiff(nolung, {'gut', 'spl'});
    
    sumQblo_ref  = sum(cellfun(@(x) getrecord(human{refAge},'Qblo', x), intoven));
    sumOWtis_ref = sum(cellfun(@(x) getrecord(human{refAge},'OWtis',x), intoven));
    sumOWtis_tar = sum(cellfun(@(x) getrecord(human{age},   'OWtis',x), intoven));
    
    refQblo_rob = getrecord(human{refAge},'co') - sumQblo_ref;
    refOWtis_rob = getrecord(human{refAge},'BW') - sumOWtis_ref - getrecord(human{refAge},'OWtbl');
    tarOWtis_rob = getrecord(human{age},'BW') - sumOWtis_tar - getrecord(human{age},'OWtbl');
   
    Q_inter_rob = tarOWtis_rob ./ refOWtis_rob .* refQblo_rob;
    
    addrecord(human{age}, 'Qblo', 'rob', Q_inter_rob)

    %%% Scale all regional tissue blood flows to match cardiac output.
    %%% First, scale all blood flows that flow into the vein, 
    %%% including rest of body, but excluding those tissues where 
    %%% experimental data were used (brain and kidney).
    
    intovenrob_nokb = setdiff([intoven 'rob'], {'kid','bra'});
    sumQinter = sum(cellfun(@(x) getrecord(human{age},'Qblo', x), intovenrob_nokb));
    SF_co = (getrecord(human{age},'co') ...
           - getrecord(human{age},'Qblo','kid') ...
           - getrecord(human{age},'Qblo','bra')) / sumQinter; 
       
    if SF_co < 1
        fprintf('\n Scaling blood flows to children resulted in cardiac output that is larger than the experimental reported one!\n\n');
    end
    
    for i = 1:numel(intovenrob_nokb)

        tis = intovenrob_nokb{i};   
 
        Qblo = SF_co * getrecord(human{age}, 'Qblo', tis);
        updaterecord(human{age}, 'Qblo', tis, Qblo)
    end
        
    %%% Second, scale all regional tissue blood flows that flow into the
    %%% liver (here gut and spleen). To this end, determine hepartic artery
    %%% blood flow (hepart)
    
    Qhepart = getrecord(human{refAge}, 'Qblo', 'liv') ...
        - getrecord(human{refAge}, 'Qblo', 'gut') ...
        - getrecord(human{refAge}, 'Qblo', 'spl');
    Q_perKg_hepart = Qhepart / getrecord(human{refAge}, 'OWtis', 'liv');
    
    Qinter_hepart = Q_perKg_hepart * getrecord(human{age}, 'OWtis', 'liv');
    
    Qblo_liv = getrecord(human{age}, 'Qblo', 'liv');
    Qblo_gut = getrecord(human{age}, 'Qblo', 'gut');
    Qblo_spl = getrecord(human{age}, 'Qblo', 'spl');
    
    SF_hepart  = Qblo_liv / (Qinter_hepart + Qblo_gut + Qblo_spl);    
    if SF_hepart < 1
        fprintf('\n Scaling blood flows to children resulted in liver blood flow that is larger than the experimental reported one!\n\n');
    end
    
    updaterecord(human{age}, 'Qblo', 'gut', Qblo_gut * SF_hepart)
    updaterecord(human{age}, 'Qblo', 'spl', Qblo_spl * SF_hepart)
    
    deleterecord(human{age}, 'Qblo', 'rob') 
    
end



%%% assign  fractions of cardiac output

children = human(1:6);
for i = 1:numel(nolung)
    tis = nolung{i};
    
    fqbloCO = getrecord(children, 'Qblo',tis) ./ getrecord(children, 'co');
    addrecord(children, 'fqbloCO', tis, fqbloCO)
end


%%% ========================================================================================================
%%% Data  : Total tissue water (Vwt)
%%%
%%% Unit  : fraction of tissue volume
%%% Source: Poulin & Theil, J Pharm Sci, Vol 91, 2002 and Poulin & Theil, J Pharm Sci, 2009 for ery value
%%% 

%%% ASSUMPTION: 
%%% 
%%% Fractions of experimental tissue volumes are identical to the 
%%% fractions of tissue volume

ref = struct;
ref.poulin2002 = 'Poulin & Theil, J Pharm Sci, Vol 91, 2002';
ref.poulin2009 = 'Poulin & Theil, J Pharm Sci, 2009';

assum = 'fractions of experimental volumes identical to fractions of tissue volumes';

addrecord(human, 'fwtotVtis', 'lun', 0.811,   ref.poulin2002, assum)
addrecord(human, 'fwtotVtis', 'kid', 0.783,   ref.poulin2002, assum)
addrecord(human, 'fwtotVtis', 'spl', 0.778,   ref.poulin2002, assum)
addrecord(human, 'fwtotVtis', 'bra', 0.77,   ref.poulin2002, assum)
addrecord(human, 'fwtotVtis', 'mus', 0.76,   ref.poulin2002, assum)
addrecord(human, 'fwtotVtis', 'hea', 0.758,   ref.poulin2002, assum)
addrecord(human, 'fwtotVtis', 'liv', 0.751,   ref.poulin2002, assum)
addrecord(human, 'fwtotVtis', 'gut', 0.718,   ref.poulin2002, assum)
addrecord(human, 'fwtotVtis', 'ski', 0.718,   ref.poulin2002, assum)
addrecord(human, 'fwtotVtis', 'bon', 0.439,   ref.poulin2002, assum)
addrecord(human, 'fwtotVtis', 'adi', 0.18,   ref.poulin2002, assum)
addrecord(human, 'fwtotVtis', 'pla', 0.945,   ref.poulin2002, assum)
addrecord(human, 'fwtotVtis', 'ery', 0.63,   ref.poulin2009, assum)


%%% ASSUMPTION: 
%%%
%%% Assume that ratio wex-to-wtot is the same as in RAT
%%%

for i=1:numel(tissues)
    tis = tissues{i};
    rat_fwecVtis = getrecord(rat{'rat250'}, 'fwecVtis', tis);
    rat_fwicVtis = getrecord(rat{'rat250'}, 'fwicVtis', tis);
    rat_wec_to_wtot = rat_fwecVtis / (rat_fwicVtis+rat_fwecVtis);
    
    hum_fwtotVtis = getrecord(human, 'fwtotVtis', tis);
    hum_fwecVtis = rat_wec_to_wtot * hum_fwtotVtis;
    hum_fwicVtis = hum_fwtotVtis - hum_fwecVtis;
    
    addrecord(human, 'fwecVtis', tis, hum_fwecVtis) %fraction of extra-celluar water (wec)
    addrecord(human, 'fwicVtis', tis, hum_fwicVtis) %fraction of intra-celluar water (wic)
end

fwtotVtis_ery = getrecord(human, 'fwtotVtis', 'ery');

addrecord(human, 'fwicVtis', 'ery', fwtotVtis_ery)


%%% ========================================================================================================
%%% Data  : Fraction of interstitial and intra-cellular space 
%%%
%%% Unit  : fraction 


clonerecord(human, 'fintVtis', rat{'rat250'})
clonerecord(human, 'fcelVtis', rat{'rat250'})


%%% ========================================================================================================
%%% Data  : Neutral lipids (fnliVtis) and neutal phospholipids (fnphVtis)
%%%
%%% Unit  : fraction of tissue volume
%%% Source: Poulin and Theil, J Pharm Sci, Vol. 91, 2002
%%%         Rodgers and Rowland, J Pharm Res, Vol. 24, 2007 (erythrocyte
%%%         values only), (Table VII)
%%%

%%% ASSUMPTION: 
%%% 
%%% Fractions of experimental tissue volumes are identical to the fractions
%%% of tissue volume
%%%

ref = struct;
ref.poulin = 'Poulin and Theil, J Pharm Sci, Vol. 91, 2002';
ref.rodgers = 'Rodgers and Rowland, J Pharm Res, Vol. 24, 2007 (Table VII)';

assum = 'fractions of experimental volumes identical to fractions of tissue volumes';

%%% neutral lipids
addrecord(human, 'fnliVtis', 'adi', 0.79,   ref.poulin, assum)
addrecord(human, 'fnliVtis', 'bon', 0.074,  ref.poulin, assum)
addrecord(human, 'fnliVtis', 'bra', 0.051,  ref.poulin, assum)
addrecord(human, 'fnliVtis', 'gut', 0.0487, ref.poulin, assum)
addrecord(human, 'fnliVtis', 'hea', 0.0115, ref.poulin, assum)
addrecord(human, 'fnliVtis', 'kid', 0.0207, ref.poulin, assum)
addrecord(human, 'fnliVtis', 'liv', 0.0348, ref.poulin, assum)
addrecord(human, 'fnliVtis', 'lun', 0.003,  ref.poulin, assum)
addrecord(human, 'fnliVtis', 'mus', 0.0238, ref.poulin, assum)
addrecord(human, 'fnliVtis', 'ski', 0.0284, ref.poulin, assum)
addrecord(human, 'fnliVtis', 'spl', 0.0201, ref.poulin, assum)
addrecord(human, 'fnliVtis', 'pla', 0.0035, ref.poulin, assum)
addrecord(human, 'fnliVtis', 'ery', 0.0033, ref.rodgers,assum)

%%% neutral phospholipids
addrecord(human, 'fnphVtis', 'adi', 0.002,  ref.poulin, assum)
addrecord(human, 'fnphVtis', 'bon', 0.0011, ref.poulin, assum)
addrecord(human, 'fnphVtis', 'bra', 0.0565, ref.poulin, assum)
addrecord(human, 'fnphVtis', 'gut', 0.0163, ref.poulin, assum)
addrecord(human, 'fnphVtis', 'hea', 0.0166, ref.poulin, assum)
addrecord(human, 'fnphVtis', 'kid', 0.0162, ref.poulin, assum)
addrecord(human, 'fnphVtis', 'liv', 0.0252, ref.poulin, assum)
addrecord(human, 'fnphVtis', 'lun', 0.009,  ref.poulin, assum)
addrecord(human, 'fnphVtis', 'mus', 0.0072, ref.poulin, assum)
addrecord(human, 'fnphVtis', 'ski', 0.0111, ref.poulin, assum)
addrecord(human, 'fnphVtis', 'spl', 0.0198, ref.poulin, assum)
addrecord(human, 'fnphVtis', 'pla', 0.00225,ref.poulin, assum)
addrecord(human, 'fnphVtis', 'ery', 0.0012, ref.rodgers,assum)


%%% ========================================================================================================
%%% Data  : Intra-cellular acidic phospholipids (aph) 
%%%
%%% Unit  : fraction

clonerecord(human, 'faphVtis', rat{'rat250'})


%%% ========================================================================================================
%%% Data  : Albumin tissue-to-plasma ratio (rtpAlb) 
%%%
%%% Unit  : --

clonerecord(human, 'rtpAlb', rat{'rat250'})


%%% ========================================================================================================
%%% Data  : Lipoprotein tissue-to-plasma ratio (rtpLip) 
%%%
%%% Unit  : --

clonerecord(human, 'rtpLip', rat{'rat250'})



% %%% set male/female children to corresponding unisex values
% for subtype = {'human0','human1','human5','human10'}
%     
%     age_root   = char(subtype);
%     age_uni    = [age_root,'u'];
%     age_male   = [age_root,'m'];
%     age_female = [age_root,'f'];
%     
%     human.(age_male)   = human.(age_uni);
%     human.(age_female) = human.(age_uni);
%     
% end


%%% ++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
%%% END: HUMAN +++ HUMAN +++ HUMAN +++ HUMAN +++ HUMAN +++ HUMAN +++ HUMAN +++ HUMAN +++ HUMAN +++ HUMAN +++ 
%%% ++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++


%%% +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
%%%                            finish database creation 
%%% +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++

physiologydb = [rat mouse human];

fprintf('...finished.\n')

end

