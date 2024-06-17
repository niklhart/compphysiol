%VALIDATENESTEDOBJ Validate a nested object
%   VALIDATENESTEDOBJ(O) with a (possibly nested) struct, cell array or 
%   table O, validates object O using default properties (see below).
%
%   VALIDATENESTEDOBJ(O, ...) allows to customize the behaviour through the
%   following property value pairs (defaults in brackets):
%     * 'mode' ('error', {'info'}, 'ignore'): if object O is invalid, 
%        throw an error, inform about the invalid part, or ignore it?
%     * 'report_nan' ({true} / false): report NaN values?
%     * 'report negative' ({true} / false): report negative values?
%
% Example:
%
%   S = struct('a',5,'b',struct('c',NaN,'d',4,'e',-2));
%   validateNestedObj(S)
%
%   T = table([1;2;NaN], [1;2;3], [-1;NaN;2],'VariableNames',{'a','b','c'});
%   validateNestedObj(T)
%

function validateNestedObj(o, varargin)

    p = inputParser();
    p.addParameter('mode',           'info', @(x) ismember(x,{'info','error','ignore'}));
    p.addParameter('report_nan',      true,  @isboolean);
    p.addParameter('report_negative', true,  @isboolean);
    p.parse(varargin{:});

    res = p.Results;

    % first level of nesting struct for display
    str = inputname(1);
    if isempty(str)
        str = 'OBJ';
    end

    % define validators to use
    if res.report_nan
        switch res.mode
            case 'info'
                disp('Looking for NaN values...')
                recchk(o, str, @nan_validator_info)
                disp('...finished.')
            case 'error'
                recchk(o, str, @nan_validator_error)
        end        
    end
    if res.report_negative
        switch res.mode
            case 'info'
                disp('Looking for negative values...')
                recchk(o, str, @neg_validator_info)
                disp('...finished.')
            case 'error'
                recchk(o, str, @neg_validator_error)
        end        
    end

end

%% Validators

function neg_validator_info(x, str)

    if any(double(x)<0, 'all')
        disp(['Negative value found (' str ').'])
    end
    
end


function neg_validator_error(x, str)

    if any(double(x)<0, 'all')
        error('ValidateNestedObj:NegVal','Negative value found (%s).', str)
    end
    
end

function nan_validator_info(x, str)

    if any(isnan(x), 'all')
        disp(['NaN found (' str ')'])
    end
    
end

function nan_validator_error(x, str)

    if any(isnan(x),'all')
        error('ValidateNestedObj:NaNVal','NaN found (%s).', str)
    end

end


