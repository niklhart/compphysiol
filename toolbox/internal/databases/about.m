%ABOUT Information about physiological or drug-related parameters
%   ABOUT(DB), with a scalar Physiology or DrugData object DB, summarizes the
%   entries in the database.
%
%   ABOUT(PAR), with a parameter named PAR defined in physiologytemplate() 
%   or drugtemplate(), displays information about that parameter.
%
%   ABOUT(DB, PAR) displays all entries of parameter PAR in the scalar 
%   Physiology or DrugData object DB.
%
%   See also physiologytemplate, drugtemplate


function about(varargin)

    narginchk(0,2)
    switch nargin
        case 0
            return        
        case 1
            input = varargin{1};
            switch class(input)
                case 'char'
                    aboutpar(input)
                case {'Physiology','DrugData','ExpDrugData'}
                    aboutdb(input)
                otherwise
                    error(['Input must be a parameter (char) or a database' ...
                        '(Physiology or DrugData).'])
            end
        case 2
            db = varargin{1};
            par = varargin{2};
            aboutdbpar(db,par)
    end
    


end

function aboutdb(db)
    assert(isscalar(db), 'Database must be scalar.')
    
    fprintf('Parameters in database %s:\n', db.name) 
    for fld = fieldnames(db.db)'
        nentry = height(db.db.(fld{1}));
        if nentry
            fprintf('- %s:\t%d record(s).\n',fld{1},nentry)
        end
    end
    
end


function aboutpar(name)

    sptmp = physiologytemplate();
    drtmp = drugtemplate();
    
    if ismember(name,sptmp(:,1))
        row = strcmp(name,sptmp(:,1));
    
        fprintf('Description: %s\n',sptmp{row,4})
        fprintf('Unit type: %s\n', sptmp{row,2})
        if sptmp{row,3}
            fprintf('Vector (per tissue) parameter\n\n')
        else
            fprintf('Scalar parameter\n\n')
        end

    elseif ismember(name,drtmp(:,1))
        row = strcmp(name,drtmp(:,1));
        
        fprintf('Description: %s\n',drtmp{row,4})
        fprintf('Unit type: %s\n', drtmp{row,2})
        if drtmp{row,3}
            fprintf('Per species parameter\n\n')
        else
            fprintf('Scalar parameter\n\n')
        end
    else
        error('Not a species / drug parameter.')
    end
end

function aboutdbpar(db, par)
assert(isscalar(db), 'Database must be scalar.')
    
    assert(isfield(db.db, par), ...
        ['"' par '" is not a valid parameter of database "' db.name '".'])
    fprintf('Entries for parameter %s in database %s:\n\n', par, db.name) 
    tab = db.db.(par);    
    disp(tab)
    
end


