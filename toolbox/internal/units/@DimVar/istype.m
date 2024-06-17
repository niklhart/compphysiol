function tf = istype(v,name)
% ISTYPE  Determine if input DimVar is of a specified category of units. 
% 
%   ISTYPE(dv,'Unit Category') returns true if dv is a DimVar of the 
%   category. Categories are case sensitive, and valid options are: 
%   
%   Length, Mass, Time, Temperature, Currency, Area, Volume, Acceleration, 
%   Force, Energy, Pressure, Power, Velocity, Mass/Volume, Amount, 
%   Amount/Volume, 1/Time, Volume/Time, Mass/Time, Amount/Time,
%   Mass/Amount, Mass/Area. 
%   
%   Otherwise, built-in isa is used.
% 
%   See also isa, u.

tf = false;

switch name
    case 'Length'
        if nnz(v.exponents) == 1 && v.exponents(1) == 1
            tf = true;
        end
    case 'Mass'
        if nnz(v.exponents) == 1 && v.exponents(2) == 1
            tf = true;
        end
    case 'Time'
        if nnz(v.exponents) == 1 && v.exponents(3) == 1
            tf = true;
        end
    case 'Temperature'
        if nnz(v.exponents) == 1 && v.exponents(5) == 1
            tf = true;
        end
    case 'Currency'
        if nnz(v.exponents) == 1 && v.exponents(9) == 1
            tf = true;
        end
    case 'Area'
        if nnz(v.exponents) == 1 && v.exponents(1) == 2
            tf = true;
        end
    case 'Volume'
        if nnz(v.exponents) == 1 && v.exponents(1) == 3
            tf = true;
        end
    case 'Acceleration'
        if nnz(v.exponents) == 2 && isequal(v.exponents(1:3),[1 0 -2])
            tf = true;
        end
    case 'Force'
        if nnz(v.exponents) == 3 && isequal(v.exponents(1:3),[1 1 -2])
            tf = true;
        end
    case 'Energy'
        if nnz(v.exponents) == 3 && isequal(v.exponents(1:3),[2 1 -2])
            tf = true;
        end
    case 'Pressure'
        if nnz(v.exponents) == 3 && isequal(v.exponents(1:3),[-1 1 -2])
            tf = true;
        end
    case 'Power'
        if nnz(v.exponents) == 3 && isequal(v.exponents(1:3),[2 1 -3])
            tf = true;
        end
    case 'Velocity'
        if nnz(v.exponents) == 2 && isequal(v.exponents(1:3),[1 0 -1])
            tf = true;
        end
    % Customized from here on (c) NH, 2019
    case 'Mass/Volume'
        if nnz(v.exponents) == 2 && isequal(v.exponents(1:2),[-3 1])
            tf = true;
        end
    case 'Amount'
        if nnz(v.exponents) == 1 && v.exponents(6) == 1
            tf = true;
        end
    case 'Amount/Volume'
        if nnz(v.exponents) == 2 && v.exponents(1) == -3 && v.exponents(6) == 1
            tf = true;
        end
    case '1/Time'
        if nnz(v.exponents) == 1 && v.exponents(3) == -1
            tf = true;
        end
    case 'Volume/Time'
        if nnz(v.exponents) == 2 && isequal(v.exponents(1:3),[3 0 -1])
            tf = true;
        end
    case 'Mass/Time'
        if nnz(v.exponents) == 2 && isequal(v.exponents(2:3),[1 -1])
            tf = true;
        end
    case 'Amount/Time'
        if nnz(v.exponents) == 2 && v.exponents(3) == -1 && v.exponents(6) == 1
            tf = true;
        end        
    case 'Mass/Amount'
        if nnz(v.exponents) == 2 && v.exponents(2) == 1 && v.exponents(6) == -1
            tf = true;
        end   
    case 'Mass/Area'
        if nnz(v.exponents) == 2 && v.exponents(2) == 1 && v.exponents(1) == -2
            tf = true;
        end   
    otherwise
        tf = isa(v,name);
end