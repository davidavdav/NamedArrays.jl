print("base, ")

include("init-namedarrays.jl")

nn = similar(n)
@test copy!(nn, 1, n, 1, length(n)) == n
@test copy!(nn, 1, n.array, 1, length(n)) == n

@test_throws BoundsError copy!(nn, 1, n.array, 1, length(n)+1)
@test_throws BoundsError copy!(nn, 0, n.array, 1, length(n))
@test_throws BoundsError copy!(nn, 2, n.array, 1, length(n))
@test_throws BoundsError copy!(nn, length(n)+1, n.array, 1, 1)
@test_throws BoundsError copy!(nn, 1, n.array, 0, length(n))
@test_throws BoundsError copy!(nn, 1, n.array, length(n)+1, length(n))

nn = similar(n, Int)
@test namesanddim(nn) == namesanddim(n)
nn = similar(n, 3, 5)
@test all(Bool[names(nn, d) != names(n, d) for d in 1:ndims(n)]) ## Bool[] for julia-0.4

@test ind2sub(n, 4) == ("two", "b")
@test_throws BoundsError ind2sub(n, 0)
@test_throws BoundsError ind2sub(n, 9)

writedlm(STDOUT, n)
writedlm(STDOUT, v)
