classdef Oral < SimpleDosing
    %ORAL Class for storing oral dosing events
    %   See also Dosing, SimpleDosing, ComplexDosing, Bolus, Infusion,
    %   Oral/Oral (constructor).

    properties
        schedule = emptytable('Compound','Time','Dose','Formulation');
    end

    methods
       
        function obj = Oral(compound, time, dose, formulation) %#ok<INUSD>
            %ORAL Create a dosing object with oral dosing
            %   OBJ = ORAL(COMPOUND, TIME, DOSE) creates an object OBJ of
            %   class Oral representing oral dosing, from the following input:
            %   * COMPOUND: a character array, e.g. 'Warfarin' or a cellstr
            %   * TIME:     convertible to a Time-type DimVar, e.g. 0*u.h or '0 h'
            %   * DOSE:     in most cases, a Mass- or Amount-type DimVar, e.g. 
            %               200*u.ug or '200 ug', but units are not checked to allow
            %               for dosing e.g. in [mg/kg]
            %
            %   OBJ = ORAL(TAB) with a table TAB with columns compound, time and
            %   dose as specified above, is an equivalent way of specifying oral
            %   dosing.
            %   
            %   Examples:
            %
            %       Oral('Warfarin',0*u.h,10*u.mg)
            %
            %   See also Bolus, Infusion, ComplexDosing

            %   D = ORAL(COMPOUND, TIME, DOSE, FORMULATION) additionally 
            %   specifies a formulation (not implemented yet).

            switch nargin 
                case 0      % pass
                    return
                case 1      % treat table input
                    tab = compound;
            
                    mandatoryCols = {'Compound','Time','Dose'};
                    mustContainColumns(tab, mandatoryCols);
            
                    % order colums
                    tab = movevars(tab,mandatoryCols,'Before',1);

                    % process [Time] and [Dose] attributes
                    tab = mergeunit(tab,{'Time','Dose'});
            
                    % convert to DimVar
                    tab.Time = tounit(tab.Time);       
                    tab.Dose = tounit(tab.Dose);  
                    
                    tab.Formulation = repmat({''},height(tab),1);

                case 3       % multi-argument input
       
                    assert(isvector(time) && isvector(dose))
            
                    time = tounit(time);       
                    dose = tounit(dose);   
            
                    compound = cellstr(compound);
            
                    % uniformize argument sizes
                    [Compound, Time, Dose, Formulation] = uniformize_size(compound(:), time(:), dose(:), {''});
            
                    tab = table(Compound, Time, Dose, Formulation);

                case 4                   
                    error('Formulations not implemented yet.')
                otherwise
                    error('Incorrect number of input arguments.')
            end
    
            % input validated, assigning to 'schedule' property
            obj.schedule = tab;

        end

        function obj = set.schedule(obj, tab)
            assert(istable(tab), 'Input must be a table.')
            tabnm  = tab.Properties.VariableNames;
            oralnm = obj.schedule.Properties.VariableNames;

            assert(issetequal(tabnm,oralnm), 'Incorrect column names.')
            if height(tab) > 0
                typecheck(tab.Time,  'Time')
            end
            obj.schedule = tab;
        end

        function out = combine(obj1, obj2)
            %COMBINE Combine two Oral dosing schedules
            
            assert(isa(obj1,'Oral') && isa(obj2,'Oral'), ...
                'Both arguments must belong to class "Oral"');
            
            out = Oral();

            oral12 = [obj1.schedule; obj2.schedule];
            if ~isempty(oral12)
                oral12 = sortrows(oral12, 2);
                oral12 = groupsummary(oral12, {'Compound','Time','Formulation'}, @sum);
                oral12.GroupCount = [];
                oral12.Properties.VariableNames{4} = 'Dose';
                oral12 = oral12(:,[1 2 4 3]);
                out.schedule = oral12;
            end
           
        end

    end
end