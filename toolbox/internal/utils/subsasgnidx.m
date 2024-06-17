function idx = subsasgnidx(str, clstr)
%SUBSASGNIDX Get index for subassignment
%   IDX = SUBSASGNIDX(STR, CLSTR) returns the numerical index IDX for which
%   char STR matches the cellstr CLSTR. If no match is found, IDX is equal
%   to the number of elements of CLSTR plus 1.

    [redef, idx] = ismember(str, clstr);
    if ~redef
        idx = numel(clstr)+1;
    end

end

