%INITEXPDRUGDB Initialize the experimental drug database
%   EDB = INITEXPDRUGDB() initializes a drug database EDB (an array of class
%   'ExpDrugData') that can be queried in different ways:
%   
%   1) direct queries corresponding to a compound CPD (character array):
%       a) getvalue(DDB{CPD}, NM) retrieves a species-independent parameter
%          NM corresponding to compound CPD
%       b) getvalue(DDB{CPD}, NM, SPEC) retrieves a per-species parameter
%          NM for species SPEC ('human', 'rat' or 'mouse')
%   2) loading a physiology and drug database with function loaddatabases()
%       
%   A handle to the drug database is returned AND stored
%   in the global toolbox options; it can be retrieved via 
%
%   getoptPBPKtoolbox('ExpDrugDBhandle')
%
%   Since some parameters are scaled from reference individuals during
%   database setup, the physiology database must be initialized before the
%   drug database (this is done automatically in 'initPBPKtoolbox').
%
%   Function INITDRUGDB can be edited to add additional entries into the
%   database, see subfunction build_database() below. To define new types
%   of parameters, function drugtemplate() must be extended.
%
%   See also initphysiologydb, loaddatabases, initPBPKtoolbox, drugtemplate 

function edb = initexpdrugdb()
    
    % add entries to the drug database
    edb = build_database();
    
    % leave a handle to the DrugDB in global options
    setoptPBPKtoolbox('ExpDrugDBhandle', edb);
end

function edb = build_database()

    ndrugs = 1;
    edb(ndrugs) = ExpDrugData(); % IMPORTANT: since DrugData is a handle class, don't use `ddb(1:n) = DrugDB()`!
    
    i = 0;
    
    % ---------------------------------------------------------------------
        
