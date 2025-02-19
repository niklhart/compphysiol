%INITDRUGDB Initialize the drug database
%   DDB = INITDRUGDB() initializes the drug database DDB (an array of class
%   'DrugData'). The function is executed the first time that
%   
%   DrugDB.Instance
%   
%   is accessed. The resulting DrugData object can be queried in different 
%   ways:
%   
%   1) direct queries corresponding to a compound CPD (character array):
%       a) getvalue(DDB{CPD}, NM) retrieves a species-independent parameter
%          NM corresponding to compound CPD
%       b) getvalue(DDB{CPD}, NM, SPEC) retrieves a per-species parameter
%          NM for species SPEC ('human', 'rat' or 'mouse')
%   2) loading a physiology and drug database with function loaddatabases()
%   
%   See DrugData for more details.
%
%   Since some parameters are scaled from reference individuals during
%   database setup, the physiology database is initializes as well when
%   be initializing the drug database.
%
%   Function INITDRUGDB can be edited to add additional entries into the
%   database, see subfunction build_database() below. To define new types
%   of parameters, function drugtemplate() must be extended.
%   
%   For a change in INITDRUGDB() to take effect, clear the DrugDB class 
%   first:
%   
%   clear DrugDB
%
%   See also initphysiologydb, DrugDB, DrugData loaddatabases, drugtemplate 

function ddb = initdrugdb()

    fprintf('Initializing the drug database...\n')

    % add entries to the drug database
    ddb = build_database();
    
    % choose reference individuals for each species for subsequent scaling
    refids = getrefids();

    % derive scalable quantities in the reference individuals 
    ddb = finish_database(ddb, refids);

    fprintf('...finished.\n')

end

