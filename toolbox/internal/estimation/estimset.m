%ESTIMSET Set options for estimation
%   Options are specified as name-value pairs; output is a struct. The
%   following options are implemented:
%   
%   fixed (cellstr)    Names of parameters not to be estimated, default: {}
%   parscale (numeric) 
%   ... to be extended

function opt = estimset(varargin)

    p = inputParser;
    
    p.addParameter('fixed',            {}, @iscellstr);
    p.addParameter('parscale',         [], @isnumeric);
    p.addParameter('relboundexpand', 1e-5, @isnumeric);
    
    p.parse(varargin{:});

    opt = p.Results;
    
end
