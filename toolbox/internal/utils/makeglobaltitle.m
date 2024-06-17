function makeglobaltitle(title, varargin)
%MAKEGLOBALTITLE Make a title for a group of subplots


    if verLessThan('matlab','9.5') % 9.5 = MATLAB R2018b

        a = axes;
        t = title(title, varargin{:});
        a.Visible = 'off';
        t.Visible = 'on';

    else 
        sgtitle(title, varargin{:}) % introduced in MATLAB R2018b
    end

end

