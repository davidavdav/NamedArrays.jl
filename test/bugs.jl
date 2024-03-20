##!/usr/bin/env julia

## Various issues

include("init-namedarrays.jl")

@testset "Issue #60: $func" for func in
    [
        similar,
        a -> fill!(similar(a), zero(eltype(a))),
        a -> fill!(similar(a), one(eltype(a))),
        n -> hcat(n, n),
        n -> vcat(n, n)
    ]
    fn = @inferred func(n)
    @test keytype.(fn.dicts) == (String, String)
end

@testset "issue 61" begin
    d = Dict(v)
    for key in keys(d)
    @test d[key] == v[key]
    end
end

@testset "issue 73" begin
    na = NamedArray([1, 2], ([1, missing],), ("A",))
    let one = na[Name(1)], two = na[Name(missing)]
        @test one == 1
        @test two == 2
    end
end

@testset "issue 39" begin
    include("init-namedarrays.jl")
    v = n[1, :]
    @test sin.(v).array == sin.(v.array)
    @test namesanddim(sin.(v)) == namesanddim(v)
end

@testset "issue 110" begin
    n = NamedArray([1 2; 3 4], ([11,12], [13,14]))
    s = sum(n, dims=1)
    table = n ./ s
    @test namesanddim(table) == namesanddim(n)
end

@testset "issue 105" begin
    a = [10, 20, 30]
    n = NamedArray(a)
    filter!(x -> x > 15, n)
    @test n == a == [20, 30]
    @test names(n, 1) == ["2", "3"]
end

@testset "issue 117" begin
    n = NamedArray(rand(2, 3), ([:a, :b], [:c, :d, :e]), (:A, :B))
    nt = NamedArray(n.array', ([:c, :d, :e], [:a, :b]), (:B, :A))
    for op in [identity, names, dimnames]
        @test op(nt) == op(n') == op(transpose(n)) == op(permutedims(n)) == op(permutedims(n, (2, 1)))
    end
end

@testset "issue 136" begin
    n = NamedArray(randn(2, 3))
    for fun in [var, std]
        for corrected in [false, true]
            @test fun(n, corrected=corrected) == fun(n.array, corrected=corrected)
        end
    end
end