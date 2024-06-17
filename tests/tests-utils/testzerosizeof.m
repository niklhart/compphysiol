%% Correct usage

assert(isequal(zerosizeof([1 2 3]), [0 0 0]))
assert(zerosizeof(3*u.s) == 0*u.s)
assert(isequal(zerosizeof([1 2 3]*u.s), [0 0 0]*u.s))
assert(isequal(zerosizeof(['a','b']), [0 0]))
assert(isequal(zerosizeof({'a','b'}), [0 0]))
