function out = tounit(in)
%OUT = TOUNIT(IN) Convert IN into a DimVar OUT, if possible.
%   Possibilities:
%   IN character or string array --> converted using str2u, then returned.
    
    if isnumeric(in)
        out = in;
    else
        try
            out = str2u(in);
            if iscell(out)
                out = reshape([out{:}],size(out));
            end
        catch 
            error('compphysiol:cannotConvert',...
                ['Cannot convert argument "' in '" to class "DimVar"'])
        end
    end


end

