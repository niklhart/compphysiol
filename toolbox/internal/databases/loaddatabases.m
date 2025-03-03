%LOADDATABASES Load physiology & (scaled) drug database and indexing struct
%   [QUERYPHYS, QUERYDRUG, I] = LOADDATABASES(PHYS, DRUG, CMT), with a 
%   Physiology object PHYS, a DrugData object DRUG, and a cellstr of
%   compartments CMT with N elements, returns 
%   * a function QUERYPHYS to query PHYS (see below)
%   * a function QUERYDRUG to query DRUG 
%   * an indexing struct I, with fields CMT{1}, ..., CMT{N} and values 
%       1, ..., N, where N is the length of CMT. 
%   
%   QUERYPHYS = LOADDATABASES(PHYS), with a Physiology object PHYS, loads a
%   query function for scalar (tissue-independent) physiological parameters
%   like body weight.
%
%   QUERYPHYS has the following syntax:
%   1) for a tissue-independent parameter NM (e.g.: BW, hct, ...), 
%      QUERYPHYS(NM) simply returns the matching entry.
%   2) for a per-tissue parameter NM (e.g.: Qblo, Vtis, ...), there are
%      two ways to call QUERYPHYS:
%      a) QUERYPHYS(NM, TIS) returns the scalar match for tissue TIS 
%         (regardless of whether this parameter was specified in CMT).
%      b) QUERYPHYS(NM) returns all database matches for CMT. Output is an
%         array, of the same size as CMT, in which a matching entry TIS is 
%         placed into position I.(TIS), and with NaN in any non-matched 
%         position. With this syntax, database entries not part of CMT are 
%         ignored.
%
%   QUERYDRUG has the following syntax:
%   1) QUERYDRUG(CPD, NM) retrieves parameter NM (e.g. MW, fuP, logPow, 
%      ...) corresponding to drug CPD from the DrugData object DRUG.
%   2) If DRUG is scalar (i.e., a single compound CPD is modelled), the call
%      QUERYDRUG(NM) is shorthand for QUERYDRUG(CPD, NM), since no ambiguity 
%      is possible.

function [hphys, hdrug, I] = loaddatabases(varargin)

    % Input processing 
    switch nargin
        case 1
            phys = varargin{1};
            drug = DrugData; % empty DrugData object
            cmt = {};
        case 3            
            phys = varargin{1};
            drug = varargin{2};
            cmt  = varargin{3};
        otherwise
            error('Incorrect number of input arguments.')
    end
    assert(isa(phys,'Physiology'), 'Input #1 must be a Physiology object.')
    assert(isa(drug,'DrugData'),   'Input #2 must be a DrugData object.')
    assert(iscellstr(cmt),         'Input #3 must be cellstr.')

    % Creation of the query functions and indexing struct
    cmt = cmt(:);
    I = initcmtidx(cmt);
    hphys = @(varargin) getfromphys(phys, cmt, varargin{:});
    hdrug = @(varargin) getfromdrug(drug, varargin{:});
end

function out = getfromphys(phys, cmt, nm, varargin)

    nm = validatestring(nm, Physiology.param);

    if ~Physiology.ispertissue(nm) || nargin == 4
        out = getvalue(phys, nm, varargin{:});
    else
        tab = phys.db.(nm);
        assert(~isempty(tab), 'Parameter "%s" missing in Physiology object.', nm)
        [lia,locb] = ismember(cmt, tab.Tissue);  

        out = unan(size(cmt)); % otherwise, subsasgn into double would trigger DimVar conversion to double
        out(lia) = tab.Value(locb(lia));
    end
end

function out = getfromdrug(drug, varargin)
    if isscalar(drug) && ~strcmp(drug.name,varargin{1})
        out = getvalue(drug, varargin{:});
    else
        out = getvalue(drug{varargin{1}}, varargin{2:end});
    end
end

