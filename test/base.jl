print("base, ")

include("init-namedarrays.jl")

nn = @inferred similar(n)

@test copyto!(nn, 1, n, 1, length(n)) == n
@test copyto!(nn, 1, n.array, 1, length(n)) == n

@test_throws BoundsError copyto!(nn, 1, n.array, 1, length(n)+1)
@test_throws BoundsError copyto!(nn, 0, n.array, 1, length(n))
@test_throws BoundsError copyto!(nn, 2, n.array, 1, length(n))
@test_throws BoundsError copyto!(nn, length(n)+1, n.array, 1, 1)
@test_throws BoundsError copyto!(nn, 1, n.array, 0, length(n))
@test_throws BoundsError copyto!(nn, 1, n.array, length(n)+1, length(n))

nn = @inferred similar(n, Int)
@test namesanddim(nn) == namesanddim(n)
nn = @inferred similar(n, 3, 5)
@test hasdefaultnames(nn)
nn = @inferred similar(n, 2)
@test namesanddim(nn, 1) == namesanddim(n, 1)
nn = @inferred similar(n, 2, 10)
@test namesanddim(nn, 1) == namesanddim(n, 1)
@test hasdefaultnames(nn, 2)
@test hasdefaultdimnames(nn, 2)
nn = @inferred similar(n, 10, 4, 5)
@test namesanddim(nn, 2) == namesanddim(n, 2)
for i in [1,3]
	@test hasdefaultnames(nn, i)
	@test hasdefaultdimnames(nn, i)
end

# `ind2sub(dims, ind)` is deprecated, use `Tuple(CartesianIndices(dims)[ind])` for a
# direct replacement. In many cases, the conversion to `Tuple` is not necessary.
# @test ind2sub(n, 4) == ("two", "b")
# @test_throws BoundsError ind2sub(n, 0)
# @test_throws BoundsError ind2sub(n, 9)

DelimitedFiles.writedlm(stdout, n)
DelimitedFiles.writedlm(stdout, v)

## Issue #60
for func in [similar,
             a -> fill!(similar(a), zero(eltype(a))),
             a -> fill!(similar(a), one(eltype(a))),
             n -> hcat(n, n),
             n -> vcat(n, n)]
    fn = @inferred func(n)
    @test keytype.(fn.dicts) == (String, String)
end

## issue 61
d = Dict(v)
for key in keys(d)
	@test d[key] == v[key]
end
