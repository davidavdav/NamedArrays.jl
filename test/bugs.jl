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

@testset "issue 140" begin
    substrings = split("a b c", " ")
    letters = ["a", "b", "c"]
    n1 = NamedArray(randn(2, 3), (letters[1:2], letters))
    n2 = NamedArray(randn(2, 3), (substrings[1:2], substrings))
    for i in 1:2, j in 1:3
        @test n1[substrings[i], substrings[j]] == n1[i, j]
        @test n2[letters[i], letters[j]] == n2[i, j]
    end
end

@testset "issue 89" begin
    v = NamedArray(randn(10), (letters[1:10], ))
    a = copy(v.array)
    ## array
    deleteat!(v, ["e", "g"])
    @test v["a"] == a[1]
    @test v["f"] == a[6]
    @test v["j"] == a[10]

    ## element
    deleteat!(v, "a")
    @test v["h"] == a[8]
    @test length(v) == 7
    @test_throws KeyError v["a"]

    ## tuple
    deleteat!(v, ("b", "h"))
    @test v["i"] == a[9]
    @test v.dicts[1] == Dict("c" => 1, "d" => 2, "f" => 3, "i" => 4, "j" => 5)
end

@testset "issue #130" begin
    n = NamedArray([1 2; 3 4], (["a", "b"], ["one", "two"]), ("A", "B"))
    @test names(n, "A") == ["a", "b"]
    @test names(n, "B") == ["one", "two"]
    @test_throws KeyError names(n, "C")
end

@testset "issue #133" begin
    mutable struct NamedArrayHolder
        named_array::NamedArray
    end

    mutable struct NamedVectorHolder
        named_vector::NamedVector
    end

    na = NamedArray([1, 2, 3], names=(["x", "y", "z"],))
    nb = NamedArray([10, 20, 30], names=(["x", "y", "z"],))

    nah = NamedArrayHolder(na)
    nah.named_array = nb
    @test nah.named_array === nb

    nvh = NamedVectorHolder(na)
    nvh.named_vector = nb
    @test nvh.named_vector === nb
end

@testset "issue #129" begin
    n = NamedArray([1 2; 3 4], ([:a, :b], [:c, :d]))
    @test n[1:end] == n.array[1:end]
end