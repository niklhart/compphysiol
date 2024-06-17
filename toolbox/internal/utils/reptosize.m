%REPTOSIZE Replicate to target size cellstr
%   C = REPTOSIZE(S, N), with character array S and positive integer N, 
%   returns the N-by-1 cellstr C = {S;...;S}. If S already is a cellstr, it
%   must be either scalar (then C = [S;...;S]) or N-by-1 (then C = S).

function cllstr = reptosize(cllstr, n)
    if ischar(cllstr)
        cllstr = {cllstr};
    end
    assert(iscell(cllstr), 'Input must be char or cellstr, but is %s.', class(cllstr))
    
    cllstr = cllstr(:);
    
    N = numel(cllstr);
    if N == 1 && n > 1
        cllstr = repmat(cllstr, [n 1]);
    else
        assert(N == n, 'Input must be scalar or length %s, but has %s elements', n, N)
    end

end