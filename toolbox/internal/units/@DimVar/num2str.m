function s = num2str(v, varargin)
%NUM2STR Char representation of DimVar objects.

    [dispVal,~,unitStr] = displayparser(v);
    s = num2str(dispVal, varargin{:});
    
    if isempty(s)
        s = '[]';
    end
    
    s = strcat(s,[' ' unitStr]);

end
