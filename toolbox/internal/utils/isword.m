%ISWORD True for character arrays or scalar strings.
function TF = isword(x)
	TF = ischar(x) || (isstring(x) && isscalar(x));
end