function ddb = build_database()

    ndrugs = 21;
    ddb(ndrugs) = DrugData(); % IMPORTANT: since DrugData is a handle class, don't use `ddb(1:n) = DrugDB()`!
    
    i = 0;
    
    % ---------------------------------------------------------------------

    % list of references used
    rodgers2007 = struct;
    rodgers2007.Tab2 = Ref('Rodgers2007','Rodgers & Rowland, ''Vss'', Pharm Res 2007, Table II');
    rodgers2007.Tab3 = Ref('Rodgers2007','Rodgers & Rowland, ''Vss'', Pharm Res 2007, Table III');
    rodgers2007.Tab4 = Ref('Rodgers2007','Rodgers & Rowland, ''Vss'', Pharm Res 2007, Table IV');
    rodgers2007.Tab5 = Ref('Rodgers2007','Rodgers & Rowland, ''Vss'', Pharm Res 2007, Table V');

    obach1999   = struct;
    obach1999.Tab2 = Ref('Obach1999','Obach, Drug Metab Disposit 27(11), 1999, Table 2');
    obach1999.Tab4 = Ref('Obach1999','Obach, Drug Metab Disposit 27(11), 1999, Table 4');

    bae2009       = Ref('Bae2009','Bae et al, J Pharm Sci, VOL. 98, NO. 4, APRIL 2009');
    kuss1985      = Ref('Kuss1985');
    alsaidan2005  = Ref('AlSaidan2005','Al-Saidan etal (2005), AAPS PharmSciTech');
    schmitt2008   = Ref('Schmitt2008','Schmitt, Toxicol in Vitro 22, 2008, Table 1');
    boyes1970     = Ref('Boyes1970','Boyes etal (1970), J Pharmacol Exp Ther 174:1-8');
    gandelman2011 = Ref('Gandelman2011','Gandelman et al, J Clin Pharmacol, VOL. 51, NO. 2, FEB 2011');
    hedaya2017    = Ref('Hedaya2017','Hedaya et al, Pharmaceutics, 2017');
    ehmann2020    = Ref('Ehmann2020','Ehmann et al, Clin. Microbiol. Infect. 26: 1222– 1228 (2020)');
    rowland2012   = Ref('Rowland2012','Rowland et al. 2012');
    nti2012       = Ref('Nti2012','Nti-Addae et al, J. Pharm. Sci. 101: 3134–3141 (2012)');
    dcunha2018    = Ref('DCunha2018','DCunha et al, AAC, Vol. 62, Iss. 9, 2018');
    az1991        = Ref('AstraZeneca1991','AstraZeneca Report BD4176 1991');
    fedrigo2017   = Ref('Fedrigo2017','Fedrigo et al., Antimicrob Agents Ch 61, 1–16 (2017)');
    matthew1992   = Ref('Matthew1992','Matthew et al 1992 Pharm Research');
    brown2005     = Ref('Brown2005','Brown et al 2005 BJCP');
    smith1981     = Ref('Smith1981','Smith etal (1981), Eur J Clin Pharmacol');
    neuhoff2013   = Ref('Neuhoff2013','Neuhoff et al., J Pharm Sci 102, (2013)');
    sawada1985    = Ref('Sawada1985','Sawada et al. J of PK/Biopharm Vol.13 1985');
    mungall1985   = Ref('Mungall1985','Mungall et al 1985 J PK Biopharm Population PK of Racemic warfarin in adult patients');
    julkunen1980  = Ref('Julkunen1980','Julkunen et al 1980, Arzneimittelforschung 30(2):264-7 (Abstract)');
    willmann2004  = Ref('Willmann2004','Willmann et al 2004, J Med Chem 47, 4022-4031');

    % ---------------------------------------------------------------------

    i = i+1;
        
    ddb(i).name     = 'Amitriptyline';

    ddb(i).class    = 'sMD';
    ddb(i).subclass = 'base'; % Rodgers2007                                       

    addrecord(ddb(i), 'formula',     'C20H23N',   'DrugBank.ca',    [])
    addrecord(ddb(i), 'MW',     277.40*u.g/u.mol, 'DrugBank.ca',    [])
    addrecord(ddb(i), 'pKa_cat',    9.40,       rodgers2007.Tab2, [])
    addrecord(ddb(i), 'logPow', 4.9,              rodgers2007.Tab2, [])

    addrecord(ddb(i), 'fuP',         'rat', 0.056,             '?', [])
    addrecord(ddb(i), 'BP',          'rat', 0.86,              '?', [])

    addrecord(ddb(i), 'fuP',         'human', 0.05,                obach1999.Tab2, [])
    addrecord(ddb(i), 'BP',          'human', 0.86,                obach1999.Tab2, [])
    addrecord(ddb(i), 'CLblood_hep', 'human', '12 mL/(min*kg)',    obach1999.Tab2, []) %TODO check if this is a rat value.
    addrecord(ddb(i), 'lambda_po',   'human', log(2)/(1.36*u.h),   kuss1985,  [])    
    addrecord(ddb(i), 'Egut',        'human', 0.48,                bae2009,   [])    

    % ---------------------------------------------------------------------
        
    i = i+1;
        
    ddb(i).name     = 'Linezolid';

    ddb(i).class    = 'sMD';
    ddb(i).subclass = 'base'; % Rodgers & Rowland, 'Vss', Pharm Res 2007, Table III                                       

%    MW    = 337.35*u.g/u.mol;
%    CLint = scd(MW * 0.0359*u.nmol/u.h/u.g,'mL/(min*kg)');
%   TODO: how to convert CLint values? What do they represent?
    
    addrecord(ddb(i), 'formula',     'C16H20FN3O4', 'DrugBank.ca', [])
    addrecord(ddb(i), 'MW',     337.35*u.g/u.mol,   'DrugBank.ca', [])
    addrecord(ddb(i), 'pKa_cat',    1.8,          gandelman2011, [])
    addrecord(ddb(i), 'logPow', 0.9,                rowland2012,   [])

    addrecord(ddb(i), 'fuP',         'human', 0.86,                ehmann2020, [])
    addrecord(ddb(i), 'BP',          'human', 1,                   hedaya2017, [])
    %addrecord(ddb(i), 'CLblood_hep', 'human', '10 mL/(min*kg)',    gandelman2011, [])
    addrecord(ddb(i), 'lambda_po',   'human', 2.8/u.h,             gandelman2011,[])
    addrecord(ddb(i), 'cellPerm',    'human', 6.90e-6*u.cm/u.sec,  nti2012, 'CaCo-2 assay')
    
    % ---------------------------------------------------------------------

    i = i+1;
        
    ddb(i).name     = 'Meropenem';

    ddb(i).class    = 'sMD';
    ddb(i).subclass = 'ampholyte';                                        

%    Christensson1992 = Ref('Christensson1992','Christensson et al, Antimicrob Agents Chemother 36: 1532–1537 (1992)');

    MW    = 383.5*u.g/u.mol;
