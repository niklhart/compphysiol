%MERGESTRUCTS Merge fields of two scalar structures
%   INTO = MERGESTRUCTS(INTO, FROM) merges fields of a scalar structure FROM
%   into the fields of scalar structure INTO. If a field is defined in INTO
%   but not in FROM, it is untouched, otherwise the value in FROM is taken.

function into = mergestructs(into, from)
    validateattributes(from, {'struct'}, {'scalar'});
	validateattributes(into, {'struct'}, {'scalar'});
	fns = fieldnames(from);
	for fn = fns.'
         into.(fn{1}) = from.(fn{1});
	end
end