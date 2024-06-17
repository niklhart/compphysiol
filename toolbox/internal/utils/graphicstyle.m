function [style, leg] = graphicstyle(individual)
%GRAPHICSTYLE Create comma separated list of legend entries from individuals.

    markers = {'x','o','+','*'};
    lines   = {'-.','-',':','--'};
    colors = {'y','r','b','k','c','m','g'};

    nid = numel(individual);
    leg   = cell(1,nid);
    style = cell(1,nid);

    iexp = cumsum(isexpid(individual(:)));
    isim = cumsum(issimid(individual(:))); 

    for i=1:nid
        if isempty(individual(i).name)
            leg{i} = defaultname(individual(i));
        else
            leg{i} = individual(i).name;
        end
        
        if ~isempty(individual(i).options) && isfield(individual(i).options, 'plotstyle')
            % custom style
            style{i} = individual(i).options.plotstyle;
        else
            % default style
            col = colors{1+mod(i,numel(colors))};
            if strcmp(individual(i).type, 'Experimental data')
                typ = markers{1+mod(iexp(i),numel(markers))};
            else
                typ = lines{1+mod(isim(i),numel(lines))};
            end
            style{i} = [col typ];                       
        end

    end
    
end

