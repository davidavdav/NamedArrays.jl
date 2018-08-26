## changingnames.jl  methods for NamedArray that change some of the names

## (c) 2013, 2017 David A. van Leeuwen

## This code is licensed under the MIT license
## See the file LICENSE.md in this distribution

## sum etc: keep names in one dimension
for f in (:(Base.sum),
          :(Base.prod),
          :(Base.maximum),
          :(Base.minimum),
          :(Statistics.mean),
          :(Statistics.std),
          :(Statistics.var))
    @eval function ($f)(a::NamedArray{T,N}; dims=:) where {T,N}
        s = ($f)(a.array, dims=dims)
        if !isa(s, AbstractArray)
            return s
        else
            dicts = tuple([issubset(i,dims) ? OrderedDict(string($f,"(",a.dimnames[i],")") => 1) : a.dicts[i] for i=1:ndims(a)]...)
            NamedArray{T,N,typeof(a.array), typeof(dicts)}(s, dicts, a.dimnames)
        end
    end
end

## I forgot what `fan` stands for.  Function Apply Name?
function fan(f::Function, fname::AbstractString, a::NamedArray{T,N}, dim::Int) where {T,N}
    DimNamType = eltype(a.dimnames)
    dimnames = Array{DimNamType}(undef, N)
    for i=1:N
        if i==dim
            dimnames[i] = DimNamType(string(fname, "(", a.dimnames[dim], ")"))
        else
            dimnames[i] = a.dimnames[i]
        end
    end
     NamedArray(f(a.array,dim), a.dicts, tuple(dimnames...))
end

## rename a dimension
for f in (:cumprod, :cumsum)
    @eval Base.$f(a::NamedArray, d::Integer) = fan($f, string($f), a, d)
end
