%COVARIATES Create a physiology object from an individuals' covariates
%   PHYS = COVARIATES(COV1,VAL1,COV2,VAL2,...) creates an object of class
%       Physiology, of which the fields COV1,COV2,... are filled out with
%       VAL1,VAL2,...
%   
%       A stratified covariate is specified as 'COV|STRAT', e.g. 'Qblo|liv'
%       for liver blood flow (see example below).
%
%   PHYS = COVARIATES(TAB) with a two-column table TAB of the form
%           Name    Value
%           COV1    VAL1
%           COV2    VAL2
%           ...
%       is an equivalent way to specify covariates. 
%
%   Examples:
%
%   p1 = Covariates('Species','human','sex','male','BH',1.80*u.m,... 
%       'BW',70*u.kg,'age',35*u.year)
%   
%   p2 = Covariates('Species','rat','sex','male','BW',200*u.g,'age',4*u.week)
%
%   p3 = Covariates('Species','human','Qblo|liv',5*u.L/u.h)

function phys = Covariates(varargin)
    
    if nargin == 1
        argtab = varargin{1};
        assert(istable(argtab) && all(ismember({'Name','Value'}, argtab.Properties.VariableNames)), ...
            'compphysiol:Covariates:wrongInputTableColumns', ...
            'In a single-argument call, the input must be a table with columns "Name" and "Value".')

        argtab = mergeunit(argtab,'Value',false);    % 'false' avoids failing conversion of e.g. species to DimVar. 
        varargin = reshape([argtab.Name'; argtab.Value'],1,[]);
    end
    
    phys = Physiology();
    physpars = fieldnames(phys.pertissue);

    assert(~mod(length(varargin),2), ...
        'compphysiol:Covariates:missingValue', ...
        'Missing value for a property-value pair.')
    varargin = reshape(varargin(:),2,[])';
    
    npairs = size(varargin,1);
    for i = 1:npairs
        % property-value pair
        prop = varargin{i,1};
        val  = varargin{i,2};

        % determine if property is stratified
        strat   = strsplit(prop,'|');
        par     = validatestring(strat{1}, physpars);

        if  numel(strat) > 1  % statified
            addrecord(phys,par,strat{2},val,'Covariate','manually set');
        else                  % not stratified
            addrecord(phys,par,val,'Covariate','manually set');
        end
    end
    
end
