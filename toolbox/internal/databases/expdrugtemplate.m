% EXPDRUGTEMPLATE Template for Exp-drug-related parameters with metadata 
%   EXPDRUGTEMPLATE is a customizable template to define the type of 
%   experimental drug-related parameters that may be added to the drug database. 
%
%   Note that in order for a change in EXPDRUGTEMPLATE to take effect,
%   function 'initPBPKtoolbox' must be re-run, and that this clears all
%   variables from the global workspace.
%
%   PARAMS = EXPDRUGTEMPLATE() returns a N-by-4 cell array PARAMS, where each
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
%   See also initexpdrugdb, ExpDrugData, typecheck, about, initPBPKtoolbox

function params = expdrugtemplate()

%    Parameter      Unit type    Per species?   Description
params = {
    'MW'                  'Mass/Amount'    false      'Molecular weight'
    'pKa'                 'unitless'       false      'log10 acid dissociation constant'
    'logPow'              'unitless'       false      'log10 octanol-water partition coefficient'
    'logPvow'             'unitless'       false      'log10 vegetable oil-water partition coefficient'
    'logMA'               'unitless'       false      'log10 membrane affinity'
    'fuP'                 'unitless'       true       'Fraction unbound in plasma'
    'BP'                  'unitless'       true       'Blood-to-plasma concentration ratio in steady-state'
    'CLblo'               'L/h'            true       'In vivo hepatic blood clearance'    
    'CLblo_perBW'         'L/(h*kg)'       true       'In vivo hepatic blood clearance per body weight'    
    'T12micro'            'h'              true       'Microsomal half-life'
%   'CLuint_liv_perOWtis'    TODO: adapt naming here.
%   'CLucel_liv'
    'CLint_hep_perOWliv'  'L/(h*kg)'       true       'Intrinsic hepatic clearance per liver tissue weight'
%    'K_ery_up'            'unitless'       true       'Erythrocyte-to-plasma partition coefficient'
    'lambda_po'           '1/Time'         true       'Absorption rate constant'
    'Egut'                'unitless'       true       'Gut extraction ratio'
    'Efeces'              'unitless'       true       'Feces extraction ratio'
    'Freabs'              'unitless'       true       'Tubular reabsorbed fraction'
    'cellPerm'            'Velocity'       true       'Cellular permeability (e.g., from CaCo-2 assay)'
};


end

