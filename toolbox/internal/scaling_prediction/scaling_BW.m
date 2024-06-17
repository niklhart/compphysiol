%SCALING_BW Body weight-based scaling of physiological parameters.
%   TARGPHYS = SCALING_BW(ORIGPHYS, TARGCOV), with Physiology objects
%   ORIGPHYS and TARGCOV, scales the detailed physiological properties of 
%   ORIGPHYS to the covariate information in TARGCOV using body weight-based
%   scaling.
%   
%   The scaling method is applicable for all species (not cross-species), 
%   but for humans, method 'scaling_LBW' is recommended.
%
%   Physiological parameters required in ORIGPHYS:
%
%       'species','age','BW','hct','dens','rtpAlb','rtpLip','pH','fqbloCO',
%       'fnliVtis','fnphVtis','faphVtis','fintVtis','fwecVtis','fwicVtis',
%       'fwtotVtis','fregVtbl','fartVtbl','fvenVtbl','OWtis','Vtbl',
%       'fcelVtis','co'.
%
%   Possible physiological parameters in TARGCOV:
%
%       'species','age','BW'.
%
%   If any of these parameters are not specified in TARGCOV, they will be
%   taken from ORIGPHYS instead.
%   
%   Output TARGPHYS will have the physiological parameters required in 
%   ORIGPHYS, scaled to TARGCOV.
%
%   Examples:
%   
%   	origPhys = Physiology('rat250');
%   	targCov  = Covariates('Species','rat', ...
%                             'age',    40*u.week, ...
%                             'BW',     300*u.g);
%   	targPhys = scaling_BW(origPhys, targCov);
%
%   See also scaling_LBW, Physiology, Covariates

% TODO: 
%   1) add a reference for this scaling method.
%   3) handle additional parameters (e.g., 'sex' in TARGCOV), see the TODO
%      in function 'scaling_LBW'.

function targPhys = scaling_BW(origPhys, targCov)

    assert(isa(origPhys, 'Physiology') && isscalar(origPhys), ...
        'Input #1 must be a scalar Physiology object.')
    assert(isa(targCov, 'Physiology') && isscalar(targCov), ...
        'Input #2 must be a scalar Physiology object.')
        
    % check required properties in dborigin
    reqorigin = {'species','age','BW','hct','dens',...
        'rtpAlb','rtpLip','pH','fqbloCO','fnliVtis','fnphVtis','faphVtis',...
        'fintVtis','fwecVtis','fwicVtis','fwtotVtis','fregVtbl','fartVtbl',...
        'fvenVtbl','OWtis','Vtbl','fcelVtis','co'};
    
    % check required properties in dborigin and those that will be
    % overwritten in target
    reqtarget = {'species','age','BW'};
    overwritten = union(setdiff(reqorigin,reqtarget), ...
        {'fowtisBW','ftblBW','OWtbl','Vtot','Vtis','Vvas','Qblo'});
    
    if any(cellfun(@(c) isempty(origPhys.db.(c)), reqorigin),'all')
        missing = reqorigin(cellfun(@(c) isempty(origPhys.db.(c)), reqorigin));
        error(['Required origin properties "' strjoin(missing,',') '" missing.']) 
    end     
    if any(cellfun(@(c) ~isempty(targCov.db.(c)), overwritten),'all')
        toomuch = overwritten(cellfun(@(c) ~isempty(targCov.db.(c)), overwritten));
        warning(['Target properties "' strjoin(toomuch,',') '" will be overwritten during scaling.']) 
    end
        
    % applicability of scaling method
    assert(~hasrecord(targCov,'species') || ...
           strcmp(getvalue(origPhys, 'species'),getvalue(targCov, 'species')), ...
        'Cross-species scaling not allowed.')
    
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

        
    % 1) add covariates from target to dbtarget and make them available
    %    as records
    
    BWorig = getrecord(origPhys,'BW');
    
    BW  = getrecord(targPhys,'BW');    
    
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
    
    % scaling of brain
    SFbra = 1;
    OWbra_orig = getorig('OWtis', 'bra');
    OWbra = SFbra * OWbra_orig;
    addtarg('OWtis', 'bra', OWbra)
    
    % scaling factor for other tissues
    BWrest_targ = BW     - OWbra;
    BWrest_orig = BWorig - OWbra_orig;
    
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
    nobrain = setdiff(tissues, 'bra');

    for i = 1:numel(nobrain)
        tis = nobrain{i};

        % tissue organ weights
        OWtis = SFtis * getorig('OWtis', tis);
        
        addtarg('OWtis', tis, OWtis)
    end
    
    % cardiac output
    SFQ = SFtis;
    co = getorig('co') * SFQ;
    
    addtarg('co', co)

    %%% 5) dependent physiological parameters
        
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
