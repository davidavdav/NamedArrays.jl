## NamedArrays is loaded by runtests.jl
using Base.Test
using DataStructures
using Compat

print("Starting test, no assertions should fail... ")

print("arithmetic, ")
include("arithmetic.jl")

print("convert, ")
include("convert.jl")

print("construction, ")
## constructors
n1 = NamedArray(Complex64, 5, 8)
n2 = NamedArray(rand(2,3), (["s", "t"],[:a, :b, :c]), ("string", :symbol))
n = NamedArray(rand(2,4))
setnames!(n, ["one", "two"], 1)
setnames!(n, ["a", "b", "c", "d"], 2)

a = [1 2 3; 4 5 6]
n3 = NamedArray(a, (["a","b"],["C","D","E"]))
n4 = NamedArray(a, (@compat OrderedDict("a"=>1,"b"=>2), @compat OrderedDict("C"=>1,"D"=>2,"E"=>3)))

@test n3.array == n4.array == a
@test dimnames(n3) == dimnames(n4) == Any[:A,:B]
@test names(n3,1) == names(n4,1) == ["a","b"]
@test names(n3,2) == names(n4,2) == ["C","D","E"]

## 0-dim case #21
if VERSION ≥ v"0.4-dev"
    n0 = NamedArray(Array{Int}())
    @test size(n0) == ()
    @test n0[1] == n0.array[1]
end

