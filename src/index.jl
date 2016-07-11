## index.jl getindex and setindex methods for NamedArray
## (c) 2013--2016 David A. van Leeuwen

## This code is licensed under the MIT license
## See the file LICENSE.md in this distribution

import Base.getindex, Base.to_index

## special 0-dimensional case
getindex{T}(a::NamedArray{T,0}, i::Real) = getindex(a.array, i)

@inline function getindex{T,N}(a::NamedArray{T,N}, I::Vararg{Any,N})
    namedgetindex(a, map((d,i)->indices(d, i), a.dicts, I)...)
end

## 0.4-dev functions
if VERSION >= v"0.4.0-dev"
    getindex(a::NamedArray, it::Base.IteratorsMD.CartesianIndex) = getindex(a.array, it)
end

## indices(::Associative, index) converts any type `index` to Integer

## single index
indices{K<:Real,V<:Integer}(dict::Associative{K,V}, i::K) = dict[i]
indices{K,V<:Integer}(dict::Associative{K,V}, i::Real) = to_index(i)
indices{K,V<:Integer}(dict::Associative{K,V}, i::K) = dict[i]
if VERSION >= v"0.4.0-dev"
    ## ambiguity if dict key is CartesionIndex
    indices{K<:CartesianIndex,V<:Integer}(dict::Associative{K,V}, i::K) = dict[i]
    indices(dict::Associative, ci::CartesianIndex) = ci
end
## multiple indices
## the following two lines are partly because of ambiguity
indices{T<:Integer,V<:Integer}(dict::Associative{T,V}, i::AbstractArray{T}) = [dict[k] for k in i]
indices{T<:Real,V<:Integer}(dict::Associative{T,V}, i::AbstractArray{T}) = [dict[k] for k in i]
indices{T<:Integer,K,V<:Integer}(dict::Associative{K,V}, i::AbstractArray{T}) = i
indices{K,V<:Integer}(dict::Associative{K,V}, i::AbstractArray{K}) = [dict[k] for k in i]
## in 0.4, we need to take care of : ourselves it seems
indices{K,V<:Integer}(dict::Associative{K,V}, ::Colon) = collect(1:length(dict))

## negation
indices{K<:Not,V<:Integer}(dict::Associative{K,V}, i::K) = dict[i]
indices(dict::Associative, i::Not) = setdiff(1:length(dict), indices(dict, i.index))

namedgetindex(a::NamedArray, i::Integer) = getindex(a.array, i)
namedgetindex(a::NamedArray, i1::Integer, i2::Integer) = getindex(a.array, i1, i2)
namedgetindex(a::NamedArray, i1::Integer, i2::Integer, i3::Integer) = getindex(a.array, i1, i2, i3)
namedgetindex(a::NamedArray, i1::Integer, i2::Integer, i3::Integer, i4::Integer) = getindex(a.array, i1, i2, i3, i4)
namedgetindex(a::NamedArray, i1::Integer, i2::Integer, i3::Integer, i4::Integer, i5::Integer) = getindex(a.array, i1, i2, i3, i4, i5)
namedgetindex(a::NamedArray, i1::Integer, i2::Integer, i3::Integer, i4::Integer, i5::Integer, I::Integer...) = getindex(a.array, i1, i2, i3, i4, i5, I...)

## namedgetindex collects the elements from the array, and takes care of the index names
## `index` is an integer now, and has been computed by `indices()`
function namedgetindex(n::NamedArray, index...)
    a = getindex(n.array, index...)
    dims = map(length, index)
    N = length(dims)
    while dims[N] == 1 && N > 1
        N -= 1
    end
    if ndims(a) != N || length(dims) == 1 && ndims(n) > 1
        return a;               # number of dimension changed
    end
    newnames = Any[]
    for d = 1:N
        sortkeys = names(n, d)
        push!(newnames, eltype(sortkeys)[sortkeys[i] for i in index[d]])
    end
    NamedArray(a, tuple(newnames...), tuple(n.dimnames[1:N]...))
end

function indices(n::NamedArray, I::Pair...)
    length(I) == ndims(n) || error("Incorrect number of dimensions")
    dict = Dict{Any,Any}(I...)
    Set(keys(dict)) == Set(n.dimnames) || error("Dimension name mismatch")
    result = Vector{Int}(ndims(n))
    for (i, name) in enumerate(n.dimnames)
        result[i] = n.dicts[i][dict[name]]
    end
    return result
end

getindex(n::NamedArray, I::Pair...) = getindex(n.array, indices(n, I...)...)

import Base.setindex!

setindex!{T}(A::NamedArray{T}, x) = setindex!(A, convert(T,x), 1)

# n[1:4] = 5
setindex!{T<:Real}(A::NamedArray, x, I::Union{Colon,AbstractVector{T}}) = setindex!(A.array, x, I)

# n[1:4] = 1:4
## shamelessly copied from array.jl
function setindex!{T}(A::NamedArray{T}, X::ArrayOrNamed{T}, I::Range{Int})
    if length(X) != length(I); error("argument dimensions must match"); end
    copy!(A, first(I), X, 1, length(I))
    return A
end

## This takes care of most other cases
@inline function setindex!{T,N}(A::NamedArray{T,N}, x, I::Vararg{Any,N})
    II = map((d,i)->indices(d, i), A.dicts, I)
    setindex!(A.array, x, II...)
end

## 0.4-dev functions
if VERSION >= v"0.4.0-dev"
    setindex!(a::NamedArray, x, it::Base.IteratorsMD.CartesianIndex) = setindex!(a.array, x, it)
end

@inline setindex!{T,N}(n::NamedArray{T,N}, x, I::Vararg{Pair,N}) = setindex!(n.array, x, indices(n, I...)...)