%    CLint = scd(MW * 0.234*u.nmol/u.h/u.g,'mL/(min*kg)');
%   TODO: how to convert CLint values? What do they represent?

    addrecord(ddb(i), 'formula', 'C17H25N3O5S', 'DrugBank.ca',  [])
    addrecord(ddb(i), 'MW',      MW,            'DrugBank.ca',  [])
    addrecord(ddb(i), 'pKa_cat', 2.9,            az1991,         [])
    addrecord(ddb(i), 'pKa_ani', 7.4,            az1991,         [])
    addrecord(ddb(i), 'Kz',      Inf,            [],'zwitterionic ampholyte')
    addrecord(ddb(i), 'logPow', -3.0,            az1991,         [])  

    addrecord(ddb(i), 'fuP',                'human', 0.98,           az1991, [])
    addrecord(ddb(i), 'BP',                 'human', 0.80,           dcunha2018, [])
%    addrecord(ddb(i), 'CLint_hep_perOWliv', 'human',CLint,           Christensson1992,[])
    addrecord(ddb(i), 'cellPerm',           'human', 8.08e-8*u.cm/u.sec, '', 'PK-Sim predicted')
    addrecord(ddb(i), 'Freabs',             'human', 0,                  '', 'No tubular reabsorption')

    % ---------------------------------------------------------------------

    i = i+1;
    ddb(i).name     = 'Fosfomycin';

    ddb(i).class    = 'sMD';
    ddb(i).subclass = 'diprotic acid';                                        

%   TGA         = Ref('TGA report','https://www.tga.gov.au/sites/default/files/auspar-fosfomycin-trometamol-180907.pdf');

    addrecord(ddb(i), 'formula',     'C3H7O4P',    'DrugBank.ca', [])
    addrecord(ddb(i), 'MW',     138.1*u.g/u.mol,   'DrugBank.ca', [])
%    addrecord(ddb(i), 'pKa',    [2.5 6.7],         TGA,  [])
    addrecord(ddb(i), 'pKa_ani', [1.3 7.82],    fedrigo2017,  [])
    addrecord(ddb(i), 'logPow', -1.6,              'DrugBank.ca', [])  

    addrecord(ddb(i), 'fuP',         'human',  0.99,            fedrigo2017, [])
%    addrecord(ddb(i), 'fuP',         'human',  0.98,             '?', [])
    addrecord(ddb(i), 'BP',          'human',  0.7,             fedrigo2017 , [])
%    addrecord(ddb(i), 'BP',          'human',  0.68,             'PK-Sim', [])
    addrecord(ddb(i), 'CLblood_hep', 'human','0 mL/(min*kg)',    '','Not cleared hepatically')
    addrecord(ddb(i), 'Freabs',      'human', 0,                 '','No tubular reabsorption')
    addrecord(ddb(i), 'cellPerm',    'human', 1.75e-6*u.cm/u.sec,'','PK-Sim predicted')

    % ---------------------------------------------------------------------
    
    i = i+1;
    
    ddb(i).name     = 'Caffeine';

    ddb(i).class    = 'sMD';
    ddb(i).subclass = 'base'; % Rodgers2007                                 

    addrecord(ddb(i), 'formula','C8H10N4O2',     'DrugBank.ca',    [])
    addrecord(ddb(i), 'MW',     194.2*u.g/u.mol, 'DrugBank.ca',    [])