%     i = i+1;
%         
%     ddb(i).name     = 'Linezolid';
% 
%     ddb(i).class    = 'sMD';
%     ddb(i).subclass = 'base'; % Rodgers & Rowland, 'Vss', Pharm Res 2007, Table III                                       
% 
%     ref = struct();
%     ref.Gandelman2011     = 'Gandelman et al, J Clin Pharmacol, VOL. 51, NO. 2, FEB 2011';
%     ref.Hedaya2017     = 'Hedaya et al, Pharmaceutics, 2017';
%     ref.Ehmann2020     = 'Ehmann et al, Clin. Microbiol. Infect. 26: 1222– 1228 (2020)';
%     ref.Rowland2012    = 'Rowland et al. 2012';
%     ref.Nti2012        = 'Nti-Addae et al, J. Pharm. Sci. 101: 3134–3141 (2012)';
%     
% %    MW    = 337.35*u.g/u.mol;
% %    CLint = scd(MW * 0.0359*u.nmol/u.h/u.g,'mL/(min*kg)');
% %   TODO: how to convert CLint values? What do they represent?
%     
%     addrecord(ddb(i), 'MW',     337.35*u.g/u.mol,   '?',            [], [])
%     addrecord(ddb(i), 'pKa',    1.8,             ref.Gandelman2011, [], [])
%     addrecord(ddb(i), 'logPow', 0.9,              ref.Rowland2012,  [], [])
% 
%     addrecord(ddb(i), 'fuP',         'human', 0.86,                ref.Ehmann2020, [])
%     addrecord(ddb(i), 'BP',          'human', 1,                ref.Hedaya2017, [])
%     %addrecord(ddb(i), 'CLblood_hep', 'human', '10 mL/(min*kg)',    ref.Gandelman2011, [])
%     addrecord(ddb(i), 'lambda_po',   'human', 2.8/u.h,       ref.Gandelman2011,[])
%     addrecord(ddb(i), 'cellPerm',    'human', 6.90e-6*u.cm/u.sec, ref.Nti2012, 'CaCo-2 assay')
% 
%     
%     % ---------------------------------------------------------------------
% 
%     i = i+1;
%         
%     ddb(i).name     = 'Meropenem';
% 
%     ddb(i).class    = 'sMD';
%     ddb(i).subclass = 'zwitter ion';                                        
% 
%     ref = struct();
%     ref.DCunha2018      = 'DCunha et al, AAC, Vol. 62, Iss. 9, 2018';
%     ref.AZ              = 'AstraZeneca Report BD4176 1991';
%     ref.Christensson    = 'Christensson et al, Antimicrob Agents Chemother 36: 1532–1537 (1992)';
% 
%     MW    = 383.5*u.g/u.mol;
% %    CLint = scd(MW * 0.234*u.nmol/u.h/u.g,'mL/(min*kg)');
% %   TODO: how to convert CLint values? What do they represent?
% 
%     addrecord(ddb(i), 'MW',     MW,   '?',            [])
%     addrecord(ddb(i), 'pKa',    [2.9 7.4],                ref.AZ,  [])
%     addrecord(ddb(i), 'logPow', -3.0,               ref.AZ,  [])  
% 
%     addrecord(ddb(i), 'fuP',                'human', 0.98,           ref.AZ, [])
%     addrecord(ddb(i), 'BP',                 'human', 0.80,           ref.DCunha2018, [])
% %    addrecord(ddb(i), 'CLint_hep_perOWliv', 'human',CLint,           ref.Christensson,[])
%     addrecord(ddb(i), 'cellPerm',           'human', 8.08e-8*u.cm/u.sec, '', 'PK-Sim predicted')
%     addrecord(ddb(i), 'Freabs',             'human', 0,                  '', 'No tubular reabsorption')
% 
%     % ---------------------------------------------------------------------
% 
%     i = i+1;
%     ddb(i).name     = 'Fosfomycin';
% 
%     ddb(i).class    = 'sMD';
%     ddb(i).subclass = 'diprotic acid';                                        
% 
%     addrecord(ddb(i), 'MW',     138.1*u.g/u.mol,   '?',  [])
%     addrecord(ddb(i), 'pKa',    [2.5 6.7],         Ref('TGA report','https://www.tga.gov.au/sites/default/files/auspar-fosfomycin-trometamol-180907.pdf'),  [])
%     addrecord(ddb(i), 'logPow', -1.6,              'DrugBank (unreferenced)',  [])  
% 
%     addrecord(ddb(i), 'fuP',         'human',  0.98,             '?', [])
%     addrecord(ddb(i), 'BP',          'human',  0.68,             'PK-Sim', [])
%     addrecord(ddb(i), 'CLblood_hep', 'human','0 mL/(min*kg)',    '','Not cleared hepatically')
%     addrecord(ddb(i), 'Freabs',      'human', 0,                 '','No tubular reabsorption')
%     addrecord(ddb(i), 'cellPerm',    'human', 1.75e-6*u.cm/u.sec,'','PK-Sim predicted')
% 
%     % ---------------------------------------------------------------------
% 
%     i = i+1;
%         
%     ddb(i).name     = 'Amitriptyline';
% 
%     ddb(i).class    = 'sMD';
%     ddb(i).subclass = 'base'; % Rodgers & Rowland, 'Vss', Pharm Res 2007, Table II                                       
% 
%     ref = struct();
%     ref.rodgers2007 = 'Rodgers & Rowland, ''Vss'', Pharm Res 2007, Table II';
%     ref.obach1999   = 'Obach, Drug Metab Disposit 27(11), 1999, Table 2';
%     ref.kuss1985    = 'Kuss 1985';
%     ref.bae2009     = 'Bae et al, J Pharm Sci, VOL. 98, NO. 4, APRIL 2009';
%     ref.bae2009     = Ref('Bae2009','Bae et al, J Pharm Sci, VOL. 98, NO. 4, APRIL 2009');
% 
%     addrecord(ddb(i), 'MW',     277.40*u.g/u.mol,   '?',            [])
%     addrecord(ddb(i), 'pKa',    9.40,             ref.rodgers2007,  [])
%     addrecord(ddb(i), 'logPow', 4.9,              ref.rodgers2007,  [])
% 
%     addrecord(ddb(i), 'fuP',         'rat', 0.056,                 '?', [])
%     addrecord(ddb(i), 'BP',          'rat', 0.86,                  '?', [])
% 
%     addrecord(ddb(i), 'fuP',         'human', 0.05,                ref.obach1999, [])
%     addrecord(ddb(i), 'BP',          'human', 0.86,                ref.obach1999, [])
%     addrecord(ddb(i), 'CLblood_hep', 'human', '12 mL/(min*kg)',    ref.obach1999, [])
%     addrecord(ddb(i), 'lambda_po',   'human', log(2)/(1.36*u.h),   ref.kuss1985,  [])    
%     addrecord(ddb(i), 'Egut',        'human', 0.48,                ref.bae2009,   [])    
% 
%     % ---------------------------------------------------------------------
%     
%     i = i+1;
%     
%     ddb(i).name     = 'Caffeine';
% 
%     ddb(i).class    = 'sMD';
%     ddb(i).subclass = 'base'; % Rodgers & Rowland, 'Vss', Pharm Res 2007, Table II                                       
% 
%     ref = struct();
%     ref.rodgers2007 = 'Rodgers & Rowland, ''Vss'', Pharm Res 2007, Table II';
% 
%     addrecord(ddb(i), 'MW',     277.40*u.g/u.mol, '?',              [])
%     addrecord(ddb(i), 'pKa',    10.4,             ref.rodgers2007,  [])
%     addrecord(ddb(i), 'logPow', 1.29,             ref.rodgers2007,  [])
% 
%     addrecord(ddb(i), 'fuP',         'human', 0.7,               '?', [])
%     addrecord(ddb(i), 'BP',          'human', 1.04,              '?', [])
%     addrecord(ddb(i), 'CLblood_hep', 'human', '1.4 mL/(min*kg)', '?', [])
%     
%     % ---------------------------------------------------------------------
%     
%     i = i+1;
%     
%     ddb(i).name     = 'Desipramine';
% 
%     ddb(i).class    = 'sMD';
%     ddb(i).subclass = 'base'; % Rodgers & Rowland, 'Vss', Pharm Res 2007, Table II                                       
% 
%     ref = struct();
%     ref.rodgers2007 = 'Rodgers & Rowland, ''Vss'', Pharm Res 2007, Table II';
%     ref.obach1999_2 = 'Obach, Drug Metab Disposit 27(11), 1999, Table 2';
%     ref.obach1999_4 = 'Obach, Drug Metab Disposit 27(11), 1999, Table 4';
% 
%     addrecord(ddb(i), 'MW',     266.38*u.g/u.mol, '?',              [])
%     addrecord(ddb(i), 'pKa',   10.32,             ref.rodgers2007,  [])
%     addrecord(ddb(i), 'logPow', 4.45,             ref.rodgers2007,  [])
% 
%     addrecord(ddb(i), 'fuP',         'human', 0.18,             ref.obach1999_2, [])
%     addrecord(ddb(i), 'BP',          'human', 0.96,             ref.obach1999_2, [])
%     addrecord(ddb(i), 'CLblood_hep', 'human', '12 mL/(min*kg)', ref.obach1999_4, [])
%     
%     % ---------------------------------------------------------------------
%     
%     i = i+1;
%     
%     ddb(i).name     = 'Diltiazem';
% 
%     ddb(i).class    = 'sMD';
%     ddb(i).subclass = 'base'; % Rodgers & Rowland, 'Vss', Pharm Res 2007, Table II                                       
% 
%     ref = struct();
%     ref.rodgers2007  = 'Rodgers & Rowland, ''Vss'', Pharm Res 2007, Table II';
%     ref.obach1999_2  = 'Obach, Drug Metab Disposit 27(11), 1999, Table 2';
%     ref.obach1999_4  = 'Obach, Drug Metab Disposit 27(11), 1999, Table 4';
%     ref.alsaidan2005 = 'Al-Saidan etal (2005), AAPS PharmSciTech';
%     
%     addrecord(ddb(i), 'MW',    414.52*u.g/u.mol, '?',  [])
%     addrecord(ddb(i), 'pKa',     7.7,            '?',  [])
%     addrecord(ddb(i), 'logPow',  2.67,           '?',  [])
% 
%     addrecord(ddb(i), 'fuP',         'human', 0.22,             ref.obach1999_2, [])
%     addrecord(ddb(i), 'BP',          'human', 1.0,              ref.obach1999_2, [])
%     addrecord(ddb(i), 'CLblood_hep', 'human', '12 mL/(min*kg)', ref.obach1999_4, [])
%     addrecord(ddb(i), 'lambda_po',   'human', 5.6004/u.h,       ref.alsaidan2005,[])
%     
%     % ---------------------------------------------------------------------
%     
%     i = i+1;
%     
%     ddb(i).name     = 'Diphenhydramine';
% 
%     ddb(i).class    = 'sMD';
%     ddb(i).subclass = 'base'; % Rodgers & Rowland, 'Vss', Pharm Res 2007, Table II                                       
% 
%     ref = struct();
%     ref.rodgers2007  = 'Rodgers & Rowland, ''Vss'', Pharm Res 2007, Table II';
%     ref.obach1999_4  = 'Obach, Drug Metab Disposit 27(11), 1999, Table 4';
%     
%     addrecord(ddb(i), 'MW',    255.35*u.g/u.mol, '?',             [])
%     addrecord(ddb(i), 'pKa',     8.98,           ref.rodgers2007, [])
%     addrecord(ddb(i), 'logPow',  3.31,           ref.rodgers2007, [])
% 
%     addrecord(ddb(i), 'fuP',         'human', 0.089,            ref.rodgers2007, [])
%     addrecord(ddb(i), 'BP',          'human', 0.74,             ref.rodgers2007, [])
%     addrecord(ddb(i), 'CLblood_hep', 'human', '9.5 mL/(min*kg)',ref.obach1999_4, [])
%      
%     % ---------------------------------------------------------------------
%     
%     i = i+1;
%     
%     ddb(i).name     = 'Imipramine';
% 
%     ddb(i).class    = 'sMD';
%     ddb(i).subclass = 'base'; % Rodgers & Rowland, 'Vss', Pharm Res 2007, Table II                                       
% 
%     ref = struct();
%     ref.rodgers2007  = 'Rodgers & Rowland, ''Vss'', Pharm Res 2007, Table II';
%     ref.obach1999_2  = 'Obach, Drug Metab Disposit 27(11), 1999, Table 2';
%     ref.obach1999_4  = 'Obach, Drug Metab Disposit 27(11), 1999, Table 4';
%     
%     addrecord(ddb(i), 'MW',    280.41*u.g/u.mol, '?',             [])
%     addrecord(ddb(i), 'pKa',     9.5,            ref.rodgers2007, [])
%     addrecord(ddb(i), 'logPow',  4.80,           ref.rodgers2007, [])
%     addrecord(ddb(i), 'logPvow', 4.00,           '?',             [])
% 
%     addrecord(ddb(i), 'fuP',         'human', 0.1,              ref.obach1999_2, [])
%     addrecord(ddb(i), 'BP',          'human', 1.1,              ref.obach1999_2, [])
%     addrecord(ddb(i), 'CLblood_hep', 'human', '12 mL/(min*kg)', ref.obach1999_4, [])        
% 
%     % ---------------------------------------------------------------------
%     
%     i = i+1;
%     
%     ddb(i).name     = 'Lidocaine';
% 
%     ddb(i).class    = 'sMD';
%     ddb(i).subclass = 'base'; % Rodgers & Rowland, 'Vss', Pharm Res 2007, Table II                                       
% 
%     ref = struct();
%     ref.rodgers2007  = 'Rodgers & Rowland, ''Vss'', Pharm Res 2007, Table II';
%     ref.obach1999_4  = 'Obach, Drug Metab Disposit 27(11), 1999, Table 4';
%     ref.boyes1970    = 'Boyes etal (1970), J Pharmacol Exp Ther 174:1-8';
%     
%     addrecord(ddb(i), 'MW',    234.34*u.g/u.mol, '?',             [])
%     addrecord(ddb(i), 'pKa',     8.01,           ref.rodgers2007, [])
%     addrecord(ddb(i), 'logPow',  2.44,           ref.rodgers2007, [])
%     addrecord(ddb(i), 'logPvow', 1.27,           '?',             [])
% 
%     addrecord(ddb(i), 'fuP',         'human', 0.296,            '?',             [])
%     addrecord(ddb(i), 'BP',          'human', 0.84,             '?',             [])
%     addrecord(ddb(i), 'CLblood_hep', 'human', '15 mL/(min*kg)', ref.obach1999_4, [])        
%     addrecord(ddb(i), 'lambda_po',   'human', 0.018/u.min,      ref.boyes1970, 'measured in dog')        
%     addrecord(ddb(i), 'cellPerm',    'human', 6.17e-5*u.cm/u.sec, 'Deciga-Campos et al. (2016)', 'CaCo-2 assay')
% 
%     % ---------------------------------------------------------------------
%     
%     i = i+1;
%     
%     ddb(i).name     = 'Diazepam';
% 
%     ddb(i).class    = 'sMD';
%     ddb(i).subclass = 'base'; % Rodgers & Rowland, 'Vss', Pharm Res 2007, Table III                                       
% 
%     ref = struct();
%     ref.rodgers2007_III  = 'Rodgers & Rowland, ''Vss'', Pharm Res 2007, Table III';
%     ref.obach1999_2     = 'Obach, Drug Metab Disposit 27(11), 1999, Table 2';
%     
%     addrecord(ddb(i), 'MW',    284.74*u.g/u.mol, '?',                 [])
%     addrecord(ddb(i), 'pKa',     3.38,           ref.rodgers2007_III, [])
%     addrecord(ddb(i), 'logPow',  2.84,           ref.rodgers2007_III, [])
% 
%     addrecord(ddb(i), 'fuP',         'human', 0.013,             ref.obach1999_2, [])
%     addrecord(ddb(i), 'BP',          'human', 0.71,              ref.obach1999_2, [])
%     addrecord(ddb(i), 'CLblood_hep', 'human', '0.6 mL/(min*kg)', ref.obach1999_2, [])        
%  
%     % ---------------------------------------------------------------------
%     
%     i = i+1;
%     
%     ddb(i).name     = 'Ketoconazole';
% 
%     ddb(i).class    = 'sMD';
%     ddb(i).subclass = 'base'; % Rodgers & Rowland, 'Vss', Pharm Res 2007, Table III                                       
% 
%     ref = struct();
%     ref.matthew1992     = 'Matthew et al 1992 Pharm Research';
%     ref.brown2005       = 'Brown et al 2005 BJCP';
%     
%     addrecord(ddb(i), 'MW',    531.431*u.g/u.mol, 'drugbank.ca', [])
%     addrecord(ddb(i), 'pKa',     6.75,            'drugbank.ca', [])
%     addrecord(ddb(i), 'logPow',  4.35,            'drugbank.ca', [])
% 
%     addrecord(ddb(i), 'fuP',         'human', 0.01,               'drugbank.ca',     [])
%     addrecord(ddb(i), 'BP',          'human', 0.6,                ref.matthew1992,   'measured in rat')
%     addrecord(ddb(i), 'CLblood_hep', 'human', '2.75 mL/(min*kg)', 'antimicrobe.org', 'PK in healthy adults at ss after po 200mg')        
%     addrecord(ddb(i), 'lambda_po',   'human', 0.013/u.min,        ref.brown2005,     [])
%     
%     % ---------------------------------------------------------------------
%     
%     i = i+1;
%     
%     ddb(i).name     = 'Midazolam';
% 
%     ddb(i).class    = 'sMD';
%     ddb(i).subclass = 'base'; % Rodgers & Rowland, 'Vss', Pharm Res 2007, Table III                                       
% 
%     ref = struct();
%     ref.rodgers2007_III = 'Rodgers & Rowland, ''Vss'', Pharm Res 2007, Table III';
%     ref.obach1999_2     = 'Obach, Drug Metab Disposit 27(11), 1999, Table 2';
%     ref.smith1981       = 'Smith etal (1981), Eur J Clin Pharmacol';
%     
%     addrecord(ddb(i), 'MW',    325.77*u.g/u.mol, '?',                 [])
%     addrecord(ddb(i), 'pKa',     6.01,           ref.rodgers2007_III, [])
%     addrecord(ddb(i), 'logPow',  3.15,           ref.rodgers2007_III, [])
% 
%     addrecord(ddb(i), 'fuP',         'human', 0.05,              ref.obach1999_2, [])
%     addrecord(ddb(i), 'BP',          'human', 0.57,              ref.obach1999_2, 'changed from 0.53 to 0.57, since otherwise smaller than 1-hct')
%     addrecord(ddb(i), 'CLblood_hep', 'human', '8.7 mL/(min*kg)', ref.obach1999_2, [])        
%     addrecord(ddb(i), 'lambda_po',   'human', 9.6/u.h,           ref.smith1981,   [])
% 
%     % ---------------------------------------------------------------------
%     
%     i = i+1;
%     
%     ddb(i).name     = 'Digoxin';
% 
%     ddb(i).class    = 'sMD';
%     ddb(i).subclass = 'neutral'; % Rodgers & Rowland, 'Vss', Pharm Res 2007, Table III                                       
% 
%     ref = struct();
%     ref.neuhoff       = 'Neuhoff et al., J Pharm Sci 102, (2013)';
%     
%     addrecord(ddb(i), 'MW',    780.94*u.g/u.mol, '?',          [])
%     addrecord(ddb(i), 'logPow',  1.26,           ref.neuhoff,  [])
% 
%     addrecord(ddb(i), 'fuP',         'human', 0.78,  ref.neuhoff, [])
%     addrecord(ddb(i), 'BP',          'human', 1.07,  ref.neuhoff, [])
% %    addrecord(ddb(i), 'CLblood_hep', 'human', 'NaN mL/(min*kg)', '?', [])        
% 
%     % ---------------------------------------------------------------------
%     
%     i = i+1;
%     
%     ddb(i).name     = 'Dexamethasone';
% 
%     ddb(i).class    = 'sMD';
%     ddb(i).subclass = 'neutral'; % Rodgers & Rowland, 'Vss', Pharm Res 2007, Table V                                       
% 
%     ref = struct();
%     ref.rodgers2007_V = 'Rodgers & Rowland, ''Vss'', Pharm Res 2007, Table V';
%     ref.obach1999     = 'Obach, Drug Metab Disposit 27(11), 1999, Table 2';
% 
%     addrecord(ddb(i), 'MW',    392.47*u.g/u.mol, 'Wikipedia',       [])
% %    addrecord(ddb(i), 'pKa',      NaN,           'not needed',      [])
%     addrecord(ddb(i), 'logPow',  2.18,           ref.rodgers2007_V, [])
% 
%     addrecord(ddb(i), 'fuP',         'human', 0.32,              ref.obach1999, [])
%     addrecord(ddb(i), 'BP',          'human', 0.93,              ref.obach1999, [])
%     addrecord(ddb(i), 'CLblood_hep', 'human', '3.8 mL/(min*kg)', ref.obach1999, [])        
% 
%     % ---------------------------------------------------------------------
%     
%     i = i+1;
%     
%     ddb(i).name     = 'Ibuprofen';
% 
%     ddb(i).class    = 'sMD';
%     ddb(i).subclass = 'acid'; % Rodgers & Rowland, 'Vss', Pharm Res 2007, Table IV                                       
% 
%     ref = struct();
%     ref.rodgers2007_IV = 'Rodgers & Rowland, ''Vss'', Pharm Res 2007, Table IV';
%     ref.obach1999     = 'Obach, Drug Metab Disposit 27(11), 1999, Table 2';
% 
%     addrecord(ddb(i), 'MW',    206.28*u.g/u.mol, 'Wikipedia',        [])
%     addrecord(ddb(i), 'pKa',     4.70,           ref.rodgers2007_IV, [])
%     addrecord(ddb(i), 'logPow',  4.06,           ref.rodgers2007_IV, [])
% 
%     addrecord(ddb(i), 'fuP',         'human', 0.01,              ref.obach1999, [])
%     addrecord(ddb(i), 'BP',          'human', 0.57,              ref.obach1999, 'changed from 0.53 to 0.57, since otherwise smaller than 1-hct')
%     addrecord(ddb(i), 'CLblood_hep', 'human', '1.5 mL/(min*kg)', ref.obach1999, [])        
%     
    % ---------------------------------------------------------------------
    
    i = i+1;

    edb(i).name     = 'Warfarin';

    edb(i).class    = 'sMD';
    edb(i).subclass = 'acid';                                        

    ref = struct();
    ref.sawada1985  = Ref('Sawada1985',   'Sawada et al. J of PK/Biopharm Vol.13 1985');
    ref.slattery1979= Ref('Slattery1979', 'Slattery et al., Clin Pharmacol Ther, Jan 1979');
    ref.obach1999   = Ref('Obach1999',    'Obach, Drug Metab Disposit 27(11), 1999');
    ref.mungall1985 = Ref('Mungall1985',  'Mungall et al 1985 J PK Biopharm Population PK of Racemic warfarin in adult patients');
    ref.julkunen1980= Ref('Julkunen1980', 'Julkunen et al 1980, Arzneimittelforschung 30(2):264-7 (Abstract)');
    ref.yacobi1975  = Ref('Yacobi1975',   'Yacobi/Levy, 1975, J Pharm Sci 60 (10)');
    ref.holford1986 = Ref('Holford1986',  'Holford, 1986, Clin Pharmacol Ther 39: 199');

    cond = struct();
    cond.rat = ExpConditions('species','rat');
    cond.hum = ExpConditions('species','human');
    cond.slattery = ExpConditions('species','human','sex','male','BW',73*u.kg);
    cond.yacobi   = ExpConditions('species','rat','sex','male','BW',425*u.g);
    cond.hct = ExpConditions('hct',0.42);

    addrecord(edb(i), 'MW',     308.33*u.g/u.mol, 'drugbank.ca',  [], [])
    addrecord(edb(i), 'pKa',    5.08,             'drugbank.ca',  [], [])
    addrecord(edb(i), 'logPow', 3,                'Wolfram Alpha',[], [])

    addrecord(edb(i), 'fuP',         0.012,              ref.yacobi1975,   cond.yacobi, [])
