%FFM Fat free mass according to Janmahasatian et al. (2005)
% M = FFM(BW,BH,SEX), with Mass-type DimVar BW (body weight), Length-type
% DimVar BH and a character array SEX ('male' or 'female') determines the 
% fat free mass M according to Janmahasatian et al., Clin Pharmacokinet 
% 2005; 44 (10): 1051-1065.
function out = ffm(BW,BH,sex)

    assert(istype(BW,'Mass'))
    assert(istype(BH,'Length'))

    BMI = BW./BH.^2;
    sex = validatestring(sex, {'male','female'});
    switch sex
        case 'male'
            out = 9.27e3*BW./(6.68e3 + 216*u.m^2/u.kg*BMI);
        case 'female'
            out = 9.27e3*BW./(8.78e3 + 244*u.m^2/u.kg*BMI);
    end

end
