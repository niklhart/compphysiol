%HUMANCOVDISTRIB Simulate a covariate distribution in adult humans 
%   HUMANS = HUMANCOVDISTRIB(N, SEX) uses the de la Grandmaison method to
%   create a N-by-1 Physiology array HUMANS of sex SEX, aged 35 years and 
%   with simulated body weight and body height which are correlated as in 
%   real populations. 
%
%   Examples:
%
%       humancovdistrib(5,'female')

function humans = humancovdistrib(N, sex)

    % Assign parameter values for underlying distributions.
    % To generate pairs of (BH,BW) values, independent (BH, BMI) 
    % pairs are first generated, assuming 
    % BH  ~ Normal(muBH,sdBH^2)
    % BMI ~ logNormal(log_muBMI,log_sdBMI^2)
    % These are then used to generate BW from the relation BMI = BW/BH^2

    sex = validatestring(sex, {'male','female'});

    switch sex
        % Ref.: de la Grandmaison et al., Forensic Sci. Int. 119 (2001): 149-154
        case 'male'
            muBH  = 1.72; sdBH  = 0.075;
            muBMI = 22.8; sdBMI = 3.3;
        case 'female'
            muBH  = 1.61; sdBH  = 0.075;
            muBMI = 22.5; sdBMI = 4.5;
    end

    % transforming mu and sd to the scale of the underlying normal distribution
    log_muBMI = log(muBMI^2/sqrt(muBMI^2+sdBMI^2));
    log_sdBMI = sqrt(log(sdBMI^2/muBMI^2+1));

    % generate BH and BMI values
    BH  = (muBH + sdBH*randn(1,N)) * u.m;
    BMI = exp( log_muBMI + log_sdBMI*randn(1,N) ) * (u.kg/u.m^2);

    % determine resulting BW values
    BW  = BMI.*(BH.^2);

    % create the output object
    humans(N) = Physiology();    % not using `humans(1:N) = Physiology()` to avoid handle reference copies
    for i=1:N
        humans(i) = Covariates(...
            'species','human',...
            'type','Caucasian',...
        	'sex',sex,...
            'age',35*u.year,...
            'BW',BW(i),...
        	'BH',BH(i));
    end

end