%    addrecord(ddb(i), 'K_ery_up',    0,                  ref.sawada1985,   cond.yacobi, 'Partitioning into RBC assumed to be negligible')
    addrecord(edb(i), 'BP',          0.58,               ref.sawada1985,   cond.rat+cond.hct, 'Assumed identical to 1-hct by the authors')
    addrecord(edb(i), 'CLblo_perBW', '13.7 mL/(h*kg)', ref.yacobi1975,   cond.yacobi, [])
    addrecord(edb(i), 'lambda_po',   '0.258/min',         ref.julkunen1980, cond.rat,    [])    
%    addrecord(ddb(i), 'lambda_po',   2/u.h,              ref.julkunen1980, cond.rat,    [])     %TODO: I don't know how this value came about!! 

    addrecord(edb(i), 'fuP',         0.008,               ref.slattery1979,  cond.slattery, [])
    addrecord(edb(i), 'fuP',         0.01,                ref.obach1999,     cond.hum,      'Value cited from OReilly (1972), but that reference is unavailable')
    addrecord(edb(i), 'BP',          0.58,                ref.sawada1985,    cond.hum+cond.hct, 'Assumed identical to 1-hct by the authors')
    addrecord(edb(i), 'CLblo_perBW', '2.2 mL/(h*kg)',     ref.slattery1979,  cond.slattery, [])
    addrecord(edb(i), 'CLblo_perBW', '0.081 mL/(min*kg)', ref.obach1999,     cond.hum,      'Value cited from OReilly (1972), but that reference is unavailable')
    addrecord(edb(i), 'CLblo_perBW', '0.141 L/(h*70*kg)', ref.holford1986,   cond.hum,      'Cited from a poster abstract, value and conditions not 100% clear.')
    addrecord(edb(i), 'lambda_po',   47/u.day,            ref.mungall1985,   cond.hum,      [])    
    
    % ---------------------------------------------------------------------
    