%    addrecord(ddb(i), 'pKa',    10.4,            rodgers2007.Tab2, [])
    addrecord(ddb(i), 'pKa_cat', 0.6,          'google search', [])
    addrecord(ddb(i), 'logPow', 1.29,            rodgers2007.Tab2, [])
    addrecord(ddb(i), 'logMA', 0.602,            willmann2004,     [])

    addrecord(ddb(i), 'fuP',         'human', 0.7,               '?', [])
    addrecord(ddb(i), 'BP',          'human', 1.04,              '?', [])
    addrecord(ddb(i), 'CLblood_hep', 'human', '1.4 mL/(min*kg)', '?', [])
    addrecord(ddb(i), 'cellPerm',    'human',2.58e-6*u.cm/u.s,  willmann2004, 'predicted')
    addrecord(ddb(i), 'Efeces',      'human', 0,              willmann2004,   [])    

    % ---------------------------------------------------------------------
    
    i = i+1;
    
    ddb(i).name     = 'Desipramine';

    ddb(i).class    = 'sMD';
    ddb(i).subclass = 'base'; % Rodgers2007                                  

    addrecord(ddb(i), 'formula','C18H22N2',       'DrugBank.ca',    [])
    addrecord(ddb(i), 'MW',     266.38*u.g/u.mol, 'DrugBank.ca',    [])
    addrecord(ddb(i), 'pKa_cat', 10.32,         rodgers2007.Tab2, [])
    addrecord(ddb(i), 'logPow', 4.45,             rodgers2007.Tab2, [])
    addrecord(ddb(i), 'logMA', 3.725,             willmann2004,     [])

    addrecord(ddb(i), 'fuP',         'human', 0.18,             obach1999.Tab2, [])
    addrecord(ddb(i), 'BP',          'human', 0.96,             obach1999.Tab2, [])
    addrecord(ddb(i), 'CLblood_hep', 'human', '12 mL/(min*kg)', obach1999.Tab4, [])
    addrecord(ddb(i), 'cellPerm',    'human',22.34e-6*u.cm/u.s,  willmann2004,  'predicted')
    addrecord(ddb(i), 'Efeces',      'human', 0,                willmann2004,   [])    

    % ---------------------------------------------------------------------
    
    i = i+1;
    
    ddb(i).name     = 'Diltiazem';

    ddb(i).class    = 'sMD';
    ddb(i).subclass = 'base'; % Rodgers & Rowland, 'Vss', Pharm Res 2007, Table II                                       

    addrecord(ddb(i), 'formula','C22H26N2O4S',   'DrugBank.ca', [])
    addrecord(ddb(i), 'MW',    414.52*u.g/u.mol, 'DrugBank.ca', [])
    addrecord(ddb(i), 'pKa_cat', 7.7,          '?',  [])
    addrecord(ddb(i), 'logPow',  2.67,           '?',  [])
    addrecord(ddb(i), 'logMA', 2.544,             willmann2004, [])

    addrecord(ddb(i), 'fuP',         'human', 0.22,             obach1999.Tab2, [])
    addrecord(ddb(i), 'BP',          'human', 1.0,              obach1999.Tab2, [])
    addrecord(ddb(i), 'CLblood_hep', 'human', '12 mL/(min*kg)', obach1999.Tab4, [])
    addrecord(ddb(i), 'lambda_po',   'human', 5.6004/u.h,       alsaidan2005,   [])
    addrecord(ddb(i), 'cellPerm',    'human', 5.77e-6*u.cm/u.s, willmann2004,   'predicted')
    addrecord(ddb(i), 'Efeces',      'human', 1-0.92,             willmann2004,   [])    

    % ---------------------------------------------------------------------
    
    i = i+1;
    
    ddb(i).name     = 'Diphenhydramine';

    ddb(i).class    = 'sMD';
    ddb(i).subclass = 'base'; % Rodgers2007                                    

    addrecord(ddb(i), 'formula','C17H21NO',       'DrugBank.ca',    [])    
    addrecord(ddb(i), 'MW',     255.35*u.g/u.mol, 'DrugBank.ca',    [])
    addrecord(ddb(i), 'pKa_cat',  8.98,         rodgers2007.Tab2, [])
    addrecord(ddb(i), 'logPow',  3.31,            rodgers2007.Tab2, [])

    addrecord(ddb(i), 'fuP',         'human', 0.089,            rodgers2007.Tab2, [])
    addrecord(ddb(i), 'BP',          'human', 0.74,             rodgers2007.Tab2, [])
    addrecord(ddb(i), 'CLblood_hep', 'human', '9.5 mL/(min*kg)',obach1999.Tab4,   [])
     
    % ---------------------------------------------------------------------
    
    i = i+1;
    
    ddb(i).name     = 'Imipramine';

    ddb(i).class    = 'sMD';
    ddb(i).subclass = 'base'; % Rodgers2007                                          

    addrecord(ddb(i), 'formula','C19H24N2',      'DrugBank.ca',    [])    
    addrecord(ddb(i), 'MW',    280.41*u.g/u.mol, 'DrugBank.ca',    [])
    addrecord(ddb(i), 'pKa_cat', 9.5,          rodgers2007.Tab2, [])
    addrecord(ddb(i), 'logPow',  4.80,           rodgers2007.Tab2, [])
    addrecord(ddb(i), 'logPvow', 4.00,           '?',              [])
    addrecord(ddb(i), 'logMA',   3.00,           schmitt2008,      [])
