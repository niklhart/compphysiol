function [F,lambda] = gutcat(P)
%GUTCAT Compartmental absorption and transit (CAT) model for the gut.
%   F = GUTCAT(P) calculates absorbed fraction (0-infty) from the
%   permeability P of a drug using the CAT model. The drug is assumed to 
%   be in solution and not subject to gut metabolism.
%   
%   [F,LAMBDA] = GUTCAT(P) additionally returns the fractional absorption 
%   rate as a function LAMBDA. It holds that int_0^infty LAMBDA(t)dt = F.
%   
%   Reference: Yu/Amidon (1999), Int J Pharm 186:119–125.
%
%   Example:
%   
%   [F,lam] = gutcat(1e-6*u.cm/u.sec);
%   F
%   t = (0:0.1:20) * u.h;
%   trapz(t,lam(t)) % approx. equal to F

    typecheck(P,'Velocity')

    %% fraction absorbed (analytical solution)

    n = 7;         % number of compartments in small intestine
    T = 3.32*u.h;  % small intestine transit time
    R = 1.75*u.cm; % radius of small intestine

    ka = 2*P/R;  % absorption rate
    kt = n/T;    % transit rate

    F = 1 - (1+ka/kt).^-n;

    if nargout == 1
        return
    end

    %% absorption rate (numerical solution)

    % stomach
    Tstom = 0.25*u.h;   % stomach transit time
    ks = 1/Tstom;       % not quite clear from the article...

    % ODE problem formulation
    model = struct( ...
        'n', n, ...
        'ks',ks, ...
        'ka',ka, ...
        'kt',kt);
    lambda = @(t) lambdafun(t, model);
    
end

function rate = lambdafun(t, model)

    tsim = unique([0*u.h;t(:)]);
    rhsfun = @catrhs;
    y0 = [1;zeros(model.n+1,1)];
    [~,y] = odeu15s(rhsfun,tsim,y0,model);

    if isscalar(t)
        idx = size(y,1);
    else
        idx = ismember(tsim,t);
    end

    rate = model.ka * sum(y(idx,2:end-1),2);

end

function dydt = catrhs(t,y,model)

    ks = model.ks;
    ka = model.ka;
    kt = model.kt;

    dydt = unitsOf(t)*zerosizeof(y);
    dydt(1) = -ks*y(1);
    dydt(2) =  ks*y(1);
    dydt(3:end) = kt*y(2:end-1);
    dydt(2:end-1) = dydt(2:end-1) - (kt+ka)*y(2:end-1);  % error in Yu/Amidon manuscript (ka term missing)!
end




