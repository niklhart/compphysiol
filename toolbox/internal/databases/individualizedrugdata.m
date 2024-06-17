function iD = individualizedrugdata(eD, phys, varargin)
%INDIVIDUALIZEDRUGDATA Derive a physiology-specific DrugData object.
%   ID = INDIVIDUALIZEDRUGDATA(ED, PHYS) takes an ExpDrugData object ED and
%   scales experimental data to a target Physiology PHYS, with default
%   options.
%
%   ID = INDIVIDUALIZEDRUGDATA(ED, PHYS, N1, V1, N2, V2, ...) allows to 
%   specify any of the following name-value pairs [values {defaults}]:
%
%   * ReferenceId [char | 'none' | {'auto'}]:
%       Reference physiology for physiological scaling. The default 'auto' 
%       selects a species-specific reference physiology for scaling: 
%       'human35m' for humans, 'rat475' for rats, 'mouse40' for mice.
%   * Duplicates [default | keep | {error}]:
%       Method to handle duplicate entries (only 'error' is implemented so far)
%   * ClParam [{CLuint_exc} | CLuint_cel | CLblo]
%       Clearance parameter to be scaled to (only the default is implemented so far)

    % check input format
    assert(isa(eD,'ExpDrugData'))
    assert(isa(phys,'Physiology'))

    % optional input parsing
    p = inputParser();
    p.addParameter('ReferenceId','auto')  % 'auto', 'none', or e.g. 'human35m'
    p.addParameter('Duplicates','error')  % 'first', 'error', 'default' (?) 
    p.addParameter('ClParam','CLuint_exc') % 'CLuint_exc', 'CLuint_cel' or 'CLblo'
    p.parse(varargin{:});

    opt = p.Results;

    % determine which ExpDrugData are defined
    isDefined = ~structfun(@isempty,eD.db);
    allNames  = fieldnames(eD.db);
    defNames  = allNames(isDefined);

    % copy physiochemical properties, thereby creating DrugData object iD
    iD = copyphyschem(eD);

    % define enriched physiology (possibly via a reference ID) 
    spec = getvalue(phys,'species');
    switch opt.ReferenceId
        case 'auto'
            switch spec
                case 'human'
                    refphys = Physiology('human35m');
                case 'rat'
                    refphys = Physiology('rat475');
                case 'mouse'
                    refphys = Physiology('mouse40');
                otherwise
                    error('Reference ID method "auto" unavailable for species "%s"', spec);
            end
        case 'none'
            refphys = phys;
        otherwise
            refphys = Physiology(opt.ReferenceId);
    end

    % parameter fuP --> carry forward (species-, but not sex-specific)
    transferrecord(eD,iD,'fuP','species',spec)   %TODO: this currently doubles some of the work...
    fuP = getvalue(eD,'fuP','species',spec);     %TODO: discuss if this should be sex-specific?
    
    % parameter BP given --> derive K_ery_up
    [BP, cond_BP] = getvalue(eD,'BP','species',spec);
    hctBP = getcondition(cond_BP, 'hct');
    if isempty(hctBP)
        sexBP = getcondition(cond_BP, 'sex');
        if isempty(sexBP)
            sexBP = getvalue(refphys, 'sex');
        end
        hctBP = getrefhct(sexBP);
    end
    Kery = bp2kery(BP, hctBP, fuP);

    addrecord(iD,'K_ery_up',spec,Kery,[],'Derived from BP data')

    % Kery --> target BP
    hctTarg = getvalue(refphys,'hct');
    BPtarg =  kery2bp(Kery, hctTarg, fuP);
    addrecord(iD,'BP',spec,BPtarg,[],'Derived from invariant K_ery_up')

    % parameter CLblo_perBW --> scale via CLint/OWtis(liv)
    if ismember('CLblo_perBW',defNames)

        % For now, only Duplicates = "Error" is handled correctly -- for 
        % the other options, 'getvalue' has to be adapted. Also, we 
        % automatically filter by species.
        [CLblo_perBW, cond_CLblo_perBW] = getvalue(eD,'CLblo_perBW','species',spec);


        % if sex is defined for CLblo, take a sex-specific hct value;
        % otherwise use the one from the reference physiology
        sexCL = getcondition(cond_CLblo_perBW,'sex');
        if isempty(sexCL) || ~strcmp(spec,'human') || strcmp(sexCL,getvalue(refphys,'sex'))
            hctCL = getvalue(refphys,'hct');
        else
            hctCL = getrefhct(sexCL);
        end
        BP_CL = kery2bp(Kery, hctCL, fuP);


        % if BW is available in ExpConditions, use it. Otherwise, use a
        % species-specific default.
        expBW = getcondition(cond_CLblo_perBW, 'BW');
        if isempty(expBW)
            expBW = getvalue(refphys,'BW');
        end

        CLblo = CLblo_perBW * expBW;

        % The actual scaling CLblo --> CLuint_exc
        fuB = fuP / BP_CL;
        Qblo_liv = getvalue(refphys,'Qblo','liv');

        CLuint_exc = ( Qblo_liv * CLblo / (Qblo_liv - CLblo) ) / fuB;

        % Derive invariant 'CLuint_exc_perOWliv' and store it in iD.
        CLuint_exc_perOWliv = CLuint_exc / getvalue(refphys,'OWtis','liv');
        addrecord(iD, 'CLint_hep_perOWliv', spec, CLuint_exc_perOWliv, [], 'Derived from CLblo (well-stirred liver model)')

    end

    % parameter lambda_po: carryForward (TODO: do we have any invariant here??)
    if ismember('lambda_po',defNames)

        lambda_po = getvalue(eD,'lambda_po','species',spec);
        addrecord(iD,'lambda_po', spec, lambda_po, [], 'Copied from experimental data.') %TODO: copy source/assumptions, too!
    end

    % parameters Egut/Efeces default to 0
    if hasrecord(eD, 'Egut', 'species', spec)
        transferrecord(eD, iD, 'Egut', 'species', spec)
    else
        addrecord(iD, 'Egut', spec, 0, [], 'Assumed Egut=0')
    end
    if hasrecord(eD, 'Efeces', 'species', spec)
        transferrecord(eD, iD, 'Efeces', 'species', spec)
    else
        addrecord(iD, 'Efeces', spec, 0, [], 'Assumed Efeces=0')
    end

    % parameters Freabs, cellPerm,  --> ?  (TODO)


end

%% Local functions

% Conversion BP <--> Kery
function Kery = bp2kery(BP, hct, fuP)

    Kery = (BP - (1-hct))/(fuP*hct);
    Kery = round(Kery,12);
end

function BP = kery2bp(Kery, hct, fuP)

    BP = Kery*fuP*hct + 1 - hct;

end

function hct = getrefhct(sex)
    % TODO: hard-coded, maybe change this
    if strcmp(sex,'male')
        hct = 0.43396;          
    else  % 'female' or 'unisex'
        hct = 0.38462;
    end
end