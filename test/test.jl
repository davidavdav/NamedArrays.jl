## test.jl
## (c) 2013--2016 David A. van Leeuwen

## various tests for NamedArrays

## This code is licensed under the MIT license
## See the file LICENSE.md in this distribution

## NamedArrays is loaded by runtests.jl

print("Starting test, no assertions should fail... ")

include("bugs.jl")

include("base.jl")

include("constructors.jl")

include("arithmetic.jl")

include("convert.jl")

include("index.jl")

include("names.jl")

include("keepnames.jl")

print("copy, ")
## copy
m = copy(n)
@test m == n
copyto!(m, n)
@test m == n
m = deepcopy(n)
@test m == n

print("sum, ")
## sum
@test sum(n) == sum(n.array)
@test sum(n, dims=1).array == sum(n.array, dims=1)
@test sum(n, dims=2).array == sum(n.array, dims=2)
@test names(sum(n, dims=2), 1) == ["one", "two"]

println("conversions")
## conversion
@test convert(Array, n) == n.array
@test map(Float32, n).array == map(Float32, n.array)

println("changing names: ")
## changingnames
for  f = (:sum, :prod, :maximum, :minimum, :mean, :std, :var)
    println("    ", f)
    for dim in 1:2
        @eval @test ($f)(n.array, dims=$dim) == ($f)(n, dims=$dim).array
        @eval @inferred ($f)(n, dims=$dim)
    end
end

for f in (:cumprod, :cumsum)
    for dim in 1:2
        @eval @test ($f)(n.array, dims=$dim) == ($f)(n, dims=$dim).array
        @eval @inferred ($f)(n, dims=$dim)
    end
end

# NOTE: KahanSummation do not support Julia 0.7 dims keyword argument at the moment
@test cumsum_kbn(n.array, 1) == cumsum_kbn(n, 1).array
@test cumsum_kbn(n.array, 2) == cumsum_kbn(n, 2).array
@inferred cumsum_kbn(n, 1)
@inferred cumsum_kbn(n, 2)

print("multi-dimensional, ")
#multidimensional
m = NamedArray(rand(2,3,4,3,2,3))
for i1 in 1:2, i2 in 1:3, i3 in 1:4, i4 in 1:3, i5 in 1:2, i6 in 1:3
    @test m[i1,i2,i3,i4,i5,i6] == m.array[i1,i2,i3,i4,i5,i6]
    @test m[string(i1), string(i2), string(i3), string(i4), string(i5), string(i6)] == m.array[i1,i2,i3,i4,i5,i6]
end
m[1, :, 2, :, 2, 3].array == m.array[1, :, 2, :, 2, 3]
i = [3 2 4; 1 4 2]
@test n[:, i].array == n.array[:, i]
@test names(n[:, i], 1) == names(n, 1)
@test names(n[:, i], 2) == map(string, 1:2)
@test names(n[:, i], 3) == map(string, 1:3)

print("dodgy indices, ")
## weird indices
m = NamedArray(rand(4), ([1//1, 1//2, 1//3, 1//4],), ("rational",))
@test m[1//2] == m.array[2]
@test m[[1//4,1//3]] == m.array[[4,3]]
m[1//4] = 1
@test m[4] == 1

m = NamedArray(rand(4), ([4, 3, 2, 1],), ("reverse confusion",))
@test m[1] == m.array[1] ## Integer precedence
@test m[Name(1)] == m.array[4] ## but Name() indicates names
## this goes wrong for julia-v0.3
@test m[[4,3,2,1]].array == m.array[[4, 3, 2, 1]]
@test m[Name.([4, 3, 2, 1])].array == m

print("sort, ")
m = NamedArray(rand(100))
for rev in [false, true]
    ms = sort(m, rev=rev)
    @test ms.array == sort(m.array, rev=rev)
    @test names(ms, 1) == names(m, 1)[sortperm(m.array, rev=rev)]
end
m = NamedArray(rand(10,10))
for rev in [false, true]
    for dim in 1:2
        ms = sort(m, dims=dim, rev=rev)
        @test ms.array == sort(m.array, dims=dim, rev=rev)
        @test names(ms, dim) == [string(i) for i in 1:size(ms, dim)]
    end
end

print("broadcast, ")
@test broadcast(-, n, mean(n, dims=1)).array == broadcast(-, n.array, mean(n.array, dims=1))

print("vectorized, ")

## a selection of vectorized functions
for f in  (:sin, :cos, :tan,  :sinpi, :cospi, :sinh, :cosh, :tanh, :asin, :acos, :atan,
           :sinc, :cosc, :deg2rad, :log, :log2, :log10, :log1p, :exp, :exp2, :exp10,
           :expm1, :abs, :abs2, :sign, :sqrt)
    @eval begin
        m = ($f).(n)
        @test m.array == ($f).(n.array)
        @test namesanddim(m) == namesanddim(n)
    end
end

include("rearrange.jl")

print("eachindex, ")
## eachindex
for I in eachindex(n)
    @test n[I] == n.array[I]
end

include("matrixops.jl")

include("show.jl")

include("speed.jl")

# julia issue #17328
a = NamedArray([1.0, 2.0, 3.0, 4.0])
@test sum(abs, a, dims=1)[1] == 10

println("done!")
