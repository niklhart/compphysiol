%UZEROS Initialize dimensioned vector of zeros
%   X = UZEROS(N,M), with integers N and M, returns a N-by-M dimensioned
%   matrix of zeros.
%
%   X = UZEROS(SZ) with N-element vector SZ returns a SZ(1)-by-...-by-SZ(N)
%   dimensioned array X of zeros.
   
function X = uzeros(varargin)


    X = HDV(zeros(varargin{:}));
    
end