%    addrecord(ddb(i), 'logMA',   3.19,           willmann2004,     [])

    addrecord(ddb(i), 'fuP',         'human', 0.1,              obach1999.Tab2, [])
    addrecord(ddb(i), 'BP',          'human', 1.1,              obach1999.Tab2, [])
    addrecord(ddb(i), 'CLblood_hep', 'human', '12 mL/(min*kg)', obach1999.Tab4, [])
    addrecord(ddb(i), 'cellPerm',    'human', 22.5e-6*u.cm/u.s, willmann2004,   'predicted')
    addrecord(ddb(i), 'Efeces',      'human', 1-0.97,             willmann2004,   [])    

    % ---------------------------------------------------------------------
    
    i = i+1;
    
    ddb(i).name     = 'Lidocaine';

    ddb(i).class    = 'sMD';
    ddb(i).subclass = 'base'; % Rodgers & Rowland, 'Vss', Pharm Res 2007, Table II                                       

    addrecord(ddb(i), 'formula', 'C14H22N2O',    'DrugBank.ca',    [])
    addrecord(ddb(i), 'MW',    234.34*u.g/u.mol, 'DrugBank.ca',    [])
    addrecord(ddb(i), 'pKa_cat', 8.01,         rodgers2007.Tab2, [])
    addrecord(ddb(i), 'logPow',  2.44,           rodgers2007.Tab2, [])
    addrecord(ddb(i), 'logPvow', 1.27,           '?',              [])
    addrecord(ddb(i), 'logMA',   1.80,           schmitt2008,      [])

    addrecord(ddb(i), 'fuP',         'human', 0.296,            '?',            [])
    addrecord(ddb(i), 'BP',          'human', 0.84,             '?',            [])
    addrecord(ddb(i), 'CLblood_hep', 'human', '15 mL/(min*kg)', obach1999.Tab4, [])        
    addrecord(ddb(i), 'lambda_po',   'human', 0.018/u.min,      boyes1970, 'measured in dog')        
%    addrecord(ddb(i), 'cellPerm',    'human', 6.17e-5*u.cm/u.sec, 'Deciga-Campos et al. (2016)', 'CaCo-2 assay')
    addrecord(ddb(i), 'cellPerm',    'human', 3.67e-6*u.cm/u.s, willmann2004,   'predicted')
    addrecord(ddb(i), 'Efeces',      'human', 0,              willmann2004,   [])    

    % ---------------------------------------------------------------------
    
    i = i+1;
    
    ddb(i).name     = 'Diazepam';

    ddb(i).class    = 'sMD';
    ddb(i).subclass = 'base'; % Rodgers & Rowland, 'Vss', Pharm Res 2007, Table III                                       

    addrecord(ddb(i), 'formula', 'C16H13ClN2O',  'DrugBank.ca',    [])
    addrecord(ddb(i), 'MW',    284.74*u.g/u.mol, 'DrugBank.ca',    [])
    addrecord(ddb(i), 'pKa_cat', 3.38,         rodgers2007.Tab3, [])
    addrecord(ddb(i), 'logPow',  2.84,           rodgers2007.Tab3, [])
    addrecord(ddb(i), 'logMA',   2.76,           schmitt2008,      [])
