classdef Bolus < SimpleDosing
    %BOLUS Class for storing bolus dosing events
    %   See also Dosing, SimpleDosing, ComplexDosing, Oral, Infusion,
    %   Bolus/Bolus (constructor).
    properties
        schedule = emptytable('Compound','Time','Dose','Target');
    end

    methods
        
        function obj = Bolus(compound,time,dose,target)
        %BOLUS Create a dosing object with bolus dosing
        %   OBJ = BOLUS(COMPOUND, TIME, DOSE, TARGET) creates an object of
        %   class Bolus, OBJ, containing information from bolus dosing. The
        %   following input is expected: 
        %   * COMPOUND: a character array (e.g. 'Warfarin') or a cellstr
        %   * TIME:     convertible to a Time-type DimVar, e.g. 0*u.h or '0 h'
        %   * DOSE:     in most cases, a Mass- or Amount-type DimVar, e.g. 
        %               200*u.ug or '200 ug', but units are not checked to allow
        %               for dosing e.g. in [mg/kg]
        %   * TARGET:   a character array (e.g. 'iv') or a cellstr
        %
        %   OBJ = BOLUS(TAB) with a table TAB containing columns 'Compound', 
        %   'Time', 'Dose' and 'Target' as specified above, is an equivalent
        %   way of specifying bolus dosing.
        %
        %   Examples:
        %
        %       Bolus('Warfarin',0*u.h,10*u.mg,'iv')
        %
        %   See also Infusion, Oral, ComplexDosing
        
            switch nargin
                case 0         % pass
                    return
                case 1         % table input
            
                    tab = compound;
                    assert(istable(tab),'Input in single-argument call must be a table.')
                    mandatoryCols = {'Compound','Time','Dose','Target'};
                    mustContainColumns(tab, mandatoryCols);
            
                    % order colums
                    tab = movevars(tab,mandatoryCols,'Before',1);

                    % process [Time] and [Dose] attributes
                    tab = mergeunit(tab, {'Time','Dose'});
            
                    % assign processed values
                    tab.Time     = tounit(tab.Time);
                    tab.Dose     = tounit(tab.Dose);
                    tab.Compound = cellstr(tab.Compound);
                    tab.Target   = cellstr(tab.Target);
            
                case 4            
            
                    %validate input types
                    assert(isvector(time) && isvector(dose))
                    compound = cellstr(compound);
                    target   = cellstr(target);
                    time     = tounit(time);       
                    dose     = tounit(dose);   
            
                    % formatting
                    [Compound, Time, Dose, Target] = uniformize_size(compound(:), time(:), dose(:), target(:));
                    tab = table(Compound, Time, Dose, Target);
    
                otherwise
                    error('Incorrect number of input arguments.')
            end

            % input validated, assigning to 'schedule' property
            obj.schedule = tab;
        
        end

        function obj = set.schedule(obj, tab)
            assert(istable(tab), 'Input must be a table.')
            tabnm   = tab.Properties.VariableNames;
            bolusnm = obj.schedule.Properties.VariableNames;
            assert(issetequal(tabnm,bolusnm), 'Incorrect column names.')            
            if height(tab) > 0
                typecheck(tab.Time,  'Time')   
                assert(iscellstr(tab.Target), 'Target must be a cell array of characters.')
            end   
            obj.schedule = tab;
        end
       
        function out = combine(obj1, obj2)
            %COMBINE Combine two Bolus dosing schedules
            
            assert(isa(obj1,'Bolus') && isa(obj2,'Bolus'))

            out = Bolus();
            bolus12 = [obj1.schedule; obj2.schedule];
            if ~isempty(bolus12)
                bolus12 = sortrows(bolus12, 2);
                bolus12 = groupsummary(bolus12, {'Compound','Time','Target'}, @sum);
                bolus12.GroupCount = [];
                bolus12.Properties.VariableNames{4} = 'Dose';
                bolus12 = bolus12(:,[1 2 4 3]);
                out.schedule = bolus12;
            end      
        end

    end
end