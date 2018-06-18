## changingnames.jl  methods for NamedArray that change some of the names

## (c) 2013, 2017 David A. van Leeuwen

## This code is licensed under the MIT license
## See the file LICENSE.md in this distribution

## sum etc: keep names in one dimension
# import Base.sum, Base.prod, Base.maximum, Base.minimum, Base.mean, Base.std
for f = (:sum, :prod, :maximum, :minimum, :mean, :std, :var)
    eval(Expr(:import, :Base, f))
    @eval function ($f){T,N}(a::NamedArray{T,N}, d::Dims)
        s = ($f)(a.array, d)
        dicts = tuple([issubset(i,d) ? OrderedDict(string($f,"(",a.dimnames[i],")") => 1) : a.dicts[i] for i=1:ndims(a)]...)
        NamedArray{T,N,typeof(a.array)}(s, dicts, a.dimnames)
    end
    @eval ($f)(a::NamedArray, d::Int) = ($f)(a, (d,))
end

## I forgot what `fan` stands for.  Function Apply Name?
function fan{T,N}(f::Function, fname::AbstractString, a::NamedArray{T,N}, dim::Int)
    dimnames = Array{Any}(N)
    for i=1:N
        if i==dim
            dimnames[i] = string(fname, "(", a.dimnames[dim], ")")
        else
            dimnames[i] = a.dimnames[i]
        end
    end
     NamedArray(f(a.array,dim), a.dicts, tuple(dimnames...))
end

## rename a dimension
for f in (:cumprod, :cumsum, :cumsum_kbn)
    eval(Expr(:import, :Base, f))
    @eval ($f)(a::NamedArray, d::Integer=1) = fan($f, string($f), a, d)
end
