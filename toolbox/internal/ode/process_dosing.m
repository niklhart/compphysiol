%PROCESS_DOSING Map dosing scheme to a model
%   [TINCR, XINCR] = PROCESS_DOSING(DOSING, ID, X0) takes Dosing object
%   DOSING and extracts properties BOLUS, ORAL, INFUSION (if non-empty).
%   For each of these, the specified dosing target (see Dosing.m) must be
%   specified in index struct ID. No index in ID may exceed numel(X0). The
%   output TINCR is a column vector of dosing events, and XINCR a matrix, 
%   with XINCR(i,:) containing the increments of state variable X at 
%   TINCR(i). Unit consistency of XINCR with X0 is checked.
%
%   See also matchdose, Dosing

function [tincr, Xincr] = process_dosing(dosing, Id, X0)
    
    % some basic assertions
    assert(isscalar(dosing) && isa(dosing,'Dosing'),  'Input #1 must be a scalar Dosing object.')
    assert(isstruct(Id),                              'Input #2 must be struct.')
    assert(isnumeric(X0) && isvector(X0),             'Input #3 must be a numeric vector.')

    % determine type of dosing (none, single drug, or multiple drugs)
    cpds = compounds(dosing);
    
    tincr = [];
    Xincr = [];
    
    if isempty(cpds)
        
        tincr = []*u.s;
        % early return; no dosing
        return
        
    elseif isscalar(cpds) && ~isfield(Id,cpds{1})
        
        % convert short (compound-free) Id notation for single drug to general syntax 
        Id = struct(cpds{1}, Id);
    end
    
    % Cut target level from Id struct (only bolus/infusion type dosing)
    % This simplifies subsequent code, but assumes only a single dosing 
    % target is present per drug and per route of administration
    Id = matchdose(Id, dosing); 
    
    % initialize
    nX = numel(X0);
    X0 = reshape(X0,1,nX);
    
    types = dosingTypes(dosing);

    % loop over compounds
    for i = 1:numel(cpds)            
        for j = 1:numel(types)

            dos = filterDosing(dosing, cpds{i}, types{j});

            if ~isa(dos,'EmptyDosing')

                [t, X] = dosingModelMatcher(dos, Id, X0);
    
                % concatenate with other dosing schemes
                tincr = [tincr; t];
                Xincr = [Xincr; X];
            end
        end
    end
    
    % group dosing at same timepoint (ensures tincr is strictly increasing)  
    [itgrp, tincr] = findgroups(tincr);
    Xincr = splitapply(@(x) sum(x,1), Xincr, itgrp);

end

