## NamedArrays is loaded by runtests.jl

print("Starting test, no assertions should fail...")

## constructors
n = NamedArray(Complex64, 5, 8)
n = NamedArray(rand(2,4))
setnames!(n, ["one", "two"], 1)
setnames!(n, ["a", "b", "c", "d"], 2)     

## getindex
@assert [x for x in n] == [x for x in n.array]
@assert n[2,4] == n.array[2,4]

## setindex
n[1,1] = 0
@assert n[1,1] == 0

## sum
@assert sum(n) == sum(n.array)
@assert sum(n, 1).array == sum(n.array, 1)
@assert sum(n, 2).array == sum(n.array, 2)
@assert names(sum(n, 2),1) == ["one", "two"]

## conversion
@assert convert(Array, n) == n.array
@assert float32(n).array == float32(n.array)

## indexing
first = n.array[1,:]
@assert n["one", :].array == first
@assert n[!"two", :].array == first
@assert n[1, 2:3].array == first[:,2:3]
@assert names(n["one", :],1) == ["one"]
@assert names(n[!"one", :],1) == ["two"]
@assert names(n[1, !"a"], 2) == ["b", "c", "d"]

## copy
m = copy(n)
@assert m == n

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

m = NamedArray(rand(10))
@assert hcat(m, m).array == hcat(m.array, m.array)
@assert broadcast(-, n, mean(n,1)).array == broadcast(-, n.array, mean(n.array,1))

## a selection of vectorized functions
for f in  (:sin, :cos, :tan,  :sinpi, :cospi, :sinh, :cosh, :tanh, :asin, :acos, :atan, :sinc, :cosc, :deg2rad, :log, :log2, :log10, :log1p, :exp, :exp2, :exp10, :expm1, :iround, :iceil, :ifloor, :itrunc, :abs, :abs2, :sign, :sqrt,  :erf, :erfc, :erfcx, :erfi, :dawson, :erfinv, :erfcinv, :gamma, :lgamma, :digamma, :invdigamma, :trigamma, :besselj0, :besselj1, :bessely0, :bessely1, :eta, :zeta)
    @eval @assert ($f)(n).array == ($f)(n.array)
end

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




println(" done")
