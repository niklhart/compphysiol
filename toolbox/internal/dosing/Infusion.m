classdef Infusion < SimpleDosing
    %INFUSION Class for specifying infusion dosing events
    %   See also Dosing, SimpleDosing, ComplexDosing, Bolus, Oral, 
    %   Infusion/Infusion (constructor).


    properties
        schedule = emptytable('Compound','Tstart','Tstop','Dose','Rate','Duration','Target');
    end

    methods

        function obj = Infusion(compound, tstart, dose, dur_or_rate, target)
            %INFUSION Create a dosing object with infusion dosing
            %   OBJ = INFUSION(COMPOUND, TSTART, DOSE, DURATION, TARGET) creates an 
            %   object of class Infusion, OBJ, containing information from infusion
            %   dosing. The following input is expected: 
            %   * COMPOUND  a character array, e.g. 'Warfarin', or a cellstr
            %   * TSTART    start of infusion: convertible to a Time-type DimVar, e.g.
            %               0*u.h or '0 h'
            %   * DOSE      in most cases, a Mass- or Amount-type DimVar, e.g. 
            %               200*u.ug or '200 ug', but units are not checked to allow
            %               for dosing e.g. in [mg/kg]
            %   * DURATION  infusion duration: convertible to a Time-type DimVar, e.g.
            %               1*u.h or '1 h'
            %   * TARGET    a character array, e.g. 'iv', or a cellstr
            %
            %   All inputs must be scalar or vectors of matching sizes 
            %   (exception: COMPOUND, DOSE, DURATION and TARGET may be 
            %   scalar even if the other quantities are vectors, meaning 
            %   repeated dosing of the same COMPOUND / using the same 
            %   DOSE / DURATION / into the same TARGET).
            %
            %   End and rate of the infusion are automatically derived from 
            %   the given information. Alternatively, rate of infusion 
            %   can be specified:
            %   
            %   INFUSION(COMPOUND, TSTART, DOSE, RATE, TARGET)
            %   
            %   where COMPOUND, TSTART, DOSE, TARGET are as above, and with
            %   
            %   * RATE      infusion rate: convertible to a Mass/Time or Amount/Time-
            %               type DimVar, e.g. 100*u.mg/u.h or '100 mg/h'
            %   
            %   Units of input #4 discriminate between the DURATION/RATE
            %   argument.
            %   
            %   DOSINGOBJ = INFUSION(TAB) with a table TAB with columns compound, 
            %   tstart, dose, duration, target with the same meaning as the arguments
            %   described above, is an equivalent way of specifying infusion dosing.
            %
            %   Examples: 
            %   
            %       % Same dosing scheme, specified as duration or rate
            %   
            %       Infusion('drugA',[0 3]*u.h,10*u.mg,1*u.h,'iv')
            %       Infusion('drugA',[0 3]*u.h,10*u.mg,10*u.mg/u.h,'iv')
            %   
            %   See also Bolus, Oral, ComplexDosing

            switch nargin 
                case 0       % early return
                    return
                case 1       % treat table input

                    tab = compound;
                    mandatoryCols = {'Compound','Tstart', 'Dose', 'Duration', 'Target'};
                    mustContainColumns(tab, mandatoryCols);
            
                    % order colums
                    tab = movevars(tab,mandatoryCols,'Before',1);

                    % process unit attributes
                    tab = mergeunit(tab,{'Tstart', 'Dose', 'Duration'});
            
                    compound    = tab.Compound;
                    tstart      = tab.Tstart;
                    dose        = tab.Dose;
                    dur_or_rate = tab.Duration;
                    target      = tab.Target;
            end
            
            tstart = tounit(tstart);        
            assert(isnumvec(tstart))
            tstart = tstart(:);
            Nt = numel(tstart);
        
            dose  = tounit(dose);
            Na = numel(dose);
            assert(any(Na == [1 Nt]))
            dose = repmat(dose(:), Nt/Na, 1);

            % handling duration or rate input
            Ndr = numel(dur_or_rate);
            assert(any(Ndr == [1 Nt]))
            dur_or_rate = tounit(dur_or_rate);
            if istype(dur_or_rate,'Time') 
                % duration specified
                duration = repmat(dur_or_rate(:), Nt/Ndr, 1);
                rate = dose ./ duration;
            elseif istype(dose,'Time')
                % argument switch dose <--> duration
                error('PBPK:Infusion:doseDurationSwitched', ...
                    'Wrong input units. Maybe the order of inputs "dose" and "duration" was switched?')
            else
                dose_per_durorrate = unitsOf(dose)/unitsOf(dur_or_rate);
                if istype(dose_per_durorrate,'1/Time')
                    % argument switch dose <--> rate
                    error('PBPK:Infusion:doseRateSwitched', ...
                        'Wrong input units. Maybe the order of inputs "dose" and "rate" was switched?')
                else
                    % rate specified
                    typecheck(dose_per_durorrate, 'Time');
                    rate = repmat(dur_or_rate(:), Nt/Ndr, 1);
                    duration = dose ./ rate;
                end
            end
            
            tstop = tstart + duration;
                
                            
            % validate compound and target arguments
            if ischar(compound)
                compound = {compound};
            else
                assert(iscellstr(compound), 'Argument "compound" must be char or cellstr.')
            end
            if ischar(target)
                target = {target};
            else
                assert(iscellstr(target), 'Argument "target" must be char or cellstr.')
            end
            
            Ncpd = numel(compound);
            Ntrg = numel(target);
            
            assert(Ncpd == 1 || Ncpd == Nt, 'Sizes of time and compound arguments not matching.')
            assert(Ntrg == 1 || Ntrg == Nt, 'Sizes of time and target arguments not matching.')
        
            compound = repmat(compound, Nt/Ncpd, 1);
            target   = repmat(target,   Nt/Ntrg, 1);
        
            % input validated, assigning to 'schedule' property
            obj.schedule = table(...
                compound, tstart, tstop, dose, rate, duration, target, ...
                'VariableNames', {'Compound', 'Tstart', 'Tstop', 'Dose', ...
                                  'Rate', 'Duration', 'Target'});
        
        end

        function obj = set.schedule(obj, tab)
            assert(istable(tab), 'Input must be a table.')
            tabnm = tab.Properties.VariableNames;
            infusnm = obj.schedule.Properties.VariableNames;
            assert(issetequal(tabnm,infusnm), 'Incorrect column names.')            
            if height(tab) > 0
                typecheck(tab.Tstart,   'Time')   
                typecheck(tab.Tstop,    'Time')   
                typecheck(tab.Rate,    tab.Dose/u.min)
                typecheck(tab.Duration, 'Time')   
                assert(iscellstr(tab.Target), 'Target must be a cell array of characters.')
            end
            obj.schedule = tab;
        end

        function out = combine(obj1, obj2)
            %COMBINE Combine two Infusion dosing schedules
            
            assert(isa(obj1,'Infusion') && isa(obj2,'Infusion'), ...
                'Both arguments must belong to class "Infusion"');
            
            out = Infusion();

            infusion12 = [obj1.schedule; obj2.schedule];
            if ~isempty(infusion12)
                infusion12 = sortrows(infusion12, 2);
                infusion12 = groupsummary(infusion12, {'Compound','Tstart','Tstop','Duration','Target'}, @sum);
                infusion12.GroupCount = [];
                infusion12.Properties.VariableNames{6} = 'Dose';
                infusion12.Properties.VariableNames{7} = 'Rate';
                infusion12 = infusion12(:,[1 2 3 6 7 4 5]);
                out.schedule = infusion12;
            end
           
        end

    end
end