%    addrecord(ddb(i), 'logMA',   3.17,           willmann2004,     [])

    addrecord(ddb(i), 'fuP',         'human', 0.013,             obach1999.Tab2, [])
    addrecord(ddb(i), 'BP',          'human', 0.71,              obach1999.Tab2, [])
    addrecord(ddb(i), 'CLblood_hep', 'human', '0.6 mL/(min*kg)', obach1999.Tab2, [])        
    addrecord(ddb(i), 'cellPerm',    'human', 23.48e-6*u.cm/u.s, willmann2004,   'predicted')
    addrecord(ddb(i), 'Efeces',      'human', 1-0.97,              willmann2004,   [])    

    % ---------------------------------------------------------------------
    
    i = i+1;
    
    ddb(i).name     = 'Ketoconazole';

    ddb(i).class    = 'sMD';
    ddb(i).subclass = 'base'; % Rodgers2007                                
    
    addrecord(ddb(i), 'formula', 'C26H28Cl2N4O4', 'DrugBank.ca', [])
    addrecord(ddb(i), 'MW',    531.431*u.g/u.mol, 'DrugBank.ca', [])
    addrecord(ddb(i), 'pKa_cat', 6.75,          'DrugBank.ca', [])
    addrecord(ddb(i), 'logPow',  4.35,            'DrugBank.ca', [])

    addrecord(ddb(i), 'fuP',         'human', 0.01,               'DrugBank.ca', [])
    addrecord(ddb(i), 'BP',          'human', 0.6,                matthew1992,   'measured in rat')
    addrecord(ddb(i), 'CLblood_hep', 'human', '2.75 mL/(min*kg)', 'antimicrobe.org', 'PK in healthy adults at ss after po 200mg')        
    addrecord(ddb(i), 'lambda_po',   'human', 0.013/u.min,        brown2005,     [])
    
    % ---------------------------------------------------------------------
    
    i = i+1;
    
    ddb(i).name     = 'Midazolam';

    ddb(i).class    = 'sMD';
    ddb(i).subclass = 'base'; % Rodgers2007                                     

    addrecord(ddb(i), 'formula', 'C18H13ClFN3',  'DrugBank.ca',    [])
    addrecord(ddb(i), 'MW',    325.77*u.g/u.mol, 'DrugBank.ca',    [])
    addrecord(ddb(i), 'pKa_cat', 6.01,         rodgers2007.Tab3, [])
    addrecord(ddb(i), 'logPow',  3.15,           rodgers2007.Tab3, [])
    addrecord(ddb(i), 'logMA',  2.897,           schmitt2008,      [])

    addrecord(ddb(i), 'fuP',         'human', 0.05,              obach1999.Tab2, [])
    addrecord(ddb(i), 'BP',          'human', 0.57,              obach1999.Tab2, 'changed from 0.53 to 0.57, since otherwise smaller than 1-hct')
    addrecord(ddb(i), 'CLblood_hep', 'human', '8.7 mL/(min*kg)', obach1999.Tab2, [])        
    addrecord(ddb(i), 'lambda_po',   'human', 9.6/u.h,           smith1981,      [])

    % ---------------------------------------------------------------------
    
    i = i+1;
    
    ddb(i).name     = 'Digoxin';

    ddb(i).class    = 'sMD';
    ddb(i).subclass = 'neutral'; % Rodgers2007                                       

    addrecord(ddb(i), 'formula', 'C41H64O14',    'DrugBank.ca', [])
    addrecord(ddb(i), 'MW',    780.94*u.g/u.mol, 'DrugBank.ca', [])
    addrecord(ddb(i), 'logPow',  1.26,           neuhoff2013,   [])
    addrecord(ddb(i), 'logMA',   1.48,           schmitt2008,   [])

    addrecord(ddb(i), 'fuP',         'human', 0.78,  neuhoff2013, [])
    addrecord(ddb(i), 'BP',          'human', 1.07,  neuhoff2013, [])
