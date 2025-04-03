%COCKCROFTGAULT Cockcroft-Gault formula to predict GFR in humans
%   POUT = COCKCROFTGAULT(PIN, SERUMCREATININE), with a Physiology object
%   PIN (representing a human, with age, body weight and sex defined) and a
%   Mass/Volume DimVar serumCreatinine (measured serum creatinine 
%   concentration), computes GFR according to the Cockcroft-Gault formula
%   and appends the calculated GFR to the outputted Physiology POUT.
%   
%   POUT = COCKCROFTGAULT(PIN, SERUMCREATININE, SIZEDESCRIPTOR)
%   additionally specifies the body size descriptor to use ('BW' for total 
%   body weight, 'LBW' for lean body weight, or 'ABW' for adjusted body
%   weight). The default is 'ABW'.
%
%   Example:
%       phys  = Covariates('species','human','sex','male','BW',70*u.kg,...
%                           'BH',1.8*u.m,'age',30*u.y);
%       sCrea = 1*u.mg/u.dL;                % healthy adult serum creatinine
%       phys  = cockcroftgault(phys, sCrea)
%   
%   See also Physiology, Covariates

function gfrphys = cockcroftgault(phys, serumCreatinine, sizeDescriptor)

    arguments 
        phys (1,1) Physiology
        serumCreatinine (1,1) DimVar {mustBeUnitType(serumCreatinine,'Mass/Volume')}
        sizeDescriptor (1,:) char {mustBeMember(sizeDescriptor,{'BW','LBW','ABW'})} = 'ABW'
    end

    % check required properties in Physiology object
    required = {'species','sex','age','BW'};

    if any(cellfun(@(c) isempty(phys.db.(c)), required),'all')
        missing = required(cellfun(@(c) isempty(phys.db.(c)), required));
        error(['Required physiological properties "' strjoin(missing,',') '" missing.']) 
    end    

    assert(strcmp(getvalue(phys,'species'),'human'), ...
        'Cockcroft-Gault method only defined for human physiologies.')

    % access the physiology database
    age = getvalue(phys,'age');
    BW  = getvalue(phys,'BW');
    sex = validatestring(getvalue(phys,'sex'), {'male','female'});

    % choose size descriptor
    switch sizeDescriptor
        case 'BW'
            BSD = BW;
        case 'LBW'
            assert(hasrecord(phys,'BH'), ...
                'Body height required for size descriptor LBW.')
            BH  = getvalue(phys,'BH');
            BSD = ffm(BW,BH,sex);

        case 'ABW'

            assert(hasrecord(phys,'BH'), ...
                'Body height required for size descriptor ABW.')
            BH  = getvalue(phys,'BH');

            IBWintercept = (50+(45.5-50)*strcmp(sex,'female'))*u.kg;
            IBW     = IBWintercept + 0.9055*u.kg/u.cm*(BH - 152.4*u.cm);
            BSD     = IBW + 0.4*(BW-IBW);
    end

    % the actual computation
    sexFactor = 1-0.15*strcmp(sex,'female');   % GFR 15% lower for female
    const = 72*u.y*u.kg*u.min*u.dL/(u.mg*u.mL);
    GFR = (140*u.y - age) * BSD * sexFactor / (const*serumCreatinine); 
    GFR = scd(GFR,'mL/min');

    % create a new Physiology object
    gfrphys = copy(phys);
    assum = sprintf('Computed by Cockcroft-Gault fomula (%s)', sizeDescriptor);
    addrecord(gfrphys,'GFR',GFR,'',assum)

end
