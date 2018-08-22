n = @inferred NamedArray(rand(2,4))
Letters = [string(Char(64+i)) for i in 1:26]
letters = [string(Char(64+32+i)) for i in 1:26]

@inferred setnames!(n, ["one", "two"], 1)
@inferred setnames!(n, letters[1:4], 2)

v = @inferred NamedArray(rand(1:100, 6), (letters[1:6],), (:index,))

m = @inferred NamedArray(rand(2,3,4,3,2,3))

bv = @inferred NamedArray(rand(Bool, 25))
bm = @inferred NamedArray(rand(Bool, 10, 10))

if ! @isdefined namesanddim
	namesanddim(n::NamedArray) = (names(n), dimnames(n))
	namesanddim(n::NamedArray, d::Int) = (names(n, d), dimnames(n, d))
end

if ! @isdefined hasdefaultnames
	hasdefaultnames(n::NamedArray, d) = names(n, d) == map(string, 1:size(n, d))
	hasdefaultnames(n::NamedArray) = all(Bool[hasdefaultnames(n, d) for d in 1:ndims(n)])
end

if ! @isdefined hasdefaultdimnames
	hasdefaultdimnames(n::NamedArray, d) = dimnames(n, d) == Symbol(Letters[d])
	hasdefaultdimnames(n::NamedArray) = all([hasdefaultdimnames(n, d) for d in 1:ndims(n)])
end
