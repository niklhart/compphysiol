%UNAN Initialize dimensioned vector of NaNs
%   X = UNAN(N,M), with integers N and M, returns a N-by-M dimensioned
%   matrix of NaNs.
%
%   X = UNAN(SZ) with N-element vector SZ returns a SZ(1)-by-...-by-SZ(N)
%   dimensioned array X of NaNs.
   
function X = unan(varargin)

    X = HDV(nan(varargin{:}));
    
end

