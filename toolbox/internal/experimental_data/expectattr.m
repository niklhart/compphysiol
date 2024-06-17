function [allAttr, mandatoryAttr] = expectattr(categ)
%EXPECTATTR Expected attribute scope
%   [ALL,REQ] = EXPECTATTR(CATEG) returns a cellstr ALL of valid attributes
%   and a cellstr REQ of mandatory attributes for event category CATEG.

    switch categ
        case 'Record'
            obs = obstemplate('ExpData');
            allAttr = [{'Time';'Value';'[Time]';'[Value]'}; obs(:,1)];
            mandatoryAttr = [{'Time'}; {'Value'}];
        case {'Bolus dosing','Oral dosing','Infusion dosing'}
            subcat = strip(lower(replace(categ,'dosing','')));
            switch subcat
                case 'bolus'
                    d = Bolus;
                    props = d.schedule.Properties.VariableNames';
                    allAttr = union(props,{'[Time]','[Dose]'});
                    mandatoryAttr = props;
                case 'oral'
                    d = Oral;
                    props = d.schedule.Properties.VariableNames';
                    allAttr       = union(props,{'[Time]','[Dose]'});
                    mandatoryAttr = setdiff(props,{'Formulation'});
                case 'infusion'
                    d = Infusion;
                    props = d.schedule.Properties.VariableNames';
                    allAttr = union(props,{'[Tstart]','[Dose]','[Duration]'});
                    mandatoryAttr = setdiff(props,{'Tstop','Rate'});
            end
        case 'Covariate'
            allAttr = {'Name';'Value';'[Value]'};                
            mandatoryAttr = {'Name';'Value'};
        otherwise
            error('Unknown event category "%s".',categ)
    end

end