%    addrecord(ddb(i), 'CLblood_hep', 'human', 'NaN mL/(min*kg)', '?', [])
    addrecord(ddb(i), 'cellPerm',    'human', 0.87e-6*u.cm/u.s, willmann2004,   'predicted')
    addrecord(ddb(i), 'Efeces',      'human', 1-0.7,              willmann2004,   [])    

    % ---------------------------------------------------------------------
    
    i = i+1;
    
    ddb(i).name     = 'Dexamethasone';

    ddb(i).class    = 'sMD';
    ddb(i).subclass = 'neutral'; % Rodgers2007                                      

    addrecord(ddb(i), 'formula', 'C22H29FO5',    'DrugBank.ca',    [])
    addrecord(ddb(i), 'MW',    392.47*u.g/u.mol, 'DrugBank.ca',    [])
    addrecord(ddb(i), 'logPow',  2.18,           rodgers2007.Tab5, [])

    addrecord(ddb(i), 'fuP',         'human', 0.32,              obach1999.Tab2, [])
    addrecord(ddb(i), 'BP',          'human', 0.93,              obach1999.Tab2, [])
    addrecord(ddb(i), 'CLblood_hep', 'human', '3.8 mL/(min*kg)', obach1999.Tab2, [])        

    % ---------------------------------------------------------------------
    
    i = i+1;
    
    ddb(i).name     = 'Ibuprofen';

    ddb(i).class    = 'sMD';
    ddb(i).subclass = 'acid'; % Rodgers2007                                 

    addrecord(ddb(i), 'formula', 'C13H18O2',     'DrugBank.ca',    [])
    addrecord(ddb(i), 'MW',    206.28*u.g/u.mol, 'DrugBank.ca',    [])
    addrecord(ddb(i), 'pKa_ani', 4.70,        rodgers2007.Tab4, [])
    addrecord(ddb(i), 'logPow',  4.06,           rodgers2007.Tab4, [])

    addrecord(ddb(i), 'fuP',         'human', 0.01,              obach1999.Tab2, [])
    addrecord(ddb(i), 'BP',          'human', 0.57,              obach1999.Tab2, 'changed from 0.53 to 0.57, since otherwise smaller than 1-hct')
    addrecord(ddb(i), 'CLblood_hep', 'human', '1.5 mL/(min*kg)', obach1999.Tab2, [])        
    
    % ---------------------------------------------------------------------
    
    i = i+1;

    ddb(i).name     = 'Warfarin';

    ddb(i).class    = 'sMD';
    ddb(i).subclass = 'acid';                                        

    addrecord(ddb(i), 'formula', 'C19H16O4',      'DrugBank.ca',  [])
    addrecord(ddb(i), 'MW',     308.33*u.g/u.mol, 'DrugBank.ca',  [])
    addrecord(ddb(i), 'pKa_ani',    5.08,      'DrugBank.ca',  [])
    addrecord(ddb(i), 'logPow', 3,                'Wolfram Alpha',[])

    addrecord(ddb(i), 'fuP',         'rat', 0.02,                  sawada1985, [])
    addrecord(ddb(i), 'BP',          'rat', 0.58,                  sawada1985, [])
    addrecord(ddb(i), 'CLblood_hep', 'rat', '0.36 mL/(min*kg)',    sawada1985, [])
    addrecord(ddb(i), 'lambda_po',   'rat', 2/u.h,                 julkunen1980,[])    

    addrecord(ddb(i), 'fuP',         'human', 0.08,                sawada1985,     [])
    addrecord(ddb(i), 'BP',          'human', 0.58,                sawada1985,     [])
    addrecord(ddb(i), 'CLblood_hep', 'human', '0.081 mL/(min*kg)', obach1999.Tab2, [])
    addrecord(ddb(i), 'lambda_po',   'human', 47/u.day,            mungall1985,    [])    
    
    % ---------------------------------------------------------------------
    
    i = i+1;

    ddb(i).name     = 'drugA';

    ddb(i).class    = 'sMD';
    ddb(i).subclass = 'acid';                                        

    addrecord(ddb(i), 'MW',     308.33*u.g/u.mol, '?', [])
    addrecord(ddb(i), 'pKa_ani', 5.08,         '?', [])
    addrecord(ddb(i), 'logPow', 3,                '?', [])

    addrecord(ddb(i), 'fuP',         'rat', 0.38,              '?', [])
    addrecord(ddb(i), 'BP',          'rat', 1.27,              '?', [])
    addrecord(ddb(i), 'CLblood_hep', 'rat', '0.1 mL/(min*kg)', '?', [])
    addrecord(ddb(i), 'lambda_po',   'rat', 0.01/u.min,        '?', [])    
    
    addrecord(ddb(i), 'fuP',         'human', 0.01,                '?', [])
    addrecord(ddb(i), 'BP',          'human', 0.567,               '?', [])
    addrecord(ddb(i), 'CLblood_hep', 'human', '0.081 mL/(min*kg)', '?', [])
    addrecord(ddb(i), 'lambda_po',   'human', 0.01/u.min,          '?', [])
    
    % ---------------------------------------------------------------------
    
    i = i+1;

    ddb(i).name     = 'drugB';

    ddb(i).class    = 'sMD';
    ddb(i).subclass = 'base';                                        

    addrecord(ddb(i), 'MW',      234.34*u.g/u.mol, '?', [])
    addrecord(ddb(i), 'pKa_cat',  8.01,          '?', [])
    addrecord(ddb(i), 'logPow',  2.26,             '?', [])
    addrecord(ddb(i), 'logPvow', 1.27,             '?', [])

    addrecord(ddb(i), 'fuP',         'rat', 0.24,             '?', [])
    addrecord(ddb(i), 'BP',          'rat', 1.27,             '?', [])
    addrecord(ddb(i), 'CLblood_hep', 'rat', '55 mL/(min*kg)', '?', [])
    addrecord(ddb(i), 'lambda_po',   'rat', 0.2/u.min,        '?', [])    
    
    addrecord(ddb(i), 'fuP',         'human', 0.296,            '?', [])
    addrecord(ddb(i), 'BP',          'human', 0.84,             '?', [])
    addrecord(ddb(i), 'CLblood_hep', 'human', '15 mL/(min*kg)', '?', [])
    addrecord(ddb(i), 'lambda_po',   'human', 0.02/u.min,       '?', [])
            
    % ---------------------------------------------------------------------
    
    i = i+1;
    
    ddb(i).name     = 'mAb7E3';

    ddb(i).class    = 'mAb';
    ddb(i).subclass = 'IgG1';                                      

    addrecord(ddb(i), 'MW', 150000*u.g/u.mol, '?', [])
    
    % ---------------------------------------------------------------------
    
    i = i+1;
    
    ddb(i).name     = 'Bevacizumab';

    ddb(i).class    = 'mAb';
    ddb(i).subclass = 'IgG1';                                      

    addrecord(ddb(i), 'MW', 149000*u.g/u.mol, '?', [])

    % ---------------------------------------------------------------------