%     i = i+1;
% 
%     ddb(i).name     = 'drugA';
% 
%     ddb(i).class    = 'sMD';
%     ddb(i).subclass = 'acid';                                        
% 
%     addrecord(ddb(i), 'MW',     308.33*u.g/u.mol, '?', [])
%     addrecord(ddb(i), 'pKa',    5.08,             '?', [])
%     addrecord(ddb(i), 'logPow', 3,                '?', [])
% 
%     addrecord(ddb(i), 'fuP',         'rat', 0.38,              '?', [])
%     addrecord(ddb(i), 'BP',          'rat', 1.27,              '?', [])
%     addrecord(ddb(i), 'CLblood_hep', 'rat', '0.1 mL/(min*kg)', '?', [])
%     addrecord(ddb(i), 'lambda_po',   'rat', 0.01/u.min,        '?', [])    
%     
%     addrecord(ddb(i), 'fuP',         'human', 0.01,                '?', [])
%     addrecord(ddb(i), 'BP',          'human', 0.567,               '?', [])
%     addrecord(ddb(i), 'CLblood_hep', 'human', '0.081 mL/(min*kg)', '?', [])
%     addrecord(ddb(i), 'lambda_po',   'human', 0.01/u.min,          '?', [])
%     
%     % ---------------------------------------------------------------------
%     
%     i = i+1;
% 
%     ddb(i).name     = 'drugB';
% 
%     ddb(i).class    = 'sMD';
%     ddb(i).subclass = 'base';                                        
% 
%     addrecord(ddb(i), 'MW',      234.34*u.g/u.mol, '?', [])
%     addrecord(ddb(i), 'pKa',     8.01,             '?', [])
%     addrecord(ddb(i), 'logPow',  2.26,             '?', [])
%     addrecord(ddb(i), 'logPvow', 1.27,             '?', [])
% 
%     addrecord(ddb(i), 'fuP',         'rat', 0.24,             '?', [])
%     addrecord(ddb(i), 'BP',          'rat', 1.27,             '?', [])
%     addrecord(ddb(i), 'CLblood_hep', 'rat', '55 mL/(min*kg)', '?', [])
%     addrecord(ddb(i), 'lambda_po',   'rat', 0.2/u.min,        '?', [])    
%     
%     addrecord(ddb(i), 'fuP',         'human', 0.296,            '?', [])
%     addrecord(ddb(i), 'BP',          'human', 0.84,             '?', [])
%     addrecord(ddb(i), 'CLblood_hep', 'human', '15 mL/(min*kg)', '?', [])
%     addrecord(ddb(i), 'lambda_po',   'human', 0.02/u.min,       '?', [])
%             
%     % ---------------------------------------------------------------------
%     
%     i = i+1;
%     
%     ddb(i).name     = 'mAb7E3';
% 
%     ddb(i).class    = 'mAb';
%     ddb(i).subclass = 'IgG1';                                      
% 
%     addrecord(ddb(i), 'MW', 150000*u.g/u.mol, '?', [])
%     
%     % ---------------------------------------------------------------------
%     
%     i = i+1;
%     
%     ddb(i).name     = 'Bevacizumab';
% 
%     ddb(i).class    = 'mAb';
%     ddb(i).subclass = 'IgG1';                                      
% 
%     addrecord(ddb(i), 'MW', 149000*u.g/u.mol, '?', [])
% 
    % ---------------------------------------------------------------------

end




