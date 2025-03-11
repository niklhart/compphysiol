function percentiles = coverage2percentile(coverage)
%COVERAGE2PERCENTILE Convert coverage probabilities to percentiles

    arguments
        coverage (1,:) double {mustBeInRange(coverage,0,100)}
    end

    percentiles = 50 + [-sort(coverage,'descend') 0 sort(coverage,'ascend')]/2;

end