end

function refid = getrefids()

    % for each species, choose a reference individual in which to convert into
    % scalable quantities

    phys = PhysiologyDB.Instance;   

    refid = struct;
    refid.rat   = phys{'rat250'};
    refid.mouse = phys{'mouse25'};
    refid.human = phys{'human35m'};

end

function ddb = finish_database(ddb, refids)
%%% finish database creation

    refspecies = fieldnames(refids);

    for i=1:numel(ddb)
        for j=1:numel(refspecies)
            spec = refspecies{j};
            sdb_j = refids.(spec);

            % the following 4 values are taken from the reference individual
            % to derive less species-dependent and better scalable parameters
            hct = getrecord(sdb_j,'hct');
            BW = getrecord(sdb_j,'BW');
            OWliv = getrecord(sdb_j,'OWtis','liv');
            Qliv = getrecord(sdb_j,'Qblo','liv');

            %%% gut and feces extraction ratios
            if ~hasrecord(ddb(i), 'Egut', spec)
                addrecord(ddb(i), 'Egut', spec, 0, [], 'Assumed Egut=0')
            end
            if ~hasrecord(ddb(i), 'Efeces', spec)
                addrecord(ddb(i), 'Efeces', spec, 0, [], 'Assumed Efeces=0')
            end
            
            if strcmp(ddb(i).class,'mAb') && ~hasrecord(ddb(i),'BP',spec) 
                addrecord(ddb(i), 'BP', spec, 1-hct)
            end
            
            %%% erythrocyte-to-plasma water partition coefficient
            if hasrecord(ddb(i),'BP',spec) && hasrecord(ddb(i),'fuP',spec)
                BP = getrecord(ddb(i), 'BP', spec);
                fuP = getrecord(ddb(i), 'fuP', spec);

                if BP < 1-hct 
                    error(['BP smaller than (1-hct) for drug "' ...
                        ddb(i).name '" in species "' spec '".'])
                end

                K_ery_up = (BP - (1-hct)) / (hct * fuP);

                addrecord(ddb(i), 'K_ery_up', spec, K_ery_up)
            end
            
            %%% intrinsic hepatic clearance * partition coefficient
            if hasrecord(ddb(i), 'CLblood_hep', spec)
                CLblood_hep_perkgBW = getrecord(ddb(i),'CLblood_hep', spec);
                CLblood_hep = CLblood_hep_perkgBW * BW;

                assert(CLblood_hep <= Qliv, 'CLblood_hep must be smaller than Qliv.')

                % Well-stirred liver model
                % (compatible with sMD_PBPK_12CMT_wellstirred.m)
                if hasrecord(ddb(i),'BP',spec) && hasrecord(ddb(i),'fuP',spec)
                    BP = getrecord(ddb(i), 'BP', spec);
                    fuP = getrecord(ddb(i), 'fuP', spec);
                    fuB = fuP / BP;
                    
                    CLint_hep = Qliv*CLblood_hep/((Qliv - CLblood_hep)*fuB);
                    CLint_hep_scaled = CLint_hep / OWliv;

                    addrecord(ddb(i), 'CLint_hep_perOWliv',   spec, CLint_hep_scaled)
                end
                
            end
        end

    end
end


