function [s] = num2str(obj, varargin)

    ST = dbstack(1,'-completenames');
    if isequal(varargin,{'%d    '}) && ...
            contains(ST(1).file,['@tabular' filesep 'disp.m'])
        % Compensation for behavior of @tabular\disp.m trying to format with %d:
        varargin = {getFloatFormats()}; % Assume double value.
    end

    % object properties
    expos = obj.exponents;
    grp   = obj.grouping;

    % parse 1-variables in all units, including customDisplay
    S = arrayfun(@displaystr,(1:size(expos,1))', obj.customDisplay);

    % multiply value property by displayingvalue and format to string
    dispfactor = [S.v];
    dispvalue  = obj.value .* reshape(dispfactor(grp), size(grp));
    if nargin == 2
        valstring = compose(string(varargin{1}), dispvalue);
    else
        valstring = string(dispvalue);
    end
    
    valstring(ismissing(valstring)) = "NaN"; % un-do conversion to <missing>
    valstring = pad(deblank(valstring),'left');
    
    % format unit string 
    unitstring = vertcat(S.str);
    unitstring = reshape(unitstring(grp), size(grp));
    unitstring = pad(unitstring,'right');
    
    % combine and format
    dispstring = strcat(valstring, unitstring);
    s = char(dispstring);
    s = deblank(reshape(s, size(s,1), []));
    
    function res = displaystr(i,cdis)
        expo = expos(i,:);
        if all(expo == 0)
            res = struct('v',1,'str',"");
            return
        end

        dv = DimVar(expo,1);
        dv = scd(dv,cdis{1});                
        [v,~,str] = displayparser(dv);
        res = struct('v',v,'str'," " + str + " ");
    end

end

function dblFmt = getFloatFormats()

switch lower(matlab.internal.display.format)
    case {'short' 'shortg' 'shorteng'}
        dblFmt  = '%.5g    ';
    case {'long' 'longg' 'longeng'}
        dblFmt  = '%.15g    ';
    case 'shorte'
        dblFmt  = '%.4e    ';
    case 'longe'
        dblFmt  = '%.14e    ';
    case 'bank'
        dblFmt  = '%.2f    ';
    otherwise % rat, hex, + fall back to shortg
        dblFmt  = '%.5g    ';
end
end