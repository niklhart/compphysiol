function C = gettype(v)
% GETTYPE Get unit types of input as a categorical array. 
%   C = GETTYPE(V), with a double, DimVar or HDV V, returns the unit
%   type(s) of V as a categorical array C of the same size as V. 
% 
%   Supported unit types are defined in subfunction compute_ref() and can 
%   be added as desired. Note that for a change to take effect, the 
%   function has to be cleared by typing 'clear gettype' on the console.
%
%   See also istype, DimVar/istype, DimVar, HDV

    persistent valid_expos
    persistent valid_types
    
    v = HDV(v);    
    
    test_expos = v.exponents;
    
    if isempty(valid_expos)
        [valid_expos, valid_types] = compute_ref();
    end
    
    [lia,locb] = ismember(test_expos,valid_expos,'rows');
    
    str = repmat({'<undefined>'},size(lia));
    % TODO: use code below instead when switching to categorical output.
%    str = repmat({''},size(lia));


    str(lia)  = valid_types(locb(lia));

    % 'str' contains one element per HDV exponent array, we now need to 
    % leverage this information using the grouping. For storage efficiency,
    % we use a categorical array

    C = reshape(str(v.grouping),size(v.value));

    % TODO: for now, I don't use the categorical type (code below) because 
    %       Observable() cannot handle it yet. However, support of 
    %       categorical type is on the agenda.

%    C = categorical(v.grouping,1:numel(lia),str);

end

function [expos,types] = compute_ref()

    valid = {
        % Type          %DimVar example   
        'unitless'      1
        'Length'        u.m
        'Mass'          u.kg
        'Time'          u.s
        'Temperature'   u.K
        'Currency'      u.EUR
        'Area'          u.sqm
        'Volume'        u.L
        'Acceleration'  u.g0
        'Force'         u.N
        'Energy'        u.J
        'Pressure'      u.Pa
        'Power'         u.W
        'Velocity'      u.m/u.s
        'Mass/Volume'   u.kg/u.L
        'Amount'        u.mol
        'Amount/Volume' u.mol/u.L
        '1/Time'        u.Hz
        'Volume/Time'   u.L/u.s
        'Mass/Time'     u.kg/u.s
        'Amount/Time'   u.mol/u.s
        'Mass/Amount'   u.kg/u.mol
        'Mass/Area'     u.kg/u.sqm
    };

    types = valid(:,1);    
    expos = cell2mat(cellfun(@(x) subsref(HDV(x),struct('type','.','subs','exponents')),...
                             valid(:,2),...
                             'UniformOutput',false));

end
