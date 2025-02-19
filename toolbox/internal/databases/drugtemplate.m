% DRUGTEMPLATE Template for drug-related parameters with metadata 
%   DRUGTEMPLATE is a customizable template to define the type of 
%   drug-related parameters that may be added to the drug database. 
%
%   Note that in order for a change in DRUGTEMPLATE to take effect,
%   function 'resetcompphysiol' must be re-run, and that this clears all
%   variables from the global workspace.
%
%   PARAMS = DRUGTEMPLATE() returns a N-by-4 cell array PARAMS, where each
%   row corresponds to a parameter type in the database and the columns 
%   contain the following information:
%   - column 1 is the parameter name
%   - column 2 is the unit type of the parameter - either a type defined in
%     function istype(), or DimVar, or a character array convertible to DimVar
%   - column 3 specifies whether the parameter is defined globally or on a
%     per-species level
%   - column 4 is an explanatory text that can be queried with function
%     about()
%
%   See also initdrugdb, DrugDB, typecheck, about, resetcompphysiol

function params = drugtemplate()

%    Parameter            Unit type    Per species?   Description
params = {
    'formula'             'char'           false      'Molecular formula'
    'MW'                  'Mass/Amount'    false      'Molecular weight'
    'pKa_ani'             'unitless'       false      'anionic log10 acid dissociation constant'
    'pKa_cat'             'unitless'       false      'cationic log10 acid dissociation constant'
    'Kz'                  'unitless'       false      'Tautomeric constant of ampholytes (ratio zwitter ion : neutral)'
    'logPow'              'unitless'       false      'log10 octanol-water partition coefficient'
    'logPvow'             'unitless'       false      'log10 vegetable oil-water partition coefficient'
    'logMA'               'unitless'       false      'log10 membrane affinity (phosphatidylcholin:water partition coefficient at pH 7.4)'
    'fuP'                 'unitless'       true       'Fraction unbound in plasma'
    'BP'                  'unitless'       true       'Blood-to-plasma concentration ratio in steady-state'
    'CLblood_hep'         'L/(h*kg)'       true       'In vivo hepatic blood clearance, scaled to body weight'    
    'CLint_hep_perOWliv'  'L/(h*kg)'       true       'Intrinsic hepatic clearance per liver tissue weight'
    'K_ery_up'            'unitless'       true       'Erythrocyte-to-plasma partition coefficient'
    'lambda_po'           '1/Time'         true       'Absorption rate constant'
    'Egut'                'unitless'       true       'Gut extraction ratio'
    'Efeces'              'unitless'       true       'Feces extraction ratio'
    'Freabs'              'unitless'       true       'Tubular reabsorbed fraction'
    'cellPerm'            'Velocity'       true       'Cellular permeability (e.g., from CaCo-2 assay)'
};


end

