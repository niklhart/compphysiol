%SCALING_LBW Lean body weight-based scaling of physiological parameters.
%   TARGPHYS = SCALING_LBW(ORIGPHYS, TARGCOV), with Physiology objects
%   ORIGPHYS and TARGCOV, scales the detailed physiological properties of 
%   ORIGPHYS to the covariate information in TARGCOV using the scaling
%   approach described in Huisinga et al., CPT:PSP (2012) 1:e4.
%
%   This scaling method is only applicable for humans.
%
%   Physiological parameters required in ORIGPHYS:
%
%       'species','sex','age','BH','BW','BSA','hct','dens','rtpAlb',
%       'rtpLip','pH','fqbloCO','fnliVtis','fnphVtis','faphVtis',
%       'fintVtis','fwecVtis','fwicVtis','fwtotVtis','fregVtbl','fartVtbl',
%       'fvenVtbl','OWtis','Vtbl','fcelVtis','co'.
%
%   Possible physiological parameters in TARGCOV:
%
%       'species','sex','age','BH','BW'.
%
%   If any of these parameters are not specified in TARGCOV, they will be
%   taken from ORIGPHYS instead.
%
%   Output TARGPHYS will have the physiological parameters required in 
%   ORIGPHYS, scaled to TARGCOV.
%   
%   Examples:
%   
%   	origPhys = Physiology('human35m');
%       targCov  = Covariates('Species','human', ...
%                             'sex',    'male', ...
%                             'age',    40*u.y, ...
%                             'BW',     70*u.kg, ...
%                             'BH',     1.70*u.m);
%   	targPhys = scaling_LBW(origPhys, targCov);
%
%   See also scaling_BW, Physiology, Covariates

%   TODO: generalize scaling method to deal with new types of physiological
%         parameters like GFR. The following behaviour is desired:
%         - defined in ORIGPHYS, but not in TARGCOV --> write to TARGPHYS
%         - not defined in ORIGPHYS, but in TARGCOV --> write to TARGPHYS
%         - defined in ORIGPHYS and in TARGCOV --> write from TARGCOV to
%                                                 TARGPHYS with a warning.


