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
@test hasdefaultnames(nn)
nn = similar(n, 2)
@test namesanddim(nn, 1) == namesanddim(n, 1)
nn = similar(n, 2, 10)
@test namesanddim(nn, 1) == namesanddim(n, 1)
@test hasdefaultnames(nn, 2)
@test hasdefaultdimnames(nn, 2)
nn = similar(n, 10, 4, 5)
@test namesanddim(nn, 2) == namesanddim(n, 2)
for i in [1,3]
	@test hasdefaultnames(nn, i)
	@test hasdefaultdimnames(nn, i)
end


@test ind2sub(n, 4) == ("two", "b")
@test_throws BoundsError ind2sub(n, 0)
@test_throws BoundsError ind2sub(n, 9)

writedlm(STDOUT, n)
writedlm(STDOUT, v)
