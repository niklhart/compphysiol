%TEST_3CMT_MODEL 3-CMT model with minimal features for testing purposes
function model = test_3cmt_model()

    model = OdeModel(@test_initfun,@test_rhsfun,@test_obsfun);

end

function setup = test_initfun(~,~,~,~)
    tissues = {'pla','liv','mus'};
    setup = struct;
    setup.indexing.I = initcmtidx(tissues);
    setup.indexing.Id.Bolus.iv.cmt     = setup.indexing.I.pla;
    setup.indexing.Id.Bolus.iv.scaling = 1;
    setup.V = [1 2 3]' * u.L;
    setup.K = [1 2 3]';
    setup.Q.liv = 4*u.L/u.h;
    setup.Q.mus = 9*u.L/u.h;
    setup.CL    = u.L/u.h;
    
    % to be used by lump_model 
    setup.cmt     = tissues;
    setup.physIdx = 1:3;
    setup.VK      = setup.V .* setup.K;      

    % initial condition ensures exact lumping of CMT 2&3 is possible
    setup.X0    = [2 4 9]'*u.mg;
end

function dX = test_rhsfun(~,X,setup)

    I  = setup.indexing.I;
    Q  = setup.Q;
    CL = setup.CL;
    V  = setup.V;
    K  = setup.K;    

    % initialize output vector
    X = X(:);
    dX = NaNsizeof(X);

    % amount --> concentration
    C = X ./ V;

    % ODEs (2 peripheral compartments with equal blood flow rate)
    dX(I.liv) = Q.liv * (C(I.pla) - C(I.liv)/K(I.liv));
    dX(I.mus) = Q.mus * (C(I.pla) - C(I.mus)/K(I.mus));
    dX(I.pla) = -dX(I.liv) - dX(I.mus) - CL*C(I.pla);

end

function yobs = test_obsfun(output, setup, obs)

    site = obs.attr.Site;
    if ismember(site,{'pla','liv','mus'})
        yobs = output.X(:,setup.indexing.I.(site));
    else
        yobs = [];
    end

end