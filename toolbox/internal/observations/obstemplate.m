% OBSTEMPLATE Template for observables 
%   OBSTEMPLATE is a customizable template to define the type of 
%   observables contained in a Sampling or Record object. 
%
%   OBS = OBSTEMPLATE(TYPE) returns a N-by-2 cell array OBS, where each
%   row corresponds to an attribute defining the type of observable, and:
%   - column 1 is the parameter name
%   - column 2 is an explanatory text 
%
%   See also Observable, Record, Sampling

function obs = obstemplate(type)

    %    Name          Help text
    obs = {
        'Compound'     'Drug name'
        'Site'         'Part of body where observation is taken (e.g., liv, bon, mus)'
        'Subspace'     'Tissue subspace (tot, tis, cel, ...)'
        'Binding'      'Type of binding (unbound/bound/total)'
        'UnitType'     'Type of requested unit (Amount, Mass, Amount/Volume, Mass/Volume)'
        'PDCat'        'Category for any other stratification'
    };

    if nargin > 0
        switch type
            case 'ExpData'
                select = {'Site', 'Subspace', 'Binding', 'UnitType'};         
            case 'PBPK'
                select = {'Site', 'Subspace', 'Binding', 'UnitType'};         
            case 'NormalizedConc'
                select = {'Site', 'Subspace'};         
            case 'SimplePK'
                select = {'Site', 'Binding', 'UnitType'};         
            case 'MultiPK'
                select = {'Compound','Site'};         
            case 'PD'
                select = {'PDCat'};
            case 'MassBalance'
                select = {'UnitType'};
            otherwise
                error('Unknown observable type "%s"', type)
        end
        obs = obs(ismember(obs(:,1), select),:);
    end

end