function targPhys = scaling_LBW(origPhys, targCov)

    assert(isa(origPhys, 'Physiology') && isscalar(origPhys), ...
        'Input #1 must be a scalar Physiology object.')
    assert(isa(targCov, 'Physiology') && isscalar(targCov), ...
        'Input #2 must be a scalar Physiology object.')

    % check required properties in dborigin
    reqorigin = {'species','sex','age','BH','BW','BSA','hct','dens',...
        'rtpAlb','rtpLip','pH','fqbloCO','fnliVtis','fnphVtis','faphVtis',...
        'fintVtis','fwecVtis','fwicVtis','fwtotVtis','fregVtbl','fartVtbl',...
        'fvenVtbl','OWtis','Vtbl','fcelVtis','co'};
    
    % check required properties in target and those that will be overwritten
    
    reqtarget = {'species','sex','age','BH','BW'};
    overwritten = union(setdiff(reqorigin,reqtarget), ...
        {'LBW','BMI','fowtisBW','ftblBW','OWtbl','Vtot','Vtis','Vvas','Qblo'});
    
    if any(cellfun(@(c) isempty(origPhys.db.(c)), reqorigin),'all')
        missing = reqorigin(cellfun(@(c) isempty(origPhys.db.(c)), reqorigin));
        error(['Required origin properties "' strjoin(missing,',') '" missing.']) 
    end    
    if any(cellfun(@(c) ~isempty(targCov.db.(c)), overwritten),'all')
        toomuch = overwritten(cellfun(@(c) ~isempty(targCov.db.(c)), overwritten));
        warning(['Target properties "' strjoin(toomuch,',') '" will be overwritten during scaling.']) 
    end
        
    % applicability of scaling method
    assert(strcmp(getvalue(origPhys, 'species'),'human') && ...
            (~hasrecord(targCov,'species') || strcmp(getvalue(targCov, 'species'),'human')), ...
        'Lean body weight-based scaling only defined for humans.')
    
    % create new Physiology object to avoid any handle class side effects
    targPhys = Physiology();
    for i = 1:numel(reqtarget)
        if hasrecord(targCov,reqtarget{i})
            clonerecord(targPhys,reqtarget{i},targCov)
        else
            clonerecord(targPhys,reqtarget{i},origPhys)
        end
    end
    targPhys.name = ['scaled from "' origPhys.name '" with "' mfilename '"'];
        
    % warn if trying to extrapolate across age groups, since no age effect
    % is included
    if getvalue(targPhys,'age') ~= getvalue(origPhys,'age')
        warning(['You are interpolating across age groups, ' ...
            'but no age effect is included in LBW-based scaling.'])
    end
    % 1) add covariates from target to dbtarget and make them available
    %    as records
    
    BWorig = getrecord(origPhys,'BW');
    
    BW  = getrecord(targPhys,'BW');
    BH  = getrecord(targPhys,'BH');
    sex = getvalue(targPhys,'sex');
    
    % 2) unchanged physiological parameters
    unchanged = {'hct','dens','rtpAlb','rtpLip','pH','fqbloCO',...
        'fnliVtis','fnphVtis','faphVtis','fintVtis','fcelVtis',...
        'fwtotVtis','fwicVtis','fwecVtis','fregVtbl','fartVtbl','fvenVtbl'};
    
    for prop = unchanged
        prp = prop{1};
        clonerecord(targPhys, prp, origPhys)
    end
        
    % 3) scaled physiological parameters
    
    % abbreviations for getting and setting properties
    getorig = @(varargin) getrecord(origPhys, varargin{:});
    gettarg = @(varargin) getrecord(targPhys, varargin{:});
    addtarg = @(varargin) addrecord(targPhys, varargin{:});
    
    % LBW and adipose tissue
    LBW = ffm(BW, BH, sex);   % Note: LBW approximated by FFM!
    OWadi = BW - LBW;

    addtarg('LBW', LBW)
    addtarg('OWtis', 'adi', OWadi)

    % scaling of skin
    BSA   = bsafun(BW, BH);
    SFski = BSA / getorig('BSA');    
    OWski_orig = getorig('OWtis','ski');
    OWski = SFski * OWski_orig;
    
    addtarg('BSA', BSA)
    addtarg('OWtis','ski',OWski)

    % scaling of brain
    SFbra = 1;
    OWbra_orig = getorig('OWtis', 'bra');
    OWbra = SFbra * OWbra_orig;
    addtarg('OWtis', 'bra', OWbra)
    
    % scaling of other tissues
    OWadi_orig = getorig('OWtis', 'adi');
    BWrest_targ = BW     - OWadi      - OWski      - OWbra;
    BWrest_orig = BWorig - OWadi_orig - OWski_orig - OWbra_orig;
    
    SFtis = BWrest_targ / BWrest_orig;

    % total blood weight / volume
    Vtbl   = SFtis * getorig('Vtbl');
    OWtbl = Vtbl * gettarg('dens','tbl');
    ftblBW = OWtbl / BW;

    addtarg('Vtbl',   Vtbl)
    addtarg('OWtbl',  OWtbl)
    addtarg('ftblBW', ftblBW)
    
    % per-tissue parameters
    tissues = {'lun','adi','bra','hea','kid','mus','bon','ski','gut','spl','liv'};
    rest = setdiff(tissues, {'adi','ski','bra'});

    for i = 1:numel(rest)
        tis = rest{i};

        % tissue organ weights
        OWtis = SFtis * getorig('OWtis', tis);
        
        addtarg('OWtis', tis, OWtis)
    end
    
    % cardiac output
    SFQ = SFtis;
    co = getorig('co') * SFQ;
    
    addtarg('co', co)

    %%% 5) dependent physiological parameters
    
    % derived: BMI
    addtarg('BMI', BW/BH^2)
    
    for i = 1:numel(tissues)
        tis = tissues{i};
        
        OWtis = gettarg('OWtis',tis);
        
        % derived: tissue volumes
        Vtis  = OWtis / gettarg('dens', tis);
        addtarg('Vtis', tis, Vtis)

        % derived: vascular and total volumes
        Vvas = getorig('fregVtbl',tis) * Vtbl;
        Vtot = Vtis + Vvas;
        
        addtarg('Vvas', tis, Vvas)
        addtarg('Vtot', tis, Vtot)
        
        % derived: tissue organ weight fraction of body weight
        fowtisBW = OWtis/BW;
        addtarg('fowtisBW',tis,fowtisBW)
        
        % derived: blood flow
        if ~strcmp(tis,'lun')
            Qblo = gettarg('fqbloCO', tis) * co;
            addtarg('Qblo', tis,  Qblo)
        end
    end
        
end



%%% +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
function out = bsafun(BW,BH)
%%% +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++

% Determine body surface area (BSA) in [m^2]
% Source: Mosteller, New Engl J Med, Vol 317, 1987

    out = sqrt(BH*(BW/(36*u.kg))*u.m^3);

end