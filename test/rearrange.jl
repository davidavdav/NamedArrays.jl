@testset "re-arrange" begin

    include("init-namedarrays.jl")
    @testset "ctranspose" begin
        @test n'.array == n.array'
        @test names(n') == reverse(names(n))
        @test dimnames(n') == reverse(dimnames(n))

        @test v'.array == v.array'
        @test names(v', 2) == names(v, 1)
        @test dimnames(v')[2] == dimnames(v)[1]
    end

    for j in 1:2
        o = 3 - j ## other dim
        @test reverse(n, dims=j).array == reverse(n.array, dims=j)
        @test names(reverse(n, dims=j), j) == reverse(names(n, j))
        @test names(reverse(n, dims=j), o) == names(n, o)
    end

    for _ in 1:10
        p = randperm(6)
        @test permutedims(m, p).array == permutedims(m.array, p)
        @test names(permutedims(m, p)) == names(m)[p]
        @test dimnames(permutedims(m, p)) == dimnames(m)[p]
    end

    @test transpose(n) == permutedims(n, [2, 1])
    @testset "Issue #138" begin
        @test transpose(n).array == transpose(n.array)
        @test parent(transpose(n.array)) === n.array
        @test transpose(v).array == transpose(v.array)
        @test parent(transpose(v.array)) === v.array
    end

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
    @test names(rot180(n)) == [reverse(name) for name in names(n)]
    @test dimnames(rot180(n)) == dimnames(n)

    for shift in (1, [0, 1], [1, 2], (2, 0))
        @test circshift(n, shift).array == circshift(n.array, shift)
        for dim in 1:length(shift)
            @test names(circshift(n, shift), dim) == circshift(names(n, dim), shift[dim])
        end
    end

    for _ in 1:10
        p = rand(1:factorial(length(v)))
        @test nthperm(v, p).array == nthperm(v.array, p)
        @test names(nthperm(v, p), 1) == nthperm(names(v, 1), p)
        v1 = @inferred deepcopy(v)
        a1 = deepcopy(v.array)
        @inferred nthperm!(v1, p)
        nthperm!(a1, p)
        @test v1.array == a1
        perm = nthperm(collect(1:length(v)), p)
        v1 = @inferred deepcopy(v)
        a1 = deepcopy(v.array)
        @inferred permute!(v1, perm)
        permute!(a1, perm)
        name = copy(names(v, 1))
        permute!(name, perm)
        @test v1.array == a1
        @test names(v1, 1) == name
        @inferred invpermute!(v1, perm)
        @test v1.array == v.array
        @test names(v1, 1) == names(v, 1)
        vs = @inferred shuffle(v)
        @test vs[sortperm(names(vs, 1))] == v
        @inferred shuffle!(v1)
        @test v1[sortperm(names(v1, 1))] == v
        start, stop = sort(perm[1:2])
        r = @inferred reverse(v, start, stop)
        @test r.array == reverse(v.array, start, stop)
        @test names(r, 1) == reverse(names(v, 1), start, stop)
        r = @inferred deepcopy(v)
        @inferred reverse!(r, start, stop)
        @test r.array == reverse(v.array, start, stop)
        @test names(r, 1) == reverse(names(v, 1), start, stop)
    end

    @testset "Issue #79" begin
        nn = NamedArray([ 2 1 4; 1 2 3; 2 1 3 ])
        @test names(sortslices(nn, dims=1), 1) == ["2", "3", "1"]
        @test names(sortslices(nn, dims=2), 2) == ["2", "1", "3"]
    end
end
