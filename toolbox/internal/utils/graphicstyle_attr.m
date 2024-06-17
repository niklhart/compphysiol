%GRAPHICSTYLE_ATTR Create graphic style / legend from attribute information
function [style, leg] = graphicstyle_attr(attr)

    % validate arguments
    if ischar(attr)
        attr = {attr};
    else
        assert(iscellstr(attr),'Input #1 must be char or cellstr.') %#ok<ISCLSTR>
    end
    
%    markers = {'x','o','+','*'};
    lines   = {'-.','-',':','--'};
    colors = {'y','r','b','k','c','m','g'};

    ngrp = numel(attr);
    leg   = attr;
    style = cell(1,ngrp);

    for i=1:ngrp

            % default style
            col = colors{1+mod(i,numel(colors))};
            typ = lines{1+mod(i,numel(lines))};
            style{i} = [col typ];                       

    end
    
end

