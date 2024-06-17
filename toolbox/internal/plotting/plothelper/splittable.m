%SPLITTABLE Split a table into cell array using grouping variables
%   Detailed explanation goes here

function [C, lvl1, lvl2] = splittable(T, var1, var2)

    nov1 = isempty(var1) || ~istablecol(T, var1);
    nov2 = isempty(var2) || ~istablecol(T, var2);
    
    if nov1
        lvl1 = [];
        if nov2
            C = {T};
            lvl2 = [];
            return
        else
            [C, lvl2] = splittable_1arg(T, var2);
            C = C';
        end
    else 
        if nov2
            [C, lvl1] = splittable_1arg(T, var1);
            lvl2 = [];
        else
            [C, lvl1, lvl2] = splittable_2arg(T, var1, var2);
        end  
    end
        
end

function [C,lvl] = splittable_1arg(T, v)
    catvar = T.(v);
    assert(iscategorical(catvar), 'Grouping column must be categorical.')
    lvl = categories(catvar);
    ncat = numel(lvl);
    C = cell(ncat,1);
    for i = 1:ncat
        C{i} = T(catvar == lvl{i},:);
    end
end

function [C, lvl1, lvl2] = splittable_2arg(T, v1, v2)

    catvar1 = T.(v1);
    catvar2 = T.(v2);
    assert(iscategorical(catvar1) && iscategorical(catvar2), ...
        'Grouping columns must be categorical.')

    lvl1 = categories(catvar1);
    lvl2 = categories(catvar2);
    ncat1 = numel(lvl1);
    ncat2 = numel(lvl2);

    C = cell(ncat1,ncat2);
    for i = 1:ncat1
        for j = 1:ncat2
            C{i,j} = T(catvar1 == lvl1{i} & catvar2 == lvl2{j}, :);
        end
    end
end

% Below I tried to generalize, but it didn't work out yet.
%
%
% function [C, varargout] = splittable(T, varargin)
%     
%     nvar = numel(varargin);
%     Glvl = cell(nvar,1);
%     [G, Glvl{:}] = findgroups(T{:, varargin});
% 
%     lvl = cellfun(@unique, Glvl, 'UniformOutput', false);
%     n   = cellfun(@numel, lvl);
%     varargout = lvl;
%     
%     C = cell(n);
%     for i = 1:numel(unique(G)) % or numel(Glvl{1}), avoiding the call to 'unique()'
%         j = cellfun(@(glv,lv) find(glv(i) == lv, 1), Glvl, lvl);
%         C{j} = T(G == i,:);
%     end
% 
% end

