## index.jl getindex and setindex methods for NamedArray
## (c) 2013--2014 David A. van Leeuwen

import Base.getindex, Base.to_index

## ambiguity from abstractarray.jl
getindex(a::NamedArray, i::Real) = namedgetindex(a, to_index(i))
getindex(a::NamedArray, i::AbstractArray) = namedgetindex(a, indices(a.dicts[1], i))
## from subarray.jl
getindex{T}(a::NamedArray{T,1}, ::Colon) = a

getindex(a::NamedArray, i) = namedgetindex(a, indices(a.dicts[1], i))
getindex(a::NamedArray, i1, i2) = namedgetindex(a, indices(a.dicts[1], i1), indices(a.dicts[2], i2))
getindex(a::NamedArray, i1, i2, i3) = namedgetindex(a, indices(a.dicts[1], i1), indices(a.dicts[2], i2), indices(a.dicts[3], i3))
getindex(a::NamedArray, i1, i2, i3, i4) = namedgetindex(a, indices(a.dicts[1], i1), indices(a.dicts[2], i2), indices(a.dicts[3], i3), indices(a.dicts[4], i4))
getindex(a::NamedArray, i1, i2, i3, i4, i5) = namedgetindex(a, indices(a.dicts[1], i1), indices(a.dicts[2], i2), indices(a.dicts[3], i3), indices(a.dicts[4], i4), indices(a.dicts[5], i5))
getindex(a::NamedArray, i1, i2, i3, i4, i5, I...) = namedgetindex(a, indices(a.dicts[1], i1), indices(a.dicts[2], i2), indices(a.dicts[3], i3), indices(a.dicts[4], i4), indices(a.dicts[5], i5), [indices(a.dicts[5+i], ind) for (i,ind) in enumerate(I...)]...)

## 0.4-dev functions
if VERSION >= v"0.4.0-dev"
    getindex(a::NamedArray, it::Base.IteratorsMD.CartesianIndex) = getindex(a.array, it)
end

## single index
indices{K}(dict::Dict{K,Int}, i::Integer) = i
indices{K}(dict::Dict{K,Int}, i::K) = dict[i]
## multiple indices
indices{T<:Integer}(dict::Dict{T,Int}, i::AbstractArray{T}) = [dict[k] for k in i]
indices{T<:Integer, K}(dict::Dict{K,Int}, i::AbstractArray{T}) = i
indices{K}(dict::Dict{K,Int}, i::AbstractArray{K}) = [dict[k] for k in i]

## negation
indices{K<:Not}(dict::Dict{K,Int}, i::K) = dict[i]
indices(dict::Dict, i::Not) = setdiff(1:length(dict), indices(dict, i.index))

namedgetindex(a::NamedArray, i::Integer) = getindex(a.array, i)
namedgetindex(a::NamedArray, i1::Integer, i2::Integer) = getindex(a.array, i1, i2)

function namedgetindex(n::NamedArray, index...)
    a = getindex(n.array, index...)
    dims = map(length, index)
    N = length(dims)
    while dims[N]==1 && N>1
        N -= 1
    end
    if ndims(a) != N || length(dims)==1 && ndims(n)>1
        return a;               # number of dimension changed
    end
    newnames = Any[]
    for d = 1:N
        sortkeys = names(n, d)
        push!(newnames, [sortkeys[i] for i in index[d]])
    end
    NamedArray(a, tuple(newnames...), tuple(n.dimnames[1:N]...))
end

import Base.setindex!

setindex!{T}(A::NamedArray{T}, x) = setindex!(A, convert(T,x), 1)

setindex!{T}(A::NamedArray{T}, x, i0::Real) = setindex!(A.array, convert(T,x), to_index(i0))
setindex!{T}(A::NamedArray{T}, x, i0::Real, i1::Real) =
    setindex!(A.array, convert(T,x), to_index(i0), to_index(i1))
setindex!{T}(A::NamedArray{T}, x, i0::Real, i1::Real, i2::Real) =
    setindex!(A.array, convert(T,x), to_index(i0), to_index(i1), to_index(i2))
setindex!{T}(A::NamedArray{T}, x, i0::Real, i1::Real, i2::Real, i3::Real) =
    setindex!(A.array, convert(T,x), to_index(i0), to_index(i1), to_index(i2), to_index(i3))
setindex!{T}(A::NamedArray{T}, x, i0::Real, i1::Real, i2::Real, i3::Real, i4::Real) =
    setindex!(A.array, convert(T,x), to_index(i0), to_index(i1), to_index(i2), to_index(i3), to_index(i4))
setindex!{T}(A::NamedArray{T}, x, i0::Real, i1::Real, i2::Real, i3::Real, i4::Real, i5::Real) =
    setindex!(A.array, convert(T,x), to_index(i0), to_index(i1), to_index(i2), to_index(i3), to_index(i4), to_index(i5))
setindex!{T}(A::NamedArray{T}, x, i0::Real, i1::Real, i2::Real, i3::Real, i4::Real, i5::Real, I::Int...) =
    setindex!(A.array, convert(T,x), to_index(i0), to_index(i1), to_index(i2), to_index(i3), to_index(i4), to_index(i5), I...)
