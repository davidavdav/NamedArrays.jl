include("init-namedarrays.jl")

print("re-arrange, ")

## ctranspose
@test n'.array == n.array'
@test allnames(n') == reverse(allnames(n))
@test dimnames(n') == reverse(dimnames(n))

@test v'.array == v.array'
@test names(v', 2) == names(v, 1)
@test dimnames(v')[2] == dimnames(v)[1]

for d in 1:2
	o = 3 - d ## other dim
	@test flipdim(n, d).array == flipdim(n.array, d)
	@test names(flipdim(n, d), d) == reverse(names(n, d))
	@test names(flipdim(n, d), o) == names(n, o)
end

for i in 1:10
	p = randperm(6)
	@test permutedims(m, p).array == permutedims(m.array, p)
	@test allnames(permutedims(m, p)) == allnames(m)[p]
	@test dimnames(permutedims(m, p)) == dimnames(m)[p]
end
@test transpose(n) == permutedims(n, [2,1])

@test vec(n) == vec(n.array)

@test rotl90(n).array == rotl90(n.array)
@test names(rotl90(n), 1) == reverse(names(n, 2))
@test names(rotl90(n), 2) == names(n, 1)
@test dimnames(rotl90(n)) == reverse(dimnames(n))

@test rotr90(n).array == rotr90(n.array)
@test names(rotr90(n), 2) == reverse(names(n, 1))
@test names(rotr90(n), 1) == names(n, 2)
@test dimnames(rotr90(n)) == reverse(dimnames(n))

@test rot180(n).array == rot180(n.array)
@test allnames(rot180(n)) == [reverse(name) for name in allnames(n)]
@test dimnames(rot180(n)) == dimnames(n)

for i in 1:10
	p = rand(1:factorial(length(v)))
	@test nthperm(v, p).array == nthperm(v.array, p)
	@test names(nthperm(v, p), 1) == nthperm(names(v, 1), p)
end