print("getindex, ")
## getindex
@test [x for x in n] == [x for x in n.array]
@test n[2,4] == n.array[2,4]
if VERSION < v"0.4-dev"
    @test n[2//1,4.0] == n.array[2,4]
end
## more indexing
first = n.array[1,:]
@test convert(Array, n["one", :]) == first
@test n[Not("two"), :].array == n.array[1:1,:]
@test convert(Array, n[1, 2:3]) == n.array[1,2:3]
if VERSION < v"0.5.0-dev"
    @test names(n["one", :],1) == ["one"]
end
@test names(n[Not("one"), :],1) == ["two"]
@test names(n[1:1, Not("a")], 2) == ["b", "c", "d"]
## indexing by pair
@test n[:B=>"a", :A=>"two"] == n.array[2, 1]
@test n[:A=>"one", :B=>"d"] == n.array[1, 4]
## https://github.com/nalimilan/FreqTables.jl/issues/10
bi = [false, true, false, true] ## Array{Bool}
for i in 1:2
    @test n[:, bi].array == n.array[:, bi]
    @test names(n[:, bi], 2) == ["b", "d"]
    bi = BitArray(bi)
end

print("copy, ")
## copy
m = copy(n)
@test m == n

print("setindex, ")
## setindex
m[1,1] = 0
m[2,:] = 1:4
m[:,"c"] = -1
m[1,[2,3]] = [10,20]
if VERSION < v"0.4-dev"
    m["one", 4//1] = 5
else
    m["one", 4] = 5
end
@test m.array == [0. 10 20 5; 1 2 -1 4]
if VERSION >= v"0.4.0-dev"
    m2 = copy(m)
    for i in eachindex(m)
        m[i] = 2*m[i]
    end
    @test 2*(m2.array) == m.array
end
m[:B=>"c", :A=>"one"] = π
@test m[1,3] == Float64(π)

print("sum, ")
## sum
@test sum(n) == sum(n.array)
@test sum(n, 1).array == sum(n.array, 1)
@test sum(n, 2).array == sum(n.array, 2)
@test names(sum(n, 2),1) == ["one", "two"]

print("conversions, ")
## conversion
@test convert(Array, n) == n.array
@test @compat map(Float32, n).array == @compat map(Float32, n.array)

print("changing names, ")
## changingnames
for  f = (:sum, :prod, :maximum, :minimum, :mean, :std, :var)
    for dim=1:2
        @eval @test ($f)(n,$dim).array == ($f)(n.array,$dim)
    end
end

for f in (:cumprod, :cumsum, :cumsum_kbn, :cummin, :cummax)
    for dim=1:2
        @eval @test ($f)(n,$dim).array == ($f)(n.array,$dim)
    end
end

print("multi-dimensional, ")
#multidimensional
m = NamedArray(rand(2,3,4,3,2,3))
for i1=1:2 for i2=1:3 for i3=1:4 for i4=1:3 for i5=1:2 for i6=1:3
    @test m[i1,i2,i3,i4,i5,i6] == m.array[i1,i2,i3,i4,i5,i6]
    @test m[string(i1), string(i2), string(i3), string(i4), string(i5), string(i6)] == m.array[i1,i2,i3,i4,i5,i6]
end end end end end end

print("dodgy indices, ")
## weird indices
m = NamedArray(rand(4), ([1//1, 1//2, 1//3, 1//4],), ("weird",))
@test m[1//2] == m.array[2]
@test m[[1//4,1//3]] == m.array[[4,3]]
m[1//4] = 1
@test m[4] == 1

m = NamedArray(rand(4), ([4, 3, 2, 1],), ("reverse confusion",))
@test m[1] == m.array[4]
## this goes wrong for julia-v0.3
## @test array(m[[4,3,2,1]]) == m.array
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
        ms = sort(m, dim, rev=rev)
        @test ms.array == sort(m.array, dim, rev=rev)
        @test names(ms, dim) == [string(i) for i in 1:size(ms, dim)]
    end
end

print("hcat, ")
letters = [string(@compat Char(96+i)) for i=1:26]
m = NamedArray(rand(10), (letters[1:10],))
m2 = NamedArray(rand(10), (letters[1:10],))
mm = hcat(m, m2)
@test mm.array == hcat(m.array, m2.array)
@test names(mm,1) == names(m,1)

print("broadcast, ")
@test broadcast(-, n, mean(n,1)).array == broadcast(-, n.array, mean(n.array,1))

print("vectorized, ")
## a selection of vectorized functions
for f in  (:sin, :cos, :tan,  :sinpi, :cospi, :sinh, :cosh, :tanh, :asin, :acos, :atan, :sinc, :cosc, :deg2rad, :log, :log2, :log10, :log1p, :exp, :exp2, :exp10, :expm1, :abs, :abs2, :sign, :sqrt,  :erf, :erfc, :erfcx, :erfi, :dawson, :erfinv, :erfcinv, :gamma, :lgamma, :digamma, :invdigamma, :trigamma, :besselj0, :besselj1, :bessely0, :bessely1, :eta, :zeta)
    @eval @test ($f)(n).array == ($f)(n.array)
end

print("matmul, ")
## matmul
for m in (NamedArray(rand(4)), NamedArray(rand(4,3)))
    m * m'
    m' * m
    @test n * m == n * m.array == n.array * m == n.array * m.array
    ## the first expression dispatches Ac_mul_Bc!:
    @test isapprox(m' * n.array', m' * n')
    @test isapprox(m' * n', m.array' * n')
    @test isapprox(m.array' * n', m.array' * n.array')
end

print("re-arrange, ")
## rearranging
@test n'.array == n.array'
for dim=1:2
    @test flipdim(n,dim).array == flipdim(n.array,dim)
    @test names(flipdim(n,dim),dim) == reverse(names(n,dim))
end

p = randperm(ndims(n))
@test permutedims(n, p).array == permutedims(n.array, p)

v = NamedArray(rand(10))
p = rand(1:factorial(length(v)))
@test nthperm(v,p).array == nthperm(v.array, p)
@test names(nthperm(v,p),1) == nthperm(names(v,1), p)
vv = copy(v)
nthperm!(vv, p)
@test vv == nthperm(v, p)

p = randperm(length(v))
vv = copy(v)
permute!(vv, p)
a = copy(v.array)
nm = copy(names(v,1))
permute!(a, p)
permute!(nm, p)
@test vv.array == a
@test names(vv,1) == nm
ipermute!(vv, p)
@test vv == v

vv = shuffle(v)
shuffle!(vv)
@test reverse(v).array == reverse(v.array)
@test names(reverse(v),1) == reverse(names(v,1))
vv = copy(v)
reverse!(vv)
@test vv == reverse(v)

if VERSION >= v"0.4.0-dev"
    print("eachindex, ")
    ## eachindex
    for i in eachindex(n)
        @test n[i] == n.array[i]
    end
end

include("matrixops.jl")

println("show")
if VERSION >= v"0.4.0-dev"
    println(NamedArray(Array{Int}()))
end
println(NamedArray([]))
println(n)
zo = [0,1]
println(NamedArray(rand(2,2,2), (zo, zo, zo), ("base", "zero", "indexing")))
for ndim in 1:5
    println(NamedArray(rand(fill(2,ndim)...)))
end
## various singletons
println(NamedArray(rand(1,2,2)))
println(NamedArray(rand(2,1,2)))
println(NamedArray(rand(2,2,1)))

println("done!")

## how are we doing for speed?
function sgetindex(x, r1=1:size(x,1), r2=1:size(x,2))
    a::Float64 = 0
    for j=r2
        for i=r1
            a = x[i,j]
        end
    end
end

n = NamedArray(rand(1000,1000))
t1 = t2 = t3 = 0.0
for j = 1:2
    t1 = @elapsed sgetindex(n)
    t2 = @elapsed sgetindex(n.array)
    si, sj = allnames(n)
    t3 = @elapsed sgetindex(n, si, sj)
end
println("Timing named index: ", t1, ", array index: ", t2, ", named key: ", t3)

s = sparse(rand(1:1000, 10), rand(1:1000, 10), true)
n = NamedArray(s)
for j = 1:2
    t1 = @elapsed for i=1:1000 sum(s, 1) end
    t2 = @elapsed for i=1:1000 sum(n, 1) end
end
println("Timing sum large sparse array: ", t1, ", named: ", t2)
