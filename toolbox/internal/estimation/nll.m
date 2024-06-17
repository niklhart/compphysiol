%NLL Negative log-likelihood function (currently least squares functional)
%
%   This function is at present just implemented for a proof-of-concept of
%   parameter estimation; its functionality will be extended and its syntax 
%   will most probably change.
%
%   See also residuals

function val = nll(model, data, par, nmest)
    
    val = 0;
    
    for j = 1:numel(par)
        model.par.(nmest{j}) = par(j);
    end
    
    for i = 1:numel(data)
        residtab = residuals(model, data(i));
        resid    = double(residtab.Residuals);        
        val      = val + resid' * resid;
    end
    
end

