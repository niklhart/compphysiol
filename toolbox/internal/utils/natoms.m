%NATOMS Number of atoms in a molecular formula
%   N = NATOMS(FORMULA, ATOM) returns the number N of ATOMs (a char) in a
%   molecular formula FORMULA.
%
%   Examples:
%   
%   natoms('CaCl2','Ca')
%   natoms('CaCl2','Cl')
%   natoms('CaCl2','Br')
%
%   See also predict_cellperm
function n = natoms(formula, atom)

    upr = isstrprop(formula,'upper');
    grp = splitapply(@(x) {x},formula, cumsum(upr));

    if any(startsWith(grp,atom))
        nstr = extractAfter(grp,atom);
        nstr = [nstr{:}];
        if isempty(nstr)
            n = 1;
        else
            n = str2double(nstr);
        end
    else
        n = 0;
    end

end