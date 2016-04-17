## NamedArrays is loaded by runtests.jl

print("Starting test, no assertions should fail... ")

print("construction, ")
## constructors
n1 = NamedArray(Complex64, 5, 8)
n2 = NamedArray(rand(2,3), (["s", "t"],[:a, :b, :c]), ("string", :symbol))
n = NamedArray(rand(2,4))
setnames!(n, ["one", "two"], 1)
setnames!(n, ["a", "b", "c", "d"], 2)

a = [1 2 3; 4 5 6]
n3 = NamedArray(a, (["a","b"],["C","D","E"]))
n4 = NamedArray(a, (@compat Dict("a"=>1,"b"=>2),@compat Dict("C"=>1,"D"=>2,"E"=>3)))

@assert n3.array == n4.array == a
@assert dimnames(n3) == dimnames(n4) == Any[:A,:B]
@assert names(n3,1) == names(n4,1) == ["a","b"]
@assert names(n3,2) == names(n4,2) == ["C","D","E"]

## 0-dim case #21
if VERSION ≥ v"0.4-dev"
    n0 = NamedArray(Array{Int}())
    @assert size(n0) == ()
    @assert n0[1] == n0.array[1]
end

print("getindex, ")
## getindex
@assert [x for x in n] == [x for x in n.array]
@assert n[2,4] == n.array[2,4]
if VERSION < v"0.4-dev"
    @assert n[2//1,4.0] == n.array[2,4]
end
## more indexing
first = n.array[1,:]
@assert convert(Array, n["one", :]) == first
@assert n[Not("two"), :].array == n.array[1:1,:]
@assert convert(Array, n[1, 2:3]) == n.array[1,2:3]
if VERSION < v"0.5.0-dev"
    @assert names(n["one", :],1) == ["one"]
end
@assert names(n[Not("one"), :],1) == ["two"]
@assert names(n[1:1, Not("a")], 2) == ["b", "c", "d"]

print("copy, ")
## copy
m = copy(n)
@assert m == n

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
@assert m.array == [0. 10 20 5; 1 2 -1 4]
if VERSION >= v"0.4.0-dev"
    m2 = copy(m)
    for i in eachindex(m)
        m[i] = 2*m[i]
    end
    @assert 2*(m2.array) == m.array
end

print("sum, ")
## sum
@assert sum(n) == sum(n.array)
@assert sum(n, 1).array == sum(n.array, 1)
@assert sum(n, 2).array == sum(n.array, 2)
@assert names(sum(n, 2),1) == ["one", "two"]

print("conversions, ")
## conversion
@assert convert(Array, n) == n.array
@assert @compat map(Float32, n).array == @compat map(Float32, n.array)

print("changing names, ")
## changingnames
for  f = (:sum, :prod, :maximum, :minimum, :mean, :std, :var)
    for dim=1:2
        @eval @assert ($f)(n,$dim).array == ($f)(n.array,$dim)
    end
end

for f in (:cumprod, :cumsum, :cumsum_kbn, :cummin, :cummax)
    for dim=1:2
        @eval @assert ($f)(n,$dim).array == ($f)(n.array,$dim)
    end
end

print("multi-dimensional, ")
#multidimensional
m = NamedArray(rand(2,3,4,3,2,3))
for i1=1:2 for i2=1:3 for i3=1:4 for i4=1:3 for i5=1:2 for i6=1:3
    @assert m[i1,i2,i3,i4,i5,i6] == m.array[i1,i2,i3,i4,i5,i6]
    @assert m[string(i1), string(i2), string(i3), string(i4), string(i5), string(i6)] == m.array[i1,i2,i3,i4,i5,i6]
end end end end end end

print("dodgy indices, ")
## weird indices
m = NamedArray(rand(4), ([1//1, 1//2, 1//3, 1//4],), ("weird",))
@assert m[1//2] == m.array[2]
@assert m[[1//4,1//3]] == m.array[[4,3]]
m[1//4] = 1
@assert m[4] == 1

m = NamedArray(rand(4), ([4, 3, 2, 1],), ("reverse confusion",))
@assert m[1] == m.array[4]
## this goes wrong for julia-v0.3
## @assert array(m[[4,3,2,1]]) == m.array
print("sort, ")
m = NamedArray(rand(100))
ms = sort(m)
@assert ms.array == sort(m.array)
@assert names(ms, 1) == names(m, 1)[sortperm(m.array)]

print("hcat, ")
letters = [string(@compat Char(96+i)) for i=1:26]
m = NamedArray(rand(10), (letters[1:10],))
m2 = NamedArray(rand(10), (letters[1:10],))
mm = hcat(m, m2)
@assert mm.array == hcat(m.array, m2.array)
@assert names(mm,1) == names(m,1)
print("broadcast, ")
@assert broadcast(-, n, mean(n,1)).array == broadcast(-, n.array, mean(n.array,1))

print("vectorized, ")
## a selection of vectorized functions
for f in  (:sin, :cos, :tan,  :sinpi, :cospi, :sinh, :cosh, :tanh, :asin, :acos, :atan, :sinc, :cosc, :deg2rad, :log, :log2, :log10, :log1p, :exp, :exp2, :exp10, :expm1, :abs, :abs2, :sign, :sqrt,  :erf, :erfc, :erfcx, :erfi, :dawson, :erfinv, :erfcinv, :gamma, :lgamma, :digamma, :invdigamma, :trigamma, :besselj0, :besselj1, :bessely0, :bessely1, :eta, :zeta)
    @eval @assert ($f)(n).array == ($f)(n.array)
end

print("matmul, ")
## matmul
for m in (NamedArray(rand(4)), NamedArray(rand(4,3)))
    m * m'
    m' * m
    @assert n * m == n * m.array == n.array * m == n.array * m.array
    ## the first expression dispatches Ac_mul_Bc!:
    @assert isapprox(m' * n.array', m' * n')
    @assert isapprox(m' * n', m.array' * n')
    @assert isapprox(m.array' * n', m.array' * n.array')
end

print("re-arrange, ")
## rearranging
@assert n'.array == n.array'
for dim=1:2
    @assert flipdim(n,dim).array == flipdim(n.array,dim)
    @assert names(flipdim(n,dim),dim) == reverse(names(n,dim))
end

p = randperm(ndims(n))
@assert permutedims(n, p).array == permutedims(n.array, p)

v = NamedArray(rand(10))
p = rand(1:factorial(length(v)))
@assert nthperm(v,p).array == nthperm(v.array, p)
@assert names(nthperm(v,p),1) == nthperm(names(v,1), p)
vv = copy(v)
nthperm!(vv, p)
@assert vv == nthperm(v, p)

p = randperm(length(v))
vv = copy(v)
permute!(vv, p)
a = copy(v.array)
nm = copy(names(v,1))
permute!(a, p)
permute!(nm, p)
@assert vv.array == a
@assert names(vv,1) == nm
ipermute!(vv, p)
@assert vv == v

vv = shuffle(v)
shuffle!(vv)
@assert reverse(v).array == reverse(v.array)
@assert names(reverse(v),1) == reverse(names(v,1))
vv = copy(v)
reverse!(vv)
@assert vv == reverse(v)

if VERSION >= v"0.4.0-dev"
    print("eachindex, ")
    ## eachindex
    for i in eachindex(n)
        @assert n[i] == n.array[i]
    end
end

include("matrixops.jl")

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
## compile
sgetindex(n)
sgetindex(n.array)

n = NamedArray(rand(1000,1000))
t1 = @elapsed sgetindex(n)
t2 = @elapsed sgetindex(n.array)
si, sj = allnames(n)
t3 = @elapsed sgetindex(n, si, sj)

println("Timing named index:", t1, " array index:", t2, " named key:", t3)
