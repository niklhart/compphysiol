function obs = PBPKobservables(varargin)
%PBPKOBSERVABLES Customizable Observable array suitable for PBPK modelling.
%   OBS = PBPKOBSERVABLES() defines the default PBPK observables, a length
%   length 11 observable array consisting of plasma concentration and 10 
%   tissue concentrations in Mass/Volume, total concentration, total tissue
%   subspace.
%
%   OBS = PBPKOBSERVABLES(...) allows to customize any of the attributes
%   'Site', 'Subspace', 'Binding', 'UnitType' through property-value pairs.
%
%   Examples:
%   
%   obs = PBPKobservables();                   % default observables
%   
%   obs = PBPKobservables('Subspace','vas');   % vascular instead of total
%                                              % tissue subspace
%   See also Observable

    % define possible inputs and their defaults
    p = inputParser;

    p.addParameter('Site', {'adi','bon','gut','hea','kid','liv','lun','mus','ski','spl'});
    p.addParameter('Subspace','tot');
    p.addParameter('Binding','total');
    p.addParameter('UnitType','Mass/Volume');

    p.parse(varargin{:});

    res = p.Results;

    % create an Observable array from the inputs
    Cpla = Observable('SimplePK','pla',res.Binding,res.UnitType);
    Ctot = Observable('PBPK',res.Site,res.Subspace,res.Binding,res.UnitType);

    obs = [Cpla; Ctot];

end